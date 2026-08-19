import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../core/llm/common/message_builder.dart';
import '../../../core/llm/common/system_prompts.dart';
import '../../../models/chat/session.dart';
import '../http_context_keys.dart';
import '../http_response_utils.dart';

/// 语言检查中间件
///
/// 将「语言维度」的检查与增强统一收敛到一个中间件：
/// 1. 解析回复语言：[MessageBuilder.resolveReplyLanguage] 按优先级
///    （模型配置显式指定 > 会话提示词中的语言要求 > 系统设置语言兜底）
///    确定本次请求的回复语言；
/// 2. 注入回复语言要求（强约束，最高优先级，覆盖历史上下文与弱指令）。
///
/// 增强后的请求体存入 `request.context['body']` 并重新注入下游。
Handler languageCheckGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context[HttpContextKeys.session] as ChatSession?;
    if (session == null) {
      return innerHandler(request);
    }

    // 读取请求体（上游中间件已重新注入，可再次读取）
    final bodyStr = await request.readAsString();
    if (bodyStr.isEmpty) {
      return innerHandler(request);
    }
    final parsed = parseJsonObjectBody(bodyStr);
    if (parsed.error != null) return parsed.error!;
    final body = parsed.body!;
    final messages = body['messages'];

    // 1. 解析回复语言
    final lang = MessageBuilder.resolveReplyLanguage(
      model: session.chatModel,
      session: session,
    );
    if (lang == null || messages is! List) {
      return innerHandler(request);
    }

    // 2. 注入回复语言要求（插在已注入的系统提示词之后、原始消息之前）
    var promptInsertCount =
        request.context[HttpContextKeys.promptInsertCount] as int? ?? 0;
    messages.insert(promptInsertCount, {
      'role': 'system',
      'name': 'language_requirement',
      'content': CommonSystemPrompts.responseLanguage(lang),
    });
    promptInsertCount++;
    debugPrint('💬 [LanguageGuard] 注入回复语言要求: $lang');

    final updatedRequest = request.change(
      body: utf8.encode(jsonEncode(body)),
      context: {
        ...request.context,
        HttpContextKeys.body: body,
        HttpContextKeys.promptInsertCount: promptInsertCount,
      },
    );

    return innerHandler(updatedRequest);
  };
}
