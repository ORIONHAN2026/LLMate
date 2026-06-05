import 'dart:convert';
import 'dart:async';
import 'package:chathub/models/bigmodel/zhipu_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// 智谱AI API 提供商
class ZhipuProvider extends BaseLlmProvider {
  @override
  String get providerName => '智谱AI';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.toolCalling,
      LlmFeatures.codeGeneration,
      LlmFeatures.functionCalling,
    ];
  }

  @override
  void onConfigure(ChatModel model) {}

  // ── HTTP 客户端 ──

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(
      milliseconds: BaseLlmProvider.defaultTimeout,
    );
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    yield* _sendOpenAIStreamRequest(userMessage: userMessage, session: session);
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    yield* _sendOpenAIStreamRequest(messages: messages, session: session);
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    try {
      final data = await _sendOpenAINonStreamRequest(
        userMessage: userMessage,
        session: session,
        extra: {
          'response_format': {'type': 'json_object'},
        },
      );
      if (data != null) {
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
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      throw Exception('错误: ${handleApiError(e)}');
    }
  }

  // ── OpenAI 兼容流式请求 ──

  Stream<Map<String, String?>> _sendOpenAIStreamRequest({
    ChatMessage? userMessage,
    List<Map<String, dynamic>>? messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');

    try {
      final requestData = buildRequestData(
        userMessage: userMessage,
        messages: messages,
        stream: true,
        session: session,
        extra: extra,
      );

      if (kDebugMode) {
        print('$providerName 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)} 请求数据结束');
      }

      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(
          headers: buildAuthHeaders(),
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _transformStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) print('$providerName 流式响应错误: $e');
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  Future<Map<String, dynamic>?> _sendOpenAINonStreamRequest({
    ChatMessage? userMessage,
    List<Map<String, dynamic>>? messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async {
    if (model == null) throw StateError('$providerName 提供商未配置');
    try {
      final requestData = buildRequestData(
        userMessage: userMessage,
        messages: messages,
        stream: false,
        session: session,
        extra: extra,
      );
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      rethrow;
    }
  }

  // ── 智谱流处理 ──

  Stream<Map<String, String?>> _transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        print(dataStr);
        if (dataStr == '[DONE]') {
          yield {'done': 'true'};
          return;
        }
        try {
          final response = ZhipuResponse.fromJson(
            jsonDecode(dataStr) as Map<String, dynamic>,
          );

          // 普通文本内容
          final content = response.choices.firstOrNull?.delta?.content;
          if (content != null && content.isNotEmpty) {
            yield {'content': content};
          }

          // 提取 think（推理过程），仅在深度思考模式下 yield
          if (thinkEnabled) {
            final reasoning =
                response.choices.firstOrNull?.delta?.reasoningContent;
            if (reasoning != null && reasoning.isNotEmpty) {
              yield {'think': reasoning};
            }
          }

          // 原生 tool_calls delta
          final toolCalls = response.choices.firstOrNull?.delta?.toolCalls;
          if (toolCalls != null && toolCalls.isNotEmpty) {
            yield {
              'toolcall': jsonEncode(toolCalls.map((t) => t.toJson()).toList()),
            };
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
    }
    // 安全兜底：流自然结束时也发送 done 信号
    yield {'done': 'true'};
  }

  // ── 验证与错误处理 ──

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;
    if (model!.apiUrl == null || model!.apiUrl!.isEmpty) return false;
    if (model!.apiKey == null || model!.apiKey!.isEmpty) return false;
    if (model!.model.isEmpty) return false;
    return true;
  }

  String handleApiError(dynamic error) {
    final es = error.toString();
    if (es.contains(
      'Dio can\'t establish a new connection after it was closed',
    ))
      return '连接错误，请重试发送消息';
    if (es.contains('DioException') || es.contains('DioError')) {
      // HTTP 状态码优先判断
      if (es.contains('401') || es.contains('Unauthorized'))
        return 'API 密钥无效，请检查密钥配置';
      if (es.contains('403') || es.contains('Forbidden'))
        return 'API 访问被拒绝，请检查权限设置';
      if (es.contains('404') || es.contains('Not Found'))
        return 'API 地址不存在，请检查 URL 配置';
      if (es.contains('429') || es.contains('Too Many Requests'))
        return 'API 调用频率过高，请稍后重试';
      if (es.contains('500') || es.contains('Internal Server Error'))
        return 'API 服务器内部错误，请稍后重试';
      // 网络错误
      if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时，请检查网络设置';
      if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时，请稍后重试';
      if (es.contains('CONNECTION_ERROR') || es.contains('Connection refused'))
        return '网络连接被拒绝，请检查网络连接和API地址';
      if (es.contains('Network is unreachable')) return '网络不可达，请检查网络连接';
      return '网络连接错误：请检查网络设置和API配置';
    }
    if (es.contains('SocketException') || es.contains('HandshakeException'))
      return '网络连接失败，请检查网络设置和证书配置';
    if (es.contains('FormatException') || es.contains('Invalid JSON'))
      return 'API 响应格式错误，请检查API配置';
    return 'API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'zhipu',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
      'supports_reasoning': model!.model.contains('glm'),
    };
  }
}
