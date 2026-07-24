import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart' as cors;

import '../../controllers/settings_controller.dart';
import '../../controllers/audit_controller.dart';
import '../../controllers/usage_controller.dart';
import '../../services/storage_paths.dart';
import '../../models/chat/session.dart';
import '../../models/audit_trace.dart';
import 'middleware/api_key_guard.dart';
import 'middleware/disabled_guard.dart';
import 'middleware/quota_guard.dart';
import 'middleware/model_tool_guard.dart';
import 'middleware/risk_control_guard.dart';
import 'sensitive_masker.dart';
import 'stream_round.dart' show streamSingleRound;
import '../../controllers/mcp_controller.dart';
import '../../models/responses/chunk.dart';

/// HTTP 服务控制器
class LocalHttpServiceController extends GetxController {
  final isRunning = false.obs;
  final port = 80.obs;

  @override
  void onInit() {
    super.onInit();
    _syncPortFromDomain();
  }

  void _syncPortFromDomain() {
    try {
      final domainController = Get.find<SettingsController>();
      port.value = domainController.httpPort.value;
    } catch (_) {}
  }

  Future<void> toggleService() async {
    if (isRunning.value) {
      LocalHttpService.stop();
      isRunning.value = false;
    } else {
      _syncPortFromDomain();
      final ok = await LocalHttpService.start(port: port.value);
      isRunning.value = ok;
    }
  }

  /// 重启服务（先停止再启动，重新加载证书配置）
  Future<void> restart() async {
    if (isRunning.value) {
      LocalHttpService.stop();
      // 短暂等待端口释放
      await Future.delayed(const Duration(milliseconds: 300));
    }
    _syncPortFromDomain();
    final ok = await LocalHttpService.start(port: port.value);
    isRunning.value = ok;
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
  static int _port = 80;
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

  /// 启动本地 HTTP/HTTPS 服务。
  ///
  /// 返回是否启动成功。端口被占用（`Address already in use`）等错误不会抛出，
  /// 仅记录日志并返回 `false`，避免拖垮应用启动或热重启。
  static Future<bool> start({int port = 80, bool allowExternal = true}) async {
    // 先停止旧服务，避免端口被占用
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    _isHttps = false;

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
      debugPrint('📡 API: POST /{sessionId}/chat/completions');
      debugPrint('📡 API: GET /{sessionId}/models');
      return true;
    } on SocketException catch (e) {
      debugPrint('❌ HTTP 服务启动失败：端口 $port 已被占用（可能有另一个实例在运行）: $e');
      _isRunning = false;
      return false;
    } catch (e) {
      debugPrint('❌ HTTP 服务启动失败: $e');
      _isRunning = false;
      return false;
    }
  }

