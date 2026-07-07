import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';

import '../../../controllers/session_controller.dart';
import '../../../models/chat/chat_session.dart';

/// 用量配额检查中间件
///
/// 1. 从 `request.context['session']` 获取已校验的会话
/// 2. 尝试重置配额周期（跨自然周期自动重置）
/// 3. 检查 Token/费用/请求次数是否超限
///
/// 将可能更新后的 [ChatSession] 重新存入 context。
Handler quotaGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context['session'] as ChatSession?;

    if (session == null) {
      // 上游中间件应已处理，此处兜底
      return innerHandler(request);
    }

    // Step 1: 尝试重置配额周期
    var currentSession = session;
    final resetSession = currentSession.tryResetQuotaPeriod();
    if (resetSession != null) {
      currentSession = resetSession;
      // 持久化重置后的 session
      final sessionController = Get.find<SessionController>();
      sessionController.updateSession(resetSession);
      debugPrint('🔄 [Quota Guard] 配额周期已重置: ${currentSession.sessionId}');
    }

    // Step 2: 检查配额
    final quotaResult = currentSession.checkQuota();
    if (quotaResult.exceeded) {
      debugPrint(
        '⛔ [Quota Guard] 配额超限: ${quotaResult.reason} → 429',
      );
      return Response(
        429,
        body: jsonEncode({
          'error': {
            'message': quotaResult.reason ?? 'Usage limit exceeded',
            'type': 'insufficient_quota',
            'code': 'quota_exceeded',
            'detail': quotaResult.detail,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    debugPrint('✅ [Quota Guard] 配额检查通过: ${currentSession.sessionId}');

    // 将可能更新后的 session 存回 context
    final updatedRequest = request.change(context: {
      ...request.context,
      'session': currentSession,
    });

    return innerHandler(updatedRequest);
  };
}
