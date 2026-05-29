import 'dart:convert';
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
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {
    // 验证 Qwen 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('Qwen 提供商未配置');
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
        print('Qwen 发送请求到: ${model!.apiUrl}');
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
        yield* _processQwenStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) {
        print('Qwen 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('Qwen 提供商未配置');
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
        print('Qwen (withMessages) 发送请求到: ${model!.apiUrl}');
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
        yield* _processQwenStreamResponse(response.data!.stream);
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
      throw StateError('Qwen 提供商未配置');
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

      // 添加工具调用支持
      if (session != null && session.isMcpToolsEnabled) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto';
        }
      }

      if (kDebugMode) {
        print('Qwen 发送非流式请求到: ${model!.apiUrl}');
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
        print('Qwen 非流式响应错误: $e');
      }
      throw Exception('Qwen API 错误: ${handleApiError(e)}');
    }
  }

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) {
      return false;
    }

    try {
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model!.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model!.model,
          'messages': [
            {'role': 'user', 'content': '你好'},
          ],
          'max_tokens': 5,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Qwen 配置验证失败: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    return {
      'provider': 'qwen',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }

  /// 处理 Qwen 流式响应
  Stream<Map<String, String?>> _processQwenStreamResponse(Stream<List<int>> stream) async* {
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
            final content = _extractQwenContent(data);
            if (content != null && content.isNotEmpty) {
              yield {'content': content, 'think': null};
            }
          } catch (e) {
            // 忽略解析错误，继续处理下一行
            if (kDebugMode) {
              print('Qwen JSON解析错误: $e, 行内容: $line');
            }
          }
        }
      }
    }
  }

  /// 从 Qwen 流式数据中提取内容
  String? _extractQwenContent(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          return delta['content'] as String?;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('提取 Qwen 内容失败: $e');
      }
    }
    return null;
  }
}
