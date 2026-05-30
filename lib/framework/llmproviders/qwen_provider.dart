import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// 通义千问 API 提供商
class QwenProvider extends BaseLlmProvider {
  @override
  String get providerName => '通义千问';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {}

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    final messages = buildMessages(userMessage: userMessage, session: session);
    yield* sendOpenAIStreamRequest(messages: messages, session: session);
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    yield* sendOpenAIStreamRequest(messages: messages);
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    final messages = buildMessages(userMessage: userMessage, session: session);
    try {
      final data = await sendOpenAINonStreamRequest(
        messages: messages,
        session: session,
      );
      if (data != null) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final message = choice['message'] as Map<String, dynamic>?;
          if (message != null) return message['content'] as String?;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      throw Exception('$providerName API 错误: ${handleApiError(e)}');
    }
  }

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;
    try {
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
        data: {
          'model': model!.model,
          'messages': [{'role': 'user', 'content': '你好'}],
          'max_tokens': 5,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('$providerName 配置验证失败: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'qwen',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
