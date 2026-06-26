import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// Google Gemini API 提供商
class GeminiProvider extends BaseLlmProvider {
  @override
  String get providerName => 'Gemini';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
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

  // ── Gemini 请求体构建（contents + systemInstruction） ──

  Map<String, dynamic> _buildGeminiRequestData({
    required List<Map<String, dynamic>> messages,
    ChatSession? session,
  }) {
    // 合并所有 system 消息（Gemini 的 systemInstruction 只支持单条）
    final systemMessages = messages.where((msg) => msg['role'] == 'system').toList();
    final systemContent = systemMessages
        .map((msg) => msg['content'].toString())
        .where((c) => c.isNotEmpty)
        .join('\n\n');

    final contents = messages.where((msg) => msg['role'] != 'system').map((msg) {
      return {
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': msg['content']}],
      };
    }).toList();

    final requestData = <String, dynamic>{
      'contents': contents,
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4000},
    };

    if (systemContent.isNotEmpty) {
      requestData['systemInstruction'] = {
        'parts': [{'text': systemContent}],
      };
    }

    if (session != null) {
      final tools = buildTools(session);
      if (tools.isNotEmpty) requestData['tools'] = tools;
    }

    return requestData;
  }

  Map<String, String> _buildAuthHeaders() {
    return {'Content-Type': 'application/json'};
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('Gemini 提供商未配置');
    try {
      final requestMessages = await buildMessages(userMessage: userMessage, session: session);
      final requestData = _buildGeminiRequestData(messages: requestMessages, session: session);

      if (kDebugMode) {
        print('Gemini 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content['parts'] != null && content['parts'].isNotEmpty) {
            yield {'content': content['parts'][0]['text'] ?? '抱歉，没有收到回复', 'think': null};
          } else {
            yield {'content': '抱歉，没有收到回复', 'think': null};
          }
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
    if (model == null) throw StateError('Gemini 提供商未配置');
    try {
      final requestData = _buildGeminiRequestData(messages: messages, session: session);
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content['parts'] != null && content['parts'].isNotEmpty) {
            yield {'content': content['parts'][0]['text'] ?? '抱歉，没有收到回复', 'think': null};
          } else {
            yield {'content': '抱歉，没有收到回复', 'think': null};
          }
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
    if (model == null) throw StateError('Gemini 提供商未配置');
    try {
      final requestData = <String, dynamic>{
        'contents': [
          {'parts': [{'text': userMessage.content}]}
        ],
        'generationConfig': {'maxOutputTokens': 4000, 'temperature': 0.7},
      };
      if (session != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) requestData['tools'] = tools;
      }
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content['parts'] != null && content['parts'].isNotEmpty) {
            return content['parts'][0]['text'] as String?;
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Gemini API 错误: ${handleApiError(e)}');
    }
  }

  // ── 验证与错误处理 ──

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;
    try {
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: _buildAuthHeaders()),
        data: {
          'contents': [
            {'parts': [{'text': '你好'}]}
          ],
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gemini 配置验证失败: $e');
      return false;
    }
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
    if (es.contains('429')) return 'API 调用频率过高';
    if (es.contains('500')) return 'API 服务器内部错误';
    return 'API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'gemini',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
