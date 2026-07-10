import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../controllers/mcp_controller.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/mcp_config.dart';
import '../../models/responses/chunk.dart';
import '../../models/responses/openai_response.dart'
    show OpenAIDelta, ToolCall, ToolCallFunction;
import '../llm/modes/mode_utils.dart' show resolveOriginalToolName;

/// 单轮流式请求的结果
///
/// 包含该轮 LLM 响应的完整信息：文本内容、工具调用分类、错误状态。
class StreamRoundResult {
  List<Chunk> sessionToolChunks;
  List<Chunk> thirdToolChunks;
  StringBuffer contentBuffer;
  StringBuffer reasonBuffer;
  bool error;
  int? promptTokens;
  int? completionTokens;

  StreamRoundResult({
    this.sessionToolChunks = const [],
    this.thirdToolChunks = const [],
    StringBuffer? contentBuffer,
    StringBuffer? reasonBuffer,
    this.error = false,
    this.promptTokens,
    this.completionTokens,
  }) : contentBuffer = contentBuffer ?? StringBuffer(),
       reasonBuffer = reasonBuffer ?? StringBuffer();
}

/// 执行一轮 LLM 流式请求，解析 SSE 并累积 content 与 tool_calls
///
/// 将 SSE chunk 透传给 [controller]，同时：
/// - 将文本内容追加到 contentBuffer
/// - 将推理内容追加到 reasonBuffer
/// - 按 index 累积 tool_calls 增量（不直接透传 tool_calls chunk）
/// - 提取 usage 信息并更新会话 token 统计
///
/// 返回 [StreamRoundResult]：包含分类后的工具 chunks、内容缓冲区和错误状态。
Future<StreamRoundResult> streamSingleRound({
  required ChatSession session,
  required String body,
  required StreamController<List<int>> controller,
}) async {
  final client = HttpClient();
  StringBuffer contentBuffer = StringBuffer();
  StringBuffer reasonBuffer = StringBuffer();
  int promptTokens = 0;
  int completionTokens = 0;
  final httpRequest = await client.postUrl(
    Uri.parse(session.chatModel!.apiUrl!),
  );
  httpRequest.headers.contentType = ContentType.json;
  httpRequest.headers.set(
    'Authorization',
    'Bearer ${session.chatModel!.apiKey}',
  );

  try {
    httpRequest.write(body);
    final response = await httpRequest.close();

    // LLM API 返回错误
    if (response.statusCode >= 400) {
      final errorBody = await response.transform(utf8.decoder).join();
      debugPrint('❌ LLM 返回错误: ${response.statusCode}\n$errorBody');
      controller.add(
        utf8.encode(
          jsonEncode({
            'error': {
              'message': 'LLM API error: ${response.statusCode} - $errorBody',
              'code': response.statusCode,
            },
          }),
        ),
      );
      return StreamRoundResult(error: true);
    }

    // 按 index 累积 tool_calls 增量（SSE 流中同一个 tool_call 的 arguments 可能分多个 chunk 到达）
    final Map<int, Chunk> toolCallList = {};

    await for (final chunk in response) {
      final raw = utf8.decode(chunk, allowMalformed: true);
      debugPrint('chunk: $raw');

      final trimmed = raw.trim();
      // 非 SSE data 行 → 直接透传（如注释行、空行）
      if (!trimmed.startsWith('data:')) {
        controller.add(chunk);
        continue;
      }

      try {
        final sseChunk = Chunk.fromIntList(chunk);
        final choice =
            sseChunk.choices.isNotEmpty ? sseChunk.choices.first : null;
        final delta = choice?.delta;

        // 文本内容 → 透传给客户端并累积
        if (delta?.content != null) {
          controller.add(sseChunk.toIntList());
          debugPrint('sseChunk content: $raw');
          contentBuffer.write(delta!.content);
        }

        // 推理/思考内容（reasoning） → 透传并累积
        if (delta?.reasoningContent != null) {
          controller.add(sseChunk.toIntList());
          debugPrint('sseChunk reasoning: $raw');
          reasonBuffer.write(delta!.reasoningContent);
        }

        // Token 用量 → 暂存，由调用方决定如何使用
        if (sseChunk.usage != null) {
          promptTokens += sseChunk.usage!.promptTokens!;
          completionTokens += sseChunk.usage!.completionTokens!;
        }

        // tool_calls → 按 index 增量合并（不透传给客户端，由 ToolLoop 统一处理）
        if (delta?.toolCalls != null) {
          for (final tc in delta!.toolCalls!) {
            final idx = tc.index ?? 0;
            if (toolCallList[idx] == null) {
              // 首次出现该 index，直接存储整个 Chunk
              toolCallList[idx] = sseChunk;
            } else {
              // 后续增量：与已存储的 Chunk 合并 arguments
              final existingChunk = toolCallList[idx]!;
              final existingChoice = existingChunk.choices.firstOrNull;
              final existingTc = existingChoice?.delta?.toolCalls?.firstWhere(
                (t) => (t.index ?? 0) == idx,
                orElse: () => tc,
              );

              final mergedId = tc.id ?? existingTc?.id;
              final mergedType = tc.type ?? existingTc?.type;
              final mergedName =
                  tc.function?.name ?? existingTc?.function?.name;
              final mergedArgs =
                  (existingTc?.function?.arguments ?? '') +
                  (tc.function?.arguments ?? '');

              final mergedTc = ToolCall(
                index: idx,
                id: mergedId,
                type: mergedType,
                function: ToolCallFunction(
                  name: mergedName,
                  arguments: mergedArgs,
                ),
              );

              final mergedDelta = OpenAIDelta(toolCalls: [mergedTc]);
              final mergedChoice = ChunkChoice(
                index: existingChoice?.index ?? 0,
                delta: mergedDelta,
                finishReason: existingChoice?.finishReason,
              );
              toolCallList[idx] = Chunk(
                id: existingChunk.id,
                object: existingChunk.object,
                created: existingChunk.created,
                model: existingChunk.model,
                choices: [mergedChoice],
              );
            }
          }
        }
      } catch (_) {
        // 忽略解析失败的行（非 JSON 的 SSE 行等）
      }
    }

    // 流结束后对累积的 tool_calls 进行分类
    final (
      session: sessionToolChunks,
      thirdParty: thirdToolChunks,
    ) = _classifyToolCalls(session, toolCallList);

    return StreamRoundResult(
      sessionToolChunks: sessionToolChunks,
      thirdToolChunks: thirdToolChunks,
      contentBuffer: contentBuffer,
      reasonBuffer: reasonBuffer,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
    );
  } finally {
    client.close();
  }
}

