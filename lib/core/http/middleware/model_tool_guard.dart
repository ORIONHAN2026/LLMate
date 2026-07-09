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

    Map<String, dynamic> original;
    Map<String, dynamic> enriched;
    try {
      original = bodyStr.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(bodyStr) as Map<String, dynamic>;
      enriched = Map<String, dynamic>.from(original);
    } catch (e) {
      debugPrint('⚠️ [ModelTool] 解析请求体失败: $e');
      return innerHandler(request.change(body: utf8.encode(bodyStr)));
    }

    // 1. 模型替换
    enriched['model'] = session.chatModel!.model;

    // 2. 工具注入（直接读取该 mcp 结构体中存储的 tools）
    final tools = McpController.instance.getTools(session.mcpServer?.name ?? '');
    if (tools.isNotEmpty) {
      final existing = enriched['tools'];
      if (existing is List) {
        enriched['tools'] = [...existing, ...tools];
      } else {
        enriched['tools'] = tools;
      }
      enriched['tool_choice'] = 'auto';
      debugPrint('🔧 [ModelTool] 注入 ${tools.length} 个 MCP 工具');
    }

    // 审计录入：收到的请求 / 组织后的请求
    final auditCallback = request.context['auditCallback'] as AuditCallback?;
    auditCallback?.call(rawRequest: original, organizedRequest: enriched);

    // 透传原始请求体供下游使用，并向内游注入增强后的请求体
    final updatedRequest = request.change(
      body: utf8.encode(jsonEncode(enriched)),
      context: {
        ...request.context,
        'originalRequest': original,
        'enrichedBody': enriched,
      },
    );

    return innerHandler(updatedRequest);
  };
}
