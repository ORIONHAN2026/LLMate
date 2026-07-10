import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;

import '../../controllers/session_controller.dart';
import '../../controllers/domain_controller.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/content_block.dart';
import 'middleware/api_key_guard.dart';
import 'middleware/quota_guard.dart';
import 'middleware/audit_guard.dart';
import 'middleware/model_tool_guard.dart';
import '../tools/tool_execution_service.dart';
import '../llm/modes/mode_utils.dart' show resolveOriginalToolName;
import '../../controllers/mcp_controller.dart';
import '../../models/chat/mcp_config.dart' show McpTool;
import '../../models/responses/chunk.dart';
import '../../models/responses/openai_response.dart'
    show OpenAIDelta, ToolCall, ToolCallFunction;

/// HTTP 服务控制器
class LocalHttpServiceController extends GetxController {
  final isRunning = false.obs;
  final port = 8899.obs;

  void toggleService() {
    if (isRunning.value) {
      LocalHttpService.stop();
      isRunning.value = false;
    } else {
      LocalHttpService.start(port: port.value);
      isRunning.value = true;
    }
  }

  /// 重启服务（先停止再启动，重新加载证书配置）
  Future<void> restart() async {
    if (isRunning.value) {
      LocalHttpService.stop();
      // 短暂等待端口释放
      await Future.delayed(const Duration(milliseconds: 300));
    }
    LocalHttpService.start(port: port.value);
    isRunning.value = true;
  }
}

/// 本地 HTTP 服务 - 纯请求透传 (基于 Shelf)
///
/// 只做两件事：
/// 1. 从会话获取模型配置（API URL、Key）
/// 2. 透传请求到大模型厂商
class LocalHttpService {
  static HttpServer? _server;
  static bool _isRunning = false;
  static bool _isHttps = false;
  static int _port = 8899;
  static String _bindAddress = '0.0.0.0';

  static bool get isRunning => _isRunning;
  static bool get isHttps => _isHttps;
  static int get port => _port;

  /// 获取当前监听的地址，如 http://0.0.0.0:8899
  static String get listenAddress {
    if (!_isRunning) return '';
    final scheme = _isHttps ? 'https' : 'http';
    return '$scheme://$_bindAddress:$_port';
  }

  /// 用于生成 RequestId 的随机源
  static final Random _requestIdRandom = Random();

