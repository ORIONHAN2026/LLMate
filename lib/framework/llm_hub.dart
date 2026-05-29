import 'dart:async';
import 'dart:convert';
import 'package:mcp_client/mcp_client.dart' hide MessageRole;
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
  Stream<Map<String, dynamic>> sendMessageStream(ChatMessage userMessage) async* {
    _cancelled = false;

    // 1. 首轮流式响应
    String acc = '';
    String? toolCallsJson;
    final stream = _provider.sendMessageStream(
      userMessage: userMessage,
      session: _session,
    );

    await for (final chunk in stream) {
      if (_cancelled) break;
      final tc = chunk['mcpToolCalls'];
      if (tc != null && tc.isNotEmpty) toolCallsJson = tc;
      final c = chunk['content'] ?? '';
      if (c.isNotEmpty) acc += c;
      yield Map<String, dynamic>.from(chunk);
    }

    // 2. 执行 MCP 工具调用 + follow-up
    if (!_cancelled && _session.mcpServer != null) {
      _McpToolResults? results;

      if (toolCallsJson != null) {
        // 原生 tool_calls
        results = await _executeMcpToolsAndYield(toolCallsJson);
      } else {
        // 回退：文本格式 tool_calls（如 <tool_call>...</tool_call>）
        final textCalls = McpService.parseToolCallsFromResponse(acc);
        if (textCalls.isNotEmpty) {
          // 从累积内容中移除原始 tool_call 文本，避免展示到 UI
          acc = _stripTextToolCalls(acc);
          // 告知 UI 开始执行
          for (final tc in textCalls) {
            yield {'tool': '执行: ${tc['tool']}'};
          }
          // 执行工具调用
          final execResults = await McpService.executeSessionToolCalls(
            session: _session,
            toolCalls: textCalls,
          );
          // 转换为统一格式供 follow-up 使用
          final list = <Map<String, dynamic>>[];
          final data = <Map<String, dynamic>>[];
          for (int i = 0; i < textCalls.length; i++) {
            final tc = textCalls[i];
            final callId = 'call_$i';
            list.add({
              'id': callId,
              'name': tc['tool'],
              'arguments': tc['args'],
              'index': i,
            });
            final tr = i < execResults.length ? execResults[i] : null;
            data.add({
              'id': callId,
              'name': tc['tool'],
              'args': tc['args'],
              'result': tr?.result ?? '',
              'isError': tr?.isSuccess != true,
            });
          }
          results = _McpToolResults(list: list, data: data);
        }
      }

      if (results == null || _cancelled) return;

      // 向 UI 透传工具执行描述（和 content/think 同级）
      for (final r in results.data) {
        final name = r['name'] as String;
        final ok = !(r['isError'] == true);
        yield {'tool': ok ? '已完成: $name' : '失败: $name'};
      }

      // 构建 follow-up 消息
      final msgs = _buildFollowUpMessages(
        list: results.list,
        results: results.data,
        userMsg: userMessage,
        assistantContent: acc,
      );

      // 3. follow-up 流式响应
      final s2 = _provider.sendMessageStreamWithMessages(msgs);
      await for (final chunk in s2) {
        if (_cancelled) break;
        yield Map<String, dynamic>.from(chunk);
      }
    }
  }

  // ── 内部: sendMessageStream 专用 ──

  /// 执行 MCP 工具调用并通过回调通知，返回解析结果
  Future<_McpToolResults?> _executeMcpToolsAndYield(
    String toolCallsJson,
  ) async {
    final List<dynamic> list;
    try {
      list = jsonDecode(toolCallsJson);
    } catch (e) {
      onError?.call('解析 tool_calls 失败: $e');
      return null;
    }
    if (list.isEmpty) return null;

    final svc = _session.mcpServer?.name;
    if (svc == null) return null;

    Client? mc = McpService.getMCPClient(svc);
    if (mc == null) {
      final inited = await McpService.initializeSessionMcpServices(_session);
      if (inited.isEmpty) {
        onError?.call('MCP 未初始化: $svc');
        return null;
      }
      mc = McpService.getMCPClient(svc);
    }
    if (mc == null) return null;

    final results = <Map<String, dynamic>>[];
    for (final raw in list) {
      if (_cancelled) break;
      final t = raw as Map<String, dynamic>;
      final name = t['name'] as String? ?? '';
      final args = t['arguments'] as Map<String, dynamic>? ?? {};
      if (name.isEmpty) continue;

      onToolCall?.call(name, args);
      try {
        final r = await mc.callTool(name, args);
        final ok = r.isError != true;
        final buf = StringBuffer();
        for (final c in r.content) {
          if (c is TextContent) {
            buf.writeln(c.text);
          } else if (c is ImageContent) {
            buf.writeln('[图片: ${c.data ?? c.url}]');
          }
        }
        final text = buf.toString().trim();
        onToolResult?.call(name, ok, text);
        results.add({
          'id': t['id'] ?? 'call_${t['index'] ?? 0}',
          'name': name,
          'args': args,
          'result': text,
          'isError': !ok,
        });
      } catch (e) {
        onToolResult?.call(name, false, '$e');
        results.add({
          'id': t['id'] ?? 'call_${t['index'] ?? 0}',
          'name': name,
          'args': args,
          'result': '$e',
          'isError': true,
        });
      }
    }
    if (results.isEmpty) return null;

    return _McpToolResults(list: list, data: results);
  }

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
        'content':
            r['isError'] == true ? '错误: ${r['result']}' : r['result'],
      });
    }
    return msgs;
  }

  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) =>
      _provider.sendMessageStreamWithMessages(messages);

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
        final tc = chunk['mcpToolCalls'];
        if (tc != null && tc.isNotEmpty) toolCallsJson = tc;
        if (c.isNotEmpty) {
          acc += c;
          onText?.call(c);
        }
        if (t.isNotEmpty) onThink?.call(t);
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
    final List<dynamic> list;
    try {
      list = jsonDecode(toolCallsJson);
    } catch (e) {
      onError?.call('解析 tool_calls 失败: $e');
      return;
    }
    if (list.isEmpty) return;

    final svc = _session.mcpServer?.name;
    if (svc == null) return;

    Client? mc = McpService.getMCPClient(svc);
    if (mc == null) {
      final inited = await McpService.initializeSessionMcpServices(_session);
      if (inited.isEmpty) {
        onError?.call('MCP 未初始化: $svc');
        return;
      }
      mc = McpService.getMCPClient(svc);
    }
    if (mc == null) return;

    // 执行
    final results = <Map<String, dynamic>>[];
    for (final raw in list) {
      if (_cancelled) break;
      final t = raw as Map<String, dynamic>;
      final name = t['name'] as String? ?? '';
      final args = t['arguments'] as Map<String, dynamic>? ?? {};
      if (name.isEmpty) continue;

      onToolCall?.call(name, args);
      try {
        final r = await mc.callTool(name, args);
        final ok = r.isError != true;
        final buf = StringBuffer();
        for (final c in r.content) {
          if (c is TextContent) {
            buf.writeln(c.text);
          } else if (c is ImageContent) {
            buf.writeln('[图片: ${c.data ?? c.url}]');
          }
        }
        final text = buf.toString().trim();
        onToolResult?.call(name, ok, text);
        results.add({
          'id': t['id'] ?? 'call_${t['index'] ?? 0}',
          'result': text,
          'isError': !ok,
        });
      } catch (e) {
        onToolResult?.call(name, false, '$e');
        results.add({
          'id': t['id'] ?? 'call_${t['index'] ?? 0}',
          'result': '$e',
          'isError': true,
        });
      }
    }
    if (results.isEmpty || _cancelled) return;

    // 组装 follow-up 消息
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

    // follow-up 流式
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

/// MCP 工具调用执行结果
class _McpToolResults {
  final List<dynamic> list;
  final List<Map<String, dynamic>> data;
  const _McpToolResults({required this.list, required this.data});
}