  /// 加载 HTTPS 安全上下文（从域名配置中获取证书）
  static SecurityContext? _loadSecurityContext() {
    try {
      final domainController = Get.find<SettingsController>();
      if (!domainController.httpsEnabled.value) return null;

      final certPath = domainController.certPath.value;
      final keyPath = domainController.keyPath.value;
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

    // 模型列表路由（返回当前会话绑定的模型，兼容 OpenAI /v1/models 格式）
    router.get('/<segment>/models', (Request request, String sessionId) async {
      final pipeline = const Pipeline()
          .addMiddleware(apiKeyGuard) // API Key 校验，装载 session
          .addMiddleware(disabledGuard); // 禁用状态检查

      return pipeline.addHandler((Request req) {
        return _handleModelsList(req);
      })(request);
    });

    // Chat Completion 路由（内联中间件链）
    router.post('/<segment>/chat/completions', (
      Request request,
      String sessionId,
    ) async {
      // 读取原始请求体（中间件处理前的原始请求，用于日志保存）
      String originBodyStr = '';
      try {
        originBodyStr = await request.readAsString();
      } catch (e) {
        debugPrint('⚠️ 读取原始请求体失败: $e');
      }

      final requestWithId = request.change(
        context: {...request.context, 'originBody': originBodyStr},
        body: utf8.encode(originBodyStr),
      );

      // 构建中间件管道（洋葱模型）：
      // 请求进入：apiKey → quota → modelTool → audit → 业务处理
      // 响应返回：业务处理（直接审计） → audit → modelTool → quota → apiKey
      final pipeline = const Pipeline()
          .addMiddleware(apiKeyGuard) //api判断,装载session
          .addMiddleware(disabledGuard) //禁用状态检查
          .addMiddleware(quotaGuard) //配额判断
          .addMiddleware(modelToolGuard) //模型工具判断，装载body
          .addMiddleware(riskControlGuard); //风控脱敏：手机号/身份证号等*

      return pipeline.addHandler((Request req) {
        return _handleChatCompletion(req);
      })(requestWithId);
    });

    return router;
  }

  /// 返回当前会话绑定的模型（OpenAI /v1/models 兼容格式）
  static Response _handleModelsList(Request request) {
    try {
      final session = request.context['session'] as ChatSession?;
      if (session == null) {
        return Response(
          400,
          body: jsonEncode({
            'error': {
              'message': 'Session not found',
              'type': 'invalid_request_error',
              'code': 400,
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final data = <Map<String, dynamic>>[
        {'id': 'auto', 'object': 'model', 'created': 0, 'owned_by': 'llmate'},
      ];

      return Response.ok(
        jsonEncode({'object': 'list', 'data': data}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ 获取模型列表失败: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'error': {
            'message': 'Failed to retrieve model list',
            'type': 'api_error',
            'code': 500,
          },
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// 处理 Chat Completion 请求（流式透传）
  ///
  /// 前置条件（由中间件保证）：
  /// - API Key 已校验通过
  /// - 会话已找到且模型已配置
  /// - 配额未超限
  /// - request.context['session'] 包含有效的 ChatSession
  /// - request.context['body'] 包含已注入 model/tools 的请求体
  ///
  /// 后置任务（本服务只做审计与统计，不创建/持久化任何消息）：
  /// - 审计链路追踪（prompt / llmRequest / llmResponse / tool / response / error）
  /// - 写入用量统计（token / 费用明细，由 UsageController 持久化）
  /// - 覆盖写入最近一次请求/响应到 log/log.json
  ///
  /// 消息的创建与落盘由调用方（聊天窗口或外部客户端）自行负责。
  ///
  /// 支持工具调用循环：LLM 返回 tool_calls → 执行 MCP 工具 → 结果回填 →
  /// 继续调用 LLM，直到无工具调用（最多 20 轮）。
  static Future<Response> _handleChatCompletion(Request request) async {
    try {
      // ──────────────────────────────────────────
      // 1. 初始化：创建流控制器，提取上下文数据
      // ──────────────────────────────────────────

      // SSE 流控制器：后续异步 IIFE 中逐步写入 chunk，shelf 框架从 stream 读取并发送给客户端
      final streamController = StreamController<List<int>>(sync: true);
      // 从中间件注入的 context 中提取会话和增强后的请求体
      final session = request.context['session'] as ChatSession;
      final body = request.context['body'] as Map<String, dynamic>;

      // 客户端断开时取消后端请求
      bool cancelStream = false;
      streamController.onCancel = () {
        cancelStream = true;
        debugPrint('🛑 [StreamProxy] 客户端断开连接，取消后端请求');
      };

      // ──────────────────────────────────────────
      // 2. 异步 IIFE：发起 LLM 请求 + 工具调用循环
      //    不 await，立即返回 Response，流内容异步写入
      // ──────────────────────────────────────────
      () async {
        // 记录生成开始时间，用于计算耗时
        final generationStartTime = DateTime.now();

        // ── 审计：开启链路追踪，记录本次请求 ──
        final audit = AuditController.instance;
        AuditTrace? auditTrace;
        final auditProvider = session.chatModel?.platform ?? 'unknown';
        final auditModel = session.chatModel?.model ?? 'unknown';
        try {
          auditTrace = await audit.beginTrace(sessionId: session.sessionId);
          audit.prompt(auditTrace, _extractUserPrompt(body));
        } catch (e) {
          debugPrint('⚠️ [Audit] 开启链路追踪失败: $e');
        }

        try {
          // ── 工具调用循环状态 ──
          final contentBuffer = StringBuffer(); // 累积所有轮次的 LLM 文本回复
          final reasonBuffer = StringBuffer();
          int promptTokens = 0;
          int completionTokens = 0;

          int toolIteration = 0; // 当前工具调用轮次
          const maxToolIterations = 20; // 防止无限循环

          // ── 工具调用循环 ──
          // 每一轮：请求 LLM → 解析响应 → 如果有 MCP 工具调用则执行 → 结果回填 → 继续下一轮
          while (true) {
            // ── 审计：LLM 请求开始 ──
            if (auditTrace != null) {
              audit.llmRequest(auditTrace, auditProvider, auditModel);
            }

            // 单轮流式请求：post LLM API，解析 SSE chunk
            final round = await streamSingleRound(
              session: session,
              body: jsonEncode(body),
              controller: streamController,
            );
            final sessionTools = round.sessionToolChunks;
            final thirdTools = round.thirdToolChunks;
            final hasError = round.error;

            contentBuffer.write(round.contentBuffer);
            reasonBuffer.write(round.reasonBuffer);
            promptTokens += round.promptTokens!;
            completionTokens += round.completionTokens!;

            // ── 审计：LLM 响应完成 ──
            if (auditTrace != null) {
              var roundCost = 0.0;
              final m = session.chatModel;
              final promptPrice = m?.promptPrice;
              final completionPrice = m?.completionPrice;
              if (promptPrice != null) {
                roundCost +=
                    (round.promptTokens ?? 0) * promptPrice / 1000000.0;
              }
              if (completionPrice != null) {
                roundCost +=
                    (round.completionTokens ?? 0) * completionPrice / 1000000.0;
              }
              audit.llmResponse(
                auditTrace,
                round.promptTokens ?? 0,
                round.completionTokens ?? 0,
                roundCost,
              );
            }

            // LLM 返回错误 或 客户端断开 → 退出循环
            if (hasError || cancelStream) break;

            // 第三方工具 chunk 直接透传给客户端（客户端自行解析执行）
            if (thirdTools.isNotEmpty) {
              debugPrint(
                '📤 [ToolLoop] 透传 ${thirdTools.length} 个第三方工具 chunk 给客户端',
              );
              for (final c in thirdTools) {
                streamController.add(c.toIntList());
              }
            }

            // 无会话工具（MCP）调用 → LLM 正常回复完毕，退出循环
            if (sessionTools.isEmpty) break;

            // 达到最大轮次 → 强制退出，防止死循环
            toolIteration++;
            if (toolIteration >= maxToolIterations) {
              debugPrint('⚠️ [ToolLoop] 工具调用已达最大轮次 $maxToolIterations');
              break;
            }

            for (final c in sessionTools) {
              debugPrint('[ToolLoop] 第 $toolIteration 轮，执行工具: ${c.toString()}');
            }

            // ── 提取工具调用参数 ──
            // 从累积的 Chunk 中解析 tool_calls：name、arguments、id、index
            final toolCallParams =
                sessionTools.map((chunk) {
                  final tc =
                      chunk.choices
                          .expand((c) => c.delta?.toolCalls ?? [])
                          .firstOrNull;
                  final argsStr = tc?.function?.arguments ?? '{}';
                  Map<String, dynamic> args;
                  try {
                    args = jsonDecode(argsStr) as Map<String, dynamic>;
                  } catch (_) {
                    // arguments 可能不是合法 JSON（如纯文本），用 raw 兜底
                    args = {'raw': argsStr};
                  }
                  return {
                    'name': tc?.function?.name ?? '',
                    'arguments': args,
                    'id': tc?.id,
                    'index': tc?.index,
                  };
                }).toList();

            // 通知客户端：工具正在执行
            streamController.add(Chunk.fromReason("大模型正在执行MCP服务").toIntList());

            // ── 审计：工具调用开始 ──
            if (auditTrace != null) {
              for (final tc in toolCallParams) {
                audit.toolStart(
                  auditTrace,
                  tc['name']?.toString() ?? 'unknown',
                );
              }
            }

            // ── 执行 MCP 工具 ──
            final executionResult = await McpController.instance
                .executeToolCalls(
                  session: session,
                  toolCalls: toolCallParams,
                  cleanContent: '',
                );

            if (executionResult != null &&
                executionResult.executionResults.isNotEmpty) {
              // 回填 assistant 消息（含 tool_calls）到对话历史
              // 符合 OpenAI Chat Completions 协议：tool 消息必须紧跟 assistant(tool_calls)
              (body['messages'] as List<dynamic>).add({
                'role': 'assistant',
                'content': null,
                'tool_calls':
                    toolCallParams.map((tc) {
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

              // 回填 tool 结果消息到对话历史（每个工具一条）
              for (final r in executionResult.executionResults) {
                final rawResult = r['result']?.toString() ?? '';
                // 风控脱敏：工具返回内容同样可能含手机号/身份证号等敏感信息，
                // 沿用与转发大模型一致的脱敏开关
                final maskedResult = maskSensitiveText(
                  rawResult,
                  riskControlOptionsOf(request),
                );
                (body['messages'] as List<dynamic>).add({
                  'role': 'tool',
                  'tool_call_id': r['id'],
                  'content':
                      r['isError'] == true ? '错误: $maskedResult' : maskedResult,
                });
              }

              // ── 审计：工具调用完成 ──
              if (auditTrace != null) {
                final results = executionResult.executionResults;
                for (var i = 0; i < toolCallParams.length; i++) {
                  final name =
                      toolCallParams[i]['name']?.toString() ?? 'unknown';
                  final res = i < results.length ? results[i] : null;
                  audit.toolFinish(
                    auditTrace,
                    name,
                    res ?? <String, dynamic>{},
                  );
                }
              }

              debugPrint('🔄 [ToolLoop] 第 $toolIteration 轮工具完成，继续请求 LLM');
              // 下一轮循环：带着更新后的 body（含工具调用历史和结果）再次请求 LLM
              // 执行过程中客户端可能断开
              if (cancelStream) break;
            } else {
              break;
            }
            // 工具执行无结果（所有工具都匹配失败等） → 退出循环
          }

          // ── 审计：响应完成并结束链路 ──
          if (auditTrace != null) {
            audit.response(auditTrace, contentBuffer.toString());
            audit.endTrace(auditTrace);
          }

          // ── 流结束：发送 DONE 标记，关闭控制器 ──
          streamController.add(utf8.encode('data: [DONE]\n\n'));
          await streamController.close();

          debugPrint('🔄 [ToolLoop] 流式请求完成，总内容长度：${contentBuffer.length}');

          // ── 用量统计：仅记录 token / 费用明细，不创建任何消息 ──
          final totalTokens = promptTokens + completionTokens;

          debugPrint(
            '✅ 流式完成: ${session.sessionId}, '
            'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
          );

          // ── 保存最新一次请求/响应到 log/log.json（覆盖写入）──
          await _saveLatestLog(
            request: request,
            sessionId: session.sessionId,
            modelId: session.chatModel?.modelId ?? 'unknown',
            originBody: request.context['originBody'] as String? ?? '',
            body: body,
            responseContent: contentBuffer.toString(),
            error: null,
          );

          // ── 保存按分钟累计的用量统计 ──
          _saveUsageStats(
            session: session,
            startTime: generationStartTime,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
          );
        } catch (e) {
          // ── 异步 IIFE 内部异常 ──
          debugPrint('❌ 流式代理错误: $e');

          // 即使出错也记录审计错误并结束链路
          if (auditTrace != null) {
            audit.error(auditTrace, e.toString());
            audit.endTrace(auditTrace);
          }

          // ── 即使出错也保存最新一次请求/响应到 log/log.json（覆盖写入）──
          await _saveLatestLog(
            request: request,
            sessionId: session.sessionId,
            modelId: session.chatModel?.modelId ?? 'unknown',
            originBody: request.context['originBody'] as String? ?? '',
            body: body,
            responseContent: '',
            error: e.toString(),
          );

          streamController.addError(e);
          await streamController.close();
        }
      }(); // ← 立即执行，不 await

      // ──────────────────────────────────────────
      // 3. 立即返回 SSE 流式响应给 shelf
      //    异步 IIFE 中的内容会逐步写入 streamController.stream
      // ──────────────────────────────────────────
      return Response(
        200,
        body: streamController.stream,
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
          'connection': 'keep-alive',
        },
      );
    } catch (e) {
      // ── 同步异常（如 StreamController 构造失败）──
      // 此时流还未建立，直接返回 500，不经过 sessionGuard
      debugPrint('❌ 请求处理失败: $e');

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

  /// 保存用量统计（写入用量数据库 `~/.llmate/usages.db`）
  ///
  /// 由 [UsageController] 负责持久化，按次记录 token 与费用明细；
  /// 看板所需的分/时/日/月/年聚合视图在读取时由 [UsageLoader] 实时计算。
  static void _saveUsageStats({
    required ChatSession session,
    required DateTime startTime,
    required int promptTokens,
    required int completionTokens,
  }) {
    () async {
      try {
        final sessionId = session.sessionId;
        final model = session.chatModel;
        final modelId = model?.modelId ?? 'unknown';
        final currency = model?.currency ?? 'USD';

        // 计算本次请求费用
        double requestCost = 0.0;
        if (model?.promptPrice != null) {
          requestCost += promptTokens * model!.promptPrice! / 1000000.0;
        }
        if (model?.completionPrice != null) {
          requestCost += completionTokens * model!.completionPrice! / 1000000.0;
        }

        await UsageController.instance.recordUsage(
          sessionId: sessionId,
          modelId: modelId,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          cost: requestCost,
          currency: currency,
          timestamp: startTime,
        );
      } catch (e) {
        debugPrint('⚠️ [Usage] 保存用量统计失败: $e');
      }
    }();
  }

  /// 保存最新一次请求/响应的「实时日志」到 `~/.llmate/log/log.json`
  ///
  /// 每次新请求都会**覆盖写入**该文件（非追加），便于随时打开查看最近一次交互的
  /// 请求报文（客户端原始 body + 实际发往 LLM 的 body）与返回报文（响应内容）。
  static Future<void> _saveLatestLog({
    required Request request,
    required String sessionId,
    required String modelId,
    required String originBody,
    required Map<String, dynamic> body,
    required String responseContent,
    String? error,
  }) async {
    try {
      final logDir = Directory('${StoragePaths.root}/log');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final log = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'sessionId': sessionId,
        'modelId': modelId,
        'method': request.method,
        'uri': request.requestedUri.toString(),
        'originBody': originBody,
        'sentBody': body,
        'response': responseContent,
        if (error != null) 'error': error,
      };
      final file = File('${logDir.path}/log.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(log));
    } catch (e) {
      debugPrint('⚠️ [Log] 保存实时日志失败: $e');
    }
  }
}

/// 从请求体 messages 中提取最近一条 user 消息的文本内容（供审计 prompt 记录）
String _extractUserPrompt(Map<String, dynamic> body) {
  final msgs = body['messages'];
  if (msgs is! List) return '';
  for (var i = msgs.length - 1; i >= 0; i--) {
    final m = msgs[i];
    if (m is Map && m['role'] == 'user') {
      final c = m['content'];
      if (c is String) return c;
      if (c is List) {
        final sb = StringBuffer();
        for (final part in c) {
          if (part is Map && part['type'] == 'text') sb.write(part['text']);
        }
        return sb.toString();
      }
    }
  }
  return '';
}
