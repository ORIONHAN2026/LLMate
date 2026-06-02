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

  // ── HTTP ──

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(
      milliseconds: BaseLlmProvider.defaultTimeout,
    );
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── 请求构建 ──

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
          if (delta['tool_calls'] != null)
            toolCall = jsonEncode(delta['tool_calls']);
        }
        finishReason = choice['finish_reason'] as String?;
      }
    } catch (_) {}
    return {
      if (content != null && content.isNotEmpty) 'content': content,
      if (thinkEnabled && reasoningContent != null && reasoningContent.isNotEmpty)
        'think': reasoningContent,
      if (toolCall != null && toolCall.isNotEmpty && toolCall != 'null')
        'toolcall': toolCall,
      if (finishReason != null) 'finish_reason': finishReason,
    };
  }

  // ── thinking extra ──

  Map<String, dynamic>? _buildThinkingExtra(ChatSession? session) {
    if (session == null) return null;
    return {'enable_thinking': session.deepThink};
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    yield* _sendOpenAIStreamRequest(
      userMessage: userMessage,
      session: session,
      extra: _buildThinkingExtra(session),
    );
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    yield* _sendOpenAIStreamRequest(
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
    try {
      final data = await _sendOpenAINonStreamRequest(
        userMessage: userMessage,
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
      throw Exception('$providerName API 错误: ${handleApiError(e)}');
    }
  }

  // ── OpenAI 兼容请求 ──

  Stream<Map<String, String?>> _sendOpenAIStreamRequest({
    ChatMessage? userMessage,
    List<Map<String, dynamic>>? messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async* {
    if (model == null) throw StateError('$providerName 提供商未配置');
    try {
      final requestData = buildRequestData(
        userMessage: userMessage,
        messages: messages,
        stream: true,
        session: session,
        extra: extra,
      );
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
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  Future<Map<String, dynamic>?> _sendOpenAINonStreamRequest({
    ChatMessage? userMessage,
    List<Map<String, dynamic>>? messages,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) async {
    if (model == null) throw StateError('$providerName 提供商未配置');
    final requestData = buildRequestData(
      userMessage: userMessage,
      messages: messages,
      stream: false,
      session: session,
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
  }

  // ── Qwen 特有流处理：原生 JSON tool_call delta 合并 + 文本工具调用解析 ──

  Stream<Map<String, String?>> _transformStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    final deltaAccumulator = <int, Map<String, dynamic>>{};
    bool yieldedToolProgress = false;
    final utf8Decoder = const Utf8Decoder();
    List<int> pendingBytes = [];

    await for (final chunk in stream) {
      // 拼接上次残留的半截字节，防止 UTF-8 多字节字符被 chunk 切断
      pendingBytes.addAll(chunk);
      String? chunkString;
      try {
        chunkString = utf8Decoder.convert(pendingBytes);
        pendingBytes.clear();
      } on FormatException {
        for (int i = pendingBytes.length - 1; i > 0; i--) {
          try {
            chunkString = utf8Decoder.convert(pendingBytes.sublist(0, i));
            pendingBytes = pendingBytes.sublist(i);
            break;
          } on FormatException {
            continue;
          }
        }
      }
      if (chunkString == null) continue;
      buffer += chunkString;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.trim().startsWith('data: ')) continue;
        final dataStr = line.trim().substring(6);
        if (dataStr == '[DONE]') continue;

        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          final extracted = extractStreamChunk(data);

          if (extracted['think'] != null && extracted['think']!.isNotEmpty) {
            yield {'think': extracted['think']};
          }

          final rawContent = extracted['content'];
          if (rawContent != null && rawContent.isNotEmpty) {
            yield {'content': rawContent};
          }

          final tc = extracted['toolcall'];
          if (tc != null && tc.isNotEmpty) {
            _accumulateDelta(deltaAccumulator, tc);
            if (!yieldedToolProgress) {
              yieldedToolProgress = true;
              yield {'tool': '🔧 正在接收工具调用参数...'};
            }
          }

          final finishReason = extracted['finish_reason'];

          if (finishReason == 'tool_calls') {
            final merged = _finalizeMergedCalls(deltaAccumulator);
            if (merged.isNotEmpty) {
              if (kDebugMode)
                debugPrint('🎯 [Qwen] 产出原生工具调用: ${jsonEncode(merged)}');
              yield {'toolcall': jsonEncode(merged)};
            }
          }
        } catch (e) {
          if (kDebugMode) print('$providerName JSON 解析错误: $e');
        }
      }
    }
  }

  void _accumulateDelta(
    Map<int, Map<String, dynamic>> accumulator,
    String toolCallsJson,
  ) {
    List<Map<String, dynamic>>? parsed;
    try {
      final decoded = jsonDecode(toolCallsJson);
      if (decoded is List) {
        parsed =
            decoded
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
      final current = accumulator.putIfAbsent(
        index,
        () => {
          'index': index,
          'id': delta['id'],
          'type': delta['type'] ?? 'function',
          'function': {'name': '', 'arguments': ''},
        },
      );
      final deltaId = delta['id'];
      if (deltaId is String && deltaId.isNotEmpty) current['id'] = deltaId;
      if (delta['type'] != null) current['type'] = delta['type'];
      final deltaFunction = delta['function'];
      if (deltaFunction is Map) {
        final curFn = Map<String, dynamic>.from(current['function'] as Map);
        final n = deltaFunction['name'];
        if (n is String && n.isNotEmpty)
          curFn['name'] = '${curFn['name'] ?? ''}$n';
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
        args =
            raw.trim().isEmpty
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
      result.add({'id': cid, 'name': name, 'arguments': args});
    }
    return result;
  }

  static String _concatJsonFragments(String prev, String next) {
    if (prev.isEmpty) return next;
    if (next.isEmpty) return prev;
    if (prev.endsWith('"') &&
        next.startsWith('"') &&
        (prev.length < 2 || prev[prev.length - 2] != '\\')) {
      return '$prev${next.substring(1)}';
    }
    return '$prev$next';
  }

  static Map<String, dynamic> _repairAndParseJson(String raw) {
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

  // ── 工具调用解析 ──



  // ── 验证与错误处理 ──

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

  String handleApiError(dynamic error) {
    final es = error.toString();
    if (es.contains('CONNECT_TIMEOUT')) return '网络连接超时，请检查网络设置';
    if (es.contains('RECEIVE_TIMEOUT')) return 'API 响应超时，请稍后重试';
    if (es.contains('401') || es.contains('Unauthorized')) return 'API 密钥无效';
    if (es.contains('429')) return 'API 调用频率过高';
    if (es.contains('500')) return 'API 服务器内部错误';
    return 'API 错误：$es';
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
