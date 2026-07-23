import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../http/local_http_service.dart';
import '../../models/model.dart';
import '../../models/chat/session.dart';
import '../../models/chat/message.dart';
import './openai_provider.dart';
import './common/message_builder.dart';
import './modes/mode_utils.dart';
import '../http/stream_round.dart' show streamSingleRound;
import '../../controllers/mcp_controller.dart';
import '../../models/responses/chunk.dart';
import '../../models/responses/openai_response.dart' show ToolCall;

/// LLM 客户端（聊天窗口侧代理）
///
/// 仅负责把会话消息组装好并转发给本机会话 HTTP 服务；
/// 工具注入、工具执行、会话持久化与用量统计均由 HTTP 服务统一处理。
class LlmClient {
  ChatSession _session;
  final OpenAiProvider _provider;
  bool _cancelled = false;

  LlmClient(ChatSession session)
    : _session = session,
      _provider = OpenAiProvider() {
    _provider.configure(session.chatModel!);
    _provider.applySessionSettings(session);
  }

  ChatModel? get model => _session.chatModel;

  void dispose() {}

  void configure(ChatModel model) => _provider.configure(model);

  Future<bool> validateConfiguration() => _provider.validateConfiguration();

  String buildSystemPrompt({ChatSession? session}) {
    return MessageBuilder.buildSystemPrompt(model: model, session: session);
  }

  /// 发送消息并获取流式响应。
  ///
  /// 始终经由本机会话 HTTP 服务转发，复用服务侧中间件
  /// （鉴权 / 配额 / 模型工具注入 / 工具执行 / 审计 / 用量统计），
  /// 客户端不再重复组装或执行工具。
  Stream<Map<String, dynamic>> LLMChat(ChatMessage userMessage) async* {
    _cancelled = false;

    if (kDebugMode) {
      debugPrint(
        '🧠 [LLMChat] 会话消息数: ${_session.messages.length}, 当前消息ID: ${userMessage.msgId}',
      );
    }

    final messages = await _buildMessages(
      userMessage: userMessage,
      session: _session,
    );

    // 管理模式：消息本地直连大模型，不经过本机 HTTP 服务，用量不计入统计
    if (_session.mode == SessionMode.management) {
      await for (final chunk in _streamLocal(userMessage, messages)) {
        yield chunk;
      }
      return;
    }

    // 会话模式：始终经由本机会话 HTTP 服务转发，复用服务侧中间件
    // （鉴权 / 配额 / 模型工具注入 / 工具执行 / 审计 / 用量统计）。
    await for (final chunk in _streamViaHttpService(userMessage, messages)) {
      yield chunk;
    }
  }

  // ======================== 经由本机会话 HTTP 服务转发 ========================

  static const String _mcpExecutingSentinel = '大模型正在执行MCP服务';

