import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/system_tool_service.dart';
import 'base_provider.dart';
import 'common/message_builder.dart';

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

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(milliseconds: BaseLlmProvider.defaultTimeout);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  @override
  String buildSystemPrompt(ChatSession? session) {
    return MessageBuilder.buildSystemPrompt(model: model, session: session);
  }

  @override
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    return MessageBuilder.buildMessages(
      userMessage: userMessage,
      model: model!,
      session: session,
    );
  }

  Map<String, dynamic> buildRequestData({
    required List<Map<String, dynamic>> messages,
    required bool stream,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) {
    final data = <String, dynamic>{
      'model': model!.model,
      'messages': messages,
      'stream': stream,
      'max_tokens': 4000,
      'temperature': 0.7,
    };
    if (session != null) {
      final tools = SystemToolService.buildAllOpenAIToolsFormat(session);
      if (tools.isNotEmpty) {
        data['tools'] = tools;
        data['tool_choice'] = 'auto';
      }
    }
    if (extra != null) data.addAll(extra);
    return data;
  }

  Map<String, String> buildAuthHeaders() {
    return {
      'Authorization': 'Bearer ${model!.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  Map<String, String?> extractStreamChunk(Map<String, dynamic> data) {
    String? content;
    String? toolCall;
    String? finishReason;
    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          content = delta['content'] as String?;
          if (delta['tool_calls'] != null) toolCall = jsonEncode(delta['tool_calls']);
        }
        finishReason = choice['finish_reason'] as String?;
      }
    } catch (_) {}
    return {
      if (content != null && content.isNotEmpty) 'content': content,
      if (toolCall != null && toolCall.isNotEmpty && toolCall != 'null') 'toolcall': toolCall,
      if (finishReason != null) 'finish_reason': finishReason,
    };
  }

  Stream<Map<String, String?>> _processSSEStream(Stream<List<int>> stream) async* {
    String buffer = '';
    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') return;
        try {
          yield extractStreamChunk(jsonDecode(dataStr) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');
    final messages = buildMessages(userMessage: userMessage, session: session);
    try {
      final requestData = buildRequestData(messages: messages, stream: true, session: session);
      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders(), responseType: ResponseType.stream),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        yield* _processSSEStream(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');
    try {
      final requestData = buildRequestData(messages: messages, stream: true, session: session);
      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders(), responseType: ResponseType.stream),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        yield* _processSSEStream(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) throw StateError('$providerName 提供商未配置');
    final messages = buildMessages(userMessage: userMessage, session: session);
    try {
      final requestData = buildRequestData(messages: messages, stream: false, session: session);
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = (choices[0] as Map)['message'] as Map<String, dynamic>?;
          if (message != null) return message['content'] as String?;
        }
      }
      return null;
    } catch (e) {
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
  Map<String, dynamic> parseToolCalls(String response) {
    final toolCalls = <Map<String, dynamic>>[];
    final xmlMatch = RegExp(r'<tool_calls>\s*(.*?)\s*</tool_calls>', dotAll: true).firstMatch(response);
    final inner = xmlMatch?.group(1) ?? response;
    final invokeRegex = RegExp(r'<invoke\s+name="([^"]+)"[^>]*>(.*?)</invoke>', dotAll: true);
    for (final im in invokeRegex.allMatches(inner)) {
      try {
        final toolName = im.group(1)?.trim();
        final invokeBody = im.group(2);
        if (toolName == null || invokeBody == null) continue;
        final args = <String, dynamic>{};
        final jsonArgs = MessageBuilder.parseArgumentsJson(invokeBody);
        if (jsonArgs != null) args.addAll(jsonArgs);
        toolCalls.add({'name': toolName, 'arguments': args});
      } catch (_) {}
    }
    final cleanContent = response
        .replaceAll(RegExp(r'<tool_calls>.*?</tool_calls>', dotAll: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return {'toolCalls': toolCalls, 'cleanContent': cleanContent};
  }

  String handleApiError(dynamic error) {
    final es = error.toString();
    if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时';
    if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时';
    if (es.contains('401') || es.contains('Unauthorized')) return 'API 密钥无效';
    if (es.contains('429')) return 'API 调用频率过高';
    if (es.contains('500')) return 'API 服务器内部错误';
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
    };
  }
}
