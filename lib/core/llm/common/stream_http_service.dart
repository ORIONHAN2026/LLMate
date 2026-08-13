import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../http/local_http_service.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/chat/session.dart';
import 'openai_provider.dart';
import 'chunk_parser.dart';
import '../tools/management_tools.dart'
    show managementToolDefinitions, managementToolNames, executeManagementTool;

/// 通过本机会话 HTTP 服务转发聊天请求，并将服务返回的
/// OpenAI 格式 SSE 流转译为 LLMChat 消费方期望的 chunk 格式。
///
/// 服务侧 [modelToolGuard] 负责注入 model / tools / 系统提示词。
///
/// 工具执行分工：
/// - MCP 工具：由服务端识别并在服务端执行、回填（会话模式）。
/// - 管理工具（审计/用量/额度）：客户端注入 schema，服务端视作第三方透传回来，
///   由客户端本地执行 [executeManagementTool] 并回填，继续多轮请求。
Stream<Map<String, dynamic>> streamViaHttpService({
  required ChatSession session,
  required OpenAiProvider provider,
  required bool Function() isCancelled,
  required List<Map<String, dynamic>> messages,
}) async* {
  final model = session.chatModel;
  if (model == null) {
    yield {'content': '模型未配置'};
    yield {'done': 'true'};
    return;
  }

  final isManagement = session.mode == SessionMode.management.name;

  // 可变消息列表：多轮工具调用时回填 assistant(tool_calls) 与 tool 结果
  var currentMessages = List<Map<String, dynamic>>.from(messages);

  var toolIteration = 0;
  const maxToolIterations = 20;

  while (true) {
    if (isCancelled()) {
      yield {'done': 'true'};
      return;
    }

    // 管理模式：客户端注入管理工具；会话模式：tools 传空，MCP 工具由服务端注入
    final body = await provider.buildRequestData(
      messages: currentMessages,
      session: session,
      stream: true,
      tools: isManagement ? managementToolDefinitions : const [],
    );

    final round = await _postRound(session, body, isCancelled);

    // 透传内容 / 思考 / 工具执行状态 chunk
    for (final c in round.chunks) {
      yield c;
    }

    if (round.error) {
      yield {'done': 'true'};
      return;
    }

    // 分类第三方工具：管理工具（客户端本地执行） vs 真第三方（透传 UI）
    final managementCalls = <Map<String, dynamic>>[];
    final thirdPartyToolCalls = <Map<String, dynamic>>[];
    for (final tc in round.toolCalls) {
      final name = (tc['function']?['name'] ?? '').toString();
      if (isManagement && managementToolNames.contains(name)) {
        managementCalls.add(tc);
      } else {
        thirdPartyToolCalls.add(tc);
      }
    }

    // 真第三方工具 → 透传给 UI 自行处理
    if (thirdPartyToolCalls.isNotEmpty) {
      yield {'toolcall': jsonEncode(thirdPartyToolCalls)};
    }

    // 管理工具 → 客户端本地执行并回填，继续下一轮
    if (managementCalls.isNotEmpty) {
      toolIteration++;
      if (toolIteration >= maxToolIterations) {
        debugPrint('⚠️ [LLMChat] 管理工具调用已达最大轮次 $maxToolIterations，停止循环');
        break;
      }

      // 通知 UI 正在执行工具
      yield {'tool': 'true'};
      yield {'toolcall': mcpExecutingSentinel};

      // 回填 assistant(tool_calls) 到消息历史
      currentMessages.add({
        'role': 'assistant',
        'content': null,
        'tool_calls': managementCalls.map((tc) {
          return {
            'id': tc['id'] ?? 'call_${tc['index'] ?? 0}',
            'type': 'function',
            'function': {
              'name': tc['function']?['name'] ?? '',
              'arguments': tc['function']?['arguments'] ?? '{}',
            },
          };
        }).toList(),
      });

      // 逐个执行管理工具，追加 tool 结果
      for (final tc in managementCalls) {
        final name = (tc['function']?['name'] ?? '').toString();
        final argsStr = (tc['function']?['arguments'] ?? '{}').toString();
        Map<String, dynamic> args;
        try {
          args = jsonDecode(argsStr) as Map<String, dynamic>;
        } catch (_) {
          args = <String, dynamic>{};
        }
        final result = await executeManagementTool(name, args, session);
        currentMessages.add({
          'role': 'tool',
          'tool_call_id': tc['id'] ?? 'call_${tc['index'] ?? 0}',
          'content': result,
        });
      }
      continue;
    }

    // 无工具调用 → 正常回复完毕
    break;
  }

  yield {'done': 'true'};
}

