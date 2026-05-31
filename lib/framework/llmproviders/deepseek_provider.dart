import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/mcp_service.dart';
import 'base_provider.dart';

/// DeepSeek API 提供商
class DeepSeekProvider extends BaseLlmProvider {
  @override
  String get providerName => 'DeepSeek';

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

  @override
  String buildProviderPrompt() => '对tools工具的调用，请严格使用<tool_calls>标签返回，禁止使用DMSL';

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    final messages = buildMessages(userMessage: userMessage, session: session);
    yield* sendOpenAIStreamRequest(messages: messages, session: session);
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) async* {
    yield* sendOpenAIStreamRequest(messages: messages);
  }

  /// DeepSeek 特有：累积正文内容，在 finish_reason=stop 时解析 <tool_calls> 文本
  @override
  Stream<Map<String, String?>> transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    String accContent = '';
    bool isFinished = false;

    await for (final chunk in stream) {
      final chunkString = utf8.decode(chunk);
      buffer += chunkString;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') continue;

        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final chunk = extractStreamChunk(data);

          // 透传 content / think 到 UI
          if (chunk['content'] != null || chunk['think'] != null) {
            yield {'content': chunk['content'] ?? '', 'think': chunk['think']};
          }

          // 累积正文
          if (chunk['content'] != null && chunk['content']!.isNotEmpty) {
            accContent += chunk['content']!;
          }

          final finishReason = chunk['finish_reason'];
          if (finishReason != null && kDebugMode) {
            debugPrint('🔧 $providerName finish_reason: $finishReason');
          }

          // finish_reason == 'stop': 从累积文本中解析工具调用
          if (finishReason == 'stop' && !isFinished) {
            isFinished = true;
            if (kDebugMode) debugPrint('接收到完整数据 : $accContent');

            if (accContent.isNotEmpty) {
              final textCalls = McpService.parseToolCallsFromResponse(
                accContent,
              );
              if (textCalls.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint(
                    '🔧 finish_reason=stop 从文本中检测到 tool_calls: ${jsonEncode(textCalls)}',
                  );
                }
                yield {'toolcall': jsonEncode(textCalls)};
              } else {
                if (kDebugMode) {
                  debugPrint('🔧 finish_reason=stop 没有检测到工具');
                }
              }
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    final messages = buildMessages(userMessage: userMessage, session: session);
    try {
      final data = await sendOpenAINonStreamRequest(
        messages: messages,
        session: session,
        extra: {
          'response_format': {'type': 'json_object'},
        },
      );
      if (data != null) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          if (message != null && message['content'] != null) {
            return message['content'] as String;
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      throw Exception('错误: ${handleApiError(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    try {
      return {
        'provider': 'deepseek',
        'model': model!.model,
        'name': model!.name,
        'features': getSupportedFeatures(),
        'configured': true,
        'supports_reasoning': model!.model.contains('r1'),
      };
    } catch (e) {
      debugPrint('获取 $providerName 模型信息失败: $e');
      return null;
    }
  }

  /// 重写 SSE chunk 提取以支持 reasoning_content
  @override
  Map<String, String?> extractStreamChunk(Map<String, dynamic> data) {
    final chunk = super.extractStreamChunk(data);
    // 基类已处理 reasoning_content → 'think'，但这里确保非空的空字符串不被 yield
    // （基类 extractStreamChunk 已过滤空值）
    return chunk;
  }
}
