import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_message.dart';
import '../services/tool_execution_service.dart';
import 'llmproviders/base_provider.dart';
import 'llmproviders/openai_provider.dart';
import 'llmproviders/deepseek_provider.dart';
import 'llmproviders/anthropic_provider.dart';
import 'llmproviders/modelscope_provider.dart';
import 'llmproviders/gemini_provider.dart';
import 'llmproviders/qwen_provider.dart';
import 'llmproviders/zhipu_provider.dart';
import 'llmproviders/ollama_provider.dart';

/// LLM Hub - provider 注册中心
class LlmHub {
  final Map<String, BaseLlmProvider> _providers = {};

  LlmHub._internal() {
    _initializeProviders();
  }
  static final LlmHub _instance = LlmHub._internal();
  static LlmHub get instance => _instance;
  factory LlmHub() => _instance;

  void _initializeProviders() {
    _providers['openai'] = OpenAiProvider();
    _providers['deepseek'] = DeepSeekProvider();
    _providers['anthropic'] = AnthropicProvider();
    _providers['modelscope'] = ModelScopeProvider();
    _providers['gemini'] = GeminiProvider();
    _providers['qwen'] = QwenProvider();
    _providers['zhipu'] = ZhipuProvider();
    _providers['ollama'] = OllamaProvider();
  }

  /// 解析 provider
  static BaseLlmProvider _resolve(ChatModel model) {
    final p = instance._providers[model.provider];
    if (p == null) throw UnsupportedError('不支持的提供商: ${model.provider}');
    return p;
  }

  /// 创建并配置 provider（用于直接调用 provider API 的场景）
  static BaseLlmProvider createProvider(ChatModel model) {
    final p = _resolve(model);
    p.configure(model);
    return p;
  }
}

class LlmClient {
  final ChatSession _session;
  final BaseLlmProvider _provider;
  bool _cancelled = false;

  // ── 构造 ──

  LlmClient(ChatSession session)
    : _session = session,
      _provider = LlmHub._resolve(session.chatModel!) {
    _provider.configure(session.chatModel!);
    _provider.applySessionSettings(session);
  }

  ChatModel? get model => _session.chatModel;

  void dispose() {}

  void configure(ChatModel model) => _provider.configure(model);

  Future<bool> validateConfiguration() => _provider.validateConfiguration();

  String buildSystemPrompt({ChatSession? session}) =>
      _provider.buildSystemPrompt(session);

