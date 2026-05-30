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

  /// 发送消息并获取流式响应（自动处理 MCP 工具调用 + follow-up）
  /// chunk: {content,think,tool}  三个字段互斥，每次必有一个有值
  /// 工具调用已由 provider 层解析好，此处只负责直接 yield + 执行
  Stream<Map<String, dynamic>> sendMessageStream(
    ChatMessage userMessage,
  ) async* {
    _cancelled = false;

    String? toolCallsJson;

    final stream = _provider.sendMessageStream(
      userMessage: userMessage,
      session: _session,
    );

    await for (final chunk in stream) {
      if (_cancelled) break;

      final tc = chunk['toolcall'];
      if (tc != null && tc.isNotEmpty) toolCallsJson = tc;

      final c = chunk['content'] ?? '';
      if (c.isNotEmpty) {
        yield {'content': c};
      }

      final t = chunk['think'] ?? '';
      if (t.isNotEmpty) yield {'think': t};
    }

    // 工具调用已由 provider 解析好，直接执行
    if (!_cancelled && toolCallsJson != null && _session.mcpServer != null) {
      // yield 执行中状态
      try {
        final parsed = jsonDecode(toolCallsJson) as List;
        for (final tc in parsed) {
          yield {'tool': '执行: ${tc['tool']}'};
        }
      } catch (_) {}

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

        final msgs = _buildFollowUpMessages(
          list: toolResult.toolCallList,
          results: toolResult.executionResults,
          userMsg: userMessage,
          assistantContent: toolResult.cleanContent,
        );

        final s2 = _provider.sendMessageStreamWithMessages(msgs);
        await for (final chunk in s2) {
          if (_cancelled) break;
          yield Map<String, dynamic>.from(chunk);
        }
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
