import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// OpenAI API 提供商
class OpenAiProvider extends BaseLlmProvider {
  @override
  String get providerName => 'OpenAI';

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

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'openai',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
