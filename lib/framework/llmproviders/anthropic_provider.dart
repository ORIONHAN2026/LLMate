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
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.imageAnalysis,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {
    // 验证 Anthropic 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('Anthropic 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      // Claude API 使用不同的消息格式
      final systemMessage = requestMessages.firstWhere(
        (msg) => msg['role'] == 'system',
        orElse: () => {'content': ''},
      );

      final userMessages =
          requestMessages.where((msg) => msg['role'] != 'system').toList();

      final requestData = {
        'model': model!.model,
        'max_tokens': 4000,
        'temperature': 0.7,
        'messages': userMessages,
      };

      // 添加系统消息
      if (systemMessage['content'].toString().isNotEmpty) {
        requestData['system'] = systemMessage['content'];
      }

      // 添加工具调用支持
      if (session != null && session.isMcpToolsEnabled) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = {'type': 'auto'};
        }
      }

      if (kDebugMode) {
        print('Anthropic 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(
          headers: {
            'x-api-key': model!.apiKey,
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
        ),
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
      if (kDebugMode) {
        print('Anthropic 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) {
      throw StateError('Anthropic 提供商未配置');
    }

    try {
      final requestData = {
        'model': model!.model,
        'messages': [
          {'role': 'user', 'content': userMessage.content},
        ],
        'max_tokens': 4000,
      };

      // 添加工具调用支持
      if (session != null && session.isMcpToolsEnabled) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = {'type': 'auto'};
        }
      }

      if (kDebugMode) {
        print('Anthropic 发送非流式请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(
          headers: {
            'x-api-key': model!.apiKey,
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
        ),
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
      if (kDebugMode) {
        print('Anthropic 非流式响应错误: $e');
      }
      throw Exception('Anthropic API 错误: ${handleApiError(e)}');
    }
  }

  @override
  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    return {
      'provider': 'anthropic',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
