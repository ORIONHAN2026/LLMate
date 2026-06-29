import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/responses/openai_response.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';

/// OpenAI 兼容协议 Provider
///
/// 只负责 HTTP 通信：请求构建、SSE 流解析、错误处理。
/// 消息组装和工具构建由 WorkModeStrategy 负责。
class OpenAiProvider {
  static const int defaultTimeout = 30000;

  ChatModel? _model;
  bool _thinkEnabled = false;

  ChatModel? get model => _model;
  bool get thinkEnabled => _thinkEnabled;

  String get providerName => 'OpenAI Compatible';

  void configure(ChatModel model) {
    _model = model;
  }

  void applySessionSettings(ChatSession session) {
    _thinkEnabled = session.deepThink;
  }

  // ── HTTP 客户端 ──

  Dio get _dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(milliseconds: defaultTimeout);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── 构建请求体 ──

  Future<Map<String, dynamic>> buildRequestData({
    required List<Map<String, dynamic>> messages,
    required ChatSession session,
    required bool stream,
    List<Map<String, dynamic>>? tools,
    Map<String, dynamic>? extra,
  }) async {
    final data = <String, dynamic>{
      'model': _model!.model,
      'messages': messages,
      'stream': stream,
      'max_tokens': 4000,
      'temperature': _model!.chatSettings?.temperature ?? 0.7,
    };

    if (tools != null && tools.isNotEmpty) {
      data['tools'] = tools;
      data['tool_choice'] = 'auto';
    }

    if (session.deepThink) {
      data['thinking'] = {'type': 'enabled'};
    } else {
      data['thinking'] = {'type': 'disabled'};
    }

    if (extra != null) data.addAll(extra);
    return data;
  }

  Map<String, String> buildAuthHeaders() {
    return {
      'Authorization': 'Bearer ${_model!.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  // ── 流式请求 ──

  Stream<Map<String, String?>> sendMessageStream({
    required List<Map<String, dynamic>> messages,
    required ChatSession session,
    List<Map<String, dynamic>>? tools,
    Map<String, dynamic>? extra,
  }) async* {
    if (_model == null) throw StateError('$providerName 未配置');

    try {
      final requestData = await buildRequestData(
        messages: messages,
        session: session,
        stream: true,
        tools: tools,
        extra: extra,
      );

      if (kDebugMode) {
        debugPrint('$providerName 发送请求到: ${_model!.apiUrl}');
      }

      final response = await _dio.post<ResponseBody>(
        _model!.apiUrl!,
        options: Options(
          headers: buildAuthHeaders(),
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _transformStreamResponse(response.data!.stream);
      } else {
        yield {
          'content': 'API 请求失败：${response.statusCode}${response.statusMessage}',
          'think': null,
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('$providerName 流式响应错误: $e');
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  // ── 非流式请求 ──

  Future<String?> sendMessage({
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    if (_model == null) throw StateError('$providerName 未配置');
    try {
      final requestData = <String, dynamic>{
        'model': _model!.model,
        'messages': [
          {'role': 'user', 'content': userMessage.content},
        ],
        'stream': false,
        'max_tokens': 4000,
        'temperature': 0.3,
      };

      final response = await _dio.post(
        _model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            return message['content'] as String;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('$providerName 非流式响应错误: $e');
      return null;
    }
  }

  // ── SSE 流处理 ──

  Stream<Map<String, String?>> _transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk, allowMalformed: true);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') {
          yield {'done': 'true'};
          return;
        }
        try {
          final response = OpenAIResponse.fromJson(
            jsonDecode(dataStr) as Map<String, dynamic>,
          );

          final content = response.choices.firstOrNull?.delta?.content;
          if (content != null && content.isNotEmpty) {
            yield {'content': content};
          }

          if (_thinkEnabled) {
            final reasoning =
                response.choices.firstOrNull?.delta?.reasoningContent;
            if (reasoning != null && reasoning.isNotEmpty) {
              yield {'think': reasoning};
            }
          }

          final toolCalls = response.choices.firstOrNull?.delta?.toolCalls;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            yield {
              'toolcall': jsonEncode(toolCalls.map((t) => t.toJson()).toList()),
            };
          }
        } catch (e) {
          if (kDebugMode) debugPrint('$providerName JSON 解析错误: $e');
        }
      }
    }
    yield {'done': 'true'};
  }

  // ── 验证 ──

  Future<bool> validateConfiguration() async {
    if (_model == null) return false;
    if (_model!.apiUrl == null || _model!.apiUrl!.isEmpty) return false;
    if (_model!.apiKey == null || _model!.apiKey!.isEmpty) return false;
    if (_model!.model.isEmpty) return false;
    return true;
  }

  // ── 错误处理 ──

  String handleApiError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      String? serverMessage;
      try {
        if (responseData is String && responseData.isNotEmpty) {
          final body = jsonDecode(responseData) as Map<String, dynamic>;
          serverMessage = body['error']?['message'] as String?;
        } else if (responseData is Map) {
          serverMessage = responseData['error']?['message'] as String?;
        }
      } catch (_) {}
      serverMessage ??= error.message;

      switch (statusCode) {
        case 401:
          return 'API 密钥无效，请检查密钥配置';
        case 402:
          return '402错误：当前模型的服务异常，请去模型提供商查看是否存在欠费情况';
        case 403:
          return serverMessage ?? 'API 访问被拒绝，请检查权限设置';
        case 404:
          return 'API 地址不存在，请检查 URL 配置';
        case 429:
          return 'API 调用频率过高，请稍后重试';
        case 500:
        case 502:
        case 503:
          return 'API 服务器内部错误，请稍后重试';
        default:
          if (statusCode != null && statusCode >= 400) {
            return serverMessage ?? 'API 请求失败 ($statusCode)';
          }
      }
    }

    final es = error.toString();
    if (es.contains('Dio can\'t establish a new connection after it was closed'))
      return '连接错误，请重试发送消息';
    if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时，请检查网络设置';
    if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时，请稍后重试';
    if (es.contains('CONNECTION_ERROR') || es.contains('Connection refused'))
      return '网络连接被拒绝，请检查网络连接和API地址';
    if (es.contains('Network is unreachable')) return '网络不可达，请检查网络连接';
    if (es.contains('SocketException') || es.contains('HandshakeException'))
      return '网络连接失败，请检查网络设置和证书配置';
    if (es.contains('FormatException') || es.contains('Invalid JSON'))
      return 'API 响应格式错误，请检查API配置';
    return 'API 错误：$es';
  }

  Future<Map<String, dynamic>?> getModelInfo() async {
    if (_model == null) return null;
    final modelName = _model!.model.toLowerCase();
    final reasoningKeywords = ['o1', 'o3', 'o4', 'r1', 'qwq', 'glm', 'deepseek-r1', 'thinking'];
    final supportsReasoning = reasoningKeywords.any(
      (kw) => modelName.contains(kw.toLowerCase()),
    );
    return {
      'provider': providerName,
      'model': _model!.model,
      'name': _model!.name,
      'configured': true,
      'supports_reasoning': supportsReasoning,
    };
  }
}
