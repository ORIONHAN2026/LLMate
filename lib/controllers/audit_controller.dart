import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../core/http/sensitive_masker.dart';
import '../data/database.dart';
import '../models/audit.dart';

// 供既有调用方沿用：直接 `import 'audit_controller.dart'` 即可访问 [AuditLog]，
// 无需额外导入 models。
export '../models/audit.dart';

/// 审计控制器
///
/// 集中负责请求/响应审计日志的「读」与「写」，底层使用 Drift / SQLite 数据库
/// `~/.llmate/llmate.sqlite` 的 `audit_rows` 表。
///
///   - 写：[saveRequestResponseLog] 将日志写入 SQLite，并在内存保留
///     最近若干条供 UI 展示。落盘前会按风控开关（[SensitiveMaskOptions]）对
///     手机号 / 身份证号等敏感信息进行 * 号脱敏。
///   - 读：[loadAuditLogs] / [loadAuditById] 从数据库加载审计日志（供审计查看界面）。
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
        middleRequest: body != null ? maskSensitiveBody(body, maskOptions) : {},
        response: maskSensitiveText(responseContent, maskOptions),
        error: error,
      );

      if (entry.requestId != null && entry.requestId!.isNotEmpty) {
        await appDatabase.upsertAudit(entry);
      } else {
        await appDatabase.insertAudit(entry);
      }

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
      return await appDatabase.getAudits(sessionId: sessionId, limit: limit);
    } catch (e) {
      debugPrint('⚠️ [Audit] 读取审计日志失败: $e');
      return [];
    }
  }

  /// ── 读：按 requestId 读取单条审计日志 ──
  Future<AuditLog?> loadAuditById(String requestId) async {
    try {
      return await appDatabase.getAuditById(requestId);
    } catch (e) {
      debugPrint('⚠️ [Audit] 按 requestId 读取失败: $e');
      return null;
    }
  }

  /// ── 写：清空所有审计日志（数据库 + 内存）──
  Future<void> clearAuditLogs() async {
    try {
      await appDatabase.clearAudits();
      recentLogs.clear();
      debugPrint('🧹 [Audit] 已清空审计日志');
    } catch (e) {
      debugPrint('⚠️ [Audit] 清空审计日志失败: $e');
    }
  }

  // ==================== 单条审计日志：增 / 删 / 改 / 查 ====================

  /// 新增单条审计日志（若 requestId 非空则以其为 key upsert，否则追加）
  Future<void> addAudit(AuditLog log) async {
    try {
      if (log.requestId != null && log.requestId!.isNotEmpty) {
        await appDatabase.upsertAudit(log);
      } else {
        await appDatabase.insertAudit(log);
      }
      recentLogs.insert(0, log);
      if (recentLogs.length > _maxCached) {
        recentLogs.removeRange(_maxCached, recentLogs.length);
      }
    } catch (e) {
      debugPrint('⚠️ [Audit] 新增单条审计失败: $e');
    }
  }

  /// 查询单条审计日志（按 requestId）
  Future<AuditLog?> getAudit(String requestId) async {
    if (requestId.isEmpty) return null;
    return loadAuditById(requestId);
  }

  /// 更新单条审计日志（按 requestId 定位并 upsert）
  Future<void> updateAudit(AuditLog log) async {
    if (log.requestId == null || log.requestId!.isEmpty) return;
    try {
      await appDatabase.upsertAudit(log);
      final idx = recentLogs.indexWhere((l) => l.requestId == log.requestId);
      if (idx != -1) recentLogs[idx] = log;
    } catch (e) {
      debugPrint('⚠️ [Audit] 更新单条审计失败: $e');
    }
  }

  /// 删除单条审计日志（按 requestId 定位并删除）
  Future<void> deleteAudit(String requestId) async {
    if (requestId.isEmpty) return;
    try {
      await appDatabase.deleteAudit(requestId);
      recentLogs.removeWhere((l) => l.requestId == requestId);
    } catch (e) {
      debugPrint('⚠️ [Audit] 删除单条审计失败: $e');
    }
  }
}
