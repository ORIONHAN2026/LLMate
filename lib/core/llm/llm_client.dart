import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../tools/tool_execution_service.dart';
import '../../controllers/mcp_controller.dart';
import './openai_provider.dart';
import './common/message_builder.dart';
import './common/system_prompts.dart';
import './modes/mode_utils.dart';

/// LLM 客户端
///
/// 负责协调 OpenAiProvider（网络层）和消息/工具组装。
class LlmClient {
  ChatSession _session;
  final OpenAiProvider _provider;
  bool _cancelled = false;

  LlmClient(ChatSession session)
    : _session = session,
      _provider = OpenAiProvider() {
    _provider.configure(session.chatModel!);
    _provider.applySessionSettings(session);
  }

  ChatModel? get model => _session.chatModel;

  void dispose() {}

  void configure(ChatModel model) => _provider.configure(model);

  Future<bool> validateConfiguration() => _provider.validateConfiguration();

  String buildSystemPrompt({ChatSession? session}) {
    return MessageBuilder.buildSystemPrompt(model: model, session: session);
  }

  /// 发送消息并获取流式响应（递归处理 MCP 工具调用，直到无工具调用为止）
  Stream<Map<String, dynamic>> LLMChat(ChatMessage userMessage) async* {
    _cancelled = false;
    bool doneReceived = false;

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

    var messages = await _buildMessages(
      model: model,
      userMessage: userMessage,
      session: _session,
    );

    final tools = _buildTools(_session);

    final requestSnapshot = List<Map<String, dynamic>>.from(
      messages.map((m) => Map<String, dynamic>.from(m)),
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

    final responseBuffer = StringBuffer();
    final thinkBuffer = StringBuffer();
    final toolCallLog = <Map<String, dynamic>>[];
    String? rawRequestData;

    int toolIteration = 0;

    while (true) {
      String loopAccContent = '';
      final nativeToolCallDeltas = <int, Map<String, dynamic>>{};
      List<Map<String, dynamic>>? completedTextToolCalls;
      final announcedToolNames = <int, String>{};

      final stream = _provider.sendMessageStream(
        messages: messages,
        session: _session,
        tools: tools,
      );
      await for (final chunk in stream) {
        if (_cancelled) return;

        // 捕获原始请求报文（仅第一次迭代）
        if (rawRequestData == null && chunk.containsKey('__requestData')) {
          rawRequestData = chunk['__requestData'];
          continue;
        }

        final tc = chunk['toolcall'];
        if (tc != null && tc.isNotEmpty) {
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
              yield {
                'toolcall': _buildToolCallProgress(parsed, announcedToolNames),
              };
            } else {
              completedTextToolCalls = parsed;
            }
          } else {
            yield {'toolcall': '🔧 正在接收工具调用参数...\n'};
          }
        }

        final c = chunk['content'] ?? '';
        if (c.isNotEmpty) {
          loopAccContent += c;
          responseBuffer.write(c);
          if (kDebugMode) debugPrint('📤 [LLMChat] content: $c');
          yield {'content': c};
        }

        final t = chunk['think'] ?? '';
        if (t.isNotEmpty) {
          thinkBuffer.write(t);
          if (kDebugMode) debugPrint('📤 [LLMChat] think: $t');
          yield {'think': t};
        }

        final done = chunk['done'] ?? '';
        if (done == 'true') {
          doneReceived = true;
        }
      }

      final parsedCalls =
          completedTextToolCalls ??
          _finalizeNativeToolCalls(nativeToolCallDeltas);

      // HTTP API 模式不执行工具调用，直接返回结果
      if (_cancelled || parsedCalls.isEmpty) {
        if (!_cancelled) {
          _writeRequestLog(
            requestMessages: requestSnapshot,
            rawRequestData: rawRequestData,
            responseContent: responseBuffer.toString(),
            responseThink: thinkBuffer.toString(),
            toolCalls: toolCallLog,
            sessionId: _session.sessionId,
            modelName: _session.chatModel?.model ?? 'unknown',
          );
        }
        if (doneReceived) {
          yield {'done': 'true'};
        }
        return;
      }

      toolIteration++;

      final toolNames = parsedCalls.map((c) => c['name'] ?? '?').join(', ');

      if (kDebugMode) {
        debugPrint('🔄 [LLMChat] 工具调用第 $toolIteration 轮: $toolNames');
      }

      final cleanContent = _stripToolCallTags(loopAccContent);

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

        toolCallLog.add({
          'name': name,
          'arguments': args,
          'success': ok,
          'result':
              resultText.length > 2000
                  ? '${resultText.substring(0, 2000)}...(truncated)'
                  : resultText,
        });

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

        yield {'toolcall': buf.toString().trim()};
      }

      yield {'tool': 'false'};

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

