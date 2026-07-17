import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../data/storage_paths.dart';
import '../models/chat/usage_stats.dart';

/// 用量控制器
///
/// 集中负责 LLM 请求「用量（token / 费用）」的读写，底层使用嵌入式 NoSQL 数据库
/// [sembast]，数据库文件位于 `~/.llmate/usages.db`，store 名为 `usage_details`。
///
///   - 写：[recordUsage] 将一次请求的用量明细写入 `usages.db`。
///   - 读：[loadDetails] / [getStats] 从数据库加载 / 聚合用量数据（供用量看板使用）。
///   - 旧版基于 `~/.llmate/usage/*.json` 的用量文件会在首次打开数据库时
///     自动迁移进 `usages.db`（按明细去重，仅执行一次），避免历史数据丢失。
///
/// 该控制器在 [LocalHttpService] 中被调用：每次大模型请求结束后，由 HTTP 层
/// 调用 [recordUsage] 把本次请求消耗的 token 与费用写入用量库。
class UsageController extends GetxController {
  UsageController();

  /// 单例访问（未注册时自动注册，保证 HTTP 静态上下文也能安全调用）
  static UsageController get instance {
    if (Get.isRegistered<UsageController>()) return Get.find<UsageController>();
    return Get.put(UsageController());
  }

  /// 用量数据库路径：~/.llmate/usages.db
  static String get _dbPath => p.join(StoragePaths.root, 'usages.db');

  /// 旧版用量目录（迁移源）：~/.llmate/usage/
  static String get _legacyUsageDir => p.join(StoragePaths.root, 'usage');

  /// sembast store 名称（每条记录为一次请求的用量明细）
  static const String _storeName = 'usage_details';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;
  bool _migrated = false;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版 `usage/*.json` 中的用量明细迁移进数据库。
  ///
  /// 旧文件按「时间戳-模型-会话-usage.json」命名，其内部的 `details` 为原始
  /// 请求明细列表；逐条写入数据库，并依据 (timestamp+model+cost) 去重，避免
  /// 不同粒度文件（分/时/日…）导入重复数据。仅当数据库中尚无对应明细时写入，
  /// 旧目录保留作备份。
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final legacyDir = Directory(_legacyUsageDir);
      if (!await legacyDir.exists()) return;

      final files = (await legacyDir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('-usage.json'))
          .toList();

