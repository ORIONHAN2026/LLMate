import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import 'mcp_service.dart';

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
/// - `exec`/`bash`/`shell` 等：本地 Shell 命令（bash -c）
/// - MCP 工具：通过 MCP 客户端执行
/// - 其他工具：尝试 MCP，不可用时返回错误
///
/// 注意：工具调用解析由 [BaseLlmProvider] 负责，本服务只执行已解析的工具。
class ToolExecutionService {
  /// Shell 命令执行超时（秒）
  static const _execTimeoutSeconds = 30;

  /// Shell 工具名称集合
  static const _shellToolNames = {'exec', 'bash', 'shell', 'sh', 'run', 'command'};

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

    debugPrint(
      '🔧 ToolExecutionService: 准备执行 ${toolCalls.length} 个工具调用',
    );

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
    // ── Shell 命令（exec / bash / shell / sh / run / command）──
    if (_shellToolNames.contains(toolName)) {
      return _executeShellCommand(
        toolName: toolName,
        arguments: arguments,
        callId: callId,
      );
    }

    // ── MCP 工具：尝试 MCP 客户端 ──
    final mc = await McpService.getOrInitClient(session);
    if (mc != null) {
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
        debugPrint('⚠️ MCP 工具 "$toolName" 执行失败: $e');
        return {
          'id': callId,
          'name': toolName,
          'args': arguments,
          'result': 'MCP 执行失败: $e',
          'isError': true,
        };
      }
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

  // ── Shell 命令执行 ──

  /// 支持 exec / bash / shell / sh / run / command 等工具名
  /// 参数 key 兼容: command, cmd, script
  static Future<Map<String, dynamic>> _executeShellCommand({
    required String toolName,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    final cmd = (arguments['command'] ?? arguments['cmd'] ?? arguments['script'] ?? '') as String;

    if (cmd.trim().isEmpty) {
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': '错误: 命令为空',
        'isError': true,
      };
    }

    debugPrint('🖥️ [$toolName] 执行: $cmd');

    try {
      final result = await Process.run(
        'bash',
        ['-c', cmd],
        runInShell: true,
        workingDirectory: Directory.current.path,
      ).timeout(
        const Duration(seconds: _execTimeoutSeconds),
        onTimeout: () {
          throw TimeoutException('命令执行超时 (${_execTimeoutSeconds}s)');
        },
      );

      final stdout = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();
      final exitCode = result.exitCode;

      final output = StringBuffer();
      if (stdout.isNotEmpty) output.writeln(stdout);
      if (stderr.isNotEmpty) output.writeln(stderr);

      final isError = exitCode != 0;
      final msg = output.toString().trim();

      debugPrint(
        '🖥️ [$toolName] exit=$exitCode, output=${msg.length > 200 ? msg.substring(0, 200) + "..." : msg}',
      );

      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': msg.isNotEmpty ? msg : (isError ? '命令执行失败 (exit $exitCode)' : '命令执行完成'),
        'isError': isError,
      };
    } on TimeoutException catch (e) {
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': '${e.message ?? "命令执行超时"}',
        'isError': true,
      };
    } catch (e) {
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': '执行失败: $e',
        'isError': true,
      };
    }
  }
}
