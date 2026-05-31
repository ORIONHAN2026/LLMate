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
    final messages = _provider.buildMessages(
      userMessage: userMessage,
      session: _session,
    );

    // 循环：LLM 返回工具调用后追加结果并重发，直到无工具调用
    while (true) {
      String? toolCallsJson;

      final stream = _provider.sendMessageStreamWithMessages(messages);
      await for (final chunk in stream) {
        if (_cancelled) return;
        final tc = chunk['toolcall'];
        if (tc != null && tc.isNotEmpty) toolCallsJson = tc;

        final c = chunk['content'] ?? '';
        if (c.isNotEmpty) yield {'content': c};

        final t = chunk['think'] ?? '';
        if (t.isNotEmpty) yield {'think': t};
      }

      // 无工具调用或已取消 → 结束
      if (_cancelled || toolCallsJson == null || _session.mcpServer == null) {
        return;
      }

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
        yield {'tool': '执行: ${tc['name']}'};
      }

      final toolResult = await McpService.processAndExecuteToolCalls(
        session: _session,
        accumulatedContent: '',
        nativeToolCallsJson: toolCallsJson,
      );

      if (toolResult == null || _cancelled) {
        if (!_cancelled) {
          yield {'tool': '⚠️ MCP 服务未连接，跳过工具调用'};
        }
        return;
      }

      for (final r in toolResult.executionResults) {
        final name = r['name'] as String;
        final ok = !(r['isError'] == true);
        yield {'tool': ok ? '已完成: $name' : '失败: $name'};
      }

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
  ) => _provider.sendMessageStreamWithMessages(messages);

  void cancel() => _cancelled = true;
}
