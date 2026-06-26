import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/memory_turn.dart';
import '../services/tool_execution_service.dart';
import '../services/memory_compressor.dart';
import '../controllers/session_controller.dart';
import 'llmproviders/base_provider.dart';
import 'llmproviders/openai_provider.dart';
import 'llmproviders/anthropic_provider.dart';
import 'llmproviders/gemini_provider.dart';

/// LLM Hub - provider 注册中心
///
/// 按协议标准注册 provider，而非按厂商：
/// - OpenAI 兼容协议：OpenAI、DeepSeek、阿里云百炼、智谱AI、ModelScope、Ollama
/// - Anthropic 协议：Claude
/// - Gemini 协议：Google Gemini
class LlmHub {
  final Map<String, BaseLlmProvider> _providers = {};

  LlmHub._internal() {
    _initializeProviders();
  }
  static final LlmHub _instance = LlmHub._internal();
  static LlmHub get instance => _instance;
  factory LlmHub() => _instance;

  void _initializeProviders() {
    // ── OpenAI 兼容协议 ──
    // 所有 OpenAI 兼容的 provider 共享同一个协议入口
    _providers['openai'] = OpenAiProvider(
      displayName: 'OpenAI Compatible',
    );

    // ── Anthropic 协议 ──
    _providers['anthropic'] = AnthropicProvider();

    // ── Gemini 协议 ──
    _providers['gemini'] = GeminiProvider();
  }

  /// 解析 provider — 按 protocol 字段路由
  static BaseLlmProvider _resolve(ChatModel model) {
    final key = model.protocol?.toLowerCase();
    if (key == null) throw UnsupportedError('模型未配置协议');
    final p = instance._providers[key];
    if (p == null) throw UnsupportedError('不支持的协议: $key');
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
  ChatSession _session;
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
  /// chunk: {content,think,tool,toolcall}
  ///   tool: 'true'/'false' 布尔状态标记，表示是否正在执行工具
  ///   toolcall: 工具调用的具体内容（函数名、参数、执行结果）
  // ignore: non_constant_identifier_names
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

    var messages = await _provider.buildMessages(
      userMessage: userMessage,
      session: _session,
    );

    // 保存请求报文快照（深拷贝，避免后续 tool 消息追加污染日志）
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

    // 累积完整响应用于记忆捕获 & 日志
    final responseBuffer = StringBuffer();
    final thinkBuffer = StringBuffer();
    final toolCallLog = <Map<String, dynamic>>[];

    // 循环：LLM 返回工具调用后追加结果并重发，直到无工具调用或检测到重复调用
    int toolIteration = 0;

    while (true) {
      // 用于累积本轮 assistant 流中的 content 文本，作为工具调用消息的 content。
      String loopAccContent = '';
      final nativeToolCallDeltas = <int, Map<String, dynamic>>{};
      List<Map<String, dynamic>>? completedTextToolCalls;
      final announcedToolNames = <int, String>{}; // 已公布的函数名，按 index

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
              // 实时产出工具调用信息给 UI
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
          responseBuffer.write(c); // 累积响应内容
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
          // 不在这里 yield done — 等工具调用全部处理完后再发
        }
      }

      // 无工具调用或已取消 → 结束
      final parsedCalls =
          completedTextToolCalls ??
          _finalizeNativeToolCalls(nativeToolCallDeltas);

