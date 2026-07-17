import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../models/chat/session.dart';

/// 禁用状态检查中间件
///
/// 紧跟在 [apiKeyGuard] 之后执行，从 `request.context['session']` 读取已校验的会话。
/// 若会话被禁用（[ChatSession.isDisabled]），无论应用内还是外部 HTTP 调用，
/// 均直接返回 403 错误，拒绝本次请求。
Handler disabledGuard(Handler innerHandler) {
  return (Request request) async {
    // 上游尚未装载 session（理论上不会走到这里），放行交由下游处理
    final session = request.context['session'] as ChatSession?;
    if (session == null) {
      return innerHandler(request);
    }

    if (session.isDisabled) {
      debugPrint('🚫 [Disabled Guard] 会话已禁用: ${session.sessionId} → 403');
      return Response(
        403,
        body: jsonEncode({
          'error': {
            'message': 'This session has been disabled and is not available.',
            'type': 'invalid_request_error',
            'code': 'session_disabled',
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    return innerHandler(request);
  };
}
