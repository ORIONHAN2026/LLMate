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
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';

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
}

/// 本地 HTTP 服务 - 纯请求透传 (基于 Shelf)
///
/// 只做两件事：
/// 1. 从会话获取模型配置（API URL、Key）
/// 2. 透传请求到大模型厂商
class LocalHttpService {
  static HttpServer? _server;
  static bool _isRunning = false;
  static int _port = 8899;

  static bool get isRunning => _isRunning;
  static int get port => _port;

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

      _server = await io.serve(handler, address, port);
      _isRunning = true;
      debugPrint(
        '🚀 HTTP 服务已启动: http://${allowExternal ? "0.0.0.0" : "127.0.0.1"}:$port',
      );
      debugPrint('📡 API: POST /{sessionId}/v1/chat/completions');
    } catch (e) {
      debugPrint('❌ HTTP 服务启动失败: $e');
      _isRunning = false;
      rethrow;
    }
  }

  static Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    debugPrint('🛑 HTTP 服务已停止');
  }

  /// 构建 Shelf Router
  static Router _buildRouter() {
    final router = Router();

    // 健康检查
    router.get('/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'content-type': 'application/json'},
      );
    });

    // Chat Completion: POST /{sessionId}/v1/chat/completions
    // sessionId 可能含 /，用正则从 request.url.path 提取完整 sessionId
    router.post('/<segment>/v1/chat/completions', (
      Request request,
      String sessionId,
    ) {
      return _handleChatCompletion(request, sessionId);
    });

    return router;
  }

  /// 处理 Chat Completion 请求
  static Future<Response> _handleChatCompletion(
    Request request,
    String sessionId,
  ) async {
    try {
      final body = await request.readAsString();
      debugPrint(
        '📨 请求体:${sessionId} ,${body.substring(0, body.length.clamp(0, 100))}...',
      );

      final sessionController = Get.find<SessionController>();
      print("session ${sessionController.sessions}");

      final session = sessionController.sessions.firstWhereOrNull(
        (s) => s.sessionId == sessionId,
      );

      if (session == null) {
        return Response.notFound(
          jsonEncode({
            'error': {'message': 'Session not found', 'code': 404},
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      if (session.chatModel == null) {
        return Response(
          400,
          body: jsonEncode({
            'error': {
              'message': 'Session has no model configured',
              'code': 400,
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      debugPrint('📤 透传请求到: ${session.chatModel?.apiUrl}');

      final requestBodyMap = jsonDecode(body) as Map<String, dynamic>;
      //使用对话模型
      requestBodyMap['model'] = session.chatModel!.model;

      final isStream = requestBodyMap['stream'] == true;

      if (isStream) {
        return _streamProxyResponse(session, requestBodyMap);
      } else {
        final responseBody = await _proxyToLLM(session, requestBodyMap);
        return Response.ok(
          responseBody,
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      debugPrint('❌ 请求处理失败: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'error': {'message': 'Internal error: $e', 'code': 500},
        }),
        headers: {'content-type': 'application/json'},
      );
    }
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

  /// 流式透传 - 返回 StreamedResponse
  static Response _streamProxyResponse(
    ChatSession session,
    Map<String, dynamic> requestBodyMap,
  ) {
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
          debugPrint(
            '❌ LLM 返回错误: ${response.statusCode}\n$errorBody',
          );
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
          return;
        }

        await for (final chunk in response) {
          debugPrint('📤 接收响应: ${chunk}');
          controller.add(chunk);
        }
        await controller.close();
      } catch (e) {
        debugPrint('❌ 流式代理错误: $e');
        controller.addError(e);
        await controller.close();
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
