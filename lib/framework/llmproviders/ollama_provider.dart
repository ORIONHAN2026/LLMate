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
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      LlmFeatures.codeGeneration,
    ];
  }

  @override
  void onConfigure(ChatModel model) {
    // 验证 Ollama 特定的配置（宽松模式）
    // 如果配置有问题，会在实际调用时显示错误，而不是在配置时立即抛出异常
    // 这样可以保持与原有 ApiService 的兼容性
  }

  @override
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async* {
    print("=== OllamaProvider.sendMessageStream 被调用 ===");
    print("模型配置: ${model?.name} (${model?.model})");
    print("API URL: ${model?.apiUrl}");

    if (model == null) {
      print("错误: 模型未配置");
      throw StateError('模型未配置');
    }
    // 构建请求数
    print("sendMessageStream");
    try {
      final requestData = _buildRequestData(
        userMessage: userMessage,
        session: session,
      );

      debugPrint('Ollama API 请求数据: ${jsonEncode(requestData)}');

      // 构建完整的 API 端点
      String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      if (!apiUrl.endsWith('/chat')) {
        apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
      }

      final response = await dio.post<ResponseBody>(
        apiUrl,
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
    List<Map<String, dynamic>> messages,
  ) async* {
    if (model == null) {
      throw StateError('Ollama 提供商未配置');
    }

    try {
      final requestData = {
        'model': model!.model,
        'messages': messages,
        'stream': true,
        'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
      };

      String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      if (!apiUrl.endsWith('/chat')) {
        apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
      }

      debugPrint('Ollama (withMessages) API 请求数据: ${jsonEncode(requestData)}');

      final response = await dio.post<ResponseBody>(
        apiUrl,
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
    if (model == null) {
      throw StateError('Ollama 提供商未配置');
    }

    try {
      // 使用基类的 buildMessages 方法构建消息列表
      final messages = buildMessages(
        userMessage: userMessage,
        session: session,
      );

      final requestData = {
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
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final message = data['message'] as Map<String, dynamic>?;
        if (message != null) {
          return message['content'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Ollama 非流式响应错误: $e');
      }
      throw Exception('Ollama API 错误: ${handleApiError(e)}');
    }
  }

  /// 构建请求数据
  Map<String, dynamic> _buildRequestData({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    // 使用基类的 buildMessages 方法构建消息列表
    final messages = buildMessages(
      userMessage: userMessage,
      session: session,
    );

    return {
      'model': model!.model,
      'messages': messages,
      'stream': true,
      'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
    };
  }

  /// 处理 Ollama 流式响应 (Chat API 格式)
  Stream<Map<String, String?>> _processOllamaStreamResponse(Stream<List<int>> stream) async* {
    String buffer = '';
    bool insideThinkTag = false;

    try {
      await for (final chunk in stream) {
        try {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;

          final lines = buffer.split('\n');
          // 安全地处理最后一行，避免 RangeError
          if (lines.isNotEmpty) {
            buffer = lines.removeLast(); // 保留可能不完整的最后一行
          } else {
            buffer = '';
          }

          for (final line in lines) {
            if (line.trim().isNotEmpty) {
              try {
                final data = jsonDecode(line);

                // 处理 Ollama Chat API 响应格式
                if (data is Map<String, dynamic>) {
                  if (data['message'] != null) {
                    final message = data['message'];
                    if (message is Map<String, dynamic> &&
                        message['content'] != null) {
                      final content = message['content'].toString();
                      if (content.isNotEmpty) {
                        debugPrint('Ollama原始内容: $content');
                        
                        // 使用基类的统一think处理逻辑
                        final processed = processContentWithThink(content, insideThinkTag);
                        insideThinkTag = processed['insideThinkTag'] as bool;
                        
                        debugPrint('处理后内容: ${processed['content']}');
                        debugPrint('处理后思考: ${processed['think']}');
                        
                        // 如果有内容或思考内容，就发送
                        if ((processed['content'] != null && processed['content']!.isNotEmpty) || 
                            (processed['think'] != null && processed['think']!.isNotEmpty)) {
                          debugPrint('发送内容: ${processed['think']}');

                          yield {
                            'content': processed['content'] ?? '',
                            'think': processed['think']
                          };
                        }
                      }
                    }
                  }

                  // 检查是否完成
                  if (data['done'] == true) {
                    debugPrint('Ollama流式响应完成');
                    return;
                  }
                }
              } catch (e) {
                // 忽略解析错误，继续处理下一行
                debugPrint('Ollama JSON解析错误: $e, 行内容: $line');
              }
            }
          }
        } catch (e) {
          debugPrint('Ollama 处理数据块错误: $e');
          // 继续处理下一个数据块
        }
      }
    } catch (e) {
      debugPrint('Ollama 流式响应处理错误: $e');
      yield {'content': '错误: 流式响应处理失败 - ${e.toString()}', 'think': null};
    }
  }

  @override
  Future<bool> validateConfiguration() async {
    print("=== OllamaProvider.validateConfiguration 被调用 ===");

    if (model == null) {
      print("Ollama 验证失败: 模型未配置");
      return false;
    }

    print("Ollama 验证开始...");
    print("模型: ${model!.model}");
    print("原始 API URL: ${model!.apiUrl}");

    try {
      // 构建完整的 API 端点
      String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      if (!apiUrl.endsWith('/chat')) {
        apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
      }

      print("最终 API URL: $apiUrl");

      final requestBody = {
        'model': model!.model,
        'messages': [
          {'role': 'user', 'content': '你好'},
        ],
        'stream': false,
      };

      print("请求体: ${jsonEncode(requestBody)}");
      print("开始发送 HTTP 请求...");

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15)); // 增加超时时间到15秒

      print("HTTP 响应状态码: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("HTTP 响应体: ${response.body}");
      }

      final isValid = response.statusCode == 200;
      print("Ollama 验证结果: ${isValid ? '成功' : '失败'}");

      return isValid;
    } catch (e) {
      print('Ollama 配置验证失败: $e');
      print('错误类型: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (model == null) {
      return null;
    }

    try {
      // 获取 Ollama 模型信息
      String baseUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      // 确保基础URL不包含/chat路径，然后添加/tags路径
      baseUrl = baseUrl.replaceAll('/chat', '');
      final apiTagsUrl =
          baseUrl.endsWith('/') ? '${baseUrl}tags' : '$baseUrl/tags';

      final response = await http
          .get(
            Uri.parse(apiTagsUrl),
            headers: {'Content-Type': 'application/json'},
          )
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
    } catch (e) {
      debugPrint('获取 Ollama 模型信息失败: $e');
    }

    return {
      'provider': 'ollama',
      'model': model!.model,
      'name': model!.name,
      'features': getSupportedFeatures(),
      'configured': true,
    };
  }

  /// 获取可用的模型列表
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    if (model == null) {
      return [];
    }

    try {
      String baseUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      // 确保基础URL不包含/chat路径，然后添加/tags路径
      baseUrl = baseUrl.replaceAll('/chat', '');
      final apiTagsUrl =
          baseUrl.endsWith('/') ? '${baseUrl}tags' : '$baseUrl/tags';

      final response = await http
          .get(
            Uri.parse(apiTagsUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['models'] ?? []);
      }
    } catch (e) {
      debugPrint('获取 Ollama 可用模型失败: $e');
    }

    return [];
  }

  @override
  Future<String?> sendSimpleMessage(String prompt) async {
    if (model == null) {
      return null;
    }

    try {
      final requestData = {
        'model': model!.model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'stream': false,
        'options': {'temperature': model!.chatSettings?.temperature ?? 0.7},
      };

      // 构建完整的 API 端点
      String apiUrl = model!.apiUrl ?? 'http://localhost:11434/api';
      if (!apiUrl.endsWith('/chat')) {
        apiUrl = apiUrl.endsWith('/') ? '${apiUrl}chat' : '$apiUrl/chat';
      }

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawContent = data['message']?['content']?.toString();
        if (rawContent != null) {
          return _processThinkContent(rawContent);
        }
      }
    } catch (e) {
      debugPrint('Ollama sendSimpleMessage 失败: $e');
    }
    return null;
  }

  /// 处理内容块，分离思考内容和正文内容
  /// 
  /// 支持的think标签格式：
  /// - <think>思考内容</think>
  /// - 跨多个chunk的think标签
  /// 
  /// [content] 原始内容
  /// [insideThinkTag] 当前是否在think标签内
  /// 
  /// 返回：
  /// - content: 处理后的正文内容
  /// - think: 提取的思考内容
  /// - insideThinkTag: 更新后的think标签状态
  Map<String, dynamic> processContentWithThink(String content, bool insideThinkTag) {
    String processedContent = content;
    String? thinkContent;
    bool newInsideThinkTag = insideThinkTag;
    
    // 如果当前在思考标签内，所有内容都被视为思考内容
    if (insideThinkTag) {
      // 检查是否包含结束标签
      if (content.contains('</think>')) {
        final parts = content.split('</think>');
        thinkContent = parts[0].trim(); // 移除开头和结尾的换行符
        processedContent = parts.length > 1 ? parts[1] : ''; // 思考后的内容
        newInsideThinkTag = false; // 退出think标签
      } else {
        // 完全在思考标签内
        thinkContent = content.trim(); // 移除开头和结尾的换行符
        processedContent = '';
        newInsideThinkTag = true; // 保持在think标签内
      }
    } else {
      // 不在思考标签内，检查是否有思考标签
      if (content.contains('<think>')) {
        if (content.contains('</think>')) {
          // 完整的思考标签在一个块中
          final thinkRegex = RegExp(r'<think>\s*(.*?)\s*</think>', dotAll: true);
          processedContent = content.replaceAllMapped(thinkRegex, (match) {
            final extractedThink = match.group(1)?.trim() ?? ''; // 移除think内容的换行符
            thinkContent = (thinkContent ?? '') + extractedThink;
            return ''; // 从正文中移除思考内容
          });
          newInsideThinkTag = false;
        } else {
          // 只有开始标签
          final parts = content.split('<think>');
          processedContent = parts[0]; // 思考前的内容
          thinkContent = parts.length > 1 ? parts[1].trim() : ''; // 思考内容开始部分，移除换行符
          newInsideThinkTag = true; // 进入think标签
        }
      }
      // 如果没有思考标签，processedContent保持原样，thinkContent保持null
    }
    
    return {
      'content': processedContent.isEmpty ? null : processedContent,
      'think': thinkContent?.isEmpty == true ? null : thinkContent,
      'insideThinkTag': newInsideThinkTag,
    };
  }

  /// 处理 <think> 标签内容，将其从正文中移除（用于非流式响应）
  String _processThinkContent(String content) {
    // 检查是否包含 <think> 标签
    if (!content.contains('<think>')) {
      return content;
    }

    // 使用正则表达式移除 <think> 标签及其内容
    final thinkRegex = RegExp(r'<think>\s*(.*?)\s*</think>', dotAll: true);
    return content.replaceAll(thinkRegex, '').trim();
  }

 }
