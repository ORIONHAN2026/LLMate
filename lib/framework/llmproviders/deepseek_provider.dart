import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
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
              final parsed = parseToolCalls(accContent);
              final textCalls = parsed['toolCalls'] as List<Map<String, dynamic>>;
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

  // ==================== 工具调用解析（DeepSeek 实现） ====================

  @override
  Map<String, dynamic> parseToolCalls(String response) {
    final toolCalls = <Map<String, dynamic>>[];
    String? inner;

    // 1) <tool_calls> XML
    final xmlMatch = RegExp(
      r'<tool_calls>\s*(.*?)\s*</tool_calls>',
      dotAll: true,
    ).firstMatch(response);
    if (xmlMatch != null) {
      inner = xmlMatch.group(1);
    }

    // 2) <|tool_calls|> DSML
    if (inner == null) {
      final dsmlMatch = RegExp(
        r'<\|\s*tool_calls\s*\|>\s*(.*?)\s*</\|\s*tool_calls\s*\|>',
        dotAll: true,
      ).firstMatch(response);
      if (dsmlMatch != null) {
        inner = dsmlMatch
            .group(1)!
            .replaceAllMapped(
              RegExp(r'<\|\s*(invoke|parameter)\b'),
              (m) => '<${m.group(1)}',
            )
            .replaceAllMapped(
              RegExp(r'</\|\s*(invoke|parameter)\s*\|?\s*>'),
              (m) => '</${m.group(1)}>',
            );
      }
    }

    // 3) 解析 <invoke> 块
    if (inner != null) {
      final invokeRegex = RegExp(
        r'<invoke\s+name="([^"]+)"[^>]*>(.*?)</invoke>',
        dotAll: true,
      );
      for (final im in invokeRegex.allMatches(inner)) {
        try {
          final toolName = im.group(1)?.trim();
          final invokeBody = im.group(2);
          if (toolName == null || invokeBody == null) continue;

          final args = <String, dynamic>{};
          final paramRegex = RegExp(
            r'<parameter\s+name="([^"]+)"\s+(\w+)="[^"]*"[^>]*>([^<]*)</parameter>',
          );
          for (final pm in paramRegex.allMatches(invokeBody)) {
            final name = pm.group(1)?.trim();
            final type = pm.group(2)?.trim();
            final rawValue = pm.group(3)?.trim() ?? '';
            if (name != null && name.isNotEmpty) {
              switch (type) {
                case 'number':
                  args[name] = num.tryParse(rawValue) ?? rawValue;
                case 'boolean':
                  args[name] = rawValue.toLowerCase() == 'true';
                default:
                  args[name] = rawValue;
              }
            }
          }

          toolCalls.add({'name': toolName, 'arguments': args});
          debugPrint('✅ 解析工具调用: $toolName, 参数: $args');
        } catch (e) {
          debugPrint('❌ 解析工具调用失败: ${im.group(0)}, 错误: $e');
        }
      }
    }

    // 4) 剥离标签
    final cleanContent = response
        .replaceAll(RegExp(r'<tool_calls>.*?</tool_calls>', dotAll: true), '')
        .replaceAll(
          RegExp(r'<\|\s*tool_calls\s*\|>.*?</\|\s*tool_calls\s*\|>',
            dotAll: true),
          '',
        )
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    debugPrint('🔍 parseToolCalls: 找到 ${toolCalls.length} 个工具调用');
    return {'toolCalls': toolCalls, 'cleanContent': cleanContent};
  }
}
