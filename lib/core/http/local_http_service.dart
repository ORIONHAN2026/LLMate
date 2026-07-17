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

import '../../controllers/domain_controller.dart';
import '../../controllers/session_controller.dart';
import '../../data/storage_paths.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/usage_stats.dart';
import 'middleware/api_key_guard.dart';
import 'middleware/quota_guard.dart';
import 'middleware/model_tool_guard.dart';
import 'middleware/user_message_guard.dart';
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
      final domainController = Get.find<DomainController>();
      port.value = domainController.domainConfig.value.httpPort;
    } catch (_) {}
  }

  void toggleService() {
    if (isRunning.value) {
      LocalHttpService.stop();
      isRunning.value = false;
    } else {
      _syncPortFromDomain();
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
    _syncPortFromDomain();
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

  static Future<void> start({int port = 80, bool allowExternal = true}) async {
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

    // 模型列表路由（返回当前会话绑定的模型，兼容 OpenAI /v1/models 格式）
    router.get('/<segment>/models', (Request request, String sessionId) async {
      final pipeline = const Pipeline().addMiddleware(
        apiKeyGuard,
      ); // API Key 校验，装载 session

      return pipeline.addHandler((Request req) {
        return _handleModelsList(req);
      })(request);
    });

    // Chat Completion 路由（内联中间件链）
    router.post('/<segment>/chat/completions', (
      Request request,
      String sessionId,
    ) async {
      // 每次请求生成唯一 RequestId，注入 context 供审计/日志与链路追踪使用
      final requestId = _generateRequestId();

      // 读取原始请求体（中间件处理前的原始请求，用于日志保存）
      String originBodyStr = '';
      try {
        originBodyStr = await request.readAsString();
      } catch (e) {
        debugPrint('⚠️ 读取原始请求体失败: $e');
      }

      final requestWithId = request.change(
        context: {
          ...request.context,
          'requestId': requestId,
          'originBody': originBodyStr,
        },
        body: utf8.encode(originBodyStr),
      );

      // 构建中间件管道（洋葱模型）：
      // 请求进入：apiKey → quota → modelTool → audit → userMessage → 业务处理
      // 响应返回：业务处理（直接更新会话/审计） → userMessage → audit → modelTool → quota → apiKey
      final pipeline = const Pipeline()
          .addMiddleware(apiKeyGuard) //api判断,装载session
          .addMiddleware(quotaGuard) //配额判断
          .addMiddleware(modelToolGuard) //模型工具判断，装载body
          .addMiddleware(userMessageGuard); //创建用户消息

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
        {
          'id': 'auto',
          'object': 'model',
          'created': 0,
          'owned_by': 'llmate',
        },
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
  /// 后置任务（由 sessionGuard 中间件处理）：
  /// - 更新本地会话（消息 + token 统计 + 计费）
  /// - 审计回调补全响应内容
  ///
  /// 支持工具调用循环：LLM 返回 tool_calls → 执行 MCP 工具 → 结果回填 →
  /// 继续调用 LLM，直到无工具调用（最多 20 轮）。
  static Future<Response> _handleChatCompletion(Request request) async {
    try {
      // ──────────────────────────────────────────
      // 1. 初始化：创建流控制器，提取上下文数据
      // ──────────────────────────────────────────

      // SSE 流控制器：后续异步 IIFE 中逐步写入 chunk，shelf 框架从 stream 读取并发送给客户端
      final streamController = StreamController<List<int>>();

      // 从中间件注入的 context 中提取会话和增强后的请求体
      final session = request.context['session'] as ChatSession;
      final body = request.context['body'] as Map<String, dynamic>;

      // 应用内聊天标记：由聊天窗口自身负责消息持久化，服务侧跳过写入以避免重复
      final isInApp =
          (request.headers['x-llmate-inapp'] ?? '').toLowerCase() == 'true';

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

            // ── 执行 MCP 工具 ──
            final executionResult = await McpController.instance.executeToolCalls(
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
                (body['messages'] as List<dynamic>).add({
                  'role': 'tool',
                  'tool_call_id': r['id'],
                  'content':
                      r['isError'] == true ? '错误: ${r['result']}' : r['result'],
                });
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

          // ── 流结束：发送 DONE 标记，关闭控制器 ──
          streamController.add(utf8.encode('data: [DONE]\n\n'));
          await streamController.close();

          debugPrint('🔄 [ToolLoop] 流式请求完成，总内容长度：${contentBuffer.length}');

          // ── 更新本地会话：创建 AI 消息 + token 统计 + 计费 ──
          // 应用内聊天（X-LLMate-InApp）由聊天窗口自身负责持久化，跳过此处写入避免重复
          final totalTokens = promptTokens + completionTokens;
          if (!isInApp) {
            final sessionController = Get.find<SessionController>();
            final userMessage = request.context['userMessage'] as ChatMessage?;
            final now = DateTime.now();

            // 创建 AI 回复消息
            final botMsgId = '${now.millisecondsSinceEpoch}_bot';
            final botMessage = ChatMessage(
              msgId: botMsgId,
              role: MessageRole.bot,
              content: contentBuffer.toString(),
              reason: reasonBuffer.toString(),
              timestamp: now,
              sessionId: session.sessionId,
              pairedMsgId: userMessage?.msgId,
              generationStartTime: generationStartTime,
              generationEndTime: now,
              promptTokens: promptTokens,
              completionTokens: completionTokens,
              totalTokens: totalTokens > 0 ? totalTokens : null,
              generationDuration: now.difference(generationStartTime),
            );
            session.messages.add(userMessage!);
            session.messages.add(botMessage);
            // 追加用户消息 + AI 回复到会话

            session.quotaRequestCount++;
            session.promptTokens += promptTokens;
            session.completionTokens += completionTokens;
            session.totalTokens += totalTokens;
            // updateSession 内部会调用 _recalculateBilling 自动计算费用
            sessionController.updateSession(session);
            // 强制通知所有监听者刷新 UI（确保非当前 session 的变更也能反映到侧边栏等位置）
            sessionController.update();
          }

          debugPrint(
            '✅ 会话已更新: ${session.sessionId}, '
            'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
          );

          // ── 保存完整请求/响应日志 ──
          _saveRequestResponseLog(
            request: request,
            body: body,
            responseContent: contentBuffer.toString(),
            sessionId: session.sessionId,
            modelId: session.chatModel?.modelId ?? 'unknown',
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

          // 即使出错也尝试保存已有的请求/响应日志
          try {
            _saveRequestResponseLog(
              request: request,
              body: null,
              responseContent: null,
              sessionId: session.sessionId,
              modelId: session.chatModel?.modelId ?? 'unknown',
              error: e.toString(),
            );
          } catch (_) {}

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
          'x-request-id': request.context['requestId'] as String? ?? '',
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
        headers: {
          'content-type': 'application/json',
          'x-request-id': request.context['requestId'] as String? ?? '',
        },
      );
    }
  }

  /// 保存完整的请求/响应日志到会话配置目录下的 audit 子目录
  ///
  /// 保存路径：~/.llmate/chats/{sessionId}/audit/
  /// 文件名格式：年-月-日-时-分-秒-requestId.json
  /// 内容包含：
  ///   - originRequest: 第三方客户端发送的原始请求体
  ///   - middleRequest: 中间件处理后最终发送给 LLM 的请求体
  ///   - response: 累计回复给第三方客户端的完整内容
  static void _saveRequestResponseLog({
    required Request request,
    Map<String, dynamic>? body,
    String? responseContent,
    required String sessionId,
    required String modelId,
    String? error,
  }) {
    () async {
      try {
        final originBodyStr = request.context['originBody'] as String? ?? '';

        // 解析原始请求体
        dynamic originRequest;
        if (originBodyStr.isNotEmpty) {
          try {
            originRequest = jsonDecode(originBodyStr);
          } catch (_) {
            originRequest = originBodyStr;
          }
        } else {
          originRequest = {};
        }

        // 构建时间戳：年-月-日-时-分-秒
        final now = DateTime.now();
        final timestamp =
            '${now.year}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}-'
            '${now.hour.toString().padLeft(2, '0')}-'
            '${now.minute.toString().padLeft(2, '0')}-'
            '${now.second.toString().padLeft(2, '0')}';

        final logData = <String, dynamic>{
          'originRequest': originRequest,
          'middleRequest': body ?? {},
          'response': responseContent ?? '',
        };

        if (error != null) {
          logData['error'] = error;
        }

        // 确保目录存在：~/.llmate/audit/
        final dir = Directory('${StoragePaths.root}/audit');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final filename = '$timestamp-$modelId-$sessionId-audit.json';
        final file = File('${dir.path}/$filename');
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(logData),
        );

        debugPrint('📝 [RequestLog] 请求日志已保存: ${file.path}');
      } catch (e) {
        debugPrint('⚠️ [RequestLog] 保存请求日志失败: $e');
      }
    }();
  }

  /// 保存用量统计（按分/时/日/月/年 五个粒度）
  ///
  /// 保存路径：~/.llmate/usage/
  /// 文件名格式（以粒度区分）：
  ///   - 分钟：年-月-日-时-分-{modelId}-{sessionId}-usage.json
  ///   - 小时：年-月-日-时-{modelId}-{sessionId}-usage.json
  ///   - 天：  年-月-日-{modelId}-{sessionId}-usage.json
  ///   - 月：  年-月-{modelId}-{sessionId}-usage.json
  ///   - 年：  年-{modelId}-{sessionId}-usage.json
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

        final detail = UsageDetail(
          timestamp: startTime,
          promptTokens: promptTokens,
          completionTokens: completionTokens,
          cost: requestCost,
          model: modelId,
          currency: currency,
        );

        final dir = Directory('${StoragePaths.root}/usage');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final y = startTime.year.toString();
        final mo = startTime.month.toString().padLeft(2, '0');
        final d = startTime.day.toString().padLeft(2, '0');
        final h = startTime.hour.toString().padLeft(2, '0');
        final mi = startTime.minute.toString().padLeft(2, '0');

        // 按粒度从细到粗：分 → 时 → 日 → 月 → 年
        final timestamps = [
          '$y-$mo-$d-$h-$mi',
          '$y-$mo-$d-$h',
          '$y-$mo-$d',
          '$y-$mo',
          y,
        ];

        for (final ts in timestamps) {
          await _accumulateUsage(
            dir: dir,
            filename: '$ts-$modelId-$sessionId-usage.json',
            detail: detail,
          );
        }
      } catch (e) {
        debugPrint('⚠️ [Usage] 保存用量统计失败: $e');
      }
    }();
  }

  /// 对单个时间粒度的用量文件进行读取-累加-写入
  static Future<void> _accumulateUsage({
    required Directory dir,
    required String filename,
    required UsageDetail detail,
  }) async {
    final file = File('${dir.path}/$filename');

    UsageStats stats;
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        stats = UsageStats.fromJson(
            jsonDecode(content) as Map<String, dynamic>);
      } catch (_) {
        stats = UsageStats.empty();
      }
    } else {
      stats = UsageStats.empty();
    }

    stats.add(detail);

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(stats.toJson()),
    );

    debugPrint(
      '📊 [Usage] 用量统计已更新: ${file.path} '
      '(请求数=${stats.requests}, 总量=${stats.totalTokens}, '
      '费用=${stats.costsByCurrency})',
    );
  }
}
