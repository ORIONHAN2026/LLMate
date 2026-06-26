import 'dart:convert';
import 'dart:async';
import 'package:llmwork/models/bigmodel/openai_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// OpenAI 兼容协议提供商
///
/// 适用于所有遵循 OpenAI Chat Completion API 格式的提供商：
/// - OpenAI
/// - DeepSeek
/// - 阿里云百炼 (Qwen)
/// - 智谱AI (Zhipu/GLM)
/// - ModelScope (魔塔)
/// - Ollama
///
/// 这些提供商的 API 格式完全一致（SSE 流式 + `data: ` 前缀 + `[DONE]` 结束标记）。
class OpenAiProvider extends BaseLlmProvider {
  /// 显示名称
  final String _displayName;

  /// 推理模型判断关键词（用于 getModelInfo 中的 supports_reasoning 判断）
  static const _reasoningKeywords = ['o1', 'o3', 'o4', 'r1', 'qwq', 'glm', 'deepseek-r1', 'thinking'];

  OpenAiProvider({
    String? displayName,
  }) : _displayName = displayName ?? 'OpenAI Compatible';

  @override
  String get providerName => _displayName;

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.toolCalling,
      LlmFeatures.imageAnalysis,
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

    // 用于累积完整响应的缓冲区
    final responseContentBuf = StringBuffer();
    final responseThinkBuf = StringBuffer();
    final responseToolCalls = <String>[];

    try {
      final requestData = await buildRequestData(
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
        await for (final chunk in _transformStreamResponse(response.data!.stream)) {
          // 累积响应内容
          if (chunk['content'] != null) responseContentBuf.write(chunk['content']);
          if (chunk['think'] != null) responseThinkBuf.write(chunk['think']);
          if (chunk['toolcall'] != null) responseToolCalls.add(chunk['toolcall']!);

          yield chunk;
        }

      } else {
        yield {
          'content': 'API 请求失败：${response.statusCode}${response.statusMessage}',
          'think': null,
        };
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
      final requestData = await buildRequestData(
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

  // ── OpenAI 兼容 SSE 流处理 ──

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
        print(dataStr);
        if (dataStr == '[DONE]') {
          yield {'done': 'true'};
          return;
        }
        try {
          final response = OpenAIResponse.fromJson(
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
    // 优先从 DioException 的响应体中提取服务器错误信息
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

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;

    // 判断是否支持推理
    final modelName = model!.model.toLowerCase();
    final supportsReasoning = _reasoningKeywords.any(
      (kw) => modelName.contains(kw.toLowerCase()),
    );

    return {
      'provider': _displayName,
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
      'supports_reasoning': supportsReasoning,
    };
  }

}
