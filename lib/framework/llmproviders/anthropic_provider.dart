import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// Anthropic (Claude) API 提供商
class AnthropicProvider extends BaseLlmProvider {
  @override
  String get providerName => 'Anthropic';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.imageAnalysis,
      LlmFeatures.codeGeneration,
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

  // ── 消息构建 ──

  // ── Claude 特有的请求体构建（system 独立字段） ──

  Map<String, dynamic> _buildClaudeRequestData({
    required List<Map<String, dynamic>> messages,
    ChatSession? session,
  }) {
    // 合并所有 system 消息（Claude API 只支持单个 system 字段）
    final systemContent = messages
        .where((msg) => msg['role'] == 'system')
        .map((msg) => msg['content'].toString())
        .where((c) => c.isNotEmpty)
        .join('\n\n');
    final userMessages = messages.where((msg) => msg['role'] != 'system').toList();

    final requestData = <String, dynamic>{
      'model': model!.model,
      'max_tokens': 4000,
      'temperature': 0.7,
      'messages': userMessages,
    };

    if (systemContent.isNotEmpty) {
      requestData['system'] = systemContent;
    }

    if (session != null) {
      final tools = buildTools(session);
      if (tools.isNotEmpty) {
        requestData['tools'] = tools;
        requestData['tool_choice'] = {'type': 'auto'};
      }
    }

    return requestData;
  }

  Map<String, String> _buildAuthHeaders() {
    return {
      'x-api-key': model!.apiKey ?? '',
      'Content-Type': 'application/json',
      'anthropic-version': '2023-06-01',
    };
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('Anthropic 提供商未配置');
    try {
      final requestMessages = buildMessages(userMessage: userMessage, session: session);
      final requestData = _buildClaudeRequestData(messages: requestMessages, session: session);

      if (kDebugMode) {
        print('Anthropic 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['content'] != null && data['content'].isNotEmpty) {
          yield {'content': data['content'][0]['text'] ?? '抱歉，没有收到回复', 'think': null};
        } else {
          yield {'content': '抱歉，没有收到回复', 'think': null};
        }
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
    yield {'done': 'true'};
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('Anthropic 提供商未配置');
    try {
      final requestData = _buildClaudeRequestData(messages: messages, session: session);
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['content'] != null && data['content'].isNotEmpty) {
          yield {'content': data['content'][0]['text'] ?? '抱歉，没有收到回复', 'think': null};
        } else {
          yield {'content': '抱歉，没有收到回复', 'think': null};
        }
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
    yield {'done': 'true'};
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) throw StateError('Anthropic 提供商未配置');
    try {
      final requestData = <String, dynamic>{
        'model': model!.model,
        'messages': [{'role': 'user', 'content': userMessage.content}],
        'max_tokens': 4000,
      };
      if (session != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = {'type': 'auto'};
        }
      }
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['content'] != null && data['content'].isNotEmpty) {
          return data['content'][0]['text'] as String?;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Anthropic API 错误: ${handleApiError(e)}');
    }
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

  Map<String, dynamic> parseToolCalls(String response) {
    return {'toolCalls': <Map<String, dynamic>>[], 'cleanContent': response};
  }

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
          return 'API 密钥无效';
        case 402:
          return '402错误：当前模型的服务异常，请去模型提供商查看是否存在欠费情况';
        case 429:
          return 'API 调用频率过高';
        case 500:
          return 'API 服务器内部错误';
        default:
          if (statusCode != null && statusCode >= 400) {
            return serverMessage ?? 'API 请求失败 ($statusCode)';
          }
      }
    }
    final es = error.toString();
    if (es.contains('401') || es.contains('Unauthorized')) return 'API 密钥无效';
    if (es.contains('429') || es.contains('Too Many Requests')) return 'API 调用频率过高';
    if (es.contains('500')) return 'API 服务器内部错误';
    return 'API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'anthropic',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
