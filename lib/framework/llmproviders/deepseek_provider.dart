import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../stream_tool_call_filter.dart';
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
  String buildProviderPrompt() => '''
## 🚨 工具调用规则 — 最高优先级

当你需要使用工具时，必须严格遵守以下格式，**禁止使用 markdown 代码块**（如 ```bash）来执行命令：

<tool_calls>
<invoke name="工具名称">
<arguments>
{"参数名": "参数值"}
</arguments>
</invoke>
</tool_calls>

**关键规则：**
- ✅ 使用 <tool_calls> XML 格式包裹所有工具调用
- ✅ 每个 <invoke> 只调用一个工具
- ✅ 参数必须是标准 JSON 格式，字符串值用双引号
- ❌ 禁止在 markdown 代码块中写 bash 命令
- ❌ 禁止用 ```bash ... ``` 代替工具调用
- ❌ 禁止跳过工具直接输出虚拟结果
- 💡 工具调用失败或结果为空时，等待真实结果，不要编造
''';

  /// DeepSeek 使用文本格式工具调用（system prompt 中注入工具信息），
  /// 不发送 OpenAI 原生 tools/tool_choice 参数，避免与文本格式冲突。
  @override
  Map<String, dynamic> buildRequestData({
    required List<Map<String, dynamic>> messages,
    required bool stream,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) {
    // 调用基类但不传 session，阻止注入 tools/tool_choice
    return super.buildRequestData(
      messages: messages,
      stream: stream,
      extra: extra,
    );
  }

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
  ///
  /// 集成 [StreamToolCallFilter] 流式状态机拦截器，实时拦截工具调用标签，
  /// 避免将 `<tool_calls>`、`<|tool_calls|>`、`<｜｜DSML｜｜tool_calls>` 等标签
  /// 透传到前端 UI。
  @override
  Stream<Map<String, String?>> transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    String accContent = '';
    bool isFinished = false;
    final filter = StreamToolCallFilter();

    await for (final chunk in stream) {
      final chunkString = utf8.decode(chunk);
      buffer += chunkString;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') {
          // 流结束，刷出状态机缓存
          final flushResult = filter.flush();
          if (flushResult.cleanText.isNotEmpty) {
            accContent += flushResult.cleanText;
            yield {'content': flushResult.cleanText};
          }
          continue;
        }

        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final extracted = extractStreamChunk(data);

          // 透传 think 到 UI（思考内容不需要过滤）
          if (extracted['think'] != null && extracted['think']!.isNotEmpty) {
            yield {'content': '', 'think': extracted['think']};
          }

          // 对 content 通过状态机过滤
          final rawContent = extracted['content'] ?? '';
          if (rawContent.isNotEmpty) {
            final filterResult = filter.feed(rawContent);
            final cleanText = filterResult.cleanText;

            // 累积原始内容（用于后续 parseToolCalls 解析）
            accContent += rawContent;

            // 仅放行过滤后的干净文本
            if (cleanText.isNotEmpty) {
              yield {'content': cleanText};
            }

            if (kDebugMode && filterResult.isInToolCall) {
              debugPrint('🎯 [DeepSeek] 状态机拦截: 工具调用标签已扣留');
            }
          }

          final finishReason = extracted['finish_reason'];
          if (finishReason != null && kDebugMode) {
            debugPrint('🔧 $providerName finish_reason: $finishReason');
          }

          // finish_reason == 'stop': 从累积文本中解析工具调用
          if (finishReason == 'stop' && !isFinished) {
            isFinished = true;

            // 刷出状态机残留缓存
            final flushResult = filter.flush();
            if (flushResult.cleanText.isNotEmpty) {
              accContent += flushResult.cleanText;
              yield {'content': flushResult.cleanText};
            }

            if (kDebugMode) debugPrint('接收到完整数据 : $accContent');

            if (accContent.isNotEmpty) {
              final parsed = parseToolCalls(accContent);
              final textCalls =
                  parsed['toolCalls'] as List<Map<String, dynamic>>;
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

    // 流自然结束，刷出状态机缓存
    final flushResult = filter.flush();
    if (flushResult.cleanText.isNotEmpty) {
      accContent += flushResult.cleanText;
      yield {'content': flushResult.cleanText};
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

    // 1) 统一提取 tool_calls 内部的文本
    // 容错匹配：<tool_calls> 或 <|tool_calls|> 或 <｜｜DSML｜｜tool_calls> 及其任意组合的闭合
    final toolCallsRegex = RegExp(
      r'<(?:tool_calls|\||｜|DSML)*>\s*(.*?)\s*</(?:tool_calls|\||｜|DSML)*>',
      dotAll: true,
    );

    final tcMatch = toolCallsRegex.firstMatch(response);
    if (tcMatch != null) {
      inner = tcMatch.group(1);
    }

    // 2) 如果提取到了内部文本，将其中的特殊 invoke 标签统一标准化为标准的 <invoke> 和 <parameter>
    if (inner != null) {
      // 清理不可见的零宽字符和特殊 Unicode 空格（模型输出有时会混入 U+200B 等）
      inner = inner.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u00A0\u2060]'), '');

      inner = inner
          // 将 <｜｜DSML｜｜invoke ...> 或 <| invoke ...> 标准化为 <invoke ...>
          .replaceAllMapped(
            RegExp(
              r'<(?:\||｜|DSML\s*)*(invoke|parameter)\b',
              caseSensitive: false,
            ),
            (m) => '<${m.group(1)}',
          )
          // 将 </｜｜DSML｜｜invoke> 等标准化为 </invoke>
          .replaceAllMapped(
            RegExp(
              r'</(?:\||｜|DSML\s*)*(invoke|parameter)(?:\||｜|DSML\s*)*>',
              caseSensitive: false,
            ),
            (m) => '</${m.group(1)}>',
          );

      // 3) 解析标准化后的 <invoke> 块
      final invokeRegex = RegExp(
        r'<invoke\s+name="([^"]+)"[^>]*>(.*?)</invoke>',
        dotAll: true,
      );

      for (final im in invokeRegex.allMatches(inner)) {
        try {
          final toolName = im.group(1)?.trim();
          var invokeBody = im.group(2)?.trim() ?? '';
          if (toolName == null) continue;

          final args = <String, dynamic>{};

          // 只有当 invokeBody 不为空时才去解析参数
          if (invokeBody.isNotEmpty) {
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
          }

          toolCalls.add({'name': toolName, 'arguments': args});
          print('✅ 解析工具调用: $toolName, 参数: $args');
        } catch (e) {
          print('❌ 解析工具调用失败: ${im.group(0)}, 错误: $e');
        }
      }
    }

    // 4) 剥离所有形式的工具调用标签，保留纯文本
    final cleanContent =
        response
            .replaceAll(
              RegExp(
                r'<(?:tool_calls|\||｜|DSML)*>.*?</(?:tool_calls|\||｜|DSML)*>',
                dotAll: true,
              ),
              '',
            )
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();

    print('🔍 parseToolCalls: 找到 ${toolCalls.length} 个工具调用');
    return {'toolCalls': toolCalls, 'cleanContent': cleanContent};
  }
}
