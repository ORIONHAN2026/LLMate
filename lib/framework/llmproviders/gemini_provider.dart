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
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.imageAnalysis,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {
    // 验证 Google 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('Gemini 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      // Gemini API 使用 contents 格式
      final contents =
          requestMessages.where((msg) => msg['role'] != 'system').map((msg) {
            return {
              'role': msg['role'] == 'user' ? 'user' : 'model',
              'parts': [
                {'text': msg['content']},
              ],
            };
          }).toList();

      final requestData = {
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4000},
      };

      // 添加系统指令
      final systemMessage = requestMessages.firstWhere(
        (msg) => msg['role'] == 'system',
        orElse: () => {'content': ''},
      );
      if (systemMessage['content'].toString().isNotEmpty) {
        requestData['systemInstruction'] = {
          'parts': [
            {'text': systemMessage['content']},
          ],
        };
      }

      // 添加工具调用支持
      if (session != null && session.mcpServer != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
        }
      }

      if (kDebugMode) {
        print('Gemini 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: {'Content-Type': 'application/json'}),
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
      if (kDebugMode) {
        print('Gemini 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('Gemini 提供商未配置');
    }

    try {
      // 转换为 Gemini 的 contents 格式
      final contents = messages.where((msg) => msg['role'] != 'system').map((msg) {
        return {
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [{'text': msg['content']}],
        };
      }).toList();

      final requestData = {
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4000},
      };

      // 处理系统消息
      final systemMessage = messages.firstWhere(
        (msg) => msg['role'] == 'system',
        orElse: () => {'content': ''},
      );
      if (systemMessage['content'].toString().isNotEmpty) {
        requestData['systemInstruction'] = {
          'parts': [{'text': systemMessage['content']}],
        };
      }

      if (kDebugMode) {
        print('Gemini (withMessages) 发送请求到: ${model!.apiUrl}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: {'Content-Type': 'application/json'}),
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
      if (kDebugMode) {
        print('Gemini 流式响应错误 (withMessages): $e');
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
      throw StateError('Gemini 提供商未配置');
    }

    try {
      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': userMessage.content},
            ],
          },
        ],
        'generationConfig': {
          'maxOutputTokens': 4000,
          'temperature': 0.7,
        },
      };

      // 添加工具调用支持
      if (session != null && session.mcpServer != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
        }
      }

      if (kDebugMode) {
        print('Gemini 发送非流式请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: {'Content-Type': 'application/json'}),
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
      if (kDebugMode) {
        print('Gemini 非流式响应错误: $e');
      }
      throw Exception('Gemini API 错误: ${handleApiError(e)}');
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
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': '你好'},
              ],
            },
          ],
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Gemini 配置验证失败: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    return {
      'provider': 'gemini',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
