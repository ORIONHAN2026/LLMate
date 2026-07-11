import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../controllers/mcp_controller.dart';
import '../../../models/chat/chat_session.dart';
import 'audit_guard.dart';

/// 请求增强中间件：模型替换 + 工具注入
///
/// 通常放置在 [auditGuard] 之后执行，以保证审计记录的是「原始请求」。
///
/// 本中间件读取请求体，完成两件事：
/// 1. 将 `model` 替换为会话实际配置的模型；
/// 2. 从 [McpController] 注入该会话 MCP 服务的工具列表
///    （若请求体中已存在 tools 则追加合并），并置 `tool_choice='auto'`。
///    同时将注入的工具列表存入 `request.context['injectedServerTools']`，
///    供下游流式响应阶段透传给客户端，告知客户端大模型后端已配置了哪些工具，
///    避免客户端本地重复创建同类型工具。
///
/// 增强后的请求体重新注入下游；同时通过 `request.context['originalRequest']`
/// 透传「原始请求体」（解析前、未注入 model/tools），供业务层审计使用。
Handler modelToolGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context['session'] as ChatSession?;
    if (session == null || session.chatModel == null) {
      // apiKeyGuard 已拦截无会话/无模型的情况，这里直接放行
      return innerHandler(request);
    }

    // 读取请求体（上游审计中间件已将其重新注入，可再次读取）
    final bodyStr = await request.readAsString();

    final body = jsonDecode(bodyStr) as Map<String, dynamic>;

    // 1. 模型替换
    body['model'] = session.chatModel!.model;

    // 2. 工具注入（直接读取该 mcp 结构体中存储的 tools）
    final mcpTools = McpController.instance.getTools(
      session.mcpServer?.name ?? '',
    );
    if (mcpTools.isNotEmpty) {
      final tools = mcpTools.map((t) => t.toOpenAIFunction()).toList();
      final existing = body['tools'];
      if (existing is List) {
        body['tools'] = [...existing, ...tools];
      } else {
        body['tools'] = tools;
      }
      body['tool_choice'] = 'auto';
      debugPrint('🔧 [ModelTool] 注入 ${tools.length} 个 MCP 工具');
    }

    final updatedRequest = request.change(
      context: {...request.context, 'body': body},
    );

    return innerHandler(updatedRequest);
  };
}