      int migrated = 0;
      for (final f in files) {
        try {
          final json =
              jsonDecode(await f.readAsString()) as Map<String, dynamic>;
          final stats = UsageStats.fromJson(json);
          // 从文件名尽力恢复 sessionId（旧文件名末段为 -{modelId}-{sessionId}-usage）
          final sessionId = _sessionIdFromFilename(p.basename(f.path));
          for (final d in stats.details) {
            final key = _detailKey(d);
            final existing = await _store.record(key).get(db);
            if (existing == null) {
              await _store.record(key).put(db, {
                'sessionId': sessionId,
                ...d.toJson(),
              });
              migrated++;
            }
          }
        } catch (_) {
          // 单文件解析失败不影响其他文件
        }
      }
      if (migrated > 0) {
        debugPrint('📦 [Usage] 已迁移 $migrated 条旧用量明细至 usages.db');
      }
    } catch (e) {
      debugPrint('⚠️ [Usage] 迁移旧用量失败: $e');
    }
  }

  /// 从旧文件名恢复 sessionId（尽力而为，无法可靠拆分时返回 'unknown'）
  static String _sessionIdFromFilename(String basename) {
    final name = basename.replaceAll('-usage.json', '');
    final parts = name.split('-');
    // 文件名结构：{时间戳段...}-{modelId 段...}-{sessionId 段...}
    // 时间戳段长度决定粒度：5=分钟 4=小时 3=天 2=月 1=年
    int tsLen;
    switch (parts.length) {
      case 5: tsLen = 5; break;
      case 4: tsLen = 4; break;
      case 3: tsLen = 3; break;
      case 2: tsLen = 2; break;
      case 1: tsLen = 1; break;
      default: tsLen = 0;
    }
    if (tsLen == 0 || parts.length <= tsLen) return 'unknown';
    // 剩余部分中：最后一段为 sessionId 的最后一段，前面为 modelId + sessionId
    // 由于 modelId / sessionId 内部均可能含 '-'，无法精确拆分，故整体作为 sessionId 占位
    return parts.sublist(tsLen).join('-');
  }

  /// 明细去重键（时间戳 + 模型 + 费用，避免不同粒度文件重复导入）
  static String _detailKey(UsageDetail d) =>
      '${d.timestamp.toIso8601String()}_${d.model}_${d.cost.toStringAsFixed(6)}';

  /// ── 写：记录一次请求的用量明细 ──
  Future<void> recordUsage({
    required String sessionId,
    required String modelId,
    required int promptTokens,
    required int completionTokens,
    required double cost,
    String currency = 'USD',
    DateTime? timestamp,
  }) async {
    try {
      final detail = UsageDetail(
        timestamp: timestamp ?? DateTime.now(),
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        cost: cost,
        model: modelId,
        currency: currency,
      );
      final db = await _database;
      await _store.record(_detailKey(detail)).put(db, {
        'sessionId': sessionId,
        ...detail.toJson(),
      });
      debugPrint(
        '📊 [Usage] 用量已记录: session=$sessionId model=$modelId '
        'tokens=${detail.totalTokens} cost=${cost.toStringAsFixed(6)}',
      );
    } catch (e) {
      debugPrint('⚠️ [Usage] 保存用量失败: $e');
    }
  }

  /// ── 读：加载用量明细 ──
  ///
  /// [sessionId] / [modelId] 为 null 时不过滤该项。
  /// [start] / [end] 为可选时间范围（含端点）。结果按时间升序。
  Future<List<UsageDetail>> loadDetails({
    String? sessionId,
    String? modelId,
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    try {
      final db = await _database;
      final filters = <Filter>[];
      if (sessionId != null) {
        filters.add(Filter.equals('sessionId', sessionId));
      }
      if (modelId != null) {
        filters.add(Filter.equals('model', modelId));
      }
      // timestamp 以 ISO8601 字符串存储，可直接按字典序做范围过滤
      if (start != null) {
        filters.add(Filter.greaterThanOrEquals(
            'timestamp', start.toIso8601String()));
      }
      if (end != null) {
        filters.add(Filter.lessThanOrEquals('timestamp', end.toIso8601String()));
      }
      final finder = Finder(
        filter: filters.isEmpty ? null : Filter.and(filters),
        sortOrders: [SortOrder('timestamp', true)],
        limit: limit,
      );
      final records = await _store.find(db, finder: finder);
      return records
          .map((r) => UsageDetail.fromJson(r.value))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [Usage] 读取用量明细失败: $e');
      return [];
    }
  }

  /// ── 读：聚合为用量统计 ──
  ///
  /// 参数同 [loadDetails]，返回累计的 [UsageStats]（请求数 / token / 分币种费用）。
  Future<UsageStats> getStats({
    String? sessionId,
    String? modelId,
    DateTime? start,
    DateTime? end,
  }) async {
    final details = await loadDetails(
      sessionId: sessionId,
      modelId: modelId,
      start: start,
      end: end,
    );
    final stats = UsageStats.empty();
    for (final d in details) {
      stats.add(d);
    }
    return stats;
  }

  /// ── 写：清空所有用量数据（数据库）──
  Future<void> clearUsage() async {
    try {
      final db = await _database;
      await _store.delete(db);
      debugPrint('🧹 [Usage] 已清空用量数据');
    } catch (e) {
      debugPrint('⚠️ [Usage] 清空用量数据失败: $e');
    }
  }
}
