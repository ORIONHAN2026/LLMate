import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';

import '../../../controllers/session_controller.dart';

/// API Key 校验中间件（风控检查）
///
/// 1. 从 Authorization header 提取 Bearer Token
/// 2. 根据 URL 中的 sessionId 查找会话
/// 3. 如果会话开启了免授权模式，跳过 API Key 校验
/// 4. 否则校验 apiKey 是否匹配
/// 5. 检查会话是否配置了模型
///
/// 将校验通过的 [ChatSession] 存入 `request.context['session']` 供下游使用。
Handler apiKeyGuard(Handler innerHandler) {
  return (Request request) async {
    final sessionId = _extractSessionIdFromPath(request.url.path);

    // Step 1: 查找会话
    final sessionController = Get.find<SessionController>();
    final session = sessionController.sessions.firstWhereOrNull(
      (s) => s.sessionId == sessionId,
    );

    if (session == null) {
      debugPrint('🔒 [API Key Guard] 会话未找到: $sessionId → 404');
      return Response.notFound(
        jsonEncode({
          'error': {
            'message': 'Session not found',
            'type': 'invalid_request_error',
            'code': 404,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // Step 2: 免授权模式 — 跳过 API Key 校验
    if (session.noAuthEnabled) {
      debugPrint('🔓 [API Key Guard] 免授权模式，跳过 API Key 校验: session=$sessionId');
    } else {
      // Step 3: 提取 Bearer Token
      final authHeader =
          request.headers['Authorization'] ??
          request.headers['authorization'] ??
          '';
      final apiKey = _extractBearerToken(authHeader);

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

      // Step 4: 校验 API Key 是否匹配
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
    }

    // Step 5: 模型检查
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

    debugPrint('✅ [API Key Guard] 校验通过: session=$sessionId');

    // 将会话存入 context 供下游中间件和 handler 使用
    final updatedRequest = request.change(
      context: {...request.context, 'session': session},
    );

    return innerHandler(updatedRequest);
  };
}

/// 从 URL path 中提取 sessionId
/// path 格式: /{sessionId}/chat/completions
String _extractSessionIdFromPath(String path) {
  final clean = path.startsWith('/') ? path.substring(1) : path;
  final slashIdx = clean.indexOf('/');
  if (slashIdx == -1) return clean;
  return clean.substring(0, slashIdx);
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
