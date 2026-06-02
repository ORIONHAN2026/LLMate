import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../stream_tool_call_filter.dart';
import 'base_provider.dart';
import 'common/message_builder.dart';

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

  // ── HTTP 客户端 ──

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(milliseconds: BaseLlmProvider.defaultTimeout);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── DeepSeek 特有提示词 ──

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

  // ── 消息构建 ──

  @override
  String buildSystemPrompt(ChatSession? session) {
    return MessageBuilder.buildSystemPrompt(
      model: model,
      session: session,
      providerPrompt: buildProviderPrompt(),
    );
  }

  @override
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    return MessageBuilder.buildMessages(
      userMessage: userMessage,
      model: model!,
      session: session,
      providerPrompt: buildProviderPrompt(),
    );
  }

  // ── 请求体构建（不含 tools/tool_choice） ──

  Map<String, dynamic> buildRequestData({
    required List<Map<String, dynamic>> messages,
    required bool stream,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) {
    final data = <String, dynamic>{
      'model': model!.model,
      'messages': messages,
      'stream': stream,
      'max_tokens': 4000,
      'temperature': 0.7,
    };
    if (extra != null) data.addAll(extra);
    return data;
  }

  Map<String, String> buildAuthHeaders() {
    return {
      'Authorization': 'Bearer ${model!.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  // ── SSE chunk 提取 ──

  Map<String, String?> extractStreamChunk(Map<String, dynamic> data) {
    String? content;
    String? reasoningContent;
    String? toolCall;
    String? finishReason;

    try {
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;
        if (delta != null) {
          content = delta['content'] as String?;
          reasoningContent = delta['reasoning_content'] as String?;
          if (delta['tool_calls'] != null) {
            toolCall = jsonEncode(delta['tool_calls']);
          }
        }
        finishReason = choice['finish_reason'] as String?;
      }
    } catch (_) {}

    final result = {
      if (content != null && content.isNotEmpty) 'content': content,
      if (reasoningContent != null && reasoningContent.isNotEmpty)
        'think': reasoningContent,
      if (toolCall != null && toolCall.isNotEmpty && toolCall != 'null')
        'toolcall': toolCall,
      if (finishReason != null) 'finish_reason': finishReason,
    };
    return result;
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    final messages = buildMessages(userMessage: userMessage, session: session);
    yield* _sendOpenAIStreamRequest(messages: messages, session: session);
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    yield* _sendOpenAIStreamRequest(messages: messages, session: session);
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    final messages = buildMessages(userMessage: userMessage, session: session);
    try {
      final data = await _sendOpenAINonStreamRequest(
        messages: messages,
        session: session,
        extra: {'response_format': {'type': 'json_object'}},
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

  // ── OpenAI 兼容流式请求 ──

  Stream<Map<String, String?>> _sendOpenAIStreamRequest({
    required List<Map<String, dynamic>> messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');

    try {
      final requestData = buildRequestData(
        messages: messages,
        stream: true,
        extra: extra,
      );

      if (kDebugMode) {
        print('$providerName 发送请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)} 请求数据结束');
      }

      final response = await dio.post<ResponseBody>(
        model!.apiUrl!,
        options: Options(
          headers: buildAuthHeaders(),
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _transformStreamResponse(response.data!.stream);
      } else {
        yield {'content': 'API 请求失败：${response.statusCode}', 'think': null};
      }
    } catch (e) {
      if (kDebugMode) print('$providerName 流式响应错误: $e');
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  Future<Map<String, dynamic>?> _sendOpenAINonStreamRequest({
    required List<Map<String, dynamic>> messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async {
    if (model == null) throw StateError('$providerName 提供商未配置');
    try {
      final requestData = buildRequestData(
        messages: messages,
        stream: false,
        extra: extra,
      );
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      rethrow;
    }
  }

  // ── DeepSeek 特有的流处理：累积 content + finish_reason=stop 时解析工具调用 ──

  Stream<Map<String, String?>> _transformStreamResponse(
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
          final flushResult = filter.flush();
          if (flushResult.cleanText.isNotEmpty) {
            accContent += flushResult.cleanText;
            yield {'content': flushResult.cleanText};
          }
          // 兼容某些 API 先发 [DONE] 后发 finish_reason 的情况
          if (!isFinished && accContent.isNotEmpty) {
            isFinished = true;
            final parsed = parseToolCalls(accContent);
            final textCalls = parsed['toolCalls'] as List<Map<String, dynamic>>;
            if (textCalls.isNotEmpty) {
              if (kDebugMode) {
                debugPrint('🔧 [DONE] 从文本中检测到 tool_calls: ${jsonEncode(textCalls)}');
              }
              yield {'toolcall': jsonEncode(textCalls)};
            }
          }
          continue;
        }

        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final extracted = extractStreamChunk(data);

          final nativeToolCall = extracted['toolcall'];
          final hasNativeToolCall = nativeToolCall != null && nativeToolCall.isNotEmpty;
          if (hasNativeToolCall) {
            yield {'toolcall': nativeToolCall};
          }

          if (extracted['think'] != null && extracted['think']!.isNotEmpty) {
            yield {'content': '', 'think': extracted['think']};
          }

          var rawContent = extracted['content'] ?? '';
          if (hasNativeToolCall && rawContent.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('🎯 [DeepSeek] 同 chunk 存在原生 tool_call，丢弃 content 残留: "$rawContent"');
            }
            rawContent = '';
          }
          if (rawContent.isNotEmpty) {
            final filterResult = filter.feed(rawContent);
            final cleanText = filterResult.cleanText;
            accContent += rawContent;
            if (cleanText.isNotEmpty) yield {'content': cleanText};
            for (final transition in filterResult.transitions) {
              switch (transition) {
                case StreamFilterTransition.enteredBuffer:
                  yield {'tool': '⏳ 检测到工具调用标记...'};
                case StreamFilterTransition.confirmedTool:
                  yield {'tool': '🔧 正在接收工具调用参数...'};
                case StreamFilterTransition.bufferCancelled:
                  yield {'tool': '✓ 非工具调用，已恢复正文输出'};
                case StreamFilterTransition.toolClosed:
                  yield {'tool': '✅ 工具调用完成，正在解析...'};
                  break;
              }
            }
          }

          final finishReason = extracted['finish_reason'];
          if (finishReason == 'stop' && !isFinished) {
            isFinished = true;
            final flushResult = filter.flush();
            if (flushResult.cleanText.isNotEmpty) {
              accContent += flushResult.cleanText;
              yield {'content': flushResult.cleanText};
            }
            if (accContent.isNotEmpty) {
              final parsed = parseToolCalls(accContent);
              final textCalls = parsed['toolCalls'] as List<Map<String, dynamic>>;
              if (textCalls.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint('🔧 finish_reason=stop 从文本中检测到 tool_calls: ${jsonEncode(textCalls)}');
                }
                yield {'toolcall': jsonEncode(textCalls)};
              }
            }
            return;
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
    }

    final flushResult = filter.flush();
    if (flushResult.cleanText.isNotEmpty) {
      yield {'content': flushResult.cleanText};
    }
  }

  // ── 工具调用解析（DeepSeek 实现） ──

  @override
  Map<String, dynamic> parseToolCalls(String response) {
    final toolCalls = <Map<String, dynamic>>[];
    String? inner;

    // 1) 尝试匹配外层 <tool_calls> 包装器
    final toolCallsRegex = RegExp(
      r'<(?:tool_calls|\||\uff5c|DSML)*>\s*(.*?)\s*</(?:tool_calls|\||\uff5c|DSML)*>',
      dotAll: true,
    );
    final tcMatch = toolCallsRegex.firstMatch(response);
    if (tcMatch != null) {
      inner = tcMatch.group(1);
      if (kDebugMode) {
        debugPrint('\u{1F4E6} [DeepSeek] 匹配到外层 <tool_calls> 包装器');
      }
    }

    // 2) 如果没有外层包装器，直接在整个 response 中查找 <invoke> 标签
    if (inner == null) {
      // 检查是否有 <invoke 标签（不带外层包装）
      if (RegExp(r'<\s*invoke\b', caseSensitive: false).hasMatch(response)) {
        inner = response;
        if (kDebugMode) {
          debugPrint('\u26A0\uFE0F [DeepSeek] 无外层 <tool_calls> 包装，在整个响应中查找 <invoke>');
        }
      }
    }

    if (inner != null) {
      inner = inner.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u00A0\u2060]'), '');
      inner = inner
          .replaceAllMapped(
            RegExp(r'<(?:\||\uff5c|DSML\s*)*(invoke|parameter)\b', caseSensitive: false),
            (m) => '<${m.group(1)}',
          )
          .replaceAllMapped(
            RegExp(r'</(?:\||\uff5c|DSML\s*)*(invoke|parameter)(?:\||\uff5c|DSML\s*)*>', caseSensitive: false),
            (m) => '</${m.group(1)}>',
          );

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
          if (invokeBody.isNotEmpty) {
            final jsonArgs = MessageBuilder.parseArgumentsJson(invokeBody);
            if (jsonArgs != null) args.addAll(jsonArgs);
            final paramRegex = RegExp(
              r'<parameter\s+name="([^"]+)"\s+(\w+)="[^"]*"[^>]*>(.*?)</parameter>',
              dotAll: true,
            );
            for (final pm in paramRegex.allMatches(invokeBody)) {
              final name = pm.group(1)?.trim();
              final type = pm.group(2)?.trim();
              final rawValue = pm.group(3)?.trim() ?? '';
              if (name != null && name.isNotEmpty) {
                switch (type) {
                  case 'number': args[name] = num.tryParse(rawValue) ?? rawValue;
                  case 'boolean': args[name] = rawValue.toLowerCase() == 'true';
                  default: args[name] = rawValue;
                }
              }
            }
          }
          toolCalls.add({'name': toolName, 'arguments': args});
          if (kDebugMode) {
            debugPrint('\u2705 [DeepSeek] 解析到工具调用: $toolName($args)');
          }
        } catch (_) {}
      }
    }

    if (toolCalls.isEmpty && kDebugMode) {
      debugPrint('\u274C [DeepSeek] parseToolCalls 未找到工具调用, response 长度: ${response.length}');
    }

    final cleanContent = response
        .replaceAll(RegExp(r'<(?:tool_calls|\||\uff5c|DSML)*>.*?</(?:tool_calls|\||\uff5c|DSML)*>', dotAll: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return {'toolCalls': toolCalls, 'cleanContent': cleanContent};
  }

  // ── 验证与错误处理 ──

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;
    if (model!.apiUrl == null || model!.apiUrl!.isEmpty) return false;
    if (model!.apiKey == null || model!.apiKey!.isEmpty) return false;
    if (model!.model.isEmpty) return false;
    return true;
  }

  String handleApiError(dynamic error) {
    final es = error.toString();
    if (es.contains('Dio can\'t establish a new connection after it was closed')) return '连接错误，请重试发送消息';
    if (es.contains('DioException') || es.contains('DioError')) {
      if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时，请检查网络设置';
      if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时，请稍后重试';
      if (es.contains('RESPONSE')) return 'API 请求失败，请检查配置和网络';
      if (es.contains('CONNECTION_ERROR') || es.contains('Connection refused')) return '网络连接被拒绝，请检查网络连接和API地址';
      if (es.contains('Network is unreachable')) return '网络不可达，请检查网络连接';
      return '网络连接错误：请检查网络设置和API配置';
    }
    if (es.contains('401') || es.contains('Unauthorized')) return 'API 密钥无效，请检查密钥配置';
    if (es.contains('403') || es.contains('Forbidden')) return 'API 访问被拒绝，请检查权限设置';
    if (es.contains('404') || es.contains('Not Found')) return 'API 地址不存在，请检查 URL 配置';
    if (es.contains('429') || es.contains('Too Many Requests')) return 'API 调用频率过高，请稍后重试';
    if (es.contains('500') || es.contains('Internal Server Error')) return 'API 服务器内部错误，请稍后重试';
    if (es.contains('SocketException') || es.contains('HandshakeException')) return '网络连接失败，请检查网络设置和证书配置';
    if (es.contains('FormatException') || es.contains('Invalid JSON')) return 'API 响应格式错误，请检查API配置';
    return 'API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'deepseek',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
      'supports_reasoning': model!.model.contains('r1'),
    };
  }
}
