import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../http/local_http_service.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import './openai_provider.dart';
import './common/message_builder.dart';
import './modes/mode_utils.dart';

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

    // 始终经由本机会话 HTTP 服务转发，复用服务侧中间件。
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
