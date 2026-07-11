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
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'middleware/api_key_guard.dart';
import 'middleware/quota_guard.dart';
import 'middleware/model_tool_guard.dart';
import 'middleware/user_message_guard.dart';
import 'stream_round.dart' show streamSingleRound;
import '../tools/tool_execution_service.dart';
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

      // 将最终请求体写入磁盘，便于调试/回放
      File(
        'log_request/request.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(body));

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
            final executionResult = await ToolExecutionService.executeToolCalls(
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
          final sessionController = Get.find<SessionController>();
          final userMessage = request.context['userMessage'] as ChatMessage?;
          final now = DateTime.now();

          final totalTokens = promptTokens + completionTokens;

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

          debugPrint(
            '✅ 会话已更新: ${session.sessionId}, '
            'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
          );
        } catch (e) {
          // ── 异步 IIFE 内部异常 ──
          debugPrint('❌ 流式代理错误: $e');
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

}
