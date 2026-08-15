import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';

import '../../../controllers/session_controller.dart';

/// API Key 校验中间件（风控检查）
///
/// 1. 从 Authorization header 提取 Bearer Token
/// 2. 通过 API Key 从数据库反查会话
/// 3. 校验 apiKey 是否匹配
/// 4. 检查会话是否配置了模型
///
/// 将校验通过的 [ChatSession] 存入 `request.context['session']` 供下游使用。
Handler apiKeyGuard(Handler innerHandler) {
  return (Request request) async {
    final authHeader =
        request.headers['Authorization'] ??
        request.headers['authorization'] ??
        '';
    final apiKey = _extractBearerToken(authHeader);
    debugPrint('🔑 [API Key Guard] 收到请求: path=${request.url.path}, apiKey=$apiKey');

    // Step 1: 通过 API Key 从数据库反查会话
    final sessionController = Get.find<SessionController>();
    final session = apiKey != null
        ? await sessionController.getSessionByApiKey(apiKey)
        : null;

    if (session == null) {
      debugPrint('🔒 [API Key Guard] 会话未找到 (by api key=$apiKey) → 404');
      return Response.notFound(
        jsonEncode({
          'error': {
            'message': 'Session not found for API key',
            'type': 'invalid_request_error',
            'code': 404,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // Step 2: 校验 API Key 是否匹配
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('🔒 [API Key Guard] 缺少 API Key → 401');
      return Response(
        401,
        body: jsonEncode({
          'error': {
            'message':
                'Invalid or missing API key. '
                'Please provide a valid API key via Authorization: Bearer lm-xxx',
            'type': 'invalid_request_error',
            'code': 'invalid_api_key',
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    if (apiKey != session.apiKey) {
      debugPrint('🔒 [API Key Guard] API Key 不匹配 → 401');
      return Response(
        401,
        body: jsonEncode({
          'error': {
            'message':
                'Incorrect API key provided. '
                'You can find your API key in the session settings.',
            'type': 'invalid_request_error',
            'code': 'invalid_api_key',
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // Step 3: 模型检查
    if (session.chatModel == null) {
      debugPrint('🔒 [API Key Guard] 会话未配置模型 → 400');
      return Response(
        400,
        body: jsonEncode({
          'error': {
            'message': 'Session has no model configured',
            'type': 'invalid_request_error',
            'code': 400,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    debugPrint('✅ [API Key Guard] 校验通过: session=${session.sessionId}');

    // 将会话存入 context 供下游中间件和 handler 使用
    final updatedRequest = request.change(
      context: {...request.context, 'session': session, 'apiKey': apiKey},
    );

    return innerHandler(updatedRequest);
  };
}

/// 从 Authorization header 中提取 Bearer Token
/// 支持格式: "Bearer lm-xxx" 或 "lm-xxx"
String? _extractBearerToken(String authHeader) {
  if (authHeader.isEmpty) return null;

  // 尝试 Bearer 格式
  final bearerMatch = RegExp(
    r'^Bearer\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(authHeader.trim());
  if (bearerMatch != null) {
    return bearerMatch.group(1)!.trim();
  }

  // 兼容直接传 lm-xxx 的情况
  if (authHeader.trim().startsWith('lm-')) {
    return authHeader.trim();
  }

  return null;
}
