import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
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

  // ──────────────────── 流式 Native Tool Call Delta 合并 ────────────────────

  /// Qwen 将 tool_calls 以增量 delta 流式返回（每个 chunk 的 arguments 为 JSON 片段）。
  /// 本方法在 provider 层累积并合并所有 delta，在 finish_reason=tool_calls 时
  /// 产出完整的工具调用，避免将碎片 delta 暴露给上层 [LlmClient]。
  @override
  Stream<Map<String, String?>> transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    final deltaAccumulator = <int, Map<String, dynamic>>{};

    bool yieldedToolProgress = false;

    await for (final chunk in stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') continue;

        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final extracted = extractStreamChunk(data);

          // content / think 直接透传
          if (extracted['content'] != null && extracted['content']!.isNotEmpty) {
            yield {'content': extracted['content']};
          }
          if (extracted['think'] != null && extracted['think']!.isNotEmpty) {
            yield {'think': extracted['think']};
          }

          // 累积 tool_call delta，首次向 UI 发送工具调用进度
          final tc = extracted['toolcall'];
          if (tc != null && tc.isNotEmpty) {
            _accumulateDelta(deltaAccumulator, tc);
            if (!yieldedToolProgress) {
              yieldedToolProgress = true;
              yield {'tool': '🔧 正在接收工具调用参数...'};
            }
          }

          // finish_reason == 'tool_calls' → 产出完整工具调用
          if (extracted['finish_reason'] == 'tool_calls') {
            final merged = _finalizeMergedCalls(deltaAccumulator);
            if (merged.isNotEmpty) {
              if (kDebugMode) {
                debugPrint('🎯 [Qwen] 产出合并后的工具调用: ${jsonEncode(merged)}');
              }
              yield {'toolcall': jsonEncode(merged)};
            }
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
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

  // ──────────────────── JSON 片段拼接修复 ────────────────────

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
