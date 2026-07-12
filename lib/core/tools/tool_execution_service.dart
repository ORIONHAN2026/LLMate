import 'dart:async';
import 'package:flutter/foundation.dart';
import '../mcp_client/mcp_client.dart';
import '../llm/modes/mode_utils.dart';
import '../../models/chat/chat_session.dart';
import '../../controllers/mcp_controller.dart';


/// 工具调用执行结果（统一返回）
class ToolExecutionResult {
  final String cleanContent;
  final List<Map<String, dynamic>> toolCallList;
  final List<Map<String, dynamic>> executionResults;

  const ToolExecutionResult({
    required this.cleanContent,
    required this.toolCallList,
    required this.executionResults,
  });
}

/// 统一工具执行服务
///
/// 与 MCP 完全解耦，独立调度所有类型工具的执行：
/// - MCP 工具：通过 MCP 客户端执行
/// - 其他工具：尝试 MCP，不可用时返回错误
///
/// 注意：工具调用解析由 OpenAiProvider 负责，本服务只执行已解析的工具。
class ToolExecutionService {
  // ── 执行入口 ──

  /// 执行已解析的工具调用列表
  ///
  /// [toolCalls] 已解析的工具调用列表 (每个: {name, arguments, id?, index?})
  /// [cleanContent] 剥离工具调用 XML 后的干净文本
  static Future<ToolExecutionResult?> executeToolCalls({
    required ChatSession session,
    required List<Map<String, dynamic>> toolCalls,
    required String cleanContent,
  }) async {
    if (toolCalls.isEmpty) return null;

    debugPrint('🔧 ToolExecutionService: 准备执行 ${toolCalls.length} 个工具调用');

    // 逐个执行工具
    final executionResults = <Map<String, dynamic>>[];
    final toolCallList = <Map<String, dynamic>>[];

    for (int i = 0; i < toolCalls.length; i++) {
      final tc = toolCalls[i];
      final name = tc['name'] as String;
      final args = tc['arguments'] as Map<String, dynamic>;
      final callId = (tc['id'] as String?) ?? 'call_$i';

      // 标准化：补齐 id / index
      toolCallList.add({
        ...tc,
        'id': callId,
        if (!tc.containsKey('index')) 'index': i,
      });

      try {
        final result = await _routeAndExecute(
          session: session,
          toolName: name,
          arguments: args,
          callId: callId,
        );
        executionResults.add(result);
      } catch (e) {
        executionResults.add({
          'id': callId,
          'name': name,
          'args': args,
          'result': '$e',
          'isError': true,
        });
      }
    }

    return ToolExecutionResult(
      cleanContent: cleanContent,
      toolCallList: toolCallList,
      executionResults: executionResults,
    );
  }

  // ── 路由 → 执行 ──

  static Future<Map<String, dynamic>> _routeAndExecute({
    required ChatSession session,
    required String toolName,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    // 还原被转义的工具名（OpenAI function calling 不允许函数名含点号等特殊字符）
    final resolvedName = resolveOriginalToolName(toolName);

    // ── MCP 工具：尝试 MCP 客户端（按工具名路由到正确的 MCP） ──
    final mc = await McpController.instance.getOrInitClient(session, toolName: resolvedName);
    if (mc != null) {
      final result = await _callMCPTool(mc, resolvedName, arguments, callId);
      // 成功或非连接类错误 → 直接返回
      if (result != null) return result;

      // 连接失败（SSE 长连接可能因空闲超时被断开），
      // 清理旧客户端并重连重试一次
      debugPrint('🔄 MCP 工具 "$toolName" 连接失败，尝试重连重试...');
      final ownerMcpName = McpController.instance.findMcpOwner(session, resolvedName);
      if (ownerMcpName != null) {
        await McpController.instance.closeClient(ownerMcpName);
        final retryMc = await McpController.instance.getOrInitClient(session, toolName: resolvedName);
        if (retryMc != null) {
          final retryResult = await _callMCPTool(
            retryMc,
            toolName,
            arguments,
            callId,
          );
          if (retryResult != null) return retryResult;
        }
      }
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': 'MCP 执行失败: 连接不可用，已尝试重连',
        'isError': true,
      };
    }

    // ── 无法识别 ──
    return {
      'id': callId,
      'name': toolName,
      'args': arguments,
      'result': '工具 "$toolName" 在当前环境中不可用。',
      'isError': true,
    };
  }

  // ── MCP 工具执行 ──

  static Future<Map<String, dynamic>?> _callMCPTool(
    Client mc,
    String toolName,
    Map<String, dynamic> arguments,
    String callId,
  ) async {
    try {
      final r = await mc.callTool(toolName, arguments);
      final ok = r.isError != true;
      final buf = StringBuffer();
      for (final c in r.content) {
        if (c is TextContent) buf.writeln(c.text);
        if (c is ImageContent) buf.writeln('[图片: ${c.data ?? c.url}]');
      }
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': buf.toString().trim(),
        'isError': !ok,
      };
    } catch (e) {
      final errStr = e.toString();
      debugPrint('⚠️ MCP 工具 "$toolName" 执行失败: $errStr');
      // 连接类错误（transport 断开、超时等）→ 返回 null 触发重连
      if (errStr.contains('disconnected') ||
          errStr.contains('Connection') ||
          errStr.contains('timed out') ||
          errStr.contains('Timeout') ||
          errStr.contains('502') ||
          errStr.contains('503') ||
          errStr.contains('not connected') ||
          errStr.contains('SSE')) {
        debugPrint('🔄 检测到连接类错误，将尝试重连');
        return null;
      }
      // 非连接类错误（参数错误等）→ 直接返回错误
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': 'MCP 执行失败: $errStr',
        'isError': true,
      };
    }
  }
}
