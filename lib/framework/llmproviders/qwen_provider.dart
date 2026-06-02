import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../stream_tool_call_filter.dart';
import 'base_provider.dart';

/// 阿里云百炼 API 提供商
class QwenProvider extends BaseLlmProvider {
  @override
  String get providerName => '阿里云百炼';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {}

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    final messages = buildMessages(userMessage: userMessage, session: session);
    yield* sendOpenAIStreamRequest(
      messages: messages,
      session: session,
      extra: _buildThinkingExtra(session),
    );
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    yield* sendOpenAIStreamRequest(
      messages: messages,
      session: session,
      extra: _buildThinkingExtra(session),
    );
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
        extra: _buildThinkingExtra(session),
      );
      if (data != null) {
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final message = choice['message'] as Map<String, dynamic>?;
          if (message != null) return message['content'] as String?;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('$providerName 非流式响应错误: $e');
      throw Exception('$providerName API 错误: ${handleApiError(e)}');
    }
  }

  /// 根据会话的深度思考开关构建 enable_thinking 参数
  /// Qwen 模型默认会进行推理思考，需要显式传递 enable_thinking 来控制
  Map<String, dynamic>? _buildThinkingExtra(ChatSession? session) {
    if (session == null) return null;
    return {'enable_thinking': session.deepThink};
  }

  // ──────────────────── 流式工具调用三角洲合并 ────────────────────

  /// Qwen 可能以两种方式输出工具调用：
  /// 1. 原生 JSON tool_call delta（流式增量，finish_reason=tool_calls）
  /// 2. 文本 `<tool_calls>` XML（嵌入 content 流中）
  ///
  /// 本方法在 provider 层统一处理两种格式，产出完整工具调用。
  @override
  Stream<Map<String, String?>> transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    final deltaAccumulator = <int, Map<String, dynamic>>{};
    final filter = StreamToolCallFilter();
    String accContent = '';
    bool yieldedToolProgress = false;

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
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

          // ── think 直接透传 ──
          if (extracted['think'] != null && extracted['think']!.isNotEmpty) {
            yield {'think': extracted['think']};
          }

          // ── content：经状态机过滤后透传（防止 <tool_calls> 标签泄露到 UI）──
          final rawContent = extracted['content'];
          if (rawContent != null && rawContent.isNotEmpty) {
            accContent += rawContent;
            final filterResult = filter.feed(rawContent);
            if (filterResult.cleanText.isNotEmpty) {
              yield {'content': filterResult.cleanText};
            }
            // 状态变化 → tool 进度通知
            for (final t in filterResult.transitions) {
              switch (t) {
                case StreamFilterTransition.enteredBuffer:
                  yield {'tool': '⏳ 检测到工具调用标记...'};
                case StreamFilterTransition.confirmedTool:
                  yield {'tool': '🔧 正在接收工具调用参数...'};
                  yieldedToolProgress = true;
                case StreamFilterTransition.toolClosed:
                case StreamFilterTransition.bufferCancelled:
                  break;
              }
            }
          }

          // ── 原生 JSON tool_call delta 累积 ──
          final tc = extracted['toolcall'];
          if (tc != null && tc.isNotEmpty) {
            _accumulateDelta(deltaAccumulator, tc);
            if (!yieldedToolProgress) {
              yieldedToolProgress = true;
              yield {'tool': '🔧 正在接收工具调用参数...'};
            }
          }

          final finishReason = extracted['finish_reason'];

          // finish_reason == 'tool_calls' → 产出原生 JSON 工具调用
          if (finishReason == 'tool_calls') {
            final merged = _finalizeMergedCalls(deltaAccumulator);
            if (merged.isNotEmpty) {
              if (kDebugMode) {
                debugPrint(
                  '🎯 [Qwen] 产出原生工具调用: ${jsonEncode(merged)}',
                );
              }
              yield {'toolcall': jsonEncode(merged)};
            }
          }

          // finish_reason == 'stop' → 检查文本 <tool_calls>（仅在无原生调用时）
          if (finishReason == 'stop' && deltaAccumulator.isEmpty) {
            // 刷出状态机缓存
            final flushResult = filter.flush();
            if (flushResult.cleanText.isNotEmpty) {
              accContent += flushResult.cleanText;
              yield {'content': flushResult.cleanText};
            }
            // 从累积 content 中解析文本工具调用
            if (accContent.contains('<tool_calls') ||
                accContent.contains('<|tool_calls') ||
                accContent.contains('<｜｜DSML｜｜tool_calls')) {
              final parsed = _parseTextToolCalls(accContent);
              final textCalls =
                  parsed['toolCalls'] as List<Map<String, dynamic>>;
              if (textCalls.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint(
                    '🎯 [Qwen] 从文本中解析到工具调用: ${jsonEncode(textCalls)}',
                  );
                }
                yield {'toolcall': jsonEncode(textCalls)};
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
    }

    // 流自然结束，刷出缓存
    final flushResult = filter.flush();
    if (flushResult.cleanText.isNotEmpty) {
      accContent += flushResult.cleanText;
      yield {'content': flushResult.cleanText};
    }
  }

  /// 将单个 chunk 中的 tool_call delta 累积进 accumulator
  void _accumulateDelta(
    Map<int, Map<String, dynamic>> accumulator,
    String toolCallsJson,
  ) {
    List<Map<String, dynamic>>? parsed;
    try {
      final decoded = jsonDecode(toolCallsJson);
      if (decoded is List) {
        parsed = decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (decoded is Map) {
        parsed = [Map<String, dynamic>.from(decoded)];
      }
    } catch (_) {
      return;
    }
    if (parsed == null) return;

    for (int i = 0; i < parsed.length; i++) {
      final delta = parsed[i];
      final index = (delta['index'] as int?) ?? i;
      final current = accumulator.putIfAbsent(index, () {
        return {
          'index': index,
          'id': delta['id'],
          'type': delta['type'] ?? 'function',
          'function': {'name': '', 'arguments': ''},
        };
      });

      // 只在 id 非空时更新，避免后续空字符串覆盖
      final deltaId = delta['id'];
      if (deltaId is String && deltaId.isNotEmpty) current['id'] = deltaId;
      if (delta['type'] != null) current['type'] = delta['type'];

      final deltaFunction = delta['function'];
      if (deltaFunction is Map) {
        final curFn = Map<String, dynamic>.from(current['function'] as Map);
        // name
        final n = deltaFunction['name'];
        if (n is String && n.isNotEmpty) {
          curFn['name'] = '${curFn['name'] ?? ''}$n';
        }
        // arguments：智能拼接，修复 JSON 片段跨 chunk 边界产生的相邻引号
        final a = deltaFunction['arguments'];
        if (a is String && a.isNotEmpty) {
          curFn['arguments'] = _concatJsonFragments(
            curFn['arguments'] as String? ?? '',
            a,
          );
        }
        current['function'] = curFn;
      }
    }
  }

  /// 将所有累积的 delta 合并为最终的完整工具调用列表
  List<Map<String, dynamic>> _finalizeMergedCalls(
    Map<int, Map<String, dynamic>> accumulator,
  ) {
    final keys = accumulator.keys.toList()..sort();
    final result = <Map<String, dynamic>>[];

    for (final k in keys) {
      final call = accumulator[k]!;
      final fn = call['function'];
      if (fn is! Map) continue;

      final name = (fn['name'] ?? '').toString();
      if (name.isEmpty) continue;

      final raw = (fn['arguments'] ?? '{}').toString();
      Map<String, dynamic> args;
      try {
        args = raw.trim().isEmpty
            ? <String, dynamic>{}
            : (jsonDecode(raw) is Map
                ? Map<String, dynamic>.from(jsonDecode(raw))
                : <String, dynamic>{'value': jsonDecode(raw)});
      } catch (_) {
        args = _repairAndParseJson(raw);
      }

      final cid =
          (call['id'] is String && (call['id'] as String).isNotEmpty)
              ? call['id'] as String
              : 'call_$k';

      // 注意：不要输出 'index' / 'function' / 'type' 等字段。
      // LlmHub 靠这些 key 来区分"流式 delta"和"完整工具调用"；
      // 完整调用只需 id、name、arguments。
      result.add({
        'id': cid,
        'name': name,
        'arguments': args,
      });
    }
    return result;
  }

  // ──────────────────── 文本格式工具调用解析 ────────────────────

  /// 从 content 文本中解析 `<tool_calls>` XML 格式的工具调用。
  ///
  /// 兼容多种变体：
  /// - `<tool_calls>`, `<|tool_calls|>`, `<｜｜DSML｜｜tool_calls>`
  /// - `<invoke name="xxx">`, `<invoke function="xxx">`
  /// - `<parameter name="xxx">val</parameter>`, `<parameter=xxx>val</parameter>`
  /// - `<arguments>JSON</arguments>`
  /// - 各种闭合标签错配（`</function>`, `</invoke>` 等）
  Map<String, dynamic> _parseTextToolCalls(String response) {
    final toolCalls = <Map<String, dynamic>>[];
    String? inner;

    // 1) 提取 tool_calls 标签内的文本
    final toolCallsRegex = RegExp(
      r'<(?:tool_calls|\||｜|DSML)*>\s*(.*?)\s*</(?:tool_calls|\||｜|DSML)*>',
      dotAll: true,
    );
    final tcMatch = toolCallsRegex.firstMatch(response);
    if (tcMatch != null) inner = tcMatch.group(1);

    if (inner == null) {
      return {'toolCalls': <Map<String, dynamic>>[], 'cleanContent': response};
    }

    // 2) 清理零宽字符，标准化标签
    inner = inner.replaceAll(
      RegExp(r'[\u200B-\u200F\uFEFF\u00A0\u2060]'),
      '',
    );

    // 标准化 invoke: <｜｜DSML｜｜invoke> / <|invoke> → <invoke>
    inner = inner.replaceAllMapped(
      RegExp(r'<(?:\||｜|DSML\s*)*(invoke|function)\b', caseSensitive: false),
      (m) => '<invoke',
    );
    // 标准化 parameter: <｜｜DSML｜｜parameter> / <|parameter> → <parameter>
    inner = inner.replaceAllMapped(
      RegExp(r'<(?:\||｜|DSML\s*)*parameter\b', caseSensitive: false),
      (m) => '<parameter',
    );
    // 标准化闭合 invoke/function
    inner = inner.replaceAllMapped(
      RegExp(
        r'</(?:\||｜|DSML\s*)*(invoke|function)(?:\||｜|DSML\s*)*>',
        caseSensitive: false,
      ),
      (m) => '</invoke>',
    );
    // 标准化闭合 parameter
    inner = inner.replaceAllMapped(
      RegExp(
        r'</(?:\||｜|DSML\s*)*parameter(?:\||｜|DSML\s*)*>',
        caseSensitive: false,
      ),
      (m) => '</parameter>',
    );

    // 3) 修复内联参数格式 <parameter=xxx>val</parameter> → <parameter name="xxx">val</parameter>
    inner = inner.replaceAllMapped(
      RegExp(r'<parameter=(\S+?)(\s*)>'),
      (m) => '<parameter name="${m.group(1)}">',
    );

    // 4) 提取所有 <invoke> 块
    final invokeRegex = RegExp(
      r'<invoke\s+name="([^"]+)"[^>]*>(.*?)</invoke>',
      dotAll: true,
    );

    for (final im in invokeRegex.allMatches(inner)) {
      try {
        final toolName = im.group(1)?.trim();
        final invokeBody = im.group(2)?.trim() ?? '';
        if (toolName == null) continue;

        final args = <String, dynamic>{};

        if (invokeBody.isNotEmpty) {
          // 4a) 先尝试 <arguments>JSON</arguments>
          final jsonArgs = _parseArgumentsJsonBlock(invokeBody);
          if (jsonArgs != null) {
            args.addAll(jsonArgs);
          }

          // 4b) 解析 <parameter name="xxx">val</parameter>
          final paramRegex = RegExp(
            r'<parameter\s+name="([^"]+)"[^>]*>(.*?)</parameter>',
            dotAll: true,
          );
          for (final pm in paramRegex.allMatches(invokeBody)) {
            final name = pm.group(1)?.trim();
            final rawValue = pm.group(2)?.trim() ?? '';
            if (name != null && name.isNotEmpty) {
              args[name] = rawValue;
            }
          }
        }

        toolCalls.add({'name': toolName, 'arguments': args});
        print('✅ [Qwen文本格式] 解析工具调用: $toolName, 参数: $args');
      } catch (e) {
        print('❌ [Qwen文本格式] 解析工具调用失败: ${im.group(0)}, 错误: $e');
      }
    }

    // 5) 剥离工具调用标签，保留纯文本
    final cleanContent = response
        .replaceAll(
          RegExp(
            r'<(?:tool_calls|\||｜|DSML)*>.*?</(?:tool_calls|\||｜|DSML)*>',
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    print('🔍 [Qwen] parseTextToolCalls: 找到 ${toolCalls.length} 个工具调用');
    return {'toolCalls': toolCalls, 'cleanContent': cleanContent};
  }

  // ──────────────────── JSON 片段拼接修复 ────────────────────

  /// 解析 <arguments> JSON
  static Map<String, dynamic>? _parseArgumentsJsonBlock(String invokeBody) {
    final match = RegExp(
      r'<arguments>\s*(.*?)\s*</arguments>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(invokeBody);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 解析 <arguments> JSON 失败: $e, raw=$raw');
      }
    }
    return null;
  }

  /// 拼接两个 JSON arguments 片段，修复流式传输中跨 chunk 边界
  /// 产生的相邻双引号问题（如 `{"title": "` + `"苏州` → `{"title": ""苏州`）。
  static String _concatJsonFragments(String prev, String next) {
    if (prev.isEmpty) return next;
    if (next.isEmpty) return prev;
    // prev 以 " 结尾且非转义，next 以 " 开头 → 去掉 next 首字符
    if (prev.endsWith('"') &&
        next.startsWith('"') &&
        (prev.length < 2 || prev[prev.length - 2] != '\\')) {
      return '$prev${next.substring(1)}';
    }
    return '$prev$next';
  }

  /// 尝试修复常见的流式 JSON 拼接错误
  static Map<String, dynamic> _repairAndParseJson(String raw) {
    // 策略：修复 `": ""xxx"` → `": "xxx"`（空对象后紧跟值导致的空引号）
    String s = raw.replaceAllMapped(
      RegExp(r'":\s*""([^",}\]]+)'),
      (m) => '": "${m.group(1)}',
    );
    try {
      return Map<String, dynamic>.from(jsonDecode(s));
    } catch (_) {
      return {'_raw': raw};
    }
  }

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;
    try {
      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: buildAuthHeaders()),
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
      debugPrint('$providerName 配置验证失败: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;
    return {
      'provider': 'qwen',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }
}
