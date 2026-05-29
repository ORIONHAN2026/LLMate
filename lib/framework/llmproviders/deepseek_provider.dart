import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// DeepSeek API 提供商
class DeepSeekProvider extends BaseLlmProvider {
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
    // 验证 DeepSeek 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    if (model == null) {
      throw StateError('DeepSeek 提供商未配置');
    }

    try {
      final requestMessages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      yield* _sendStreamRequest(requestMessages, session);
    } catch (e) {
      if (kDebugMode) {
        print('DeepSeek 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('DeepSeek 提供商未配置');
    }

    try {
      // 对于 MCP follow-up，通常不需要再次发送 tools（已经执行过了）
      yield* _sendStreamRequest(messages, null);
    } catch (e) {
      if (kDebugMode) {
        print('DeepSeek 流式响应错误 (withMessages): $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  /// 发送流式请求的通用方法
  Stream<Map<String, String?>> _sendStreamRequest(
    List<Map<String, dynamic>> messages,
    ChatSession? session,
  ) async* {
    if (model == null) {
      throw StateError('DeepSeek 提供商未配置');
    }

    try {
      final requestData = {
        'model': model!.model,
        'messages': messages,
        'stream': true,
        'max_tokens': 4000,
        'temperature': 0.7,
      };

      // 添加工具调用支持（仅在首次请求时，follow-up 不重复发送 tools）
      if (session != null && session.mcpServer != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto';
        }
      }

      if (kDebugMode) {
        print('DeepSeek 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      // 打印工具调用请求报文
      if (requestData.containsKey('tools')) {
        debugPrint('🔧 DeepSeek 工具调用请求 tools: ${jsonEncode(requestData['tools'])}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${model!.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
      );

      // 处理流式响应
      yield* _processDeepSeekStreamResponse(response.data.stream);
    } catch (e) {
      if (kDebugMode) {
        print('DeepSeek 流式响应错误: $e');
      }
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    try {
      return {
        'provider': 'deepseek',
        'model': model!.model,
        'name': model!.name,
        'features': getSupportedFeatures(),
        'configured': true,
        'supports_reasoning': model!.model.contains('r1'), // DeepSeek R1 支持推理
      };
    } catch (e) {
      debugPrint('获取 DeepSeek 模型信息失败: $e');
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
      // DeepSeek 的工具调用处理
      return {'tool_call_id': toolCall['id'], 'content': '工具调用结果'};
    } catch (e) {
      debugPrint('DeepSeek 工具调用处理失败: $e');
      return null;
    }
  }

  /// 将累积的 tool_calls 转换为 MCP 标准协议格式输出
  /// 将 OpenAI 流式格式的 function.arguments (JSON string) 解析为 Map
  static List<Map<String, dynamic>> _buildMcpToolCallsOutput(
    Map<int, Map<String, dynamic>> accumulated,
  ) {
    return accumulated.entries
        .map((e) {
          final tc = Map<String, dynamic>.from(e.value);
          // 解析 arguments 从 JSON string 到 Map (MCP 标准格式)
          try {
            final argsStr = tc['arguments'] as String? ?? '{}';
            tc['arguments'] = jsonDecode(argsStr);
          } catch (_) {
            tc['arguments'] = <String, dynamic>{};
          }
          return tc;
        })
        .toList()
      ..sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
  }

  /// 处理 DeepSeek 流式响应
  Stream<Map<String, String?>> _processDeepSeekStreamResponse(Stream<List<int>> stream) async* {
    String buffer = '';
    
    // 用于累积 native tool_calls (MCP 标准协议格式: {index, id, name, arguments})
    final Map<int, Map<String, dynamic>> accumulatedToolCalls = {};
    bool hasToolCalls = false;

    await for (final chunk in stream) {
      final chunkString = utf8.decode(chunk);
      debugPrint('接收到 DeepSeek 数据块: $chunkString');
      buffer += chunkString;

      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // 保留可能不完整的最后一行

      for (final line in lines) {
        if (line.trim().startsWith('data: ')) {
          final dataStr = line.trim().substring(6);
          if (dataStr == '[DONE]') {
            // 流结束时，yield 累积的 tool_calls 信息
            debugPrint('🔧 DeepSeek 流结束 [DONE], hasToolCalls=$hasToolCalls, accumulatedCount=${accumulatedToolCalls.length}');
            if (hasToolCalls && accumulatedToolCalls.isNotEmpty) {
              final toolCallsList = _buildMcpToolCallsOutput(accumulatedToolCalls);
              debugPrint('🔧 [DONE] 累积的 tool_calls (MCP格式): ${jsonEncode(toolCallsList)}');
              yield {
                'content': '',
                'think': null,
                'mcpToolCalls': jsonEncode(toolCallsList),
              };
            }
            return;
          }

          try {
            final data = jsonDecode(dataStr);
            
            // 直接提取 DeepSeek 内容，不使用单独函数
            String? content;
            String? reasoningContent;
            try {
              final choices = data['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final choice = choices[0] as Map<String, dynamic>;
                final delta = choice['delta'] as Map<String, dynamic>?;
                if (delta != null) {
                  content = delta['content'] as String?;
                  // 支持 DeepSeek R1 的推理内容
                  reasoningContent = delta['reasoning_content'] as String?;
                  
                  // 处理 native tool_calls (OpenAI streaming delta → MCP 标准格式累积)
                  final toolCalls = delta['tool_calls'] as List?;
                  if (toolCalls != null && toolCalls.isNotEmpty) {
                    hasToolCalls = true;
                    debugPrint('🔧 DeepSeek 流式返回 tool_calls delta: ${jsonEncode(toolCalls)}');
                    for (final toolCall in toolCalls) {
                      final tc = toolCall as Map<String, dynamic>;
                      final index = tc['index'] as int? ?? 0;
                      
                      accumulatedToolCalls.putIfAbsent(index, () => {
                        'index': index,
                        'id': '',
                        'name': '',
                        'arguments': '',
                      });
                      
                      final accumulated = accumulatedToolCalls[index]!;
                      if (tc['id'] != null) {
                        accumulated['id'] = tc['id'];
                      }
                      if (tc['function'] != null) {
                        final func = tc['function'] as Map<String, dynamic>;
                        if (func['name'] != null && (func['name'] as String).isNotEmpty) {
                          accumulated['name'] += func['name'];
                        }
                        if (func['arguments'] != null) {
                          accumulated['arguments'] += func['arguments'];
                        }
                      }
                    }
                  }
                }
                
                // 检查 finish_reason 是否为 tool_calls
                final finishReason = choice['finish_reason'] as String?;
                if (finishReason != null) {
                  debugPrint('🔧 DeepSeek finish_reason: $finishReason, hasToolCalls=$hasToolCalls, accumulatedCount=${accumulatedToolCalls.length}');
                }
                if (finishReason == 'tool_calls' && hasToolCalls && accumulatedToolCalls.isNotEmpty) {
                  final toolCallsList = _buildMcpToolCallsOutput(accumulatedToolCalls);
                  debugPrint('🔧 累积的 tool_calls (MCP格式): ${jsonEncode(toolCallsList)}');
                  yield {
                    'content': content ?? '',
                    'think': reasoningContent,
                    'mcpToolCalls': jsonEncode(toolCallsList),
                  };
                  return; // 结束流
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('提取 DeepSeek 内容失败: $e');
              }
            }
            
            if ((content != null && content.isNotEmpty) || 
                (reasoningContent != null && reasoningContent.isNotEmpty)) {
              yield {
                'content': content ?? '',
                'think': reasoningContent, // 将推理内容映射到think字段
              };
            }
          } catch (e) {
            // 忽略解析错误，继续处理下一行
            if (kDebugMode) {
              print('DeepSeek JSON解析错误: $e, 行内容: $line');
            }
          }
        }
      }
    }
    
    // 流结束后，yield 累积的 tool_calls（如果没有在 finish_reason 中处理）
    if (hasToolCalls && accumulatedToolCalls.isNotEmpty) {
      final toolCallsList = _buildMcpToolCallsOutput(accumulatedToolCalls);
      yield {
        'content': '',
        'think': null,
        'mcpToolCalls': jsonEncode(toolCallsList),
      };
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) {
      throw StateError('DeepSeek 提供商未配置');
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
      if (session != null && session.mcpServer != null) {
        final tools = buildTools(session);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto';
        }
      }

      if (kDebugMode) {
        print('DeepSeek 发送非流式请求到: ${model!.apiUrl}');
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
        print('DeepSeek 非流式响应错误: $e');
      }
      throw Exception('错误: ${handleApiError(e)}');
    }
  }
}
