import 'dart:async';
import 'dart:convert';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_message.dart';
import '../services/mcp_service.dart';
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

  // ── 回调 ──

  void Function(String text)? onText;
  void Function(String think)? onThink;
  void Function(String toolName, Map<String, dynamic> args)? onToolCall;
  void Function(String toolName, bool success, String result)? onToolResult;
  void Function(String error)? onError;
  void Function()? onDone;

  // ── 构造 ──

  LlmClient(ChatSession session)
    : _session = session,
      _provider = LlmHub._resolve(session.chatModel!) {
    _provider.configure(session.chatModel!);
  }

  ChatModel? get model => _session.chatModel;

  void dispose() {}

  void configure(ChatModel model) => _provider.configure(model);

  Future<bool> validateConfiguration() => _provider.validateConfiguration();

  String buildSystemPrompt({String? customPrompt, ChatSession? session}) =>
      _provider.buildSystemPrompt(customPrompt: customPrompt, session: session);

  /// 发送消息并获取流式响应（递归处理 MCP 工具调用，直到无工具调用为止）
  /// chunk: {content,think,tool}  三个字段互斥，每次必有一个有值
  Stream<Map<String, dynamic>> sendMessageStream(
    ChatMessage userMessage,
  ) async* {
    _cancelled = false;

    // 构建初始消息列表
    final messages = <Map<String, dynamic>>[];
    final sp = _provider.buildSystemPrompt(session: _session);
    if (sp.isNotEmpty) messages.add({'role': 'system', 'content': sp});
    messages.add({'role': 'user', 'content': userMessage.content});

    yield* _sendWithToolLoop(messages);
  }

  /// 发送消息 + 递归处理工具调用
  /// [messages] 会随每次工具调用追加 assistant + tool 消息，递归传递
  Stream<Map<String, dynamic>> _sendWithToolLoop(
    List<Map<String, dynamic>> messages,
  ) async* {
    String? toolCallsJson;

    final stream = _provider.sendMessageStreamWithMessages(messages);

    await for (final chunk in stream) {
      if (_cancelled) break;
      final tc = chunk['toolcall'];
      if (tc != null && tc.isNotEmpty) toolCallsJson = tc;

      final c = chunk['content'] ?? '';
      if (c.isNotEmpty) yield {'content': c};

      final t = chunk['think'] ?? '';
      if (t.isNotEmpty) yield {'think': t};
    }

    // 有工具调用且未取消 → 执行工具，追加到 messages 后递归
    if (!_cancelled && toolCallsJson != null && _session.mcpServer != null) {
      List<Map<String, dynamic>> parsed;
      try {
        parsed =
            (jsonDecode(toolCallsJson) as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
      } catch (_) {
        return;
      }

      for (final tc in parsed) {
        yield {'tool': '执行: ${tc['tool']}'};
      }

      final toolResult = await McpService.processAndExecuteToolCalls(
        session: _session,
        accumulatedContent: '',
        nativeToolCallsJson: toolCallsJson,
      );

      if (toolResult != null && !_cancelled) {
        for (final r in toolResult.executionResults) {
          final name = r['name'] as String;
          final ok = !(r['isError'] == true);
          yield {'tool': ok ? '已完成: $name' : '失败: $name'};
        }

        // 追加 assistant(tool_calls) 消息
        messages.add({
          'role': 'assistant',
          'content':
              toolResult.cleanContent.isNotEmpty
                  ? toolResult.cleanContent
                  : null,
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
            'content':
                r['isError'] == true ? '错误: ${r['result']}' : r['result'],
          });
        }

        // 递归：大模型可能再次返回工具调用
        yield* _sendWithToolLoop(messages);
      }
    }
  }

  // ── 内部: sendMessageStream / send 共用 ──

  /// 构建 MCP 工具调用的 follow-up 消息列表
  List<Map<String, dynamic>> _buildFollowUpMessages({
    required List<dynamic> list,
    required List<Map<String, dynamic>> results,
    required ChatMessage userMsg,
    required String assistantContent,
  }) {
    final msgs = <Map<String, dynamic>>[];
    final sp = _provider.buildSystemPrompt(session: _session);
    if (sp.isNotEmpty) msgs.add({'role': 'system', 'content': sp});
    msgs.add({'role': 'user', 'content': userMsg.content});
    msgs.add({
      'role': 'assistant',
      'content': assistantContent.isNotEmpty ? assistantContent : null,
      'tool_calls':
          list.map((tc) {
            final m = tc as Map<String, dynamic>;
            return {
              'id': m['id'] ?? 'call_${m['index'] ?? 0}',
              'type': 'function',
              'function': {
                'name': m['name'] ?? '',
                'arguments':
                    m['arguments'] is String
                        ? m['arguments']
                        : jsonEncode(m['arguments'] ?? {}),
              },
            };
          }).toList(),
    });
    for (final r in results) {
      msgs.add({
        'role': 'tool',
        'tool_call_id': r['id'],
        'content': r['isError'] == true ? '错误: ${r['result']}' : r['result'],
      });
    }
    return msgs;
  }

  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) => _provider.sendMessageStreamWithMessages(messages);

  // ── 高级 API ──

  void cancel() => _cancelled = true;

  /// 发送消息，自动处理工具调用 + follow-up
  Future<void> send(String userText) async {
    _cancelled = false;
    try {
      // 1. 组装用户消息
      final userMsg = ChatMessage(
        msgId: '${DateTime.now().millisecondsSinceEpoch}_user',
        role: MessageRole.user,
        content: userText,
        timestamp: DateTime.now(),
        sessionId: _session.sessionId,
      );

      // 2. 发送流式请求 (provider 内部组装 tools)
      final stream = _provider.sendMessageStream(
        userMessage: userMsg,
        session: _session,
      );

      // 3. 监听流式响应
      String acc = '';
      String? toolCallsJson;
      await for (final chunk in stream) {
        if (_cancelled) break;
        final c = chunk['content'] ?? '';
        final t = chunk['think'] ?? '';
        final tc = chunk['toolcall'];
        if (tc != null && tc.isNotEmpty) toolCallsJson = tc;
        if (c.isNotEmpty) {
          acc += c;
          onText?.call(c);
        }
        if (t.isNotEmpty) onThink?.call(t);
        final cf = chunk['content_finish'];
        if (cf != null && cf.isNotEmpty) {
          acc = cf;
        }
      }

      // 4. 工具调用
      if (!_cancelled && toolCallsJson != null && _session.mcpServer != null) {
        await _toolsAndFollowUp(toolCallsJson, userMsg, acc);
      }
    } catch (e) {
      onError?.call('$e');
    } finally {
      onDone?.call();
    }
  }

  // ── 内部: 工具执行 + follow-up ──

  Future<void> _toolsAndFollowUp(
    String toolCallsJson,
    ChatMessage userMsg,
    String assistantContent,
  ) async {
    final result = await McpService.processAndExecuteToolCalls(
      session: _session,
      accumulatedContent: assistantContent,
      nativeToolCallsJson: toolCallsJson,
    );

    if (result == null || _cancelled) return;

    // 通过回调通知
    for (final r in result.executionResults) {
      final name = r['name'] as String;
      final ok = !(r['isError'] == true);
      onToolResult?.call(name, ok, r['result'] as String);
    }

    // 组装 follow-up 消息并流式输出
    final msgs = _buildFollowUpMessages(
      list: result.toolCallList,
      results: result.executionResults,
      userMsg: userMsg,
      assistantContent: result.cleanContent,
    );

    final s2 = _provider.sendMessageStreamWithMessages(msgs);
    await for (final chunk in s2) {
      if (_cancelled) break;
      final c = chunk['content'] ?? '';
      final t = chunk['think'] ?? '';
      if (c.isNotEmpty) onText?.call(c);
      if (t.isNotEmpty) onThink?.call(t);
    }
  }
}
