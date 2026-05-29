import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// ModelScope (魔塔) API 提供商
class ModelScopeProvider extends BaseLlmProvider {
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
  void onConfigure(ChatModel model) {
    // 验证 ModelScope 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('ModelScope 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      final requestData = {
        'model': model!.model,
        'messages': requestMessages,
        'stream': true,
        'max_tokens': 4000,
        'temperature': 0.7,
      };

      // 添加工具调用支持
      if (session != null && session.isMcpToolsEnabled) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto';
        }
      }

      if (kDebugMode) {
        print('ModelScope 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model!.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _processModelScopeStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) {
        print('ModelScope 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('ModelScope 提供商未配置');
    }

    try {
      final requestData = {
        'model': model!.model,
        'messages': messages,
        'stream': true,
        'max_tokens': 4000,
        'temperature': 0.7,
      };

      if (kDebugMode) {
        print('ModelScope (withMessages) 发送请求到: ${model!.apiUrl}');
      }

      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model!.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _processModelScopeStreamResponse(response.data!.stream);
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
    if (model == null) {
      throw StateError('ModelScope 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      final requestData = {
        'model': model!.model,
        'messages': requestMessages,
        'stream': false,
        'max_tokens': 4000,
        'temperature': 0.7,
      };

      if (kDebugMode) {
        print('ModelScope 发送非流式请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model!.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final message = choice['message'] as Map<String, dynamic>?;
          if (message != null) {
            return message['content'] as String?;
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ModelScope 非流式响应错误: $e');
      }
      throw Exception('ModelScope API 错误: ${handleApiError(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    return {
      'provider': 'modelscope',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }

  /// 处理 ModelScope 流式响应
  Stream<Map<String, String?>> _processModelScopeStreamResponse(Stream<List<int>> stream) async* {
    String buffer = '';

    await for (final chunk in stream) {
      final chunkString = utf8.decode(chunk);
      buffer += chunkString;

      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // 保留可能不完整的最后一行

      for (final line in lines) {
        if (line.trim().startsWith('data: ')) {
          final dataStr = line.trim().substring(6);
          if (dataStr == '[DONE]') {
            return;
          }

          try {
            final data = jsonDecode(dataStr);
            final content = _extractModelScopeContent(data);
            if (content != null && content.isNotEmpty) {
              yield {'content': content, 'think': null};
            }
          } catch (e) {
            // 忽略解析错误，继续处理下一行
            if (kDebugMode) {
              print('ModelScope JSON解析错误: $e, 行内容: $line');
            }
          }
        }
      }
    }
  }

  /// 从 ModelScope 流式数据中提取内容
  String? _extractModelScopeContent(Map<String, dynamic> data) {
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      final choice = data['choices'][0];
      if (choice['delta'] != null && choice['delta']['content'] != null) {
        return choice['delta']['content'];
      }
      if (choice['message'] != null && choice['message']['content'] != null) {
        return choice['message']['content'];
      }
    }
    return null;
  }
}
