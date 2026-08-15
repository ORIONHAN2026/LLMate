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
    show managementToolDefinitions, executeManagementTool;

/// 通过本机会话 HTTP 服务转发聊天请求，并将服务返回的
/// OpenAI 格式 SSE 流转译为 LLMChat 消费方期望的 chunk 格式。
///
/// 服务侧 [modelToolGuard] 负责注入 model / tools / 系统提示词。
///
/// 工具执行分工：
/// - MCP 工具：由服务端识别并在服务端执行、回填（与模式无关，一视同仁）。
/// - 管理工具（审计/用量/额度）：客户端注入 schema，服务端视作第三方透传回来，
///   由客户端本地执行 [executeManagementTool] 并回填，继续多轮请求。
///   客户端输入框只在本软件执行，收到的工具调用全部是管理工具，无真第三方工具。
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

  // 可变消息列表：多轮工具调用时回填 assistant(tool_calls) 与 tool 结果
  var currentMessages = List<Map<String, dynamic>>.from(messages);

  var toolIteration = 0;
  const maxToolIterations = 20;

  while (true) {
    if (isCancelled()) {
      yield {'done': 'true'};
      return;
    }

    // 只要是从本软件聊天输入框发出的请求，一律注入全部管理工具；
    // MCP 工具仍由服务端注入
    final body = await provider.buildRequestData(
      messages: currentMessages,
      session: session,
      stream: true,
      tools: managementToolDefinitions,
    );

    // 流式透传内容 / 思考 / 工具执行状态 chunk，保证实时返回；
    // 轮次结束时由结束 chunk 带回 toolCalls 与错误标记
    final toolCalls = <Map<String, dynamic>>[];
    var roundError = false;
    await for (final chunk in _postRound(session, body, isCancelled)) {
      if (chunk['roundEnd'] == 'true') {
        roundError = chunk['error'] == 'true';
        final tcList = chunk['toolCalls'];
        if (tcList is List) {
          for (final tc in tcList) {
            if (tc is Map<String, dynamic>) toolCalls.add(tc);
          }
        }
        break;
      }
      yield chunk;
    }

    if (roundError) {
      yield {'done': 'true'};
      return;
    }

    // 客户端只注入了管理工具 schema，服务端把不认识的管理工具视作第三方透传回来；
    // 聊天输入框的输入只在本软件执行，不会出现真第三方工具，因此这里的 tool_calls
    // 全都是管理工具，直接本地执行回填，继续下一轮。
    if (toolCalls.isNotEmpty) {
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
        'tool_calls':
            toolCalls.map((tc) {
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
      for (final tc in toolCalls) {
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

/// 向本机 HTTP 服务发起一轮 chat completion 请求，流式解析 SSE。
///
/// 边解析边 yield content / think / 工具执行状态 chunk（保证实时返回）；
/// 轮次结束时 yield 一个带 `roundEnd: true` 的结束 chunk，
/// 携带该轮收集的 tool_calls 与 error 标记，交外层处理多轮工具循环。
Stream<Map<String, dynamic>> _postRound(
  ChatSession session,
  Map<String, dynamic> body,
  bool Function() isCancelled,
) async* {
  final scheme = LocalHttpService.isHttps ? 'https' : 'http';
  // 优先使用本机回环地址 127.0.0.1（比 localhost 更可靠，避免 IPv6 ::1 解析问题）
  final host = '127.0.0.1';
  // 端口：优先用本机服务实际监听端口，无效时回退到系统设置中配置的 HTTP 端口
  final port =
      LocalHttpService.port > 0
          ? LocalHttpService.port
          : Get.find<SettingsController>().httpPort.value;
  final uri = Uri.parse('$scheme://$host:$port/v1/chat/completions');

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
      yield {'content': '请求失败 ($err)'};
      yield {'roundEnd': 'true', 'toolCalls': const [], 'error': 'true'};
      return;
    }

    final toolCalls = <Map<String, dynamic>>[];
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
            yield {'roundEnd': 'true', 'toolCalls': toolCalls};
            return;
          }
          // 检测服务端返回的标准 OpenAI 错误对象，转成 content chunk 并正常结束
          if (dataStr.startsWith('{')) {
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              final err = json['error'];
              if (err != null) {
                final msg =
                    err is Map
                        ? (err['message']?.toString() ?? err.toString())
                        : err.toString();
                yield {'content': '错误: $msg'};
                yield {
                  'roundEnd': 'true',
                  'toolCalls': toolCalls,
                  'error': 'true',
                };
                return;
              }
            } catch (_) {}
          }
          for (final c in parseOpenAiChunk(dataStr)) {
            final toolcall = c['toolcall'];
            // 真实工具调用（JSON 数组）→ 收集，交外层本地执行；
            // 哨兵值（服务端执行 MCP 工具状态）则透传 UI。
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
            yield c;
          }
        } else if (trimmed.startsWith('{')) {
          // 非 SSE 的原始 JSON（如错误行）
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final err = json['error'];
            if (err != null) {
              final msg =
                  err is Map
                      ? (err['message']?.toString() ?? err.toString())
                      : err.toString();
              yield {'content': '错误: $msg'};
            }
          } catch (_) {}
        }
      }
    }
    // 上游流结束但未收到 [DONE]（连接关闭 / 取消）
    yield {'roundEnd': 'true', 'toolCalls': toolCalls};
  } catch (e) {
    yield {'content': '错误: $e'};
    yield {'roundEnd': 'true', 'toolCalls': const [], 'error': 'true'};
  } finally {
    client.close(force: true);
  }
}
