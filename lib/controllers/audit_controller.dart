import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../core/http/sensitive_masker.dart';
import '../data/storage_paths.dart';

/// 单条审计日志条目
///
/// 持久化于 sembast 数据库 `~/.llmate/autits.db` 的 `audit_logs` store 中。
class AuditLog {
  final String? requestId;
  final DateTime timestamp;
  final String sessionId;
  final String modelId;

  /// 第三方客户端发送的原始请求体（已按风控开关脱敏）
  final dynamic originRequest;

  /// 中间件处理后最终发送给 LLM 的请求体（已按风控开关脱敏）
  final dynamic middleRequest;

  /// 累计回复给第三方客户端的完整内容（已按风控开关脱敏）
  final String response;

  /// 若请求处理出错，记录错误信息
  final String? error;

  AuditLog({
    this.requestId,
    required this.timestamp,
    required this.sessionId,
    required this.modelId,
    this.originRequest,
    this.middleRequest,
    required this.response,
    this.error,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      requestId: json['requestId'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      sessionId: json['sessionId'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      originRequest: json['originRequest'],
      middleRequest: json['middleRequest'],
      response: json['response'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (requestId != null) 'requestId': requestId,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'modelId': modelId,
      'originRequest': originRequest,
      'middleRequest': middleRequest,
      'response': response,
      if (error != null) 'error': error,
    };
  }
}

/// 审计控制器
///
/// 集中负责请求/响应审计日志的「读」与「写」，底层使用嵌入式 NoSQL 数据库
/// [sembast]，数据库文件位于 `~/.llmate/autits.db`，store 名为 `audit_logs`。
///
///   - 写：[saveRequestResponseLog] 将日志写入 `autits.db`，并在内存保留
///     最近若干条供 UI 展示。落盘前会按风控开关（[SensitiveMaskOptions]）对
///     手机号 / 身份证号等敏感信息进行 * 号脱敏。
///   - 读：[loadAuditLogs] / [loadAuditById] 从数据库加载审计日志（供审计查看界面）。
///   - 旧版基于 `~/.llmate/audit/*.json` 的审计文件会在首次打开数据库时
///     自动迁移进 `autits.db` 并删除旧目录，避免数据丢失。
///
/// 该控制器在 [LocalHttpService] 中被调用：每次大模型请求结束后，由 HTTP 层
/// 调用 [saveRequestResponseLog] 把本次请求/响应写入审计日志。
class AuditController extends GetxController {
  AuditController();

  /// 单例访问（未注册时自动注册，保证 HTTP 静态上下文也能安全调用）
  static AuditController get instance {
    if (Get.isRegistered<AuditController>()) return Get.find<AuditController>();
    return Get.put(AuditController());
  }

  /// 内存缓存的最近审计日志（最新在前），供 UI 展示
  final recentLogs = <AuditLog>[].obs;

  /// 内存缓存最大保留条数
  static const int _maxCached = 200;

  /// 审计数据库路径：~/.llmate/autits.db
  static String get _dbPath => p.join(StoragePaths.root, 'autits.db');

  /// 旧版审计目录（迁移源）：~/.llmate/audit/
  static String get _legacyAuditDir => p.join(StoragePaths.root, 'audit');

  /// sembast store 名称
  static const String _storeName = 'audit_logs';
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

  /// 一次性将旧版 `audit/*.json` 文件迁移进数据库（仅当数据库为空时执行一次）
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final legacyDir = Directory(_legacyAuditDir);
      if (!await legacyDir.exists()) return;
      final count = await _store.count(db);
      if (count > 0) return; // 库中已有数据，跳过迁移

      final files = (await legacyDir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('-audit.json'))
          .toList();

      for (final f in files) {
        try {
          final json =
              jsonDecode(await f.readAsString()) as Map<String, dynamic>;
          await _store.add(db, json);
        } catch (_) {
          // 单条解析失败不影响其他条目
        }
      }
      await legacyDir.delete(recursive: true);
      debugPrint('📦 [Audit] 已迁移旧审计文件至 autits.db');
    } catch (_) {
      // 迁移失败不影响新写入
    }
  }

  /// 写出前对原始请求体字符串做解析 + 脱敏
  static dynamic _parseAndMaskOrigin(
    String originBodyStr,
    SensitiveMaskOptions maskOptions,
  ) {
    if (originBodyStr.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(originBodyStr);
      return maskSensitiveJson(decoded, maskOptions);
    } catch (_) {
      // 非 JSON 文本则按纯文本脱敏
      return maskSensitiveText(originBodyStr, maskOptions);
    }
  }

  /// ── 写：保存一次请求/响应的审计日志 ──
  ///
  /// [originBodyStr] 第三方客户端发送的原始请求体字符串。
  /// [body] 中间件处理后最终发给 LLM 的请求体（可为 null，表示异常路径）。
  /// [responseContent] 累计回复内容（可为空）。
  /// [maskOptions] 风控脱敏开关，由大模型安全设置驱动，缺省全部关闭。
  Future<void> saveRequestResponseLog({
    String? requestId,
    required String originBodyStr,
    required Map<String, dynamic>? body,
    required String responseContent,
    required String sessionId,
    required String modelId,
    SensitiveMaskOptions maskOptions = const SensitiveMaskOptions(),
    String? error,
  }) async {
    try {
      final entry = AuditLog(
        requestId: requestId,
        timestamp: DateTime.now(),
        sessionId: sessionId,
        modelId: modelId,
        originRequest: _parseAndMaskOrigin(originBodyStr, maskOptions),
        middleRequest:
            body != null ? maskSensitiveBody(body, maskOptions) : {},
        response: maskSensitiveText(responseContent, maskOptions),
        error: error,
      );

      final db = await _database;
      await _store.add(db, entry.toJson());

      // 更新内存缓存（最新在前）
      recentLogs.insert(0, entry);
      if (recentLogs.length > _maxCached) {
        recentLogs.removeRange(_maxCached, recentLogs.length);
      }

      debugPrint('📝 [Audit] 请求审计日志已保存 (session=$sessionId)');
    } catch (e) {
      debugPrint('⚠️ [Audit] 保存审计日志失败: $e');
    }
  }

  /// ── 读：加载审计日志 ──
  ///
  /// [sessionId] 为 null 时加载全部会话的日志；否则只返回该会话的日志。
  /// [limit] 限制返回条数（默认 200），结果按时间倒序（最新在前）。
  Future<List<AuditLog>> loadAuditLogs({
    String? sessionId,
    int limit = _maxCached,
  }) async {
    try {
      final db = await _database;
      final finder = Finder(
        filter: sessionId != null ? Filter.equals('sessionId', sessionId) : null,
        sortOrders: [SortOrder('timestamp', false)],
        limit: limit,
      );
      final records = await _store.find(db, finder: finder);
      return records.map((r) => AuditLog.fromJson(r.value)).toList();
    } catch (e) {
      debugPrint('⚠️ [Audit] 读取审计日志失败: $e');
      return [];
    }
  }

  /// ── 读：按 requestId 读取单条审计日志 ──
  Future<AuditLog?> loadAuditById(String requestId) async {
    try {
      final db = await _database;
      final finder = Finder(
        filter: Filter.equals('requestId', requestId),
        limit: 1,
      );
      final records = await _store.find(db, finder: finder);
      if (records.isEmpty) return null;
      return AuditLog.fromJson(records.first.value);
    } catch (e) {
      debugPrint('⚠️ [Audit] 按 requestId 读取失败: $e');
      return null;
    }
  }

  /// ── 写：清空所有审计日志（数据库 + 内存）──
  Future<void> clearAuditLogs() async {
    try {
      final db = await _database;
      await _store.delete(db);
      recentLogs.clear();
      debugPrint('🧹 [Audit] 已清空审计日志');
    } catch (e) {
      debugPrint('⚠️ [Audit] 清空审计日志失败: $e');
    }
  }
}
