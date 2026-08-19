import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../core/router/model_router.dart';
import '../../../models/chat/session.dart';
import '../http_context_keys.dart';
import '../http_response_utils.dart';

/// 模型检查中间件
///
/// 将「模型维度」的检查与增强统一收敛到一个中间件，按顺序执行：
/// 1. 模型配置检查：会话未配置模型（[ChatSession.chatModel] 为空）→ 400
/// 2. 模型路由替换：按会话配置（自动选择开关/手动选定模型）决策实际使用模型
/// 3. 注入模型级系统提示词（[ChatModel.systemPrompt]，最高优先级指令）
///
/// 增强后的请求体存入 `request.context['body']` 并重新注入下游，
/// 路由决策明细存入 `request.context['routeDecision']` 供审计日志复用。
Handler modelCheckGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context[HttpContextKeys.session] as ChatSession?;
    if (session == null) {
      // 上游会话检查应已拦截，此处兜底
      return innerHandler(request);
    }

    // 1. 模型配置检查
    if (session.chatModel == null) {
      debugPrint('🔒 [ModelGuard] 会话未配置模型 → 400');
      return openAiErrorResponse(
        statusCode: 400,
        message: 'Session has no model configured',
        type: 'invalid_request_error',
        code: 400,
      );
    }

    // 读取请求体（上游会话检查已重新注入，可再次读取）
    final bodyStr = await request.readAsString();
    if (bodyStr.isEmpty) {
      // 无请求体（如 GET /v1/models），无需模型增强
      return innerHandler(request);
    }
    final parsed = parseJsonObjectBody(bodyStr);
    if (parsed.error != null) return parsed.error!;
    final body = parsed.body!;

    // 2. 模型替换（会话级：自动选择开关开启则按多信号灵活选，关闭则用手动选定模型）
    final routeDecision = ModelRouter.decideForSessionDetailed(
      session: session,
      body: body,
    );
    body['model'] = routeDecision.modelId;
    debugPrint(
      '🧭 [ModelGuard] 本轮使用模型: ${routeDecision.modelId}'
      '(complex=${routeDecision.usedComplex})',
    );

    // 3. 模型级系统提示词（最高优先级，插到最前；
    //    会话提示词由上游 sessionCheckGuard 已插入，此处置顶后顺序为：模型 → 会话）
    var promptInsertCount =
        request.context[HttpContextKeys.promptInsertCount] as int? ?? 0;
    final messages = body['messages'];
    final modelSystemPrompt = session.chatModel?.systemPrompt;
    if (messages is List &&
        modelSystemPrompt != null &&
        modelSystemPrompt.isNotEmpty) {
      messages.insert(0, {
        'role': 'system',
        'name': 'model_system_prompt',
        'content':
            '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. In any conflict with other instructions (including the session system prompt), this prompt takes precedence.\n\n$modelSystemPrompt',
      });
      promptInsertCount++;
      debugPrint('💬 [ModelGuard] 注入模型系统提示词');
    }

    final updatedRequest = request.change(
      body: utf8.encode(jsonEncode(body)),
      context: {
        ...request.context,
        HttpContextKeys.body: body,
        HttpContextKeys.routeDecision: routeDecision,
        HttpContextKeys.promptInsertCount: promptInsertCount,
      },
    );

    return innerHandler(updatedRequest);
  };
}
