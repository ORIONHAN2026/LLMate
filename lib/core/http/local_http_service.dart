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
      // session / requestId / 审计回调等均已由前面的中间件注入 request.context，
      // 直接透传 request 给代理层即可。
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

  /// 非流式透传
  static Future<Response> _handleNonStream(
    ChatSession session,
    Map<String, dynamic> requestBodyMap, {
    AuditCallback? auditCallback,
  }) async {
    final responseBody = await _proxyToLLM(session, requestBodyMap);

    Map<String, dynamic>? llmResponse;
    String? content;
    int? promptTokens, completionTokens, totalTokens;
    int? reasoningTokens, cachedTokens;
    try {
      llmResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = llmResponse['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        content = choices[0]['message']?['content'] as String?;
      }
      final usage = llmResponse['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        promptTokens = usage['prompt_tokens'] as int?;
        completionTokens = usage['completion_tokens'] as int?;
        totalTokens = usage['total_tokens'] as int?;
        final completionDetails =
            usage['completion_tokens_details'] as Map<String, dynamic>?;
        reasoningTokens = completionDetails?['reasoning_tokens'] as int?;
        final promptDetails =
            usage['prompt_tokens_details'] as Map<String, dynamic>?;
        cachedTokens = promptDetails?['cached_tokens'] as int?;
      }
    } catch (_) {}

    final sessionController = Get.find<SessionController>();
    final updatedSession = session.recordRequest();
    sessionController.updateSession(updatedSession);

    auditCallback?.call(
      rawResponse: llmResponse,
      responseContent: content,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      reasoningTokens: reasoningTokens,
      cachedTokens: cachedTokens,
    );

    return Response.ok(
      responseBody,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 非流式透传（底层 HTTP 请求）
  static Future<String> _proxyToLLM(
    ChatSession session,
    Map<String, dynamic> requestBodyMap,
  ) async {
    final uri = Uri.parse(session.chatModel!.apiUrl!);
    final client = HttpClient();

    try {
      final httpRequest = await client.postUrl(uri);

      httpRequest.headers.contentType = ContentType.json;
      if (session.chatModel!.apiKey != null &&
          session.chatModel!.apiKey!.isNotEmpty) {
        httpRequest.headers.set(
          'Authorization',
          'Bearer ${session.chatModel!.apiKey}',
        );
      }

      final requestJson = jsonEncode(requestBodyMap);
      httpRequest.write(requestJson);

      final response = await httpRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 400) {
        debugPrint('❌ LLM 返回错误: ${response.statusCode}');
        throw Exception(
          'LLM API error: ${response.statusCode} - $responseBody',
        );
      }

      return responseBody;
    } finally {
      client.close();
    }
  }

  /// 将工具调用分类为会话工具（匹配 MCP 工具）和第三方工具
  ///
  /// 同时穿透 ToolSearch 等元工具的 arguments.tool_names 进行匹配
  static ({List<ToolCall> session, List<ToolCall> thirdParty})
  _classifyToolCalls(ChatSession session, List<ToolCall> toolCalls) {
    if (toolCalls.isEmpty) return (session: const [], thirdParty: const []);

    final mcpName = session.mcp;
    final mcpTools =
        mcpName != null && mcpName.isNotEmpty
            ? McpController.instance.getTools(mcpName)
            : <McpTool>[];
    final mcpToolNames = mcpTools.map((t) => t.name).toSet();
    debugPrint('🔧 [Classify] 会话 MCP 工具: $mcpToolNames');

    final sessionTools = <ToolCall>[];
    final thirdPartyTools = <ToolCall>[];

    for (final tc in toolCalls) {
      final name = tc.function?.name;

      // 1) 工具名本身匹配 MCP 工具
      if (name != null) {
        final resolvedName = resolveOriginalToolName(name);
        debugPrint(
          '🔧 [Classify] 工具 "$name" → 解析后 "$resolvedName"，会话含: $mcpToolNames',
        );
        if (mcpToolNames.contains(resolvedName)) {
          sessionTools.add(tc);
          continue;
        }
      }

      // 无匹配 → 第三方工具
      thirdPartyTools.add(tc);
    }

    return (session: sessionTools, thirdParty: thirdPartyTools);
  }

  /// 流式透传 - 返回 StreamedResponse，同时解析 SSE 并更新本地会话
  ///
  /// 支持工具调用循环：LLM 返回 tool_calls → 执行 MCP 工具 → 结果回填 →
  /// 继续调用 LLM，直到无工具调用（最多 5 轮）。
  static Response _streamDirectProxy(Request request) {
    final controller = StreamController<List<int>>();

    final session = request.context['session'] as ChatSession;
    // 异步发起请求并透传 SSE 流（支持工具调用循环）
    () async {
      // 由中间件注入到 context 的辅助信息（try 中读取请求体后补全）
      AuditCallback? auditCallback;

      try {
        // 读取请求体（中间件已注入 model / tools），仅补 stream
        final bodyStr = await request.readAsString();
        debugPrint(
          '📨 请求体: ${bodyStr.substring(0, bodyStr.length.clamp(0, 100))}...',
        );
        final requestBodyMap = jsonDecode(bodyStr) as Map<String, dynamic>;
        requestBodyMap['stream'] = true;
        auditCallback = request.context['auditCallback'] as AuditCallback?;

        // 工具注入完成后，优先透传服务端工具清单给客户端，

        // ── 工具调用循环状态 ──
        final generationStartTime = DateTime.now();
        final contentBuffer = StringBuffer();
        int? totalPromptTokens;
        int? totalCompletionTokens;
        int? totalTokens;
        int? totalReasoningTokens;
        int? totalCachedTokens;
        final List<Map<String, dynamic>> toolCallResults = [];
        // ── 单轮 LLM 请求 ──
        final result = await _streamSingleRound(
          session: session,
          requestJson: jsonEncode(requestBodyMap),
          controller: controller,
          contentBuffer: contentBuffer,
        );

        if (!result.error) {
          if (result.promptTokens != null) {
            totalPromptTokens = (totalPromptTokens ?? 0) + result.promptTokens!;
          }
          if (result.completionTokens != null) {
            totalCompletionTokens =
                (totalCompletionTokens ?? 0) + result.completionTokens!;
          }
          totalTokens = result.totalTokens ?? totalTokens;
          totalReasoningTokens = result.reasoningTokens ?? totalReasoningTokens;
          totalCachedTokens = result.cachedTokens ?? totalCachedTokens;

          // 透传第三方工具 chunk 给客户端（客户端自行处理）
          if (result.toolCallChunks.isNotEmpty) {
            debugPrint(
              '📤 [ToolLoop] 透传 ${result.toolCallChunks.length} 个第三方工具 chunk 给客户端',
            );
            for (final c in result.toolCallChunks) {
              controller.add(c.toIntList());
            }
          }

          // 有会话工具 → 执行并总结
          if (result.sessionToolCalls.isNotEmpty) {
            final executionResult = await ToolExecutionService.executeToolCalls(
              session: session,
              toolCalls:
                  result.sessionToolCalls.map((tc) {
                    final argsStr = tc.function?.arguments ?? '{}';
                    Map<String, dynamic> args;
                    try {
                      args = jsonDecode(argsStr) as Map<String, dynamic>;
                    } catch (_) {
                      args = {'raw': argsStr};
                    }
                    return {
                      'name': tc.function?.name ?? '',
                      'arguments': args,
                      'id': tc.id,
                      'index': tc.index,
                    };
                  }).toList(),
              cleanContent: '',
            );

            if (executionResult != null &&
                executionResult.executionResults.isNotEmpty) {
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

              // 单次发给大模型进行总结
              final summaryBody = jsonEncode({
                'model': session.chatModel!.model,
                'messages': [
                  {
                    'role': 'user',
                    'content':
                        '请根据以下工具执行结果，用自然语言向用户汇报：\n\n${resultTexts.join('\n\n')}',
                  },
                ],
                'stream': true,
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
                  await for (final chunk in summaryResp) {
                    final raw = utf8.decode(chunk, allowMalformed: true);
                    for (final line in raw.split('\n')) {
                      if (!line.startsWith('data: ')) continue;
                      final data = line.substring(6);
                      if (data == '[DONE]') continue;
                      try {
                        final json = jsonDecode(data);
                        final choices = json['choices'] as List?;
                        final delta =
                            choices != null && choices.isNotEmpty
                                ? choices.first['delta'] as Map<String, dynamic>?
                                : null;
                        if (delta != null && delta['content'] != null) {
                          final summaryChunk = Chunk(
                            id: json['id'] as String? ?? '',
                            object: json['object'] as String? ?? '',
                            created: json['created'] as int? ?? 0,
                            model: json['model'] as String? ?? '',
                            choices: [
                              ChunkChoice(
                                index: 0,
                                delta: OpenAIDelta(
                                  content: delta['content'] as String,
                                ),
                                finishReason: null,
                              ),
                            ],
                          );
                          controller.add(summaryChunk.toIntList());
                          contentBuffer.write(delta['content']);
                        }
                      } catch (_) {}
                    }
                  }
                }
              } finally {
                summaryClient.close();
              }
            }
          }

          controller.add(utf8.encode('data: [DONE]\n\n'));
        }

        await controller.close();

        debugPrint('🔄 [ToolLoop] 流式请求完成，总内容长度：${contentBuffer.length}');

        // 流结束后，更新本地会话
        _updateSessionAfterStream(
          session: session,
          requestBodyMap: requestBodyMap,
          content: contentBuffer.toString(),
          promptTokens: totalPromptTokens,
          completionTokens: totalCompletionTokens,
          totalTokens: totalTokens,
          generationStartTime: generationStartTime,
          toolCalls: null,
          reasoningTokens: totalReasoningTokens,
          cachedTokens: totalCachedTokens,
        );

        // 审计回调：补入返回内容
        auditCallback?.call(
          responseContent: contentBuffer.toString(),
          promptTokens: totalPromptTokens,
          completionTokens: totalCompletionTokens,
          totalTokens: totalTokens,
          reasoningTokens: totalReasoningTokens,
          cachedTokens: totalCachedTokens,
          toolCallResults: toolCallResults,
        );
      } catch (e) {
        debugPrint('❌ 流式代理错误: $e');
        controller.addError(e);
        await controller.close();

        // 审计回调：记录流式异常（请求审计已在 modelToolGuard 中完成）
        auditCallback?.call(error: 'Stream proxy error: $e');
      }
    }();

    return Response(
      200,
      body: controller.stream,
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
    int? reasoningTokens,
    int? cachedTokens,
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

  /// 打印累积的工具调用清单
  static void _printToolCalls(List<ToolCall> toolCalls) {
    if (toolCalls.isNotEmpty) {
      final toolList = toolCalls
          .asMap()
          .entries
          .map(
            (e) =>
                '  [${e.key}] id=${e.value.id}, '
                'type=${e.value.type}, '
                'name=${e.value.function?.name}, '
                'args=${e.value.function?.arguments}',
          )
          .join('\n');
      debugPrint('🛠 [ToolCalls] 收到 ${toolCalls.length} 个工具调用:\n$toolList');
    } else {
      debugPrint('🛠 [ToolCalls] 无工具调用');
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
  final List<ToolCall> sessionToolCalls;
  final List<Chunk> toolCallChunks;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? reasoningTokens;
  final int? cachedTokens;
  final bool error;

  const _StreamRoundResult({
    this.sessionToolCalls = const [],
    this.toolCallChunks = const [],
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.reasoningTokens,
    this.cachedTokens,
    this.error = false,
  });
}

/// 执行一轮 LLM 流式请求，解析 SSE 并累积 content 与 tool_calls
///
/// 将 SSE chunk 透传给 [controller]，同时：
/// - 将文本内容追加到 [contentBuffer]
/// - 按 index 累积 tool_calls 增量
/// - 提取 usage 信息
Future<_StreamRoundResult> _streamSingleRound({
  required ChatSession session,
  required String requestJson,
  required StreamController<List<int>> controller,
  required StringBuffer contentBuffer,
}) async {
  final uri = Uri.parse(session.chatModel!.apiUrl!);
  final client = HttpClient();

  try {
    final httpRequest = await client.postUrl(uri);
    httpRequest.headers.contentType = ContentType.json;
    if (session.chatModel!.apiKey != null &&
        session.chatModel!.apiKey!.isNotEmpty) {
      httpRequest.headers.set(
        'Authorization',
        'Bearer ${session.chatModel!.apiKey}',
      );
    }
    httpRequest.write(requestJson);
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
      return const _StreamRoundResult(error: true);
    }

    // SSE 解析状态
    int? promptTokens;
    int? completionTokens;
    int? totalTokens;
    int? reasoningTokens;
    int? cachedTokens;

    final Map<int, ToolCall> toolCallAccum = {};

    await for (final chunk in response) {
      final raw = utf8.decode(chunk, allowMalformed: true);
      debugPrint('chunk: $raw');

      final trimmed = raw.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final dataStr = trimmed.substring(6);
      if (dataStr == '[DONE]') continue;

      try {
        final sseChunk = Chunk.fromIntList(chunk);
        final choice =
            sseChunk.choices.isNotEmpty ? sseChunk.choices.first : null;
        final delta = choice?.delta;

        // content → 透传并累积
        if (delta?.content != null || delta?.reasoningContent != null) {
          controller.add(sseChunk.toIntList());
          contentBuffer.write(delta!.content);
        }

        // tool_calls → 按 index 累加合并（不透传）
        if (delta?.toolCalls != null) {
          for (final tc in delta!.toolCalls!) {
            final idx = tc.index ?? 0;
            final existing = toolCallAccum[idx];
            toolCallAccum[idx] =
                existing == null
                    ? tc
                    : ToolCall(
                      index: idx,
                      id: tc.id ?? existing.id,
                      type: tc.type ?? existing.type,
                      function: ToolCallFunction(
                        name: tc.function?.name ?? existing.function?.name,
                        arguments:
                            (existing.function?.arguments ?? '') +
                            (tc.function?.arguments ?? ''),
                      ),
                    );
          }
        }

        // usage 信息
        final usage = sseChunk.usage;
        if (usage != null) {
          promptTokens = usage.promptTokens;
          completionTokens = usage.completionTokens;
          totalTokens = usage.totalTokens;
          reasoningTokens = usage.completionTokensDetails?.reasoningTokens;
          cachedTokens = usage.promptTokensDetails?.cachedTokens;
        }
      } catch (_) {
        // 忽略解析失败的行
      }
    }

    //
    // 累加完成，直接获取工具调用列表，并与会话 MCP 工具比对分类
    final extractedToolCalls = toolCallAccum.values.toList();
    LocalHttpService._printToolCalls(extractedToolCalls);
    final (
      session: sessionTools,
      thirdParty: thirdPartyTools,
    ) = LocalHttpService._classifyToolCalls(session, extractedToolCalls);

    // 将第三方工具重建为 Chunk 列表（用于透传给客户端）
    final thirdPartyChunks =
        thirdPartyTools.map((tc) {
          return Chunk(
            id: '',
            object: 'chat.completion.chunk',
            created: 0,
            model: '',
            choices: [
              ChunkChoice(
                index: tc.index ?? 0,
                delta: OpenAIDelta(toolCalls: [tc]),
                finishReason: 'tool_calls',
              ),
            ],
          );
        }).toList();

    return _StreamRoundResult(
      sessionToolCalls: sessionTools,
      toolCallChunks: thirdPartyChunks,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      reasoningTokens: reasoningTokens,
      cachedTokens: cachedTokens,
    );
  } finally {
    client.close();
  }
}
