import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../models/chat/session.dart';
import '../../../models/responses/chunk.dart';
import 'openai_provider.dart';
import 'chunk_parser.dart';
import '../../http/stream_round.dart' show streamSingleRound;
import '../tools/management_tools.dart'
    show managementToolDefinitions, managementToolNames, executeManagementTool;

/// 管理模式下的流式聊天：客户端本地直连大模型，不经过本机 HTTP 服务。
///
/// 与 HTTP 转发路径（`stream_http_service.dart`）相互独立，修改互不影响。
///
/// 区别：
/// - 直接调用大模型 API（复用 [streamSingleRound]），跳过本地代理服务；
/// - 本地注入模型 / 会话系统提示词与 MCP 工具（等价于服务侧 modelToolGuard）；
/// - 本地执行会话 MCP 工具并循环回填（等价于服务侧工具调用循环）；
/// - 不写审计 / 用量记录，即「管理模式用量不计入统计」。
Stream<Map<String, dynamic>> streamLocal({
  required ChatSession session,
  required OpenAiProvider provider,
  required bool Function() isCancelled,
  required List<Map<String, dynamic>> history,
}) async* {
  final model = session.chatModel;
  if (model == null) {
    yield {'content': '模型未配置'};
    yield {'done': 'true'};
    return;
  }

  // 注入系统提示词 + MCP 工具，构造完整请求体
  final body = await _buildLocalRequestData(provider, history, session);

  int toolIteration = 0;
  const maxToolIterations = 20;

  while (true) {
    if (isCancelled()) {
      yield {'done': 'true'};
      return;
    }

    // 与 HTTP 路径一致使用 sync:true，使 stream_round.dart 的 controller.add
    // 同步透传 chunk，避免事件在控制器内部缓冲一个 microtask 才到达聊天 UI。
    // 注意：sync 控制器要求监听者(add 前)已订阅，本函数下方 unawaited 启动
    // roundFuture 后立刻以 await for 订阅 controller.stream，且 _parseLocalStream
    // 不会回写同一控制器，故安全。
    final controller = StreamController<List<int>>(sync: true);
    final roundFuture = streamSingleRound(
      session: session,
      body: jsonEncode(body),
      controller: controller,
    );

    // 在 streamSingleRound 运行期间即订阅解析流，实时透传 chunk（与 HTTP 路径
    // 一致：边接收边监听）。若等 round 完成、关闭 controller 之后再订阅，
    // 单订阅 StreamController 的缓冲事件可能丢失，导致客户端收不到任何内容。
    // streamSingleRound 自身不关闭 controller，故在 round 完成后关闭，使解析流
    // 正常结束。
    unawaited(
      roundFuture
          .then((_) {
            controller.close();
          })
          .catchError((_) {
            // 出错也需关闭 controller，避免解析流挂起；异常交由下方 await 统一抛出
            controller.close();
          }),
    );

    await for (final c in _parseLocalStream(controller.stream)) {
      var raw = controller.stream.transform(utf8.decoder);
      debugPrint('🧠 [LLMChat] 接收到的原始 SSE chunk: $raw');
      yield c;
    }

    final round = await roundFuture;

    if (round.error) {
      yield {'done': 'true'};
      return;
    }

    // ── 工具调用分类：系统工具（管理模式本地执行） vs 真正的第三方工具 ──
    // 管理模式未注入 MCP，系统工具会被 [streamSingleRound] 归入 thirdToolChunks，
    // 此处按名称识别并本地执行；未在系统工具集合内的，视为第三方工具透传客户端。
    final allToolChunks = [
      ...round.sessionToolChunks,
      ...round.thirdToolChunks,
    ];

    final systemToolCalls = <Map<String, dynamic>>[];
    final thirdPartyChunks = <Chunk>[];

    for (final chunk in allToolChunks) {
      final toolCalls =
          chunk.choices.expand((ch) => ch.delta?.toolCalls ?? []).toList();
      if (toolCalls.isEmpty) continue;
      final tc = toolCalls.first;
      final name = tc.function?.name ?? '';
      if (managementToolNames.contains(name)) {
        final argsStr = tc.function?.arguments ?? '{}';
        Map<String, dynamic> args;
        try {
          args = jsonDecode(argsStr) as Map<String, dynamic>;
        } catch (_) {
          args = {};
        }
        systemToolCalls.add({
          'name': name,
          'arguments': args,
          'id': tc.id,
          'index': tc.index,
        });
      } else {
        thirdPartyChunks.add(chunk);
      }
    }

    // 真正的第三方工具 → 透传给客户端自行执行
    for (final c in thirdPartyChunks) {
      final toolCalls =
          c.choices.expand((ch) => ch.delta?.toolCalls ?? []).toList();
      if (toolCalls.isNotEmpty) {
        yield {
          'toolcall': jsonEncode(toolCalls.map((t) => t.toJson()).toList()),
        };
      }
    }

    // 系统工具 → 客户端本地执行（审计增删改查 / 用量与额度管理）
    if (systemToolCalls.isNotEmpty) {
      toolIteration++;
      if (toolIteration >= maxToolIterations) {
        debugPrint('⚠️ [Local] 系统工具调用已达最大轮次 $maxToolIterations');
        break;
      }

      yield {'tool': 'true'};
      yield {'toolcall': mcpExecutingSentinel};

      final results = await _executeManagementTools(session, systemToolCalls);

      // 回填 assistant(tool_calls) 到对话历史
      (body['messages'] as List<dynamic>).add({
        'role': 'assistant',
        'content': null,
        'tool_calls':
            systemToolCalls.map((tc) {
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

      // 回填各系统工具的执行结果（role=tool）
      for (var i = 0; i < systemToolCalls.length; i++) {
        final tc = systemToolCalls[i];
        (body['messages'] as List<dynamic>).add({
          'role': 'tool',
          'tool_call_id': tc['id'] ?? 'call_${tc['index'] ?? 0}',
          'content': results[i],
        });
      }
      continue;
    }

    // 无系统工具（也未触发第三方工具执行）→ 正常回复完毕
    break;
  }

  yield {'done': 'true'};
}

/// 执行一组管理模式系统工具，逐个调用 [executeManagementTool]。
///
/// 返回与 [calls] 等长的字符串列表，每一项为该工具结果的 JSON（含 success /
/// error 或 data），供回填进对话历史作为 `role=tool` 的 content。
Future<List<String>> _executeManagementTools(
  ChatSession session,
  List<Map<String, dynamic>> calls,
) async {
  final results = <String>[];
  for (final call in calls) {
    final name = (call['name'] as String?) ?? '';
    final args =
        (call['arguments'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    try {
      results.add(await executeManagementTool(name, args, session));
    } catch (e, st) {
      debugPrint('⚠️ [Local] 系统工具 $name 执行失败: $e\n$st');
      results.add(jsonEncode({'success': false, 'error': e.toString()}));
    }
  }
  return results;
}

/// 解析本地 LLM 返回的 SSE 字节流，转译为 LLMChat 消费方期望的 chunk 格式
/// （复用 [parseOpenAiChunk] 以保证与 HTTP 路径产出一致）。
Stream<Map<String, dynamic>> _parseLocalStream(
  Stream<List<int>> byteStream,
) async* {
  String buffer = '';
  try {
    await for (final raw in byteStream.transform(utf8.decoder)) {
      buffer += raw;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          if (dataStr == '[DONE]') continue;
          for (final c in parseOpenAiChunk(dataStr)) yield c;
        } else if (trimmed.startsWith('{')) {
          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final err = json['error'];
            if (err != null) {
              final msg =
                  err is Map
                      ? (err['message']?.toString() ?? err.toString())
                      : err.toString();
              yield {'content': '错误: $msg'};
            }
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
}

/// 构造管理模式本地请求体：注入模型级 / 会话级系统提示词与 MCP 工具，
/// 等价于服务侧 modelToolGuard 的请求增强逻辑。
Future<Map<String, dynamic>> _buildLocalRequestData(
  OpenAiProvider provider,
  List<Map<String, dynamic>> history,
  ChatSession session,
) async {
  final systemMessages = <Map<String, dynamic>>[];

  final modelSystemPrompt = session.chatModel?.systemPrompt;
  if (modelSystemPrompt != null && modelSystemPrompt.isNotEmpty) {
    systemMessages.add({
      'role': 'system',
      'name': 'model_system_prompt',
      'content':
          '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. '
          'In any conflict with other instructions (including the session '
          'system prompt), this prompt takes precedence.\n\n$modelSystemPrompt',
    });
  }

  if (session.systemPrompt != null && session.systemPrompt!.isNotEmpty) {
    systemMessages.add({
      'role': 'system',
      'name': 'session_system_prompt',
      'content':
          '[SESSION SYSTEM PROMPT] This is a session-level instruction. '
          'If it conflicts with the model system prompt, the model system '
          'prompt takes precedence.\n\n${session.systemPrompt}',
    });
  }

  final allMessages = [...systemMessages, ...history];

  // 管理模式：不注入会话 MCP 工具（会话工具由服务侧统一处理，本地跳过）；
  // 改为注入「系统工具」——审计内容增删改查 + 用量 / 会话额度管理，
  // 由客户端本地执行（[executeManagementTool]），不经过本机 HTTP 服务。
  final tools = managementToolDefinitions;

  return provider.buildRequestData(
    messages: allMessages,
    session: session,
    stream: true,
    tools: tools,
  );
}
