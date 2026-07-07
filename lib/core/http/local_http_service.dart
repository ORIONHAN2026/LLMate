import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import '../mcp/mcp_service.dart';
import '../llm/modes/mode_utils.dart';
import 'middleware/api_key_guard.dart';
import 'middleware/quota_guard.dart';
import 'middleware/audit_guard.dart';

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
        _server = await io.serve(handler, address, port, securityContext: securityContext);
        _isHttps = true;
        debugPrint(
          '🚀 HTTPS 服务已启动: https://$_bindAddress:$port',
        );
      } else {
        _server = await io.serve(handler, address, port);
        _isHttps = false;
        debugPrint(
          '🚀 HTTP 服务已启动: http://$_bindAddress:$port',
        );
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
      // 构建中间件管道：API Key 校验 → 配额检查 → 审计记录 → 业务处理
      final pipeline = const Pipeline()
          .addMiddleware(apiKeyGuard)
          .addMiddleware(quotaGuard)
          .addMiddleware(auditGuard);

      return pipeline.addHandler((Request req) {
        return _handleChatCompletion(req, sessionId);
      })(request);
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
  ///
  /// 当会话配置了 MCP 时，会自动在请求中注入 tools，并在服务端完成
  /// MCP 工具调用的完整循环（LLM → tool_call → MCP 执行 → LLM 继续）。
  static Future<Response> _handleChatCompletion(
    Request request,
    String sessionId,
  ) async {
    // 获取审计回调（由 auditGuard 中间件注入）
    final auditCallback = request.context['auditCallback'] as AuditCallback?;

    try {
      // 从中间件 context 获取已校验的会话
      final session = request.context['session'] as ChatSession;

      final body = await request.readAsString();
      debugPrint(
        '📨 请求体: $sessionId, ${body.substring(0, body.length.clamp(0, 100))}...',
      );

      final requestBodyMap = jsonDecode(body) as Map<String, dynamic>;
      // 使用对话模型
      requestBodyMap['model'] = session.chatModel!.model;

      final isStream = requestBodyMap['stream'] == true;

      // 检查是否需要 MCP 工具调用
      final hasMcp = session.mcp != null && session.mcp!.tools != null && session.mcp!.tools!.isNotEmpty;

      if (isStream) {
        return _streamProxyResponse(session, requestBodyMap,
            auditCallback: auditCallback, hasMcp: hasMcp);
      } else {
        return await _handleNonStreamWithMcp(
          session, requestBodyMap, auditCallback: auditCallback, hasMcp: hasMcp);
      }
    } catch (e) {
      debugPrint('❌ 请求处理失败: $e');

      // 审计回调：记录错误
      auditCallback?.call(error: '$e');

      return Response.internalServerError(
        body: jsonEncode({
          'error': {
            'message': 'Internal error: $e',
            'type': 'api_error',
            'code': 500,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// 非流式处理（含 MCP tool-calling 循环）
  static Future<Response> _handleNonStreamWithMcp(
    ChatSession session,
    Map<String, dynamic> requestBodyMap, {
    AuditCallback? auditCallback,
    bool hasMcp = false,
  }) async {
    if (!hasMcp) {
      // 无 MCP：直接透传
      final responseBody = await _proxyToLLM(session, requestBodyMap);

      Map<String, dynamic>? llmResponse;
      String? content;
      int? promptTokens, completionTokens, totalTokens;
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
      );

      return Response.ok(
        responseBody,
        headers: {'content-type': 'application/json'},
      );
    }

    // 有 MCP：注入 tools 并执行 tool-calling 循环
    return _executeMcpToolCallingLoop(
      session, requestBodyMap,
      auditCallback: auditCallback,
    );
  }

  /// MCP Tool-Calling 循环（非流式）
  ///
  /// 流程：
  /// 1. 在请求中注入 MCP tools
  /// 2. 发送请求到 LLM
  /// 3. 如果 LLM 返回 tool_calls → 服务端执行 MCP 工具 → 将结果追加到 messages
  /// 4. 继续请求 LLM，直到 LLM 返回纯文本响应
  /// 5. 将最终结果返回给客户端
  static Future<Response> _executeMcpToolCallingLoop(
    ChatSession session,
    Map<String, dynamic> originalRequestBody, {
    AuditCallback? auditCallback,
    int maxIterations = 10,
  }) async {
    // 深拷贝请求体，避免修改原始数据
    final body = Map<String, dynamic>.from(originalRequestBody);
    final messages = List<Map<String, dynamic>>.from(
      (body['messages'] as List?)?.map((m) => Map<String, dynamic>.from(m)) ?? [],
    );

    // 构建 MCP tools 并注入
    final tools = buildMcpTools(session);
    if (tools.isNotEmpty) {
      body['tools'] = tools;
      body['tool_choice'] = 'auto';
    }

    // 确保 MCP 客户端已初始化
    if (session.mcp != null) {
      try {
        await McpService.ensureGlobalConfigsLoaded();
        await McpService.initializeSessionMcpServices(session);
      } catch (e) {
        debugPrint('⚠️ MCP 初始化失败（继续无工具模式）: $e');
      }
    }

    int totalPromptTokens = 0;
    int totalCompletionTokens = 0;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      body['messages'] = messages;
      body['stream'] = false;

      debugPrint('🔄 [MCP-Loop] 第 ${iteration + 1} 轮 LLM 请求, 消息数: ${messages.length}');

      final responseBody = await _proxyToLLM(session, body);
      Map<String, dynamic> llmResponse;
      try {
        llmResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('❌ [MCP-Loop] 解析 LLM 响应失败: $e');
        return Response.ok(
          responseBody,
          headers: {'content-type': 'application/json'},
        );
      }

      // 累积 token 用量
      final usage = llmResponse['usage'] as Map<String, dynamic>?;
      if (usage != null) {
        totalPromptTokens += (usage['prompt_tokens'] as int?) ?? 0;
        totalCompletionTokens += (usage['completion_tokens'] as int?) ?? 0;
      }

      final choices = llmResponse['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        debugPrint('⚠️ [MCP-Loop] LLM 响应无 choices');
        return Response.ok(
          responseBody,
          headers: {'content-type': 'application/json'},
        );
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      if (message == null) {
        debugPrint('⚠️ [MCP-Loop] LLM 响应无 message');
        return Response.ok(
          responseBody,
          headers: {'content-type': 'application/json'},
        );
      }

      final toolCalls = message['tool_calls'] as List?;
      final content = message['content'] as String?;

      // 没有工具调用 → 返回最终结果
      if (toolCalls == null || toolCalls.isEmpty) {
        debugPrint('✅ [MCP-Loop] 第 ${iteration + 1} 轮: 获得最终文本响应');

        // 更新 llmResponse 的 usage 为累计值
        llmResponse['usage'] = {
          'prompt_tokens': totalPromptTokens,
          'completion_tokens': totalCompletionTokens,
          'total_tokens': totalPromptTokens + totalCompletionTokens,
        };

        final finalResponse = jsonEncode(llmResponse);

        // 记录请求 & 更新会话
        final sessionController = Get.find<SessionController>();
        final updatedSession = session.recordRequest();
        sessionController.updateSession(updatedSession);

        auditCallback?.call(
          rawResponse: llmResponse,
          responseContent: content,
          promptTokens: totalPromptTokens,
          completionTokens: totalCompletionTokens,
          totalTokens: totalPromptTokens + totalCompletionTokens,
        );

        return Response.ok(
          finalResponse,
          headers: {'content-type': 'application/json'},
        );
      }

      // 有工具调用 → 服务端执行 MCP 工具
      debugPrint('🔧 [MCP-Loop] 第 ${iteration + 1} 轮: LLM 请求调用 ${toolCalls.length} 个工具');

      // 添加 assistant 消息（含 tool_calls）到 messages
      messages.add({
        'role': 'assistant',
        'content': content,
        'tool_calls': toolCalls,
      });

      // 逐个执行工具调用
      for (final tc in toolCalls) {
        final tcMap = tc as Map<String, dynamic>;
        final tcId = tcMap['id'] as String? ?? '';
        final func = tcMap['function'] as Map<String, dynamic>?;
        final toolName = func?['name'] as String? ?? '';
        Map<String, dynamic> toolArgs;
        try {
          final rawArgs = func?['arguments'];
          toolArgs = rawArgs is String
              ? (jsonDecode(rawArgs) as Map<String, dynamic>)
              : (rawArgs as Map<String, dynamic>?) ?? {};
        } catch (_) {
          toolArgs = {};
        }

        String toolResult;
        try {
          // 通过 McpService 执行工具
          final mcpClient = McpService.getMCPClient(session.mcp!.mcpId);
          if (mcpClient != null) {
            final result = await mcpClient.callTool(toolName, toolArgs);
            final buf = StringBuffer();
            for (final c in result.content) {
              try {
                buf.writeln((c as dynamic).text);
              } catch (_) {
                buf.writeln(c.toString());
              }
            }
            toolResult = buf.toString().trim();
            if (result.isError == true) {
              toolResult = '错误: $toolResult';
            }
            debugPrint('  ✅ 工具 "$toolName" 执行成功');
          } else {
            toolResult = 'MCP 客户端未初始化，无法执行工具';
            debugPrint('  ❌ 工具 "$toolName": MCP 客户端未初始化');
          }
        } catch (e) {
          toolResult = '工具执行异常: $e';
          debugPrint('  ❌ 工具 "$toolName" 执行异常: $e');
        }

        // 添加 tool 结果消息
        messages.add({
          'role': 'tool',
          'tool_call_id': tcId,
          'content': toolResult,
        });
      }
    }

    // 超过最大迭代次数
    debugPrint('⚠️ [MCP-Loop] 超过最大迭代次数 ($maxIterations)，返回错误');
    return Response.internalServerError(
      body: jsonEncode({
        'error': {
          'message': 'MCP tool-calling loop exceeded max iterations ($maxIterations)',
          'type': 'mcp_loop_error',
          'code': 500,
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// 非流式透传
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

      httpRequest.write(requestBodyMap);

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

  /// 流式透传 - 返回 StreamedResponse，同时解析 SSE 并更新本地会话
  ///
  /// [hasMcp] 是否启用 MCP tool-calling。启用后会在请求中注入 tools，
  /// 并在服务端完成完整的 tool-calling 循环，最终将合并后的文本流返回给客户端。
  static Response _streamProxyResponse(
    ChatSession session,
    Map<String, dynamic> requestBodyMap, {
    AuditCallback? auditCallback,
    bool hasMcp = false,
  }) {
    // 如果启用 MCP，走服务端 tool-calling 循环的流式模式
    if (hasMcp) {
      return _streamWithMcpToolCalling(session, requestBodyMap,
          auditCallback: auditCallback);
    }
    return _streamDirectProxy(session, requestBodyMap, auditCallback: auditCallback);
  }

  /// 直接流式透传（无 MCP）
  static Response _streamDirectProxy(
    ChatSession session,
    Map<String, dynamic> requestBodyMap, {
    AuditCallback? auditCallback,
  }) {
    final controller = StreamController<List<int>>();

    // 异步发起请求并透传 SSE 流
    () async {
      final uri = Uri.parse(session.chatModel!.apiUrl!);
      final client = HttpClient();

      try {
        final httpRequest = await client.postUrl(uri);

        httpRequest.headers.contentType = ContentType.json;

        //更新模式参数
        if (session.chatModel!.apiKey != null &&
            session.chatModel!.apiKey!.isNotEmpty) {
          httpRequest.headers.set(
            'Authorization',
            'Bearer ${session.chatModel!.apiKey}',
          );
        }
        requestBodyMap['model'] = session.chatModel!.model;

        final requestBody = jsonEncode(requestBodyMap);
        httpRequest.write(requestBody);

        final response = await httpRequest.close();

        if (response.statusCode >= 400) {
          final errorBody = await response.transform(utf8.decoder).join();
          debugPrint('❌ LLM 返回错误: ${response.statusCode}\n$errorBody');
          controller.add(
            utf8.encode(
              jsonEncode({
                'error': {
                  'message':
                      'LLM API error: ${response.statusCode} - $errorBody',
                  'code': response.statusCode,
                },
              }),
            ),
          );
          await controller.close();

          // 审计回调：记录流式错误
          auditCallback?.call(error: 'LLM API error: ${response.statusCode}');
          return;
        }

        // SSE 解析状态
        final generationStartTime = DateTime.now();
        final contentBuffer = StringBuffer();
        int? promptTokens;
        int? completionTokens;
        int? totalTokens;
        String sseBuffer = '';

        await for (final chunk in response) {
          // 透传原始数据给客户端
          controller.add(chunk);

          // 解析 SSE 数据提取 content 和 usage
          sseBuffer += utf8.decode(chunk, allowMalformed: true);
          final lines = sseBuffer.split('\n');
          sseBuffer = lines.removeLast(); // 保留不完整的行

          for (final line in lines) {
            final trimmed = line.trim();
            if (!trimmed.startsWith('data: ')) continue;
            final dataStr = trimmed.substring(6);
            if (dataStr == '[DONE]') continue;

            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;

              // 提取 content
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                if (delta != null && delta['content'] != null) {
                  contentBuffer.write(delta['content']);
                }
              }

              // 提取 usage（通常在最后一个 chunk 中）
              final usage = json['usage'] as Map<String, dynamic>?;
              if (usage != null) {
                promptTokens = usage['prompt_tokens'] as int?;
                completionTokens = usage['completion_tokens'] as int?;
                totalTokens = usage['total_tokens'] as int?;
              }
            } catch (_) {
              // 忽略解析失败的行
            }
          }
        }
        await controller.close();

        // 流结束后，更新本地会话
        _updateSessionAfterStream(
          session: session,
          requestBodyMap: requestBodyMap,
          content: contentBuffer.toString(),
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          totalTokens: totalTokens,
          generationStartTime: generationStartTime,
          auditCallback: auditCallback,
        );
      } catch (e) {
        debugPrint('❌ 流式代理错误: $e');
        controller.addError(e);
        await controller.close();

        // 审计回调：记录流式异常
        auditCallback?.call(error: 'Stream proxy error: $e');
      } finally {
        client.close();
      }
    }();

    return Response(
      200,
      body: controller.stream,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
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
    AuditCallback? auditCallback,
  }) {
    try {
      final sessionController = Get.find<SessionController>();
      final now = DateTime.now();

      // 从请求体中提取用户消息内容
      final messages = requestBodyMap['messages'] as List?;
      final lastUserMsg = messages?.lastOrNull as Map<String, dynamic>?;
      final userContent = lastUserMsg?['content'] as String? ?? '';

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

      // 审计回调：流式响应完成后补充实际内容
      auditCallback?.call(
        responseContent: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
      );
    } catch (e) {
      debugPrint('❌ 更新会话失败: $e');

      // 审计回调：记录流式更新失败
      auditCallback?.call(error: 'Session update failed: $e');
    }
  }

  /// 流式 MCP Tool-Calling（服务端完成完整循环后，将最终文本以 SSE 流返回）
  ///
  /// 流程：
  /// 1. 注入 tools 到请求体
  /// 2. 初始化 MCP 客户端
  /// 3. 在服务端完成完整的 tool-calling 循环（非流式 LLM 请求）
  /// 4. 收集所有轮次的文本内容
  /// 5. 将最终合并的文本以 SSE 流格式返回给客户端
  static Response _streamWithMcpToolCalling(
    ChatSession session,
    Map<String, dynamic> originalRequestBody, {
    AuditCallback? auditCallback,
    int maxIterations = 10,
  }) {
    final controller = StreamController<List<int>>();

    () async {
      try {
        // 深拷贝请求体
        final body = Map<String, dynamic>.from(originalRequestBody);
        final messages = List<Map<String, dynamic>>.from(
          (body['messages'] as List?)?.map((m) => Map<String, dynamic>.from(m)) ?? [],
        );

        // 注入 MCP tools
        final tools = buildMcpTools(session);
        if (tools.isNotEmpty) {
          body['tools'] = tools;
          body['tool_choice'] = 'auto';
        }

        // 初始化 MCP 客户端
        if (session.mcp != null) {
          try {
            await McpService.ensureGlobalConfigsLoaded();
            await McpService.initializeSessionMcpServices(session);
          } catch (e) {
            debugPrint('⚠️ [MCP-Stream] MCP 初始化失败（继续无工具模式）: $e');
          }
        }

        final allContentParts = <String>[];
        int totalPromptTokens = 0;
        int totalCompletionTokens = 0;
        final generationStartTime = DateTime.now();

        for (int iteration = 0; iteration < maxIterations; iteration++) {
          body['messages'] = messages;
          body['stream'] = false;

          debugPrint('🔄 [MCP-Stream] 第 ${iteration + 1} 轮 LLM 请求');

          final responseBody = await _proxyToLLM(session, body);
          Map<String, dynamic> llmResponse;
          try {
            llmResponse = jsonDecode(responseBody) as Map<String, dynamic>;
          } catch (e) {
            _sendSseError(controller, '解析 LLM 响应失败: $e');
            return;
          }

          // 累积 token 用量
          final usage = llmResponse['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            totalPromptTokens += (usage['prompt_tokens'] as int?) ?? 0;
            totalCompletionTokens += (usage['completion_tokens'] as int?) ?? 0;
          }

          final choices = llmResponse['choices'] as List?;
          if (choices == null || choices.isEmpty) {
            _sendSseError(controller, 'LLM 响应无 choices');
            return;
          }

          final message = choices[0]['message'] as Map<String, dynamic>?;
          if (message == null) {
            _sendSseError(controller, 'LLM 响应无 message');
            return;
          }

          final toolCalls = message['tool_calls'] as List?;
          final content = message['content'] as String?;

          // 收集文本内容
          if (content != null && content.isNotEmpty) {
            allContentParts.add(content);
          }

          // 没有工具调用 → 循环结束
          if (toolCalls == null || toolCalls.isEmpty) {
            debugPrint('✅ [MCP-Stream] 第 ${iteration + 1} 轮: 获得最终响应');

            final finalContent = allContentParts.join('\n');

            // 将最终内容以 SSE 流格式发送给客户端
            final sseChunk = {
              'id': 'mcp-${DateTime.now().millisecondsSinceEpoch}',
              'object': 'chat.completion.chunk',
              'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'model': session.chatModel!.model,
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': finalContent},
                  'finish_reason': 'stop',
                },
              ],
              'usage': {
                'prompt_tokens': totalPromptTokens,
                'completion_tokens': totalCompletionTokens,
                'total_tokens': totalPromptTokens + totalCompletionTokens,
              },
            };
            controller.add(utf8.encode('data: ${jsonEncode(sseChunk)}\n\n'));
            controller.add(utf8.encode('data: [DONE]\n\n'));
            await controller.close();

            // 更新会话
            _updateSessionAfterMcpStream(
              session: session,
              requestBodyMap: originalRequestBody,
              content: finalContent,
              promptTokens: totalPromptTokens,
              completionTokens: totalCompletionTokens,
              totalTokens: totalPromptTokens + totalCompletionTokens,
              generationStartTime: generationStartTime,
              auditCallback: auditCallback,
            );
            return;
          }

          // 有工具调用 → 服务端执行
          debugPrint('🔧 [MCP-Stream] 第 ${iteration + 1} 轮: LLM 请求调用 ${toolCalls.length} 个工具');

          messages.add({
            'role': 'assistant',
            'content': content,
            'tool_calls': toolCalls,
          });

          for (final tc in toolCalls) {
            final tcMap = tc as Map<String, dynamic>;
            final tcId = tcMap['id'] as String? ?? '';
            final func = tcMap['function'] as Map<String, dynamic>?;
            final toolName = func?['name'] as String? ?? '';
            Map<String, dynamic> toolArgs;
            try {
              final rawArgs = func?['arguments'];
              toolArgs = rawArgs is String
                  ? (jsonDecode(rawArgs) as Map<String, dynamic>)
                  : (rawArgs as Map<String, dynamic>?) ?? {};
            } catch (_) {
              toolArgs = {};
            }

            String toolResult;
            try {
              final mcpClient = McpService.getMCPClient(session.mcp!.mcpId);
              if (mcpClient != null) {
                final result = await mcpClient.callTool(toolName, toolArgs);
                final buf = StringBuffer();
                for (final c in result.content) {
                  try {
                    buf.writeln((c as dynamic).text);
                  } catch (_) {
                    buf.writeln(c.toString());
                  }
                }
                toolResult = buf.toString().trim();
                if (result.isError == true) {
                  toolResult = '错误: $toolResult';
                }
              } else {
                toolResult = 'MCP 客户端未初始化，无法执行工具';
              }
            } catch (e) {
              toolResult = '工具执行异常: $e';
            }

            messages.add({
              'role': 'tool',
              'tool_call_id': tcId,
              'content': toolResult,
            });
          }
        }

        // 超过最大迭代次数
        _sendSseError(controller, 'MCP tool-calling loop exceeded max iterations ($maxIterations)');
      } catch (e) {
        debugPrint('❌ [MCP-Stream] 异常: $e');
        _sendSseError(controller, 'Stream MCP error: $e');
        auditCallback?.call(error: 'Stream MCP error: $e');
      }
    }();

    return Response(
      200,
      body: controller.stream,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
        'connection': 'keep-alive',
      },
    );
  }

  /// 发送 SSE 错误
  static void _sendSseError(StreamController<List<int>> controller, String message) {
    final errorChunk = jsonEncode({
      'error': {
        'message': message,
        'type': 'api_error',
        'code': 500,
      },
    });
    controller.add(utf8.encode('data: $errorChunk\n\n'));
    controller.add(utf8.encode('data: [DONE]\n\n'));
    controller.close();
  }

  /// MCP 流式完成后更新本地会话
  static void _updateSessionAfterMcpStream({
    required ChatSession session,
    required Map<String, dynamic> requestBodyMap,
    required String content,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    required DateTime generationStartTime,
    AuditCallback? auditCallback,
  }) {
    try {
      final sessionController = Get.find<SessionController>();
      final now = DateTime.now();

      final messages = requestBodyMap['messages'] as List?;
      final lastUserMsg = messages?.lastOrNull as Map<String, dynamic>?;
      final userContent = lastUserMsg?['content'] as String? ?? '';

      final userMsgId = '${DateTime.now().millisecondsSinceEpoch}_user';
      final userMessage = ChatMessage(
        msgId: userMsgId,
        role: MessageRole.user,
        content: userContent,
        timestamp: now,
        sessionId: session.sessionId,
      );

      final botMsgId = '${DateTime.now().millisecondsSinceEpoch}_bot';
      final botMessage = ChatMessage(
        msgId: botMsgId,
        role: MessageRole.bot,
        content: content,
        timestamp: now,
        sessionId: session.sessionId,
        pairedMsgId: userMsgId,
        generationStartTime: generationStartTime,
        generationEndTime: now,
        inputTokens: promptTokens,
        outputTokens: completionTokens,
        totalTokens: totalTokens,
        generationDuration: now.difference(generationStartTime),
      );

      final newMessages = [...session.messages, userMessage, botMessage];
      var updatedSession = session.copyWith(messages: newMessages);
      updatedSession = updatedSession.recordRequest();
      sessionController.updateSession(updatedSession);

      debugPrint(
        '✅ [MCP-Stream] 会话已更新: ${session.sessionId}, '
        '用户消息: "${userContent.substring(0, userContent.length.clamp(0, 30))}", '
        'AI回复: "${content.substring(0, content.length.clamp(0, 30))}", '
        'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
      );

      auditCallback?.call(
        responseContent: content,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
      );
    } catch (e) {
      debugPrint('❌ [MCP-Stream] 更新会话失败: $e');
      auditCallback?.call(error: 'Session update failed: $e');
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