/// 单轮 HTTP 请求的聚合结果。
class _HttpRoundResult {
  final List<Map<String, dynamic>> chunks; // content / think / tool 状态 chunk
  final List<Map<String, dynamic>> toolCalls; // 第三方工具调用（含管理工具）
  final bool error;
  _HttpRoundResult({
    required this.chunks,
    required this.toolCalls,
    this.error = false,
  });
}

/// 向本机 HTTP 服务发起一轮 chat completion 请求，解析 SSE 流。
///
/// 返回该轮的 content/think chunk（透传 UI）与 tool_calls（交外层分类）。
Future<_HttpRoundResult> _postRound(
  ChatSession session,
  Map<String, dynamic> body,
  bool Function() isCancelled,
) async {
  final chunks = <Map<String, dynamic>>[];
  final toolCalls = <Map<String, dynamic>>[];

  final scheme = LocalHttpService.isHttps ? 'https' : 'http';
  // 优先使用本机回环地址 127.0.0.1（比 localhost 更可靠，避免 IPv6 ::1 解析问题）
  final host = '127.0.0.1';
  // 端口：优先用本机服务实际监听端口，无效时回退到系统设置中配置的 HTTP 端口
  final port = LocalHttpService.port > 0
      ? LocalHttpService.port
      : Get.find<SettingsController>().httpPort.value;
  final uri = Uri.parse(
    '$scheme://$host:$port/${session.sessionId}/chat/completions',
  );

  final client = HttpClient();
  if (LocalHttpService.isHttps) {
    // 本地自签名证书，放宽校验
    client.badCertificateCallback = (_, _, _) => true;
  }

  try {
    final req = await client.postUrl(uri);
    req.headers.contentType = ContentType.json;
    req.headers.set('X-LLMate-InApp', 'true');
    if (!session.noAuthEnabled) {
      req.headers.set('Authorization', 'Bearer ${session.apiKey}');
    }
    req.write(jsonEncode(body));

    final response = await req.close();
    if (response.statusCode >= 400) {
      final err = await response.transform(utf8.decoder).join();
      chunks.add({'content': '请求失败 ($err)'});
      return _HttpRoundResult(chunks: chunks, toolCalls: toolCalls, error: true);
    }

    String buffer = '';
    await for (final raw in response.transform(utf8.decoder)) {
      debugPrint('🧠 [LLMChat] 接收到的原始 SSE chunk: $raw');
      if (isCancelled()) break;
      buffer += raw;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          if (dataStr == '[DONE]') {
            return _HttpRoundResult(chunks: chunks, toolCalls: toolCalls);
          }
          for (final c in parseOpenAiChunk(dataStr)) {
            final toolcall = c['toolcall'];
            // 真实工具调用（JSON 数组）→ 收集，交外层分类/执行；
            // 哨兵值（服务端执行 MCP 工具状态）则透传。
            if (toolcall is String &&
                toolcall.isNotEmpty &&
                toolcall != mcpExecutingSentinel) {
              try {
                final list = jsonDecode(toolcall);
                if (list is List) {
                  for (final tc in list) {
                    if (tc is Map<String, dynamic>) toolCalls.add(tc);
                  }
                  continue;
                }
              } catch (_) {}
            }
            chunks.add(c);
          }
        } else if (trimmed.startsWith('{')) {
          // 非 SSE 的原始 JSON（如错误行）
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final err = json['error'];
            if (err != null) {
              final msg = err is Map
                  ? (err['message']?.toString() ?? err.toString())
                  : err.toString();
              chunks.add({'content': '错误: $msg'});
            }
          } catch (_) {}
        }
      }
    }
    return _HttpRoundResult(chunks: chunks, toolCalls: toolCalls);
  } catch (e) {
    chunks.add({'content': '错误: $e'});
    return _HttpRoundResult(chunks: chunks, toolCalls: toolCalls, error: true);
  } finally {
    client.close(force: true);
  }
}