  /// 发送消息并获取流式响应（递归处理 MCP 工具调用，直到无工具调用为止）
  /// chunk: {content,think,tool}  三个字段互斥，每次必有一个有值
  // ignore: non_constant_identifier_names
  Stream<Map<String, dynamic>> LLMChat(ChatMessage userMessage) async* {
    _cancelled = false;

    // 使用 buildMessages 构建初始消息列表：
    //   [system 提示词] + [当前会话历史] + [当前用户消息]
    // 每个会话的消息历史完全独立，不会与其他会话混合。
    // MCP 工具调用循环中会在此基础上追加 assistant + tool 消息。
    if (kDebugMode) {
      debugPrint(
        '🧠 [LLMChat] 会话消息数: ${_session.messages.length}, 当前消息ID: ${userMessage.msgId}',
      );
      for (int i = 0; i < _session.messages.length; i++) {
        final m = _session.messages[i];
        final preview =
            m.content.length > 50
                ? '${m.content.substring(0, 50)}...'
                : m.content;
        debugPrint('  [$i] ${m.role.name}: $preview (id: ${m.msgId})');
      }
    }
    final messages = _provider.buildMessages(
      userMessage: userMessage,
      session: _session,
    );
    if (kDebugMode) {
      debugPrint('🧠 [LLMChat] buildMessages 返回 ${messages.length} 条消息');
      for (int i = 0; i < messages.length; i++) {
        final m = messages[i];
        final content = m['content']?.toString() ?? '';
        final preview =
            content.length > 80 ? '${content.substring(0, 80)}...' : content;
        debugPrint('  [$i] ${m['role']}: $preview');
      }
    }

    // 循环：LLM 返回工具调用后追加结果并重发，直到无工具调用或检测到重复调用
    int toolIteration = 0;

    while (true) {
      // 用于累积本轮 assistant 流中的 content 文本，作为工具调用消息的 content。
      String loopAccContent = '';
      final nativeToolCallDeltas = <int, Map<String, dynamic>>{};
      List<Map<String, dynamic>>? completedTextToolCalls;

      final stream = _provider.sendMessageStreamWithMessages(
        messages,
        session: _session,
      );
      await for (final chunk in stream) {
        if (_cancelled) return;
        final tc = chunk['toolcall'];
        if (tc != null && tc.isNotEmpty) {
          // 收到工具调用，通知 UI 显示"正在执行工具"
          yield {'tool': 'true'};
          final parsed = _parseToolCallChunk(tc);
          if (parsed != null && parsed.isNotEmpty) {
            final isNativeDelta = parsed.any(
              (call) =>
                  call.containsKey('function') ||
                  call.containsKey('index') ||
                  call.containsKey('type'),
            );
            if (isNativeDelta) {
              _mergeNativeToolCallDeltas(nativeToolCallDeltas, parsed);
            } else {
              completedTextToolCalls = parsed;
            }
          }
        }

        final c = chunk['content'] ?? '';
        if (c.isNotEmpty) {
          loopAccContent += c;
          if (kDebugMode) debugPrint('📤 [LLMChat] content: $c');
          yield {'content': c};
        }

        final t = chunk['think'] ?? '';
        if (t.isNotEmpty) {
          if (kDebugMode) debugPrint('📤 [LLMChat] think: $t');
          yield {'think': t};
        }
      }

      // 无工具调用或已取消 → 结束
      final parsedCalls =
          completedTextToolCalls ??
          _finalizeNativeToolCalls(nativeToolCallDeltas);

      if (_cancelled || parsedCalls.isEmpty) {
        return;
      }

      toolIteration++;

      final toolNames = parsedCalls.map((c) => c['name'] ?? '?').join(', ');

      if (kDebugMode) {
        debugPrint('🔄 [LLMChat] 工具调用第 $toolIteration 轮: $toolNames');
      }

      // 从累积文本中剥离工具调用标签，得到干净的正文内容
      // 这将作为 assistant 消息的 content 发送给 LLM
      final cleanContent = _stripToolCallTags(loopAccContent);

      // 统一工具执行（MCP 工具 + Skill 内置工具）
      final toolResult = await ToolExecutionService.executeToolCalls(
        session: _session,
        toolCalls: parsedCalls,
        cleanContent: cleanContent,
      );

      if (toolResult == null || _cancelled) {
        return;
      }

      for (int i = 0; i < toolResult.toolCallList.length; i++) {
        final tc = toolResult.toolCallList[i];
        final name = tc['name'] ?? '';
        final args = tc['arguments'];
        final er =
            i < toolResult.executionResults.length
                ? toolResult.executionResults[i]
                : null;
        final ok = !(er?['isError'] == true);
        final resultText = er?['result'] ?? '';

        final buf = StringBuffer();
        buf.writeln('${ok ? '✅' : '❌'} $name');
        buf.writeln();
        buf.writeln('📤 参数:');
        if (args is Map && args.isNotEmpty) {
          for (final e in args.entries) {
            buf.writeln('  ${e.key}: ${e.value}');
          }
        } else {
          buf.writeln('  (无)');
        }
        buf.writeln();
        if (resultText.isNotEmpty) {
          buf.writeln('${ok ? '📥' : '⚠'} 结果:');
          buf.writeln(_linkifyFilePaths(resultText));
        }

        yield {'tool': buf.toString().trim()};
      }

      // 工具执行完毕，通知 UI 隐藏"正在执行工具"
      yield {'tool': 'false'};

      // 追加 assistant(tool_calls) 消息
      messages.add({
        'role': 'assistant',
        'content':
            toolResult.cleanContent.isNotEmpty ? toolResult.cleanContent : null,
        'tool_calls':
            toolResult.toolCallList.map((tc) {
              return {
                'id': tc['id'] ?? 'call_${tc['index'] ?? 0}',
                'type': 'function',
                'function': {
                  'name': tc['name'] ?? '',
                  'arguments':
                      tc['arguments'] is String
                          ? tc['arguments']
                          : jsonEncode(tc['arguments'] ?? {}),
                },
              };
            }).toList(),
      });

      // 追加 tool_result 消息
      for (final r in toolResult.executionResults) {
        messages.add({
          'role': 'tool',
          'tool_call_id': r['id'],
          'content': r['isError'] == true ? '错误: ${r['result']}' : r['result'],
        });
      }
      // 循环继续 → LLM 可能再次返回工具调用
    }
  }

  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) => _provider.sendMessageStreamWithMessages(messages, session: _session);

  void cancel() => _cancelled = true;

  /// 将工具结果 JSON 中的文件路径替换为 Markdown 链接，
  /// 使其在 UI 中可以被点击打开。
  ///
  /// 工具返回的 result 是 JSON 字符串，其中 "path" 或 "filePath" 字段
  /// 包含本地绝对路径，将它们转为 `[文件名](file:///路径)` 格式。
  static String _linkifyFilePaths(String resultText) {
    try {
      final decoded = jsonDecode(resultText);
      if (decoded is! Map) return resultText;

      // 查找文件路径字段
      String? filePath;
      for (final key in ['path', 'filePath', 'outputPath']) {
        if (decoded[key] is String && (decoded[key] as String).isNotEmpty) {
          filePath = decoded[key] as String;
          break;
        }
      }
      if (filePath == null) return resultText;

      // 提取文件名用于链接显示
      final fileName =
          filePath.contains('/')
              ? filePath.substring(filePath.lastIndexOf('/') + 1)
              : filePath;

      // 将路径字段替换为 Markdown 链接
      decoded['path'] = '[$fileName](file://$filePath)';
      if (decoded.containsKey('filePath')) {
        decoded['filePath'] = '[$fileName](file://$filePath)';
      }
      // 同时更新 message 中的路径引用
      if (decoded['message'] is String) {
        decoded['message'] = (decoded['message'] as String).replaceAll(
          filePath,
          '[$fileName](file://$filePath)',
        );
      }

      return jsonEncode(decoded);
    } catch (_) {
      // resultText 不是合法 JSON，尝试直接替换绝对路径
      return _linkifyRawPaths(resultText);
    }
  }

  /// 对非 JSON 文本中的绝对路径进行链接化处理
  static String _linkifyRawPaths(String text) {
    // 匹配 macOS/Linux 绝对路径，排除已在 Markdown 链接 [text](url) 中的
    final pathPattern = RegExp(
      r'(?<![(\[])(\/(?:Users|home|tmp|var|etc|opt|srv)\/[\w./\-_]+)',
    );
    return text.replaceAllMapped(pathPattern, (match) {
      final path = match.group(0)!;
      final fileName =
          path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;
      return '[$fileName](file://$path)';
    });
  }

  /// 从累积文本中剥离工具调用标签，返回干净的正文内容
  /// 支持 XML、管道分隔、DSML 等工具调用标签格式。
  static String _stripToolCallTags(String text) {
    if (text.isEmpty) return text;
    return text
        // 标准 XML: <tool_calls>...</tool_calls>
        .replaceAll(RegExp(r'<tool_calls>.*?</tool_calls>', dotAll: true), '')
        // 管道分隔: <|tool_calls|>...</|tool_calls|>
        .replaceAll(
          RegExp(
            r'<\|\s*tool_calls\s*\|>.*?</\|\s*tool_calls\s*\|>',
            dotAll: true,
          ),
          '',
        )
        // DSML 全角: <｜｜DSML｜｜tool_calls>...</｜｜DSML｜｜tool_calls>
        .replaceAll(
          RegExp(
            r'<[｜\|]\s*DSML\s*[｜\|]\s*tool_calls>.*?</[｜\|]\s*DSML\s*[｜\|]\s*tool_calls>',
            dotAll: true,
          ),
          '',
        )
        // 通用 DSML 格式容错
        .replaceAll(
          RegExp(
            r'<(?:\||｜|DSML\s*)*tool_calls[^>]*>.*?</(?:\||｜|DSML\s*)*tool_calls[^>]*>',
            dotAll: true,
          ),
          '',
        )
        // 清理多余空行
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static List<Map<String, dynamic>>? _parseToolCallChunk(String toolCallsJson) {
    try {
      final decoded = jsonDecode(toolCallsJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (decoded is Map) {
        return [Map<String, dynamic>.from(decoded)];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ 工具调用 JSON 解析失败: $e, raw=$toolCallsJson');
      }
    }
    return null;
  }

  static void _mergeNativeToolCallDeltas(
    Map<int, Map<String, dynamic>> accumulator,
    List<Map<String, dynamic>> deltas,
  ) {
    for (
      int fallbackIndex = 0;
      fallbackIndex < deltas.length;
      fallbackIndex++
    ) {
      final delta = deltas[fallbackIndex];
      final index = (delta['index'] as int?) ?? fallbackIndex;
      final current = accumulator.putIfAbsent(index, () {
        return {
          'index': index,
          'id': delta['id'],
          'type': delta['type'] ?? 'function',
          'function': {'name': '', 'arguments': ''},
        };
      });

      if (delta['id'] != null) current['id'] = delta['id'];
      if (delta['type'] != null) current['type'] = delta['type'];

      final deltaFunction = delta['function'];
      if (deltaFunction is Map) {
        final currentFunction = Map<String, dynamic>.from(
          current['function'] as Map,
        );
        final namePart = deltaFunction['name'];
        if (namePart is String && namePart.isNotEmpty) {
          currentFunction['name'] = '${currentFunction['name'] ?? ''}$namePart';
        }
        final argumentsPart = deltaFunction['arguments'];
        if (argumentsPart is String && argumentsPart.isNotEmpty) {
          currentFunction['arguments'] =
              '${currentFunction['arguments'] ?? ''}$argumentsPart';
        }
        current['function'] = currentFunction;
      }
    }
  }

  static List<Map<String, dynamic>> _finalizeNativeToolCalls(
    Map<int, Map<String, dynamic>> accumulator,
  ) {
    final orderedKeys = accumulator.keys.toList()..sort();
    final result = <Map<String, dynamic>>[];

    for (final key in orderedKeys) {
      final call = accumulator[key]!;
      final function = call['function'];
      if (function is! Map) continue;

      final name = (function['name'] ?? '').toString();
      if (name.isEmpty) continue;

      final rawArguments = (function['arguments'] ?? '{}').toString();
      Map<String, dynamic> arguments;
      try {
        final decoded =
            rawArguments.trim().isEmpty
                ? <String, dynamic>{}
                : jsonDecode(rawArguments);
        arguments =
            decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : <String, dynamic>{'value': decoded};
      } catch (_) {
        arguments = {'_raw': rawArguments};
      }

      result.add({
        'id': call['id'] ?? 'call_$key',
        'index': key,
        'name': name,
        'arguments': arguments,
      });
    }

    return result;
  }
}