  /// 通过本机会话 HTTP 服务转发聊天请求，并将服务返回的
  /// OpenAI 格式 SSE 流转译为 LLMChat 消费方期望的 chunk 格式。
  ///
  /// 服务侧 [modelToolGuard] 负责注入 model / tools / 系统提示词，
  /// 因此此处只发送会话历史与用户消息（不重复携带 tools）。
  Stream<Map<String, dynamic>> _streamViaHttpService(
    ChatMessage userMessage,
    List<Map<String, dynamic>> messages,
  ) async* {
    final session = _session;
    final model = session.chatModel;
    if (model == null) {
      yield {'content': '模型未配置'};
      yield {'done': 'true'};
      return;
    }

    final body = await _provider.buildRequestData(
      messages: messages,
      session: session,
      stream: true,
      tools: const [],
    );

    final scheme = LocalHttpService.isHttps ? 'https' : 'http';
    final uri = Uri.parse(
      '$scheme://localhost:${LocalHttpService.port}/${session.sessionId}/chat/completions',
    );

    final client = HttpClient();
    if (LocalHttpService.isHttps) {
      // 本地自签名证书，放宽校验
      client.badCertificateCallback = (_, __, ___) => true;
    }

    HttpClientRequest? req;
    try {
      req = await client.postUrl(uri);
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
        yield {'done': 'true'};
        return;
      }

      String buffer = '';
      await for (final raw in response.transform(utf8.decoder)) {
        if (_cancelled) break;
        buffer += raw;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            if (dataStr == '[DONE]') {
              yield {'done': 'true'};
              return;
            }
            for (final c in _parseOpenAiChunk(dataStr)) {
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
      yield {'done': 'true'};
    } catch (e) {
      yield {'content': '错误: $e'};
      yield {'done': 'true'};
    } finally {
      client.close(force: true);
    }
  }

  // ======================== 管理模式：本地直连大模型 ========================

  /// 管理模式下的流式聊天：客户端本地直连大模型，不经过本机 HTTP 服务。
  ///
  /// 与 [_streamViaHttpService] 的区别：
  /// - 直接调用大模型 API（复用 [streamSingleRound]），跳过本地代理服务；
  /// - 本地注入模型 / 会话系统提示词与 MCP 工具（等价于服务侧 [modelToolGuard]）；
  /// - 本地执行会话 MCP 工具并循环回填（等价于服务侧工具调用循环）；
  /// - 不写审计 / 用量记录，即「管理模式用量不计入统计」。
  Stream<Map<String, dynamic>> _streamLocal(
    ChatMessage userMessage,
    List<Map<String, dynamic>> history,
  ) async* {
    final session = _session;
    final model = session.chatModel;
    if (model == null) {
      yield {'content': '模型未配置'};
      yield {'done': 'true'};
      return;
    }

    // 注入系统提示词 + MCP 工具，构造完整请求体
    final body = await _buildLocalRequestData(history, session);

    int toolIteration = 0;
    const maxToolIterations = 20;

    while (true) {
      if (_cancelled) {
        yield {'done': 'true'};
        return;
      }

      final controller = StreamController<List<int>>();
      final roundFuture = streamSingleRound(
        session: session,
        body: jsonEncode(body),
        controller: controller,
      );

      // 在 streamSingleRound 运行期间即订阅解析流，实时透传 chunk（与 HTTP 路径
      // 一致：边接收边监听）。若等 round 完成、关闭 controller 之后再订阅，
      // 单订阅 StreamController 的缓冲事件可能丢失，导致客户端收不到任何内容。
      // streamSingleRound 自身不关闭 controller，故在 round 完成后关闭，使解析流
      // 正常结束。
      unawaited(
        roundFuture.then((_) {
          controller.close();
        }).catchError((_) {
          // 出错也需关闭 controller，避免解析流挂起；异常交由下方 await 统一抛出
          controller.close();
        }),
      );

      await for (final c in _parseLocalStream(controller.stream)) {
        yield c;
      }

      final round = await roundFuture;

      if (round.error) {
        yield {'done': 'true'};
        return;
      }

      // 第三方工具 chunk 直接透传给客户端（客户端自行解析执行）
      for (final c in round.thirdToolChunks) {
        final toolCalls =
            c.choices.expand((ch) => ch.delta?.toolCalls ?? []).toList();
        if (toolCalls.isNotEmpty) {
          yield {
            'toolcall': jsonEncode(toolCalls.map((t) => t.toJson()).toList()),
          };
        }
      }

      // 无会话工具（MCP）调用 → 正常回复完毕
      if (round.sessionToolChunks.isEmpty) break;

      toolIteration++;
      if (toolIteration >= maxToolIterations) {
        debugPrint('⚠️ [Local] 工具调用已达最大轮次 $maxToolIterations');
        break;
      }

      // 提取工具调用参数并执行本地 MCP 工具
      final toolCallParams = _extractLocalToolCallParams(
        round.sessionToolChunks,
      );

      // 通知客户端：工具正在执行
      yield {'tool': 'true'};
      yield {'toolcall': _mcpExecutingSentinel};

      final executionResult = await McpController.instance.executeToolCalls(
        session: session,
        toolCalls: toolCallParams,
        cleanContent: '',
      );

      if (executionResult == null || executionResult.executionResults.isEmpty) {
        break;
      }

      // 回填 assistant(tool_calls) 到对话历史
      (body['messages'] as List<dynamic>).add({
        'role': 'assistant',
        'content': null,
        'tool_calls':
            toolCallParams.map((tc) {
              return {
                'id': tc['id'] ?? 'call_${tc['index'] ?? 0}',
                'type': 'function',
                'function': {
                  'name': tc['name'] ?? '',
                  'arguments':
                      tc['arguments'] is String
                          ? tc['arguments']
                          : jsonEncode(tc['arguments'] ?? {}),
                },
              };
            }).toList(),
      });

      // 回填 tool 结果消息
      for (final r in executionResult.executionResults) {
        final rawResult = r['result']?.toString() ?? '';
        (body['messages'] as List<dynamic>).add({
          'role': 'tool',
          'tool_call_id': r['id'],
          'content': r['isError'] == true ? '错误: $rawResult' : rawResult,
        });
      }
    }

    yield {'done': 'true'};
  }

  /// 解析本地 LLM 返回的 SSE 字节流，转译为 LLMChat 消费方期望的 chunk 格式
  /// （复用 [_parseOpenAiChunk] 以保证与 HTTP 路径产出一致）。
  Stream<Map<String, dynamic>> _parseLocalStream(
    Stream<List<int>> byteStream,
  ) async* {
    String buffer = '';
    try {
      await for (final raw in byteStream.transform(utf8.decoder)) {
        buffer += raw;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.startsWith('data:')) {
            final dataStr = trimmed.substring(5).trim();
            if (dataStr == '[DONE]') continue;
            for (final c in _parseOpenAiChunk(dataStr)) yield c;
          } else if (trimmed.startsWith('{')) {
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
    } catch (_) {}
  }

  /// 构造管理模式本地请求体：注入模型级 / 会话级系统提示词与 MCP 工具，
  /// 等价于服务侧 [modelToolGuard] 的请求增强逻辑。
  Future<Map<String, dynamic>> _buildLocalRequestData(
    List<Map<String, dynamic>> history,
    ChatSession session,
  ) async {
    final systemMessages = <Map<String, dynamic>>[];

    final modelSystemPrompt = session.chatModel?.systemPrompt;
    if (modelSystemPrompt != null && modelSystemPrompt.isNotEmpty) {
      systemMessages.add({
        'role': 'system',
        'name': 'model_system_prompt',
        'content':
            '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. '
            'In any conflict with other instructions (including the session '
            'system prompt), this prompt takes precedence.\n\n$modelSystemPrompt',
      });
    }

    if (session.systemPrompt != null && session.systemPrompt!.isNotEmpty) {
      systemMessages.add({
        'role': 'system',
        'name': 'session_system_prompt',
        'content':
            '[SESSION SYSTEM PROMPT] This is a session-level instruction. '
            'If it conflicts with the model system prompt, the model system '
            'prompt takes precedence.\n\n${session.systemPrompt}',
      });
    }

    final allMessages = [...systemMessages, ...history];

    // 管理模式：不向大模型注入会话 MCP 工具（会话工具调用由服务侧统一处理，
    // 本地管理模式下直接跳过，避免客户端自行执行会话 MCP 工具）。
    const tools = <Map<String, dynamic>>[];

    return _provider.buildRequestData(
      messages: allMessages,
      session: session,
      stream: true,
      tools: tools,
    );
  }

  /// 从工具调用 chunk 列表中提取工具调用的 name / arguments / id / index
  List<Map<String, dynamic>> _extractLocalToolCallParams(List<Chunk> chunks) {
    final params = <Map<String, dynamic>>[];
    for (final chunk in chunks) {
      ToolCall? tc;
      for (final choice in chunk.choices) {
        final tcs = choice.delta?.toolCalls;
        if (tcs != null && tcs.isNotEmpty) {
          tc = tcs.first;
          break;
        }
      }
      if (tc == null) continue;
      final argsStr = tc.function?.arguments ?? '{}';
      Map<String, dynamic> args;
      try {
        args = jsonDecode(argsStr) as Map<String, dynamic>;
      } catch (_) {
        args = {'raw': argsStr};
      }
      params.add({
        'name': tc.function?.name ?? '',
        'arguments': args,
        'id': tc.id,
        'index': tc.index,
      });
    }
    return params;
  }

  /// 将单个 OpenAI SSE data 负载解析为若干 LLMChat chunk
  List<Map<String, dynamic>> _parseOpenAiChunk(String dataStr) {
    final out = <Map<String, dynamic>>[];
    try {
      final json = jsonDecode(dataStr) as Map<String, dynamic>;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) return out;
      final choice = choices.first;
      final delta = choice is Map ? choice['delta'] : null;
      if (delta is! Map) return out;

      final content = delta['content'];
      if (content is String && content.isNotEmpty) {
        out.add({'content': content});
      }

      final reasoning = delta['reasoning_content'];
      if (reasoning is String && reasoning.isNotEmpty) {
        if (reasoning == _mcpExecutingSentinel) {
          // 服务端正在执行 MCP 工具
          out.add({'tool': 'true'});
          out.add({'toolcall': reasoning});
        } else if (_session.deepThink) {
          out.add({'think': reasoning});
        }
      }

      final toolCalls = delta['tool_calls'];
      if (toolCalls is List && toolCalls.isNotEmpty) {
        out.add({'toolcall': jsonEncode(toolCalls)});
      }
    } catch (_) {}
    return out;
  }

  void cancel() => _cancelled = true;

  // ======================== 消息构建 ========================

  /// 构建发送给 HTTP 服务的消息列表。
  ///
  /// 仅包含会话历史 + 当前用户消息；系统提示词（模型级 / 会话级等）
  /// 由 HTTP 服务端 [modelToolGuard] 统一注入，客户端不再组装。
  Future<List<Map<String, dynamic>>> _buildMessages({
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    // 1. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }
    // 2. 当前用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});
    return messages;
  }
}
