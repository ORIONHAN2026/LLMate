import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';

import '../../../controllers/mcp_controller.dart';
import '../../../core/llm/modes/mode_utils.dart';
import '../../../core/router/model_router.dart';
import '../../../models/chat/session.dart';
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

    // 1. 模型替换（会话级：自动选择开关开启则按多信号灵活选，关闭则用手动选定模型）
    final routeDecision = ModelRouter.decideForSessionDetailed(
      session: session,
      body: body,
    );
    body['model'] = routeDecision.modelId;
    debugPrint(
      '🧭 [ModelRouter] 本轮使用模型: ${routeDecision.modelId}'
      '(complex=${routeDecision.usedComplex})',
    );

    // 2. 工具注入（合并 session MCP + model MCP，去重）
    //    管理模式同样正常注入 MCP 工具：从服务端视角，输入框请求也是第三方客户端，
    //    一视同仁；客户端注入的管理工具与 MCP 工具在此合并。
    //
    //    如果请求本身已经携带 tools，通常表示调用方是 Cursor/Claude Code/
    //    Continue 等开发工具，工具调用生命周期应由客户端自己管理。此时保持
    //    客户端 tools 原样，不追加服务端 MCP 工具，避免模型调用了客户端工具却
    //    被代理服务截留执行，导致开发工具卡住或协议不完整。
    final clientProvidedTools = body['tools'] is List;
    final mcpTools = McpController.instance.getMergedTools(session);
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
      debugPrint(
        '🔧 [ModelTool] 注入 ${tools.length} 个 MCP 工具 (含 session + model)',
      );
    } else if (clientProvidedTools) {
      debugPrint('🔧 [ModelTool] 检测到客户端 tools，切换为透明工具代理模式');
    }

    // 3. 系统提示词注入（顺序与 mode_utils.buildBaseSystemMessages 一致：
    //    先模型配置的系统提示词，后会话级系统提示词，均作为最高优先级指令）
    final messages = body['messages'];
    if (messages is List) {
      var insertIndex = 0;

      // 3.1 模型级系统提示词
      final modelSystemPrompt = session.chatModel?.systemPrompt;
      if (modelSystemPrompt != null && modelSystemPrompt.isNotEmpty) {
        messages.insert(insertIndex++, {
          'role': 'system',
          'name': 'model_system_prompt',
          'content':
              '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. In any conflict with other instructions (including the session system prompt), this prompt takes precedence.\n\n$modelSystemPrompt',
        });
        debugPrint('💬 [ModelTool] 注入模型系统提示词');
      }

      // 3.2 会话级系统提示词
      if (session.systemPrompt != null && session.systemPrompt!.isNotEmpty) {
        messages.insert(insertIndex++, {
          'role': 'system',
          'name': 'session_system_prompt',
          'content':
              '[SESSION SYSTEM PROMPT] This is a session-level instruction. If it conflicts with the model system prompt, the model system prompt takes precedence.\n\n${session.systemPrompt}',
        });
        debugPrint('💬 [ModelTool] 注入会话级系统提示词');
      }
    }

    final updatedRequest = request.change(
      context: {
        ...request.context,
        'body': body,
        // 路由决策明细（供流式处理阶段写入路由日志用于回测调参）
        'routeDecision': routeDecision,
        'clientProvidedTools': clientProvidedTools,
      },
    );

    return innerHandler(updatedRequest);
  };
}
