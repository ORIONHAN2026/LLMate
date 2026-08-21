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
import '../../controllers/session_controller.dart';
import '../../controllers/usage_controller.dart';
import '../../controllers/address_detector_controller.dart';
import '../services/storage_paths.dart';
import '../../models/chat/message.dart';
import '../../models/chat/session.dart';
import '../../models/audit.dart';
import 'middleware/session_check_guard.dart';
import 'middleware/model_check_guard.dart';
import 'middleware/language_check_guard.dart';
import 'middleware/risk_control_guard.dart';
import 'middleware/audit_guard.dart';
import 'http_context_keys.dart';
import 'http_response_utils.dart';
import 'sensitive_masker.dart';
import 'stream_round.dart' show streamSingleRound, writeOpenAiError;
import '../router/model_router.dart';
import '../../models/model_price_catalog.dart';
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
    // 与真实服务状态对齐（例如应用启动时服务可能已由 main() 直接启动）
    isRunning.value = LocalHttpService.isRunning;
    if (isRunning.value) {
      port.value = LocalHttpService.port;
    }
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
  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers':
        'Authorization, Content-Type, Accept, Cache-Control, OpenAI-Organization, OpenAI-Project, X-Request-ID, X-Requested-With',
    'Access-Control-Expose-Headers': 'X-Request-ID, X-Trace-ID',
    'Access-Control-Max-Age': '86400',
  };

  static bool get isRunning => _isRunning;
  static bool get isHttps => _isHttps;
  static int get port => _port;

  /// 将真实运行状态同步到 [LocalHttpServiceController]，
  /// 保证 UI 响应式状态（如侧栏状态灯）与真实服务状态一致。
  static void _syncController() {
    if (Get.isRegistered<LocalHttpServiceController>()) {
      final controller = Get.find<LocalHttpServiceController>();
      controller.isRunning.value = _isRunning;
      if (_isRunning) {
        controller.port.value = _port;
      }
    }
  }

  /// 服务启动成功后自动执行一次地址检测（内网 / 外网 IP）。
  ///
  /// 无论服务从哪条路径启动（应用启动 / 手动开关 / 重启），
  /// 都会重新检测并持久化访问地址，使「服务管理」页面的
  /// 地址信息与系统配置保持一致。
  static void _triggerAddressDetect() {
    try {
      final controller =
          Get.isRegistered<AddressDetectorController>()
              ? Get.find<AddressDetectorController>()
              : AddressDetectorController();
      controller.detect(force: true);
    } catch (e) {
      debugPrint('⚠️ [AddressDetect] 服务启动后自动检测地址失败: $e');
    }
  }

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
          .addMiddleware(cors.corsHeaders(headers: _corsHeaders))
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
      _syncController();
      _triggerAddressDetect();
      debugPrint('📡 API: POST /v1/chat/completions');
      debugPrint('📡 API: GET /v1/models');
      debugPrint('📡 兼容会话路径: /{sessionId}/v1/chat/completions');
      return true;
    } on SocketException catch (e) {
      debugPrint('❌ HTTP 服务启动失败：端口 $port 已被占用（可能有另一个实例在运行）: $e');
      _isRunning = false;
      _syncController();
      return false;
    } catch (e) {
      debugPrint('❌ HTTP 服务启动失败: $e');
      _isRunning = false;
      _syncController();
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
    _syncController();
    debugPrint('🛑 HTTP 服务已停止');
  }

  /// 构建 Shelf Router，通过中间件链组装
  static Router _buildRouter() {
    final router = Router();

    // 健康检查（无需中间件）
    router.get('/health', (Request request) {
      return Response.ok(jsonEncode({'status': 'ok'}), headers: jsonHeaders);
    });
    router.options('/health', _handleCorsPreflight);

    // CORS 预检请求不携带业务 API Key，必须在业务中间件前直接放行。
    router.options('/v1/models', _handleCorsPreflight);
    router.options(
      '/<segment>/v1/models',
      (Request request, String _) => _handleCorsPreflight(request),
    );
    router.options('/v1/chat/completions', _handleCorsPreflight);
    router.options(
      '/<segment>/v1/chat/completions',
      (Request request, String _) => _handleCorsPreflight(request),
    );

    // 模型列表路由（对外仅暴露企业统一代理模型 auto，兼容 OpenAI /v1/models 格式）
    // 标准入口通过 API Key 定位会话；/{sessionId}/v1 仅作为旧配置兼容。
    router.get(
      '/v1/models',
      (Request request) => _handleModelsRoute(request, ''),
    );
    router.get('/<segment>/v1/models', _handleModelsRoute);

    // Chat Completion 路由（含 /v1 前缀兼容版本）
    router.post(
      '/v1/chat/completions',
      (Request request) => _handleChatRoute(request, ''),
    );
    router.post('/<segment>/v1/chat/completions', _handleChatRoute);

    return router;
  }

  static Response _handleCorsPreflight(Request request) {
    return Response(204, headers: _corsHeaders);
  }

  /// 模型列表路由处理（含中间件链），
  /// 供 `/v1/models` 与 `/<segment>/v1/models` 共用
  static Future<Response> _handleModelsRoute(
    Request request,
    String sessionId,
  ) async {
    final pipeline = const Pipeline().addMiddleware(
      sessionCheckGuard,
    ); // 会话检查：密钥 / 状态 / 配额

    return pipeline.addHandler((Request req) {
      return _handleModelsList(req);
    })(request);
  }

  /// Chat Completion 路由处理（含中间件链），
  /// 供 `/v1/chat/completions` 与 `/<segment>/v1/chat/completions` 共用
  static Future<Response> _handleChatRoute(
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

    // 保存第三方客户请求的原始内容到 log_request 目录（每个请求一个文件，追加保存）
    await _saveRequestLog(
      request: request,
      sessionId: sessionId.isEmpty ? 'by-api-key' : sessionId,
      originBody: originBodyStr,
    );

    final requestWithId = request.change(
      context: {...request.context, HttpContextKeys.originBody: originBodyStr},
      body: utf8.encode(originBodyStr),
    );

    // 构建中间件管道（洋葱模型）：
    // 请求进入：sessionCheck(密钥/状态/配额/会话提示词/会话MCP工具) → modelCheck(模型配置/替换/模型提示词)
    //          → languageCheck(语言设置/语言要求) → riskControl → 业务处理
    final pipeline = const Pipeline()
        .addMiddleware(sessionCheckGuard) //会话检查：密钥/状态/配额/会话提示词/会话MCP工具
        .addMiddleware(modelCheckGuard) //模型检查：模型配置/模型替换/模型系统提示词
        .addMiddleware(languageCheckGuard) //语言检查：语言设置/语言要求
        .addMiddleware(riskControlGuard); //风控脱敏：手机号/身份证号等*

    return pipeline.addHandler((Request req) {
      return _handleChatCompletion(req);
    })(requestWithId);
  }

  /// 返回当前会话绑定的模型（OpenAI /v1/models 兼容格式）
  static Response _handleModelsList(Request request) {
    try {
      final session = request.context[HttpContextKeys.session] as ChatSession?;
      if (session == null) {
        return openAiErrorResponse(
          statusCode: 400,
          message: 'Session not found',
          type: 'invalid_request_error',
          code: 400,
        );
      }

      final data = <Map<String, dynamic>>[
        {
          'id': session.name,
          'object': 'model',
          'created': 0,
          'owned_by': 'LLMate',
        },
      ];

      return Response.ok(
        jsonEncode({'object': 'list', 'data': data}),
        headers: jsonHeaders,
      );
    } catch (e) {
      debugPrint('❌ 获取模型列表失败: $e');
      return openAiErrorResponse(
        statusCode: 500,
        message: 'Failed to retrieve model list',
        type: 'api_error',
        code: 500,
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
  /// - 审计链路追踪（prompt / model / usage / tool / response / error）
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
      final session = request.context[HttpContextKeys.session] as ChatSession;
      final body =
          request.context[HttpContextKeys.body] as Map<String, dynamic>;
      debugPrint('📨 [Request] body: ${jsonEncode(body["messages"])}');
      // 客户端是否请求流式响应（缺省视为流式）。
      // 编程工具等第三方客户端可能发送 stream: false，此时本服务内部仍按流式
      // 请求上游，待生成完成后将 SSE 聚合为标准 JSON 响应返回。
      final wantStream = body['stream'] != false;
      // 上游 LLM 始终按流式请求（保证 streamSingleRound 能解析 SSE chunk）
      body['stream'] = true;

      // 客户端断开时取消后端请求
      bool cancelStream = false;
      streamController.onCancel = () {
        cancelStream = true;
        debugPrint('🛑 [StreamProxy] 客户端断开连接，取消后端请求');
      };

      // ──────────────────────────────────────────
      // 2. 异步 IIFE：发起 LLM 请求 + 工具调用循环
      //    流式模式下不 await，立即返回 Response，流内容异步写入；
      //    非流式模式下 await 其完成后聚合为 JSON 返回
      // ──────────────────────────────────────────
      final bufferedChunksFuture =
          !wantStream ? streamController.stream.toList() : null;

      final audit = AuditController.instance;
      AuditTrace? auditTrace;
      final auditProvider = session.chatModel?.platform ?? 'unknown';
      final auditModel = session.chatModel?.model ?? 'unknown';
      try {
        auditTrace = await audit.beginTrace(
          sessionId: session.sessionId,
          ip: extractClientIp(request),
        );
        // 记录第三方请求的完整 body（原样存储，便于离线审计排查）
        audit.body(auditTrace, body);
        audit.prompt(auditTrace, _extractUserPrompt(body));
      } catch (e) {
        debugPrint('⚠️ [Audit] 开启链路追踪失败: $e');
      }

      final pipelineFuture = () async {
        // 记录生成开始时间，用于计算耗时
        final generationStartTime = DateTime.now();

        try {
          // ── 工具调用循环状态 ──
          final contentBuffer = StringBuffer(); // 累积所有轮次的 LLM 文本回复
          final reasonBuffer = StringBuffer();
          int promptTokens = 0;
          int completionTokens = 0;
          int cacheWriteTokens = 0;
          int cacheReadTokens = 0;

          int toolIteration = 0; // 当前工具调用轮次
          const maxToolIterations = 20; // 防止无限循环
          bool fallbackTried = false; // 失败回退链：是否已重试过高能力模型
          bool requestFailed = false;
          String? requestError;

          // ── 工具调用循环 ──
          // 每一轮：请求 LLM → 解析响应 → 如果有 MCP 工具调用则执行 → 结果回填 → 继续下一轮
          while (true) {
            // ── 审计：LLM 请求开始（含模型使用决策模式）──
            if (auditTrace != null) {
              final routeDecision =
                  request.context[HttpContextKeys.routeDecision]
                      as RouteDecision?;
              Map<String, dynamic>? auditDecision;
              if (routeDecision != null) {
                final autoSelect = session.autoSelectModel;
                final routingEnabled =
                    session.chatModel?.routingEnabled ?? false;
                String decisionMode;
                if (routeDecision.usedCapable) {
                  decisionMode = 'auto_capable';
                } else if (routeDecision.lightweightModel != null) {
                  decisionMode = 'auto_lightweight';
                } else if (autoSelect && routingEnabled) {
                  decisionMode = 'fallback';
                } else if (autoSelect) {
                  decisionMode = 'routing_disabled';
                } else {
                  decisionMode = 'manual';
                }
                auditDecision = {
                  'mode': decisionMode,
                  ...routeDecision.toJson(),
                };
              }
              audit.model(
                auditTrace,
                auditProvider,
                auditModel,
                decision: auditDecision,
              );
            }

            // 单轮流式请求：post LLM API，解析 SSE chunk
            // deferErrorWrite: 错误延迟写出，便于失败回退重试，最终错误统一写出

            var round = await streamSingleRound(
              session: session,
              body: jsonEncode(body),
              controller: streamController,
              deferErrorWrite: true,
              handleSessionTools: true,
            );
            var sessionTools = round.sessionToolChunks;
            var thirdTools = round.thirdToolChunks;
            var hasError = round.error;

            contentBuffer.write(round.contentBuffer);
            reasonBuffer.write(round.reasonBuffer);
            promptTokens += round.promptTokens ?? 0;
            completionTokens += round.completionTokens ?? 0;
            cacheWriteTokens += round.cacheWriteTokens ?? 0;
            cacheReadTokens += round.cacheReadTokens ?? 0;

            // ── 审计：LLM 响应完成 ──
            if (auditTrace != null) {
              audit.usage(
                auditTrace,
                round.promptTokens ?? 0,
                round.completionTokens ?? 0,
              );
            }

            // ── 回退链：轻量模型出错且存在高能力模型 → 重试一次 ──
            if (hasError && !cancelStream && !fallbackTried) {
              final currentModel = body['model']?.toString() ?? '';
              final fallbackModel = ModelRouter.fallbackModelFor(
                session,
                currentModel,
              );
              if (fallbackModel != null &&
                  fallbackModel != currentModel &&
                  _isRetryableError(round.errorCode)) {
                debugPrint(
                  '🔄 [Fallback] 模型 $currentModel 失败(code=${round.errorCode})，切换高能力模型重试: $fallbackModel',
                );
                body['model'] = fallbackModel;
                fallbackTried = true;
                round = await streamSingleRound(
                  session: session,
                  body: jsonEncode(body),
                  controller: streamController,
                  deferErrorWrite: true,
                  handleSessionTools: true,
                );
                sessionTools = round.sessionToolChunks;
                thirdTools = round.thirdToolChunks;
                hasError = round.error;
                contentBuffer.write(round.contentBuffer);
                reasonBuffer.write(round.reasonBuffer);
                promptTokens += round.promptTokens ?? 0;
                completionTokens += round.completionTokens ?? 0;
                cacheWriteTokens += round.cacheWriteTokens ?? 0;
                cacheReadTokens += round.cacheReadTokens ?? 0;
                // ── 审计：回退重试后的用量 ──
                if (auditTrace != null) {
                  audit.usage(
                    auditTrace,
                    round.promptTokens ?? 0,
                    round.completionTokens ?? 0,
                  );
                }
              }
            }

            // LLM 最终仍错误 → 把延迟的错误 SSE 写出并退出
            if (hasError) {
              requestFailed = true;
              requestError = round.errorMessage ?? 'LLM API error';
              writeOpenAiError(
                streamController,
                message: round.errorMessage ?? 'LLM API error',
                type: round.errorType ?? 'api_error',
                code: round.errorCode,
              );
              break;
            }
            // 客户端断开 → 退出循环
            if (cancelStream) break;

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
            originBody:
                request.context[HttpContextKeys.originBody] as String? ?? '',
            body: body,
            responseContent: contentBuffer.toString(),
            error: null,
          );

          // ── 保存路由决策日志（JSONL 追加，供回测调参）──
          await _saveRouteLog(
            sessionId: session.sessionId,
            routeDecision:
                request.context[HttpContextKeys.routeDecision]
                    as RouteDecision?,
            fallbackTried: fallbackTried,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            cacheWriteTokens: cacheWriteTokens,
            cacheReadTokens: cacheReadTokens,
          );

          // ── 保存按分钟累计的用量统计 ──
          _saveUsageStats(
            session: session,
            startTime: generationStartTime,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            cacheWriteTokens: cacheWriteTokens,
            cacheReadTokens: cacheReadTokens,
            routeDecision:
                request.context[HttpContextKeys.routeDecision]
                    as RouteDecision?,
          );

          if (auditTrace != null) {
            await _appendHttpAuditNotificationMessage(
              request: request,
              session: session,
              trace: auditTrace,
              success: !requestFailed,
              error: requestError,
              duration: DateTime.now().difference(generationStartTime),
              promptTokens: promptTokens,
              completionTokens: completionTokens,
              cacheWriteTokens: cacheWriteTokens,
              cacheReadTokens: cacheReadTokens,
            );
          }
        } catch (e, st) {
          // ── 异步 IIFE 内部异常 ──
          debugPrint('❌ 流式代理错误: $e');
          debugPrint('📌 [pipelineFuture] 堆栈:\n$st');

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
            originBody:
                request.context[HttpContextKeys.originBody] as String? ?? '',
            body: body,
            responseContent: '',
            error: e.toString(),
          );

          if (auditTrace != null) {
            await _appendHttpAuditNotificationMessage(
              request: request,
              session: session,
              trace: auditTrace,
              success: false,
              error: e.toString(),
              duration: DateTime.now().difference(generationStartTime),
            );
          }

          // 按 OpenAI 标准错误格式返回给调用方并正常结束响应，而不是抛异常断连
          streamController.add(
            utf8.encode(
              'data: ${jsonEncode(openAiErrorBody(message: e.toString(), type: 'api_error', code: 500))}\n\n',
            ),
          );
          streamController.add(utf8.encode('data: [DONE]\n\n'));
          await streamController.close();
        }
      }(); // ← 立即执行，不 await

      // ──────────────────────────────────────────
      // 3. 按客户端请求类型返回响应
      // ──────────────────────────────────────────
      if (!wantStream) {
        // 非流式：等待生成完成，将 SSE 聚合为标准 OpenAI JSON 响应
        try {
          await pipelineFuture;
          final chunks = await bufferedChunksFuture!;
          final bytes = chunks.fold<List<int>>(
            <int>[],
            (acc, chunk) => acc..addAll(chunk),
          );
          final sseText = utf8.decode(bytes, allowMalformed: true);
          return Response.ok(
            jsonEncode(_sseToChatCompletionJson(sseText, 'auto')),
            headers: {
              ...jsonHeaders,
              if (auditTrace != null) 'X-Trace-ID': auditTrace.traceId,
            },
          );
        } catch (e) {
          debugPrint('❌ 非流式请求处理失败: $e');
          return openAiErrorResponse(
            statusCode: 500,
            message: 'Internal error: $e',
            type: 'api_error',
            code: 500,
          );
        }
      }

      // 流式：立即返回 SSE 响应，内容由异步 IIFE 逐步写入 streamController.stream
      return Response(
        200,
        body: streamController.stream,
        headers: {
          'content-type': 'text/event-stream',
          'cache-control': 'no-cache',
          'connection': 'keep-alive',
          if (auditTrace != null) 'X-Trace-ID': auditTrace.traceId,
        },
      );
    } catch (e) {
      // ── 同步异常（如 StreamController 构造失败）──
      // 此时流还未建立，直接返回 500，不经过 sessionGuard
      debugPrint('❌ 请求处理失败: $e');

      return openAiErrorResponse(
        statusCode: 500,
        message: 'Internal error: $e',
        type: 'api_error',
        code: 500,
      );
    }
  }

  /// 将 SSE 流文本（含 `data: {...}` 行与 `[DONE]`）聚合为 OpenAI 标准
  /// `chat.completion` JSON 响应。
  ///
  /// 供 `stream: false` 的非流式客户端（编程工具等）使用：服务端内部仍按流式
  /// 请求上游并逐条写出，最后由本函数把 SSE 数据还原为普通 JSON 响应。
  static Map<String, dynamic> _sseToChatCompletionJson(
    String sseText,
    String model,
  ) {
    final content = StringBuffer();
    String finishReason = 'stop';
    Map<String, dynamic>? usage;
    Map<String, dynamic>? error;
    final toolCallsByIndex = <int, Map<String, dynamic>>{};

    for (final line in sseText.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final payload = trimmed.substring('data: '.length).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;

      try {
        final obj = jsonDecode(payload) as Map<String, dynamic>;
        final err = obj['error'];
        if (err is Map<String, dynamic> && error == null) {
          error = err;
          continue;
        }
        final choices = obj['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = choices.first as Map<String, dynamic>;
          final delta = choice['delta'];
          if (delta is Map<String, dynamic>) {
            content.write(delta['content']?.toString() ?? '');
            final toolCalls = delta['tool_calls'];
            if (toolCalls is List) {
              for (final rawToolCall in toolCalls) {
                if (rawToolCall is! Map<String, dynamic>) continue;
                final index = rawToolCall['index'] as int? ?? 0;
                final existing =
                    toolCallsByIndex[index] ??
                    <String, dynamic>{
                      'id': null,
                      'type': 'function',
                      'function': {'name': null, 'arguments': ''},
                    };

                final function =
                    (existing['function'] as Map<String, dynamic>?) ??
                    <String, dynamic>{'name': null, 'arguments': ''};
                final rawFunction = rawToolCall['function'];
                if (rawToolCall['id'] != null) {
                  existing['id'] = rawToolCall['id'];
                }
                if (rawToolCall['type'] != null) {
                  existing['type'] = rawToolCall['type'];
                }
                if (rawFunction is Map<String, dynamic>) {
                  if (rawFunction['name'] != null) {
                    function['name'] = rawFunction['name'];
                  }
                  if (rawFunction['arguments'] != null) {
                    function['arguments'] =
                        (function['arguments']?.toString() ?? '') +
                        rawFunction['arguments'].toString();
                  }
                }
                existing['function'] = function;
                toolCallsByIndex[index] = existing;
              }
            }
          }
          final fr = choice['finish_reason'];
          if (fr is String && fr.isNotEmpty) finishReason = fr;
        }
        if (obj['usage'] is Map<String, dynamic>) {
          usage = obj['usage'] as Map<String, dynamic>;
        }
      } catch (_) {
        // 忽略无法解析的行
      }
    }

    if (error != null) {
      return {
        'error': {
          'message': error['message']?.toString() ?? 'LLM API error',
          'type': error['type']?.toString() ?? 'api_error',
          'code': error['code'] ?? 500,
        },
      };
    }

    final toolCalls =
        toolCallsByIndex.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final message = <String, dynamic>{
      'role': 'assistant',
      'content': content.toString(),
    };
    if (toolCalls.isNotEmpty) {
      message['content'] = content.isEmpty ? null : content.toString();
      message['tool_calls'] = toolCalls.map((e) => e.value).toList();
      if (finishReason == 'stop') finishReason = 'tool_calls';
    }

    return {
      'id': 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}',
      'object': 'chat.completion',
      'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'model': model,
      'choices': [
        {'index': 0, 'message': message, 'finish_reason': finishReason},
      ],
      if (usage != null) 'usage': usage,
    };
  }

  static Future<void> _appendHttpAuditNotificationMessage({
    required Request request,
    required ChatSession session,
    required AuditTrace trace,
    required bool success,
    String? error,
    Duration? duration,
    int promptTokens = 0,
    int completionTokens = 0,
    int cacheWriteTokens = 0,
    int cacheReadTokens = 0,
  }) async {
    try {
      if (!Get.isRegistered<SessionController>()) return;
      final now = DateTime.now();
      final traceId = trace.traceId;
      final riskHit = request.context[HttpContextKeys.riskControlHit] == true;
      final totalTokens = promptTokens + completionTokens;
      final content = _buildHttpAuditNotificationContent(
        success: success,
        riskHit: riskHit,
        alert: !success || riskHit,
        duration: duration,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        cacheWriteTokens: cacheWriteTokens,
        cacheReadTokens: cacheReadTokens,
        error: error,
      );
      final message = ChatMessage(
        msgId: 'http_audit_$traceId',
        role: MessageRole.bot,
        content: content,
        timestamp: now,
        sessionId: session.sessionId,
        model: session.chatModel?.modelId,
        isError: !success,
        auditTraceId: traceId,
        noticeLevel:
            !success || riskHit
                ? MessageNoticeLevel.alert
                : MessageNoticeLevel.normal,
        generationStartTime: duration == null ? null : now.subtract(duration),
        generationEndTime: duration == null ? null : now,
        generationDuration: duration,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
      );
      await Get.find<SessionController>().appendMessage(message);
    } catch (e) {
      debugPrint('⚠️ [HTTP] 写入审计提醒消息失败: $e');
    }
  }

  static String _buildHttpAuditNotificationContent({
    required bool success,
    required bool riskHit,
    required bool alert,
    Duration? duration,
    int promptTokens = 0,
    int completionTokens = 0,
    int totalTokens = 0,
    int cacheWriteTokens = 0,
    int cacheReadTokens = 0,
    String? error,
  }) {
    final lines = <String>[
      success ? '已经完成大模型请求，点击查看审计。' : '大模型请求已结束，但处理失败，点击查看审计。',
      '',
      '- 消息级别：${alert ? '告警' : '正常'}',
      '- 敏感信息：${riskHit ? '已触发脱敏' : '未发现敏感信息'}',
      '- 本次耗时：${_formatDurationSeconds(duration)}',
      '- Token 消耗：$totalTokens（输入 $promptTokens，输出 $completionTokens）',
    ];
    if (cacheWriteTokens > 0 || cacheReadTokens > 0) {
      lines.add('- 缓存 Token：写入 $cacheWriteTokens，读取 $cacheReadTokens');
    }
    if (!success && error != null && error.isNotEmpty) {
      lines
        ..add('')
        ..add('错误信息：$error');
    }
    return lines.join('\n');
  }

  static String _formatDurationSeconds(Duration? duration) {
    if (duration == null) return '-- 秒';
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} 秒';
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
    int cacheWriteTokens = 0,
    int cacheReadTokens = 0,
    RouteDecision? routeDecision,
  }) {
    () async {
      try {
        final sessionId = session.sessionId;
        final model = session.chatModel;
        // 实际使用的模型：路由决策优先（自动选择可能命中轻量模型），
        // 否则取配置模型的 API 模型名（model），而非配置记录 id（modelId，形如 model<uuid>）
        final modelId = routeDecision?.modelId ?? model?.model ?? 'unknown';
        var currency = model?.currency ?? 'USD';

        // 计算本次请求费用：优先按「实际使用模型」的价格计价
        double requestCost = 0.0;
        if (routeDecision != null && routeDecision.modelId != model?.model) {
          // 路由实际调用了与配置主模型不同的模型（如命中轻量模型）→ 按该模型价格计价
          final price = ModelPriceCatalog.priceOf(routeDecision.modelId);
          if (price != null) {
            requestCost =
                promptTokens * price.promptCny / 1000000.0 +
                completionTokens * price.completionCny / 1000000.0;
            currency = price.currency == PriceCurrency.cny ? 'CNY' : 'USD';
          } else {
            // 取不到实际模型价格 → 回退配置模型价格
            if (model?.promptPrice != null) {
              requestCost += promptTokens * model!.promptPrice! / 1000000.0;
            }
            if (model?.completionPrice != null) {
              requestCost +=
                  completionTokens * model!.completionPrice! / 1000000.0;
            }
          }
        } else {
          // 未路由或路由仍使用配置模型 → 按配置模型价格
          if (model?.promptPrice != null) {
            requestCost += promptTokens * model!.promptPrice! / 1000000.0;
          }
          if (model?.completionPrice != null) {
            requestCost +=
                completionTokens * model!.completionPrice! / 1000000.0;
          }
        }

        await UsageController.instance.recordUsage(
          sessionId: sessionId,
          modelId: modelId,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          cacheWriteTokens: cacheWriteTokens,
          cacheReadTokens: cacheReadTokens,
          cost: requestCost,
          currency: currency,
          timestamp: startTime,
        );
      } catch (e) {
        debugPrint('⚠️ [Usage] 保存用量统计失败: $e');
      }
    }();
  }

  /// 保存第三方客户请求的原始内容到 `~/.llmate/log_request/`（追加，每个请求一个文件）。
  ///
  /// 与 `~/.llmate/log/log.json`（覆盖写入最近一次）不同，本目录按请求逐条落盘，
  /// 保留所有第三方客户（如编程工具）发送的原始报文，便于离线审计与排查。
  /// 文件名格式：`yyyyMMdd_HHmmss_SSS_{sessionId}.json`
  static Future<void> _saveRequestLog({
    required Request request,
    required String sessionId,
    required String originBody,
  }) async {
    try {
      final logDir = Directory('${StoragePaths.root}/log_request');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName =
          '${now.year}${two(now.month)}${two(now.day)}_'
          '${two(now.hour)}${two(now.minute)}${two(now.second)}_'
          '${now.millisecond.toString().padLeft(3, '0')}_'
          '${safeFileNameSegment(sessionId)}.json';

      final entry = <String, dynamic>{
        'timestamp': now.toIso8601String(),
        'sessionId': sessionId,
        'method': request.method,
        'uri': request.requestedUri.toString(),
        'headers': request.headers,
        'body': originBody,
      };

      final file = File('${logDir.path}/$fileName');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(entry),
      );
    } catch (e) {
      debugPrint('⚠️ [RequestLog] 保存请求日志失败: $e');
    }
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

  /// 追加写入路由决策日志到 `~/.llmate/log/route_log.jsonl`（JSONL，一行一条）。
  ///
  /// 供离线回测调参：记录每次路由决策的输入特征、信号命中、阈值，
  /// 以及实际 token 用量与回退情况，用于分析各信号/阈值是否合理。
  /// 仅记录开启自动选择且成功完成流式的请求（routeDecision 为 null 时跳过）。
  static Future<void> _saveRouteLog({
    required String sessionId,
    required RouteDecision? routeDecision,
    required bool fallbackTried,
    required int promptTokens,
    required int completionTokens,
    int cacheWriteTokens = 0,
    int cacheReadTokens = 0,
  }) async {
    try {
      if (routeDecision == null) return;
      final logDir = Directory('${StoragePaths.root}/log');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final entry = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'sessionId': sessionId,
        'decision': routeDecision.toJson(),
        'fallbackTried': fallbackTried,
        'actualTokens': {
          'prompt': promptTokens,
          'completion': completionTokens,
          'cacheWrite': cacheWriteTokens,
          'cacheRead': cacheReadTokens,
        },
      };
      final file = File('${logDir.path}/route_log.jsonl');
      await file.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('⚠️ [RouteLog] 保存路由日志失败: $e');
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

/// 判断 LLM 错误是否可回退重试。
///
/// - code 为 null（网络/超时/未知异常）→ 可重试
/// - 429（限流）→ 可重试（换模型可能绕过配额）
/// - >= 500（服务端错误）→ 可重试
/// - 其余 4xx（鉴权/参数错误）→ 不可重试，换模型通常无效
bool _isRetryableError(int? code) {
  if (code == null) return true;
  if (code == 429) return true;
  if (code >= 500) return true;
  return false;
}
