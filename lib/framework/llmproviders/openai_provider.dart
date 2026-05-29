import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// OpenAI API 提供商
class OpenAiProvider extends BaseLlmProvider {
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
  void onConfigure(ChatModel model) {
    // 验证 OpenAI 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('OpenAI 提供商未配置');
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
        print('OpenAI 发送请求到: ${model!.apiUrl}');
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
        yield* _processOpenAIStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('OpenAI 提供商未配置');
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
        print('OpenAI (withMessages) 发送请求到: ${model!.apiUrl}');
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
        yield* _processOpenAIStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI 流式响应错误 (withMessages): $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  /// 处理 OpenAI 流式响应
  Stream<Map<String, String?>> _processOpenAIStreamResponse(Stream<List<int>> stream) async* {
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
            final content = _extractOpenAIContent(data);
            if (content != null && content.isNotEmpty) {
              yield {'content': content, 'think': null};
            }
          } catch (e) {
            // 忽略解析错误，继续处理下一行
            if (kDebugMode) {
              print('OpenAI JSON解析错误: $e, 行内容: $line');
            }
          }
        }
      }
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) {
      throw StateError('OpenAI 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      final requestData = {
        'model': model!.model,
        'messages': requestMessages,
        'stream': false, // 非流式请求
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
        print('OpenAI 发送非流式请求到: ${model!.apiUrl}');
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
        final data = response.data;
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final message = data['choices'][0]['message'];
          if (message != null && message['content'] != null) {
            return message['content'] as String;
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI 非流式响应错误: $e');
      }
      throw Exception('错误: ${handleApiError(e)}');
    }
  }

  /// 从 OpenAI 流式数据中提取内容
  String? _extractOpenAIContent(Map<String, dynamic> data) {
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      final choice = data['choices'][0];
      if (choice['delta'] != null && choice['delta']['content'] != null) {
        return choice['delta']['content'];
      }
      // 兼容部分API直接返回content
      if (choice['message'] != null && choice['message']['content'] != null) {
        return choice['message']['content'];
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    try {
      // OpenAI 不直接提供模型信息端点，返回基本信息
      return {
        'provider': 'openai',
        'model': model!.model,
        'name': model!.name,
        'features': getSupportedFeatures(),
        'configured': true,
      };
    } catch (e) {
      debugPrint('获取 OpenAI 模型信息失败: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> handleToolCall({
    required Map<String, dynamic> toolCall,
    ChatSession? session,
  }) async {
    if (!supportsFeature(LlmFeatures.toolCalling) || session == null) {
      return null;
    }

    try {
      // 这里可以集成 MCP 服务处理工具调用
      // 具体实现依赖于 MCP 服务的接口
      return {'tool_call_id': toolCall['id'], 'content': '工具调用结果'};
    } catch (e) {
      debugPrint('OpenAI 工具调用处理失败: $e');
      return null;
    }
  }
}
