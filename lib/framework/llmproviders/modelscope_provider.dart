import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// ModelScope (魔塔) API 提供商
class ModelScopeProvider extends BaseLlmProvider {
  @override
  String get providerName => 'ModelScope';

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

  // ── HTTP ──

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(milliseconds: BaseLlmProvider.defaultTimeout);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── SSE ──

  Map<String, String?> extractStreamChunk(Map<String, dynamic> data) {
    String? content;
    String? reasoningContent;
    String? toolCall;
    String? finishReason;
    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          content = delta['content'] as String?;
          reasoningContent = delta['reasoning_content'] as String?;
          if (delta['tool_calls'] != null) toolCall = jsonEncode(delta['tool_calls']);
        }
        finishReason = choice['finish_reason'] as String?;
      }
    } catch (_) {}
    return {
      if (content != null && content.isNotEmpty) 'content': content,
      if (reasoningContent != null && reasoningContent.isNotEmpty) 'think': reasoningContent,
      if (toolCall != null && toolCall.isNotEmpty && toolCall != 'null') 'toolcall': toolCall,
      if (finishReason != null) 'finish_reason': finishReason,
    };
  }

  Stream<Map<String, String?>> _processSSEStream(Stream<List<int>> stream) async* {
    String buffer = '';
    final utf8Decoder = const Utf8Decoder();
    List<int> pendingBytes = [];
    await for (final chunk in stream) {
      pendingBytes.addAll(chunk);
      String? chunkString;
      try {
        chunkString = utf8Decoder.convert(pendingBytes);
        pendingBytes.clear();
      } on FormatException {
        for (int i = pendingBytes.length - 1; i > 0; i--) {
          try {
            chunkString = utf8Decoder.convert(pendingBytes.sublist(0, i));
            pendingBytes = pendingBytes.sublist(i);
            break;
          } on FormatException {
            continue;
          }
        }
      }
      if (chunkString == null) continue;
      buffer += chunkString;
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

  // ── 核心抽象 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');
    try {
      final requestData = buildRequestData(userMessage: userMessage, stream: true, session: session);
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
    try {
      final requestData = buildRequestData(userMessage: userMessage, stream: false, session: session);
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
    if (model!.apiUrl == null || model!.apiUrl!.isEmpty) return false;
    if (model!.apiKey == null || model!.apiKey!.isEmpty) return false;
    if (model!.model.isEmpty) return false;
    return true;
  }



  String handleApiError(dynamic error) {
    final es = error.toString();
    if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时，请检查网络设置';
    if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时，请稍后重试';
    if (es.contains('CONNECTION_ERROR') || es.contains('Connection refused')) return '网络连接被拒绝';
    if (es.contains('401') || es.contains('Unauthorized')) return 'API 密钥无效';
    if (es.contains('403') || es.contains('Forbidden')) return 'API 访问被拒绝';
    if (es.contains('404') || es.contains('Not Found')) return 'API 地址不存在';
    if (es.contains('429')) return 'API 调用频率过高';
    if (es.contains('500')) return 'API 服务器内部错误';
    if (es.contains('SocketException')) return '网络连接失败';
    return 'API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'modelscope',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
