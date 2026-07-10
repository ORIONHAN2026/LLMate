import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:llmwork/models/responses/chunk.dart';
import 'package:llmwork/models/responses/openai_response.dart';
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

    Map<String, dynamic> original;
    Map<String, dynamic> enriched;
    try {
      original =
          bodyStr.isEmpty
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
    final mcpTools = McpController.instance.getTools(
      session.mcpServer?.name ?? '',
    );
    List<Map<String, dynamic>>? injectedTools;
    if (mcpTools.isNotEmpty) {
      final tools = mcpTools.map((t) => t.toOpenAIFunction()).toList();
      final existing = enriched['tools'];
      if (existing is List) {
        enriched['tools'] = [...existing, ...tools];
      } else {
        enriched['tools'] = tools;
      }
      enriched['tool_choice'] = 'auto';
      injectedTools = tools;
      debugPrint('🔧 [ModelTool] 注入 ${tools.length} 个 MCP 工具');
    }
    // 告知客户端大模型后端已配置了哪些工具，避免本地重复创建同类型工具
    // final controller = StreamController<List<int>>();

    // if (injectedTools != null && injectedTools.isNotEmpty) {
    //   final toolInfoChunk = Chunk(
    //     id: 'server-tools',
    //     object: 'chat.completion.chunk',
    //     created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    //     model: session.chatModel?.model ?? '',
    //     choices: [
    //       ChunkChoice(
    //         index: 0,
    //         delta: OpenAIDelta(
    //           content: jsonEncode({
    //             'type': 'server_tools_info',
    //             'message': '后端大模型已配置以下工具，请勿在客户端本地重复定义同类型工具。',
    //             'server_tools': injectedTools,
    //             'hint':
    //                 '客户端可直接发送 messages 请求，无需在请求体中携带 tools / tool_choice 字段。',
    //           }),
    //         ),
    //       ),
    //     ],
    //   );
    //   controller.add(toolInfoChunk.toIntList());
    //   controller.close();
    //   debugPrint('📤 [ModelTool] 透传 ${injectedTools.length} 个服务端工具信息给客户端');
    // }

    // 审计录入：收到的请求 / 组织后的请求
    final auditCallback = request.context['auditCallback'] as AuditCallback?;
    auditCallback?.call(rawRequest: original, organizedRequest: enriched);

    // 透传原始请求体供下游使用，并向内游注入增强后的请求体
    final contextExtras = <String, Object>{
      'originalRequest': original,
      'enrichedBody': enriched,
      if (injectedTools != null) 'injectedServerTools': injectedTools,
    };
    final updatedRequest = request.change(
      body: utf8.encode(jsonEncode(enriched)),
      context: {...request.context, ...contextExtras},
    );

    return innerHandler(updatedRequest);
  };
}