/// 将工具调用分类为会话工具（匹配 MCP 工具）和第三方工具
///
/// 从累积的 Chunk Map 中匹配会话绑定的 MCP 工具名：
/// - 匹配成功 → 会话工具（由 ToolLoop 在服务端执行）
/// - 不匹配 → 第三方工具（透传给客户端自行处理）
({List<Chunk> session, List<Chunk> thirdParty}) _classifyToolCalls(
  ChatSession session,
  Map<int, Chunk> toolCallChunks,
) {
  if (toolCallChunks.isEmpty) {
    return (session: const [], thirdParty: const []);
  }

  final mcpName = session.mcp;
  final mcpTools =
      mcpName != null && mcpName.isNotEmpty
          ? McpController.instance.getTools(mcpName)
          : <McpTool>[];
  final mcpToolNames = mcpTools.map((t) => t.name).toSet();
  debugPrint('🔧 [Classify] 会话 MCP 工具: $mcpToolNames');

  final sessionChunks = <Chunk>[];
  final thirdToolChunks = <Chunk>[];

  for (final entry in toolCallChunks.entries) {
    final chunk = entry.value;
    final tc = chunk.choices
        .expand((c) => c.delta?.toolCalls ?? [])
        .firstWhere((t) => (t.index ?? 0) == entry.key);
    final name = tc.function?.name;

    if (name != null) {
      final resolvedName = resolveOriginalToolName(name);
      debugPrint(
        '🔧 [Classify] 工具 "$name" → 解析后 "$resolvedName"，会话含: $mcpToolNames',
      );
      if (mcpToolNames.contains(resolvedName)) {
        sessionChunks.add(chunk);
        continue;
      }
    }

    // 无匹配 → 第三方工具
    thirdToolChunks.add(chunk);
  }

  return (session: sessionChunks, thirdParty: thirdToolChunks);
}