  /// 为每次请求生成唯一 RequestId（用于日志文件命名与链路追踪）
  static String _generateRequestId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = _requestIdRandom
        .nextInt(0xffffff)
        .toRadixString(16)
        .padLeft(6, '0');
    return '$ts-$rnd';
  }

  static Future<void> start({
    int port = 8899,
    bool allowExternal = true,
  }) async {
    if (_isRunning) return;
    _port = port;
    try {
      final address =
          allowExternal
              ? InternetAddress.anyIPv4
              : InternetAddress.loopbackIPv4;

      _bindAddress = allowExternal ? '0.0.0.0' : '127.0.0.1';

      final router = _buildRouter();

      // 添加 CORS 中间件
      final handler = const Pipeline()
          .addMiddleware(
            cors.corsHeaders(
              headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
              },
            ),
          )
          .addMiddleware(logRequests())
          .addHandler(router.call);

      // 检查是否配置了 HTTPS 证书
      SecurityContext? securityContext = _loadSecurityContext();

      if (securityContext != null) {
        _server = await io.serve(
          handler,
          address,
          port,
          securityContext: securityContext,
        );
        _isHttps = true;
        debugPrint('🚀 HTTPS 服务已启动: https://$_bindAddress:$port');
      } else {
        _server = await io.serve(handler, address, port);
        _isHttps = false;
        debugPrint('🚀 HTTP 服务已启动: http://$_bindAddress:$port');
      }
      _isRunning = true;
      debugPrint('📡 API: POST /{sessionId}/llmwork/chat/completions');
    } catch (e) {
      debugPrint('❌ HTTP 服务启动失败: $e');
      _isRunning = false;
      rethrow;
    }
  }

  /// 加载 HTTPS 安全上下文（从域名配置中获取证书）
  static SecurityContext? _loadSecurityContext() {
    try {
      final domainController = Get.find<DomainController>();
      final config = domainController.domainConfig.value;
      if (!config.httpsEnabled) return null;

      final certPath = config.certPath;
      final keyPath = config.keyPath;
      if (certPath == null || keyPath == null) return null;

      final certFile = File(certPath);
      final keyFile = File(keyPath);
      if (!certFile.existsSync() || !keyFile.existsSync()) {
        debugPrint('⚠️ HTTPS 证书文件不存在，回退到 HTTP');
        return null;
      }

      final context = SecurityContext();
      context.useCertificateChain(certPath);
      context.usePrivateKey(keyPath);
      debugPrint('🔒 HTTPS 证书已加载');
      return context;
    } catch (e) {
      debugPrint('⚠️ 加载 HTTPS 证书失败: $e，回退到 HTTP');
      return null;
    }
  }

  static Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _isHttps = false;
    debugPrint('🛑 HTTP 服务已停止');
  }

  /// 构建 Shelf Router，通过中间件链组装
  static Router _buildRouter() {
    final router = Router();

    // 健康检查（无需中间件）
    router.get('/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'content-type': 'application/json'},
      );
    });

    // Chat Completion 路由（内联中间件链）
    router.post('/<segment>/llmwork/chat/completions', (
      Request request,
      String sessionId,
    ) async {
      // 每次请求生成唯一 RequestId，注入 context 供审计/日志与链路追踪使用
      final requestId = _generateRequestId();
      final requestWithId = request.change(
        context: {...request.context, 'requestId': requestId},
      );

      // 构建中间件管道：API Key 校验 → 配额检查 → 审计记录 → 模型替换/工具注入 → 业务处理
      final pipeline = const Pipeline()
          .addMiddleware(apiKeyGuard)
          .addMiddleware(quotaGuard)
          .addMiddleware(auditGuard)
          .addMiddleware(modelToolGuard);

      return pipeline.addHandler((Request req) {
        return _handleChatCompletion(req);
      })(requestWithId);
    });

    return router;
  }

  /// 处理 Chat Completion 请求（核心业务逻辑）
  ///
  /// 前置条件（由中间件保证）：
  /// - API Key 已校验通过
  /// - 会话已找到且模型已配置
  /// - 配额未超限
  /// - request.context['session'] 包含有效的 ChatSession
  static Future<Response> _handleChatCompletion(Request request) async {
    try {
      return _streamDirectProxy(request);
    } catch (e) {
      debugPrint('❌ 请求处理失败: $e');

      // 审计回调：记录错误（请求审计已在 modelToolGuard 中完成）
      final auditCallback = request.context['auditCallback'] as AuditCallback?;
      auditCallback?.call(error: '$e');

      return Response.internalServerError(
        body: jsonEncode({
          'error': {
            'message': 'Internal error: $e',
            'type': 'api_error',
            'code': 500,
          },
        }),
        headers: {
          'content-type': 'application/json',
          'x-request-id': request.context['requestId'] as String? ?? '',
        },
      );
    }
  }

  /// 将工具调用分类为会话工具（匹配 MCP 工具）和第三方工具
  ///
  /// 从累积的 Chunk 中匹配 MCP 工具名，两边均返回原始 Chunk
  static ({List<Chunk> session, List<Chunk> thirdParty}) _classifyToolCalls(
    ChatSession session,
    Map<int, Chunk> toolCallChunks,
  ) {
    if (toolCallChunks.isEmpty)
      return (session: const [], thirdParty: const []);

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

  /// 流式透传 - 返回 StreamedResponse，同时解析 SSE 并更新本地会话
  ///
  /// 支持工具调用循环：LLM 返回 tool_calls → 执行 MCP 工具 → 结果回填 →
  /// 继续调用 LLM，直到无工具调用（最多 5 轮）。
  static Response _streamDirectProxy(Request request) {
    final streamController = StreamController<List<int>>();
    final session = request.context['session'] as ChatSession;
    final body = request.context['body'] as Map<String, dynamic>;
    final sessionController = Get.find<SessionController>();
    sessionController.updateSession(session);
    File(
      'log_request/request.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(body));
    bool cancel = false;
    streamController.onCancel = () {
      cancel = true;
      debugPrint('🛑 [StreamProxy] 客户端断开连接，取消后端请求${cancel}');
    };
    // 异步发起请求并透传 SSE 流（支持工具调用循环）
    () async {
      // 由中间件注入到 context 的辅助信息（try 中读取请求体后补全）
      AuditCallback? auditCallback;

      try {
        // 读取请求体（中间件已注入 model / tools），仅补 stream

        auditCallback = request.context['auditCallback'] as AuditCallback?;

        // 工具注入完成后，优先透传服务端工具清单给客户端，

        // ── 工具调用循环状态 ──
        final generationStartTime = DateTime.now();
        final contentBuffer = StringBuffer();

        final thinkBuffer = StringBuffer();

        final List<Map<String, dynamic>> toolCallResults = [];
        // ── 单轮 LLM 请求 ──
        final result = await _streamSingleRound(
          session: session,
          body: jsonEncode(body),
          controller: streamController,
        );
        contentBuffer.write(result.contentBuffer);
        thinkBuffer.write(result.reasonBuffer);

        if (result.sessionToolChunks.isNotEmpty) {
          for (final c in result.sessionToolChunks) {
            debugPrint('要执行的[McpTools] sseChunk: ${c.toString()}');
          }
        }

        if (!result.error) {
          // 透传第三方工具 chunk 给客户端（客户端自行处理）
          if (result.thirdToolChunks.isNotEmpty) {
            debugPrint(
              '📤 [ToolLoop] 透传 ${result.thirdToolChunks.length} 个第三方工具 chunk 给客户端',
            );
            for (final c in result.thirdToolChunks) {
              debugPrint('[ToolLoop] 透传 sseChunk: ${c.toString()}');
              streamController.add(c.toIntList());
            }
          }

          // 有会话工具 → 执行并总结
          if (result.sessionToolChunks.isNotEmpty) {
            // 直接从 Chunk 中提取调用参数
            final toolCallParams =
                result.sessionToolChunks.map((chunk) {
                  final tc =
                      chunk.choices
                          .expand((c) => c.delta?.toolCalls ?? [])
                          .firstOrNull;
                  final argsStr = tc?.function?.arguments ?? '{}';
                  Map<String, dynamic> args;
                  try {
                    args = jsonDecode(argsStr) as Map<String, dynamic>;
                  } catch (_) {
                    args = {'raw': argsStr};
                  }
                  return {
                    'name': tc?.function?.name ?? '',
                    'arguments': args,
                    'id': tc?.id,
                    'index': tc?.index,
                  };
                }).toList();

            final executionResult = await ToolExecutionService.executeToolCalls(
              session: session,
              toolCalls: toolCallParams,
              cleanContent: '',
            );

            if (executionResult != null &&
                executionResult.executionResults.isNotEmpty) {
              var toolThink = Chunk.fromReason("发现大模型后端工具调用，正在执行，请稍后");
              streamController.add(toolThink.toIntList());
              // 收集结果并构建总结请求
              final List<String> resultTexts = [];
              for (final execResult in executionResult.executionResults) {
                resultTexts.add(
                  '工具 "${execResult['name']}" 执行结果：\n${execResult['result']}',
                );
                toolCallResults.add({
                  'name': execResult['name'],
                  'id': execResult['id'],
                  'result': execResult['result'],
                });
                debugPrint(
                  '✅ [ToolLoop] 工具 "${execResult['name']}" 执行完成，结果长度：${(execResult['result'] as String? ?? '').length}',
                );
              }

              // 单次发给大模型进行总结（非流式，关闭深度思考）
              final summaryBody = jsonEncode({
                'model': session.chatModel!.model,
                'messages': [
                  {
                    'role': 'user',
                    'content':
                        '请根据以下工具执行结果，用自然语言向用户汇报：\n\n${resultTexts.join('\n\n')}',
                  },
                ],
                'stream': false,
                'thinking': {'type': 'disabled'},
              });

              final summaryUri = Uri.parse(session.chatModel!.apiUrl!);
              final summaryClient = HttpClient();
              try {
                final summaryReq = await summaryClient.postUrl(summaryUri);
                summaryReq.headers.contentType = ContentType.json;
                if (session.chatModel!.apiKey != null &&
                    session.chatModel!.apiKey!.isNotEmpty) {
                  summaryReq.headers.set(
                    'Authorization',
                    'Bearer ${session.chatModel!.apiKey}',
                  );
                }
                summaryReq.write(summaryBody);
                final summaryResp = await summaryReq.close();

                if (summaryResp.statusCode < 400) {
                  final summaryBytes = await summaryResp.fold<List<int>>(
                    <int>[],
                    (prev, chunk) => prev..addAll(chunk),
                  );
                  final summaryRaw = utf8.decode(summaryBytes);
                  try {
                    final summaryJson =
                        jsonDecode(summaryRaw) as Map<String, dynamic>;
                    final choices = summaryJson['choices'] as List<dynamic>?;
                    final message =
                        choices != null && choices.isNotEmpty
                            ? choices.first['message'] as Map<String, dynamic>?
                            : null;
                    final content = message?['content'] as String?;
                    if (content != null && content.isNotEmpty) {
                      final summaryChunk = Chunk(
                        id: summaryJson['id'] as String? ?? '',
                        object: summaryJson['object'] as String? ?? '',
                        created: summaryJson['created'] as int? ?? 0,
                        model: summaryJson['model'] as String? ?? '',
                        choices: [
                          ChunkChoice(
                            index: 0,
                            delta: OpenAIDelta(content: content),
                            finishReason: null,
                          ),
                        ],
                      );
                      debugPrint(
                        '✅ [ToolLoop] 工具 执行完成，总结：${summaryChunk.toString()}',
                      );
                      streamController.add(summaryChunk.toIntList());
                      contentBuffer.write(content);
                    }
                  } catch (_) {}
                }
              } finally {
                summaryClient.close();
              }
            }
          }

          streamController.add(utf8.encode('data: [DONE]\n\n'));
        }

        await streamController.close();

        debugPrint('🔄 [ToolLoop] 流式请求完成，总内容长度：${contentBuffer.length}');

        // 流结束后，更新本地会话
        _updateSessionAfterStream(
          session: session,
          requestBodyMap: body,
          content: contentBuffer.toString(),

          generationStartTime: generationStartTime,
          toolCalls: null,
        );

        // 审计回调：补入返回内容
        auditCallback?.call(
          responseContent: contentBuffer.toString(),

          toolCallResults: toolCallResults,
        );
      } catch (e) {
        debugPrint('❌ 流式代理错误: $e');
        streamController.addError(e);
        await streamController.close();

        // 审计回调：记录流式异常（请求审计已在 modelToolGuard 中完成）
        auditCallback?.call(error: 'Stream proxy error: $e');
      }
    }();

    return Response(
      200,
      body: streamController.stream,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
        'x-request-id': request.context['requestId'] as String? ?? '',
      },
    );
  }

  /// 流结束后更新本地会话：添加用户消息 + AI 回复 + token 统计 + 计费
  static void _updateSessionAfterStream({
    required ChatSession session,
    required Map<String, dynamic> requestBodyMap,
    required String content,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    required DateTime generationStartTime,
    List<ToolCall>? toolCalls,
  }) {
    try {
      final sessionController = Get.find<SessionController>();
      final now = DateTime.now();

      // 从请求体中提取用户消息内容
      final messages = requestBodyMap['messages'] as List?;
      final lastUserMsg = messages?.lastOrNull as Map<String, dynamic>?;
      final userContent = lastUserMsg?['content'] as String? ?? '';

      // 构建工具调用 contentBlocks（如果有）
      List<ContentBlock> contentBlocks = [];
      final extractedToolCalls =
          toolCalls != null && toolCalls.isNotEmpty ? toolCalls : <ToolCall>[];
      for (final tc in extractedToolCalls) {
        final name = tc.function?.name ?? '';
        final args = tc.function?.arguments ?? '';
        contentBlocks.add(
          ContentBlock(type: ContentBlockType.tool, text: '$name\n$args'),
        );
      }

      // 创建用户消息
      final userMsgId = '${DateTime.now().millisecondsSinceEpoch}_user';
      final userMessage = ChatMessage(
        msgId: userMsgId,
        role: MessageRole.user,
        content: userContent,
        timestamp: now,
        sessionId: session.sessionId,
      );

      // 创建 AI 回复消息
      final botMsgId = '${DateTime.now().millisecondsSinceEpoch}_bot';
      final botMessage = ChatMessage(
        msgId: botMsgId,
        role: MessageRole.bot,
        content: content,
        timestamp: now,
        sessionId: session.sessionId,
        pairedMsgId: userMsgId,
        contentBlocks: contentBlocks,
        generationStartTime: generationStartTime,
        generationEndTime: now,
        inputTokens: promptTokens,
        outputTokens: completionTokens,
        totalTokens: totalTokens,
        generationDuration: now.difference(generationStartTime),
      );

      // 更新会话消息列表
      final newMessages = [...session.messages, userMessage, botMessage];
      var updatedSession = session.copyWith(messages: newMessages);

      // 记录一次请求（配额计数）
      updatedSession = updatedSession.recordRequest();

      // updateSession 内部会调用 _recalculateBilling 自动计算费用
      sessionController.updateSession(updatedSession);

      debugPrint(
        '✅ 会话已更新: ${session.sessionId}, '
        '用户消息: "${userContent.substring(0, userContent.length.clamp(0, 30))}", '
        'AI回复: "${content.substring(0, content.length.clamp(0, 30))}", '
        'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
      );
    } catch (e) {
      debugPrint('❌ 更新会话失败: $e');
    }
  }

  /// 本地对话调用（对话框使用）
  ///
  /// 组装请求体，通过 HTTP 服务透传
  static Stream<Map<String, dynamic>> chatLocally({
    required ChatSession session,
    required ChatMessage userMessage,
  }) async* {
    debugPrint(
      '💬 本地对话: ${userMessage.content.substring(0, userMessage.content.length.clamp(0, 50))}...',
    );

    final model = session.chatModel;
    if (model == null) {
      debugPrint('❌ 会话未配置模型');
      yield {'error': 'No model configured'};
      return;
    }

    final requestBody = jsonEncode({
      'model': model.model,
      'messages': [
        {'role': 'user', 'content': userMessage.content},
      ],
      'stream': true,
    });

    final uri = Uri.parse(model.apiUrl!);
    final client = HttpClient();

    try {
      final httpRequest = await client.postUrl(uri);

      httpRequest.headers.contentType = ContentType.json;
      if (model.apiKey != null && model.apiKey!.isNotEmpty) {
        httpRequest.headers.set('Authorization', 'Bearer ${model.apiKey}');
      }

      httpRequest.write(requestBody);

      final response = await httpRequest.close();

      if (response.statusCode >= 400) {
        final errorBody = await response.transform(utf8.decoder).join();
        debugPrint('❌ LLM 返回错误: ${response.statusCode}\n$errorBody');
        yield {'error': 'LLM API error: ${response.statusCode} - $errorBody'};
        return;
      }

      await for (final chunk in response.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                if (delta != null && delta['content'] != null) {
                  yield {'content': delta['content']};
                }
              }
            } catch (_) {}
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
// ── 工具调用循环 ──

/// 单轮流式请求的结果
class _StreamRoundResult {
  List<Chunk> sessionToolChunks;
  List<Chunk> thirdToolChunks;
  StringBuffer contentBuffer;
  StringBuffer reasonBuffer;
  bool error;

  _StreamRoundResult({
    this.sessionToolChunks = const [],
    this.thirdToolChunks = const [],
    StringBuffer? contentBuffer,
    StringBuffer? reasonBuffer,
    this.error = false,
  }) : contentBuffer = contentBuffer ?? StringBuffer(),
       reasonBuffer = reasonBuffer ?? StringBuffer();
}

/// 执行一轮 LLM 流式请求，解析 SSE 并累积 content 与 tool_calls
///
/// 将 SSE chunk 透传给 [controller]，同时：
/// - 将文本内容追加到 [contentBuffer]
/// - 按 index 累积 tool_calls 增量
/// - 提取 usage 信息
Future<_StreamRoundResult> _streamSingleRound({
  required ChatSession session,
  required String body,
  required StreamController<List<int>> controller,
}) async {
  final client = HttpClient();
  StringBuffer contentBuffer = StringBuffer();
  StringBuffer reasonBuffer = StringBuffer();
  final httpRequest = await client.postUrl(
    Uri.parse(session.chatModel!.apiUrl!),
  );
  try {
    httpRequest.headers.contentType = ContentType.json;
    httpRequest.headers.set(
      'Authorization',
      'Bearer ${session.chatModel!.apiKey}',
    );
    httpRequest.write(body);
    final response = await httpRequest.close();

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
      return _StreamRoundResult(error: true);
    }

    final Map<int, Chunk> toolCallList = {};

    await for (final chunk in response) {
      // controller.add(chunk);
      final raw = utf8.decode(chunk, allowMalformed: true);
      debugPrint('chunk: $raw');

      final trimmed = raw.trim();
      if (!trimmed.startsWith('data:')) {
        //
        controller.add(chunk);
        continue;
      }

      try {
        final sseChunk = Chunk.fromIntList(chunk);
        final choice =
            sseChunk.choices.isNotEmpty ? sseChunk.choices.first : null;
        final delta = choice?.delta;

        // content → 透传并累积 ,思考也炖鱼
        if (delta?.content != null) {
          controller.add(sseChunk.toIntList());
          final raw = utf8.decode(chunk, allowMalformed: true);
          debugPrint('sseChunk: $raw');
          contentBuffer.write(delta!.content);
        }
        // reasoningContent → 透传并累积 ,思考也炖鱼
        if (delta?.reasoningContent != null) {
          controller.add(sseChunk.toIntList());
          debugPrint('sseChunk: $raw');
          reasonBuffer.write(delta!.reasoningContent);
        }
        //usage 统计信息
        if (sseChunk.usage != null) {
          final sessionController = Get.find<SessionController>();
          session.promptTokens = sseChunk.usage!.promptTokens!;
          session.completionTokens += sseChunk.usage!.completionTokens!;
          sessionController.updateSession(session);
        }
        // tool_calls → 按 index 累加合并（不透传）
        if (delta?.toolCalls != null) {
          for (final tc in delta!.toolCalls!) {
            final idx = tc.index ?? 0;
            if (toolCallList[idx] == null) {
              // 首次出现该 index，直接存储整个 Chunk
              toolCallList[idx] = sseChunk;
            } else {
              // 后续增量：从已存储的 Chunk 中取出原有 ToolCall，合并 arguments
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
        // 忽略解析失败的行
      }
    }

    // 直接根据累积的 Chunk Map 进行分类，两边都返回 Chunk
    final (
      session: sessionToolChunks,
      thirdParty: thirdToolChunks,
    ) = LocalHttpService._classifyToolCalls(session, toolCallList);

    return _StreamRoundResult(
      sessionToolChunks: sessionToolChunks,
      thirdToolChunks: thirdToolChunks,
      contentBuffer: contentBuffer,
      reasonBuffer: reasonBuffer,
    );
  } finally {
    client.close();
  }
}
