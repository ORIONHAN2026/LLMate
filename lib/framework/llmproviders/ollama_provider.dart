import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import 'base_provider.dart';

/// Ollama 本地模型提供商
class OllamaProvider extends BaseLlmProvider {
  @override
  String get providerName => 'Ollama';

  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {}

  Dio get dio {
    final client = Dio();
    client.options.connectTimeout = const Duration(milliseconds: BaseLlmProvider.defaultTimeout);
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);
    return client;
  }

  // ── 消息构建 ──

  // ── Ollama URL 辅助 ──

  String _buildChatApiUrl() {
    String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
    if (!apiUrl.endsWith('/chat')) {
      apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
    }
    return apiUrl;
  }

  // ── 核心抽象方法 ──

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    print("=== OllamaProvider.sendMessageStream 被调用 ===");
    if (model == null) throw StateError('模型未配置');

    try {
      final messages = buildMessages(userMessage: userMessage, session: session);
      final requestData = <String, dynamic>{
        'model': model!.model,
        'messages': messages,
        'stream': true,
        'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
      };

      debugPrint('Ollama API 请求数据: ${jsonEncode(requestData)}');

      final response = await dio.post<ResponseBody>(
        _buildChatApiUrl(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _processOllamaStreamResponse(response.data!.stream);
      } else {
        yield {'content': '错误: API 请求失败，状态码: ${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  }) async* {
    if (model == null) throw StateError('Ollama 提供商未配置');

    try {
      final requestData = <String, dynamic>{
        'model': model!.model,
        'messages': messages,
        'stream': true,
        'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
      };

      debugPrint('Ollama (withMessages) API 请求数据: ${jsonEncode(requestData)}');

      final response = await dio.post<ResponseBody>(
        _buildChatApiUrl(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        yield* _processOllamaStreamResponse(response.data!.stream);
      } else {
        yield {'content': '错误: API 请求失败，状态码: ${response.statusCode}', 'think': null};
      }
    } catch (e) {
      yield {'content': '错误: ${handleApiError(e)}', 'think': null};
    }
  }

  @override
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    if (model == null) throw StateError('Ollama 提供商未配置');

    try {
      final messages = buildMessages(userMessage: userMessage, session: session);
      final requestData = <String, dynamic>{
        'model': model!.model,
        'messages': messages,
        'stream': false,
        'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
      };

      if (kDebugMode) {
        print('Ollama 发送非流式请求到: ${model!.apiUrl}');
        print('请求数据: ${jsonEncode(requestData)}');
      }

      final response = await dio.post(
        model!.apiUrl!,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final message = data['message'] as Map<String, dynamic>?;
        if (message != null) return message['content'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Ollama API 错误: ${handleApiError(e)}');
    }
  }

  // ── Ollama 流式响应处理 ──

  Stream<Map<String, String?>> _processOllamaStreamResponse(
    Stream<List<int>> stream,
  ) async* {
    String buffer = '';
    bool insideThinkTag = false;

    try {
      final utf8Decoder = const Utf8Decoder();
      List<int> pendingBytes = [];
      await for (final chunk in stream) {
        try {
          pendingBytes.addAll(chunk);
          String? chunkString;
          try {
            chunkString = utf8Decoder.convert(pendingBytes);
            pendingBytes.clear();
          } on FormatException {
            for (int i = pendingBytes.length - 1; i > 0; i--) {
              try {
                chunkString = utf8Decoder.convert(pendingBytes.sublist(0, i));
                pendingBytes = pendingBytes.sublist(i);
                break;
              } on FormatException {
                continue;
              }
            }
          }
          if (chunkString == null) continue;
          buffer += chunkString;

          final lines = buffer.split('\n');
          if (lines.isNotEmpty) {
            buffer = lines.removeLast();
          } else {
            buffer = '';
          }

          for (final line in lines) {
            if (line.trim().isNotEmpty) {
              try {
                final data = jsonDecode(line);

                if (data is Map<String, dynamic>) {
                  if (data['message'] != null) {
                    final message = data['message'];
                    if (message is Map<String, dynamic> && message['content'] != null) {
                      final content = message['content'].toString();
                      if (content.isNotEmpty) {
                        final processed = processContentWithThink(content, insideThinkTag);
                        insideThinkTag = processed['insideThinkTag'] as bool;

                        if ((processed['content'] != null && processed['content']!.isNotEmpty) ||
                            (processed['think'] != null && processed['think']!.isNotEmpty)) {
                          yield {
                            'content': processed['content'] ?? '',
                            'think': processed['think'],
                          };
                        }
                      }
                    }
                  }

                  if (data['done'] == true) {
                    debugPrint('Ollama流式响应完成');
                    yield {'done': 'true'};
                    return;
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Ollama 流式响应处理错误: $e');
      yield {'content': '错误: 流式响应处理失败 - ${e.toString()}', 'think': null};
    }
    // 安全兜底：流自然结束时也发送 done 信号
    yield {'done': 'true'};
  }

  /// 处理内容块，分离思考内容和正文内容
  Map<String, dynamic> processContentWithThink(String content, bool insideThinkTag) {
    String processedContent = content;
    String? thinkContent;
    bool newInsideThinkTag = insideThinkTag;

    if (insideThinkTag) {
      if (content.contains('</think>')) {
        final parts = content.split('</think>');
        thinkContent = parts[0].trim();
        processedContent = parts.length > 1 ? parts[1] : '';
        newInsideThinkTag = false;
      } else {
        thinkContent = content.trim();
        processedContent = '';
        newInsideThinkTag = true;
      }
    } else {
      if (content.contains('<think>')) {
        if (content.contains('</think>')) {
          final thinkRegex = RegExp(r'<think>\s*(.*?)\s*</think>', dotAll: true);
          processedContent = content.replaceAllMapped(thinkRegex, (match) {
            final extractedThink = match.group(1)?.trim() ?? '';
            thinkContent = (thinkContent ?? '') + extractedThink;
            return '';
          });
          newInsideThinkTag = false;
        } else {
          final parts = content.split('<think>');
          processedContent = parts[0];
          thinkContent = parts.length > 1 ? parts[1].trim() : '';
          newInsideThinkTag = true;
        }
      }
    }

    return {
      'content': processedContent.isEmpty ? null : processedContent,
      'think': thinkContent?.isEmpty == true ? null : thinkContent,
      'insideThinkTag': newInsideThinkTag,
    };
  }

  // ── 验证与错误处理 ──

  @override
  Future<bool> validateConfiguration() async {
    if (model == null) return false;

    try {
      String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      if (!apiUrl.endsWith('/chat')) {
        apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
      }

      final requestBody = {
        'model': model!.model,
        'messages': [{'role': 'user', 'content': '你好'}],
        'stream': false,
      };

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Ollama 配置验证失败: $e');
      return false;
    }
  }

  Map<String, dynamic> parseToolCalls(String response) {
    return {'toolCalls': <Map<String, dynamic>>[], 'cleanContent': response};
  }

  String handleApiError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      String? serverMessage;
      try {
        if (responseData is String && responseData.isNotEmpty) {
          final body = jsonDecode(responseData) as Map<String, dynamic>;
          serverMessage = body['error']?['message'] as String?;
        } else if (responseData is Map) {
          serverMessage = responseData['error']?['message'] as String?;
        }
      } catch (_) {}
      serverMessage ??= error.message;

      if (statusCode != null && statusCode >= 400) {
        return serverMessage ?? 'Ollama API 请求失败 ($statusCode)';
      }
    }
    final es = error.toString();
    if (es.contains('Connection refused')) return '无法连接到 Ollama 服务，请确认服务已启动';
    if (es.contains('SocketException')) return '网络连接失败，请检查 Ollama 服务';
    if (es.contains('CONNECT_TIMEOUT')) return '连接 Ollama 超时';
    return 'Ollama API 错误：$es';
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) return null;

    try {
      String baseUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      baseUrl = baseUrl.replaceAll('/chat', '');
      final apiTagsUrl = baseUrl.endsWith('/') ? '${baseUrl}tags' : '$baseUrl/tags';

      final response = await http
          .get(Uri.parse(apiTagsUrl), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        final modelInfo = models?.firstWhere(
          (m) => m['name'] == model!.model,
          orElse: () => null,
        );

        return {
          'provider': 'ollama',
          'model': model!.model,
          'name': model!.name,
          'features': getSupportedFeatures(),
          'configured': true,
          'size': modelInfo?['size'],
          'digest': modelInfo?['digest'],
        };
      }
    } catch (_) {}

    return {
      'provider': 'ollama',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }

  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    if (model == null) return [];

    try {
      String baseUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      baseUrl = baseUrl.replaceAll('/chat', '');
      final apiTagsUrl = baseUrl.endsWith('/') ? '${baseUrl}tags' : '$baseUrl/tags';

      final response = await http
          .get(Uri.parse(apiTagsUrl), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['models'] ?? []);
      }
    } catch (_) {}

    return [];
  }
}
