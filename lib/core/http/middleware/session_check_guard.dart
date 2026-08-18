import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';

import '../../../controllers/mcp_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../core/llm/modes/mode_utils.dart';
import '../../../models/chat/session.dart';

/// 会话检查中间件
///
/// 将「会话维度」的检查与增强统一收敛到一个中间件，按顺序执行：
/// 1. API Key 校验：从 Authorization header 提取 Bearer Token，
///    通过 API Key 从数据库反查会话并比对密钥（失败 → 404/401）
/// 2. 禁用状态检查：会话被禁用（[ChatSession.isDisabled]）→ 403
/// 3. 配额检查：跨自然周期自动重置后检查 Token/费用/请求次数 → 429
/// 4. 注入会话级系统提示词（[ChatSession.systemPrompt]）
/// 5. 注入会话 MCP 工具：合并会话绑定的 MCP 服务工具（若客户端自带 tools
///    则保持客户端原样，不追加服务端工具），并置 `tool_choice='auto'`
///
/// 校验通过的会话存入 `request.context['session']`；增强后的请求体存入
/// `request.context['body']` 并重新注入下游（无请求体的 GET 请求跳过增强）。
Handler sessionCheckGuard(Handler innerHandler) {
  return (Request request) async {
    // ── 1. API Key 校验 ──
    final authHeader =
        request.headers['Authorization'] ??
        request.headers['authorization'] ??
        '';
    final apiKey = _extractBearerToken(authHeader);
    debugPrint(
      '🔑 [SessionGuard] 收到请求: path=${request.url.path}, apiKey=$apiKey',
    );

    // Step 1: 通过 API Key 从数据库反查会话
    final sessionController = Get.find<SessionController>();
    final session = apiKey != null
        ? await sessionController.getSessionByApiKey(apiKey)
        : null;

    if (session == null) {
      debugPrint('🔒 [SessionGuard] 会话未找到 (by api key=$apiKey) → 404');
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
      debugPrint('🔒 [SessionGuard] 缺少 API Key → 401');
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
      debugPrint('🔒 [SessionGuard] API Key 不匹配 → 401');
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

    // ── 2. 禁用状态检查 ──
    if (session.isDisabled) {
      debugPrint('🚫 [SessionGuard] 会话已禁用: ${session.sessionId} → 403');
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

    // ── 3. 配额检查 ──
    var currentSession = session;
    final resetSession = currentSession.tryResetQuotaPeriod();
    if (resetSession != null) {
      currentSession = resetSession;
      sessionController.updateSession(resetSession);
      debugPrint('🔄 [SessionGuard] 配额周期已重置: ${currentSession.sessionId}');
    }

    final quotaResult = currentSession.checkQuota();
    if (quotaResult.exceeded) {
      debugPrint('⛔ [SessionGuard] 配额超限: ${quotaResult.reason} → 429');
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

    // ── 4/5. 请求体增强：会话系统提示词 + 会话 MCP 工具 ──
    // 无请求体（如 GET /v1/models）时跳过增强，仅做上述检查
    final bodyStr = await request.readAsString();
    Map<String, dynamic>? body;
    var promptInsertCount = 0;
    var clientProvidedTools = false;

    if (bodyStr.isNotEmpty) {
      body = jsonDecode(bodyStr) as Map<String, dynamic>;

      // 4. 会话级系统提示词（若设置，作为会话级指令注入）
      final messages = body['messages'];
      if (messages is List &&
          currentSession.systemPrompt != null &&
          currentSession.systemPrompt!.isNotEmpty) {
        messages.insert(0, {
          'role': 'system',
          'name': 'session_system_prompt',
          'content':
              '[SESSION SYSTEM PROMPT] This is a session-level instruction. If it conflicts with the model system prompt, the model system prompt takes precedence.\n\n${currentSession.systemPrompt}',
        });
        promptInsertCount++;
        debugPrint('💬 [SessionGuard] 注入会话级系统提示词');
      }

      // 5. 会话 MCP 工具注入
      //    如果请求本身已经携带 tools，通常表示调用方是 Cursor/Claude Code/
      //    Continue 等开发工具，工具调用生命周期应由客户端自己管理。此时保持
      //    客户端 tools 原样，不追加服务端 MCP 工具，避免模型调用了客户端工具却
      //    被代理服务截留执行，导致开发工具卡住或协议不完整。
      clientProvidedTools = body['tools'] is List;
      final mcpTools = McpController.instance.getMergedTools(currentSession);
      if (!clientProvidedTools && mcpTools.isNotEmpty) {
        // OpenAI 要求函数名匹配 ^[a-zA-Z0-9_-]+$，MCP 工具名可能含点号/空格等，
        // 注入前 sanitize 并注册映射，执行端按安全名还原原始名调用 MCP。
        final tools = mcpTools.map((t) {
          final func = t.toOpenAIFunction();
          final f = func['function'] as Map<String, dynamic>;
          f['name'] = registerSafeToolName(t.name);
          return func;
        }).toList();
        body['tools'] = tools;
        body['tool_choice'] = 'auto';
        debugPrint('🔧 [SessionGuard] 注入 ${tools.length} 个会话 MCP 工具');
      } else if (clientProvidedTools) {
        debugPrint('🔧 [SessionGuard] 检测到客户端 tools，切换为透明工具代理模式');
      }
    }

    debugPrint('✅ [SessionGuard] 校验通过: session=${currentSession.sessionId}');

    final updatedRequest = body != null
        ? request.change(
            body: utf8.encode(jsonEncode(body)),
            context: {
              ...request.context,
              'session': currentSession,
              'apiKey': apiKey,
              'body': body,
              'clientProvidedTools': clientProvidedTools,
              'promptInsertCount': promptInsertCount,
            },
          )
        : request.change(
            context: {
              ...request.context,
              'session': currentSession,
              'apiKey': apiKey,
              'clientProvidedTools': clientProvidedTools,
              'promptInsertCount': promptInsertCount,
            },
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
