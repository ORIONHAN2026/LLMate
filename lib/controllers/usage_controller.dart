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

  /// sembast store 名称（每条记录为一次请求的用量明细）
  static const String _storeName = 'usage_details';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    return _db!;
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

  // ==================== 单条用量明细：增 / 删 / 改 / 查 ====================

  /// 新增单条用量明细（按明细 key upsert）
  Future<void> addUsage(UsageDetail detail, {String? sessionId}) async {
    try {
      final db = await _database;
      await _store.record(_detailKey(detail)).put(db, {
        'sessionId': sessionId ?? '',
        ...detail.toJson(),
      });
    } catch (e) {
      debugPrint('⚠️ [Usage] 新增单条用量失败: $e');
    }
  }

  /// 更新单条用量明细（按明细 key upsert）
  Future<void> updateUsage(UsageDetail detail, {String? sessionId}) async {
    try {
      final db = await _database;
      await _store.record(_detailKey(detail)).put(db, {
        'sessionId': sessionId ?? '',
        ...detail.toJson(),
      });
    } catch (e) {
      debugPrint('⚠️ [Usage] 更新单条用量失败: $e');
    }
  }

  /// 查询单条用量明细（按明细 key）
  Future<UsageDetail?> getUsage(UsageDetail detail) async {
    try {
      final db = await _database;
      final rec = await _store.record(_detailKey(detail)).get(db);
      if (rec == null) return null;
      return UsageDetail.fromJson(rec);
    } catch (e) {
      debugPrint('⚠️ [Usage] 查询单条用量失败: $e');
      return null;
    }
  }

  /// 删除单条用量明细（按明细 key）
  Future<void> deleteUsage(UsageDetail detail) async {
    try {
      final db = await _database;
      await _store.record(_detailKey(detail)).delete(db);
    } catch (e) {
      debugPrint('⚠️ [Usage] 删除单条用量失败: $e');
    }
  }
}
