import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../core/http/sensitive_masker.dart';
import '../data/storage_paths.dart';

/// 单条审计日志条目
///
/// 对应磁盘文件 `~/.llmate/audit/{timestamp}-{modelId}-{sessionId}-audit.json`。
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
/// 集中负责请求/响应审计日志的「读」与「写」：
///   - 写：[saveRequestResponseLog] 落盘到 `~/.llmate/audit/`，并在内存保留
///     最近若干条供 UI 展示。落盘前会按风控开关（[SensitiveMaskOptions]）对
///     手机号 / 身份证号等敏感信息进行 * 号脱敏。
///   - 读：[loadAuditLogs] / [loadAuditById] 从磁盘加载审计日志（供审计查看界面）。
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

  /// 审计日志根目录：~/.llmate/audit/
  static String get _auditDirPath => p.join(StoragePaths.root, 'audit');

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

      await _writeToFile(entry);

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

  /// 将单条审计日志写入磁盘
  Future<void> _writeToFile(AuditLog entry) async {
    final dir = Directory(_auditDirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // 文件名时间戳：年-月-日-时-分-秒（与历史文件命名保持一致）
    final ts = entry.timestamp;
    final timestamp =
        '${ts.year}-'
        '${ts.month.toString().padLeft(2, '0')}-'
        '${ts.day.toString().padLeft(2, '0')}-'
        '${ts.hour.toString().padLeft(2, '0')}-'
        '${ts.minute.toString().padLeft(2, '0')}-'
        '${ts.second.toString().padLeft(2, '0')}';

    final filename =
        '$timestamp-${entry.modelId}-${entry.sessionId}-audit.json';
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entry.toJson()),
    );
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
      final dir = Directory(_auditDirPath);
      if (!await dir.exists()) return [];

      final files = (await dir.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('-audit.json'))
          .toList();

      // 文件名带时间戳，字典序即时间序；倒序取最新在前
      files.sort((a, b) => b.path.compareTo(a.path));

      final result = <AuditLog>[];
      for (final f in files) {
        try {
          final content = await f.readAsString();
          final log = AuditLog.fromJson(
            jsonDecode(content) as Map<String, dynamic>,
          );
          if (sessionId != null && log.sessionId != sessionId) continue;
          result.add(log);
          if (result.length >= limit) break;
        } catch (_) {
          // 单条解析失败不影响其他条目
        }
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ [Audit] 读取审计日志失败: $e');
      return [];
    }
  }

  /// ── 读：按 requestId 读取单条审计日志 ──
  Future<AuditLog?> loadAuditById(String requestId) async {
    final logs = await loadAuditLogs(limit: _maxCached);
    try {
      return logs.firstWhere((e) => e.requestId == requestId);
    } catch (_) {
      return null;
    }
  }

  /// ── 写：清空所有审计日志（磁盘 + 内存）──
  Future<void> clearAuditLogs() async {
    try {
      final dir = Directory(_auditDirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      recentLogs.clear();
      debugPrint('🧹 [Audit] 已清空审计日志');
    } catch (e) {
      debugPrint('⚠️ [Audit] 清空审计日志失败: $e');
    }
  }
}