      for (final r in toolResult.executionResults) {
        messages.add({
          'role': 'tool',
          'tool_call_id': r['id'],
          'content': r['isError'] == true ? '错误: ${r['result']}' : r['result'],
        });
      }
    }
  }

  void cancel() => _cancelled = true;

  // ======================== 消息和工具构建 ========================

  /// 构建完整的消息列表（系统提示词 + 历史消息 + 用户消息）
  Future<List<Map<String, dynamic>>> _buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    final workDir = getEffectiveWorkDir(session);

    // 1. 通用系统提示词
    messages.addAll(
      buildBaseSystemMessages(
        model: model,
        session: session,
        thinkEnabled: session.deepThink,
        workDir: workDir,
      ),
    );

    // 2. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }

    // 3. 核心规则 + 语言（紧邻用户消息前）
    messages.add({'role': 'system', 'content': CommonSystemPrompts.coreRules});
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(
        Get.locale?.languageCode ?? 'zh',
      ),
    });

    // 4. 用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});

    return messages;
  }

  /// 构建可用的工具列表（MCP）
  List<Map<String, dynamic>> _buildTools(ChatSession? session) {
    return McpController.instance.getTools(session?.mcpServer?.name ?? '');
  }

  // ======================== 请求日志 ========================

  static const _projectRoot = '/Users/orion/Documents/Flutter/llmchat';
  static const _logDir = 'log_request';

  static Future<void> _writeRequestLog({
    required List<Map<String, dynamic>> requestMessages,
    String? rawRequestData,
    required String responseContent,
    String? responseThink,
    List<Map<String, dynamic>>? toolCalls,
    required String sessionId,
    required String modelName,
    List<Map<String, dynamic>>? requestTools,
  }) async {
    try {
      final dir = Directory(p.join(_projectRoot, _logDir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final now = DateTime.now();
      final timestamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_'
          '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final fileName = '${timestamp}_${sessionId.substring(0, 8)}.json';
      final file = File(p.join(dir.path, fileName));

      final logData = <String, dynamic>{
        'timestamp': now.toIso8601String(),
        'sessionId': sessionId,
        'model': modelName,
        if (rawRequestData != null) 'rawRequest': jsonDecode(rawRequestData),
        'request': {
          'messages': requestMessages,
          if (requestTools != null && requestTools.isNotEmpty)
            'tools': requestTools,
        },
        'response': {
          if (responseThink != null && responseThink.isNotEmpty)
            'think': responseThink,
          'content': responseContent,
          if (toolCalls != null && toolCalls.isNotEmpty)
            'tool_calls': toolCalls,
        },
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(logData),
      );
      if (kDebugMode) debugPrint('📝 [RequestLog] 日志已写入: ${file.path}');
    } catch (e) {
      if (kDebugMode) debugPrint('📝 [RequestLog] 写入日志失败: $e');
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  // ==================== 压缩请求 ====================

  // ==================== 工具调用解析 ====================

  static String _linkifyFilePaths(String resultText) {
    try {
      final decoded = jsonDecode(resultText);
      if (decoded is! Map) return resultText;

      String? filePath;
      for (final key in ['path', 'filePath', 'outputPath']) {
        if (decoded[key] is String && (decoded[key] as String).isNotEmpty) {
          filePath = decoded[key] as String;
          break;
        }
      }
      if (filePath == null) return resultText;

      final fileName =
          filePath.contains('/')
              ? filePath.substring(filePath.lastIndexOf('/') + 1)
              : filePath;

      decoded['path'] = '[$fileName](file://$filePath)';
      if (decoded.containsKey('filePath')) {
        decoded['filePath'] = '[$fileName](file://$filePath)';
      }
      if (decoded['message'] is String) {
        decoded['message'] = (decoded['message'] as String).replaceAll(
          filePath,
          '[$fileName](file://$filePath)',
        );
      }

      return jsonEncode(decoded);
    } catch (_) {
      return _linkifyRawPaths(resultText);
    }
  }

  static String _linkifyRawPaths(String text) {
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

  static String _stripToolCallTags(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(RegExp(r'<tool_calls>.*?</tool_calls>', dotAll: true), '')
        .replaceAll(
          RegExp(
            r'<\|\s*tool_calls\s*\|>.*?</\|\s*tool_calls\s*\|>',
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<[｜\|]\s*DSML\s*[｜\|]\s*tool_calls>.*?</[｜\|]\s*DSML\s*[｜\|]\s*tool_calls>',
            dotAll: true,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'<(?:\||｜|DSML\s*)*tool_calls[^>]*>.*?</(?:\||｜|DSML\s*)*tool_calls[^>]*>',
            dotAll: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _buildToolCallProgress(
    List<Map<String, dynamic>> deltas,
    Map<int, String> announcedNames,
  ) {
    final buf = StringBuffer();
    for (final delta in deltas) {
      final index = (delta['index'] as int?) ?? 0;
      final fn = delta['function'];
      if (fn is Map) {
        final name = fn['name'] as String?;
        final args = fn['arguments'] as String? ?? '';
        if (name != null && name.isNotEmpty) {
          announcedNames[index] = name;
          buf.writeln('🔧 $name');
          if (args.isNotEmpty) buf.writeln('   参数: $args');
        } else if (announcedNames.containsKey(index) && args.isNotEmpty) {
          buf.writeln('$args');
        }
      }
    }
    return buf.toString();
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
