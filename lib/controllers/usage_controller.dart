import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/database.dart';
import '../models/chat/usage.dart';

/// 用量控制器
///
/// 集中负责 LLM 请求「用量（token / 费用）」的读写，底层使用 Drift / SQLite 数据库
/// `~/.llmate/llmate.sqlite` 的 `usage_rows` 表。
///
///   - 写：[recordUsage] 将一次请求的用量明细写入 SQLite。
///   - 读：[loadDetails] / [getStats] 从数据库加载 / 聚合用量数据（供用量看板使用）。
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
      await appDatabase.upsertUsage(sessionId, detail);
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
      return await appDatabase.getUsages(
        sessionId: sessionId,
        modelId: modelId,
        start: start,
        end: end,
        limit: limit,
      );
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
      await appDatabase.clearUsages();
      debugPrint('🧹 [Usage] 已清空用量数据');
    } catch (e) {
      debugPrint('⚠️ [Usage] 清空用量数据失败: $e');
    }
  }

  // ==================== 单条用量明细：增 / 删 / 改 / 查 ====================

  /// 新增单条用量明细（按明细 key upsert）
  Future<void> addUsage(UsageDetail detail, {String? sessionId}) async {
    try {
      await appDatabase.upsertUsage(sessionId ?? '', detail);
    } catch (e) {
      debugPrint('⚠️ [Usage] 新增单条用量失败: $e');
    }
  }

  /// 更新单条用量明细（按明细 key upsert）
  Future<void> updateUsage(UsageDetail detail, {String? sessionId}) async {
    try {
      await appDatabase.upsertUsage(sessionId ?? '', detail);
    } catch (e) {
      debugPrint('⚠️ [Usage] 更新单条用量失败: $e');
    }
  }

  /// 查询单条用量明细（按明细 key）
  Future<UsageDetail?> getUsage(UsageDetail detail) async {
    try {
      return await appDatabase.getUsage(detail);
    } catch (e) {
      debugPrint('⚠️ [Usage] 查询单条用量失败: $e');
      return null;
    }
  }

  /// 删除单条用量明细（按明细 key）
  Future<void> deleteUsage(UsageDetail detail) async {
    try {
      await appDatabase.deleteUsage(detail);
    } catch (e) {
      debugPrint('⚠️ [Usage] 删除单条用量失败: $e');
    }
  }
}
