import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../http/local_http_service.dart';
import '../../../controllers/settings_controller.dart';
import '../../../models/chat/session.dart';
import 'openai_provider.dart';
import 'chunk_parser.dart';

/// 通过本机会话 HTTP 服务转发聊天请求，并将服务返回的
/// OpenAI 格式 SSE 流转译为 LLMChat 消费方期望的 chunk 格式。
///
/// 服务侧 [modelToolGuard] 负责注入 model / tools / 系统提示词，
/// 因此此处只发送会话历史与用户消息（不重复携带 tools）。
///
/// 与本地管理模式（`stream_local.dart`）相互独立，修改互不影响。
Stream<Map<String, dynamic>> streamViaHttpService({
  required ChatSession session,
  required OpenAiProvider provider,
  required bool Function() isCancelled,
  required List<Map<String, dynamic>> messages,
}) async* {
  final model = session.chatModel;
  if (model == null) {
    yield {'content': '模型未配置'};
    yield {'done': 'true'};
    return;
  }

  final body = await provider.buildRequestData(
    messages: messages,
    session: session,
    stream: true,
    tools: const [],
  );

  final scheme = LocalHttpService.isHttps ? 'https' : 'http';
  // 优先使用本机回环地址 127.0.0.1（比 localhost 更可靠，避免 IPv6 ::1 解析问题）
  final host = '127.0.0.1';
  // 端口：优先用本机服务实际监听端口，无效时回退到系统设置中配置的 HTTP 端口
  final port =
      LocalHttpService.port > 0
          ? LocalHttpService.port
          : Get.find<SettingsController>().httpPort.value;
  final uri = Uri.parse(
    '$scheme://$host:$port/${session.sessionId}/chat/completions',
  );

  final client = HttpClient();
  if (LocalHttpService.isHttps) {
    // 本地自签名证书，放宽校验
    client.badCertificateCallback = (_, __, ___) => true;
  }

  HttpClientRequest? req;
  try {
    req = await client.postUrl(uri);
    req.headers.contentType = ContentType.json;
    req.headers.set('X-LLMate-InApp', 'true');
    if (!session.noAuthEnabled) {
      req.headers.set('Authorization', 'Bearer ${session.apiKey}');
    }
    req.write(jsonEncode(body));

    final response = await req.close();
    if (response.statusCode >= 400) {
      final err = await response.transform(utf8.decoder).join();
      yield {'content': '请求失败 ($err)'};
      yield {'done': 'true'};
      return;
    }

    String buffer = '';
    await for (final raw in response.transform(utf8.decoder)) {
      debugPrint('🧠 [LLMChat] 接收到的原始 SSE chunk: $raw');
      if (isCancelled()) break;
      buffer += raw;
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          if (dataStr == '[DONE]') {
            yield {'done': 'true'};
            return;
          }
          for (final c in parseOpenAiChunk(dataStr)) {
            yield c;
          }
        } else if (trimmed.startsWith('{')) {
          // 非 SSE 的原始 JSON（如错误行）
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
    yield {'done': 'true'};
  } catch (e) {
    yield {'content': '错误: $e'};
    yield {'done': 'true'};
  } finally {
    client.close(force: true);
  }
}