      if (_cancelled || parsedCalls.isEmpty) {
        // ========== 请求日志写入 ==========
        if (!_cancelled) {
          // 不 await，异步写日志不阻塞 UI
          _writeRequestLog(
            requestMessages: requestSnapshot,
            responseContent: responseBuffer.toString(),
            responseThink: thinkBuffer.toString(),
            toolCalls: toolCallLog,
            sessionId: _session.sessionId,
            modelName: _session.chatModel?.model ?? 'unknown',
          );
        }
        // ========== 记忆累积 & 压缩（必须在 done 之前处理，避免接收端 break 后丢失） ==========
        if (!_cancelled && responseBuffer.isNotEmpty) {
          // 累积到会话级记忆并检查压缩
          final memoryUpdatedSession = await accumulateMemory(
            userMessage.content,
            responseBuffer.toString(),
            null, // sessionController 由 caller 处理
          );
          if (memoryUpdatedSession != null) {
            yield {
              'memory_updated': jsonEncode(memoryUpdatedSession.toJson()),
            };
          }
        }
        // 所有工具调用处理完毕，此时才发送 done 信号
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

      // 从累积文本中剥离工具调用标签，得到干净的正文内容
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

        // 记录到工具调用日志
        toolCallLog.add({
          'name': name,
          'arguments': args,
          'success': ok,
          'result': resultText.length > 2000
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

  // ======================== 请求日志 ========================

  /// 日志目录名
  /// 项目日志目录（硬编码为代码仓库路径）
  static const _projectRoot = '/Users/orion/Documents/Flutter/llmchat';
  static const _logDir = 'log_request';

  /// 将当前轮次的请求报文和回复写入本地日志文件
  static Future<void> _writeRequestLog({
    required List<Map<String, dynamic>> requestMessages,
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
      final timestamp = '${now.year}${_pad(now.month)}${_pad(now.day)}_'
          '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final fileName = '${timestamp}_${sessionId.substring(0, 8)}.json';
      final file = File(p.join(dir.path, fileName));

      final logData = {
        'timestamp': now.toIso8601String(),
        'sessionId': sessionId,
        'model': modelName,
        'request': {
          'messages': requestMessages,
          if (requestTools != null && requestTools.isNotEmpty) 'tools': requestTools,
        },
        'response': {
          if (responseThink != null && responseThink.isNotEmpty)
            'think': responseThink,
          'content': responseContent,
          if (toolCalls != null && toolCalls.isNotEmpty) 'tool_calls': toolCalls,
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

  // ==================== 工具调用解析等 ====================
  Future<String?> sendCompressRequest(String prompt) async {
    try {
      final model = _session.chatModel;
      if (model == null) return null;

      final protocol = model.protocol?.toLowerCase() ?? '';

      if (protocol == 'openai') {
        // OpenAI 兼容 provider：绕过 sendMessage 的 json_object 约束
        return await _sendOpenAICompatPlainRequest(prompt, model);
      } else {
        // Anthropic / Gemini / Ollama：sendMessage 无 JSON 格式约束，可正常使用
        final response = await _provider.sendMessage(
          userMessage: ChatMessage(
            msgId: 'compress_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: prompt,
            timestamp: DateTime.now(),
            sessionId: _session.sessionId,
          ),
          session: _session,
        );
        return response;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🧠 压缩请求失败: $e');
      return null;
    }
  }

  /// 为 OpenAI 兼容 API 发送纯文本请求（无 response_format 约束）
  Future<String?> _sendOpenAICompatPlainRequest(
    String prompt,
    ChatModel model,
  ) async {
    if (model.apiUrl == null) return null;

    final dio = Dio();
    dio.options.connectTimeout = const Duration(milliseconds: 30000);
    dio.options.receiveTimeout = const Duration(minutes: 5);
    dio.options.sendTimeout = const Duration(minutes: 5);

    final requestData = <String, dynamic>{
      'model': model.model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'stream': false,
      'max_tokens': 4000,
      'temperature': 0.3,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (model.apiKey != null && model.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${model.apiKey}';
    }

    final response = await dio.post(
      model.apiUrl!,
      options: Options(headers: headers),
      data: requestData,
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        if (message != null && message['content'] != null) {
          return message['content'] as String;
        }
      }
    }

    if (kDebugMode) {
      debugPrint(
        '🧠 压缩请求异常: status=${response.statusCode}, '
        'body=${response.data?.toString().substring(0, 200)}',
      );
    }
    return null;
  }

  /// 累积对话记忆并在达到阈值时触发压缩
  ///
  /// 逻辑：
  /// 1. 将本轮 user/assistant 消息添加到 [ChatSession.memory]
  /// 2. 检查记忆轮数是否达到 [ChatSession.memoryRounds] 阈值
  /// 3. 达到阈值时，调用 LLM 压缩 memory + compressedMemory，生成新的压缩摘要
  /// 4. 压缩成功后，更新 compressedMemory 并清空 memory（重新累积）
  /// 5. 未达到阈值时，只更新 memory
  ///
  /// 返回更新后的 ChatSession（如果记忆有变化），否则返回 null
  Future<ChatSession?> accumulateMemory(
    String userText,
    String assistantText,
    SessionController? sessionController,
  ) async {
    // 禁用记忆压缩
    if (_session.memoryRounds <= 0) return null;

    // 添加本轮对话到记忆
    final now = DateTime.now();
    final updatedMemory = List<MemoryTurn>.from(_session.memory)
      ..add(MemoryTurn(role: 'user', content: userText, timestamp: now))
      ..add(MemoryTurn(
        role: 'assistant',
        content: assistantText,
        timestamp: now,
      ));

    final rounds = MemoryTurn.roundCount(updatedMemory);

    // 达到压缩阈值，触发 LLM 压缩
    if (rounds >= _session.memoryRounds) {
      if (kDebugMode) {
        debugPrint(
          '🧠 [Memory] 记忆达到 ${rounds} 轮 (≥ ${_session.memoryRounds})，触发压缩',
        );
      }

      // 异步压缩（不阻塞）
      final compressed = await MemoryCompressor.compress(
        session: _session,
        compressedMemory: _session.compressedMemory,
        memory: updatedMemory,
      );

      if (compressed != null) {
        _session = _session.copyWith(
          compressedMemory: compressed,
          memory: [], // 清空原始记忆
        );
        return _session;
      }
    }

    // 不需要压缩，只更新记忆
    _session = _session.copyWith(memory: updatedMemory);
    return _session;
  }

  /// 将工具结果 JSON 中的文件路径替换为 Markdown 链接
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
