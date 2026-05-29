import 'dart:convert';
import 'dart:async';
import 'package:chathub/models/bigmodel/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'mcp_service.dart';

class ApiService {
  static const int timeout = 30000; // 30秒超时

  // 实例变量
  final ChatSession chatSession;
  final ChatMessage userMessage;

  // 构造函数
  ApiService({required this.chatSession, required this.userMessage});

  // 处理OpenAI流式响应，提取content字段
  String? _processOpenAIStreamResponse(dynamic data) {
    if (data == null) return null;
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      final choice = data['choices'][0];
      if (choice['delta'] != null && choice['delta']['content'] != null) {
        return choice['delta']['content'];
      }
      // 兼容部分API直接返回content
      if (choice['message'] != null && choice['message']['content'] != null) {
        return choice['message']['content'];
      }
    }
    return null;
  }

  // 构建完整的系统提示词，使用模型设置
  String _buildSystemPrompt() {
    final List<String> systemParts = [];
    final chatModel = chatSession.chatModel;

    // 用户自定义系统提示词 - 使用模型设置
    if (chatModel != null &&
        chatModel.chatSettings?.systemPrompt != null &&
        chatModel.chatSettings!.systemPrompt.isNotEmpty) {
      systemParts.add(chatModel.chatSettings!.systemPrompt);
    }

    // 语言指令 - 使用模型设置
    if (chatModel?.chatSettings?.replyLanguage != null &&
        chatModel!.chatSettings!.replyLanguage.isNotEmpty) {
      systemParts.add('请使用 ${chatModel.chatSettings!.replyLanguage} 回复。');
    }
    systemParts.add('请严格遵照系统提示词进行回答。');

    return systemParts.join('\n\n');
  }

  // 构建包含MCP工具信息的消息列表
  List<Map<String, dynamic>> _buildMessages() {
    final messages = <Map<String, dynamic>>[];

    // 构建系统提示词（不再包含MCP工具信息，工具信息将使用tools字段）
    String systemPrompt = _buildSystemPrompt();

    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    // 构建用户消息内容
    final userContent = _buildUserContent();
    messages.add({'role': 'user', 'content': userContent});

    return messages;
  }

  // 构建包含附件信息的用户消息内容（移除MCP处理）
  String _buildUserContent() {
    String content = userMessage.content;

    // 注释：MCP服务处理已移至使用 mcp_client 包
    // 这里保留接口兼容性，实际MCP处理应在更上层调用

    // 如果有附件，添加附件信息到消息内容中
    if (userMessage.attachments.isNotEmpty) {
      final attachmentInfos = <String>[];

      for (final attachment in userMessage.attachments) {
        final buffer = StringBuffer();

        // 基本文件信息
        switch (attachment.type) {
          case 'image':
            buffer.write('[图片文件: ${attachment.name}');
            break;
          case 'document':
          case 'text':
            buffer.write('[文档文件: ${attachment.name}');
            break;
          case 'code':
            buffer.write('[代码文件: ${attachment.name}');
            break;
          case 'web':
            buffer.write('[网页链接: ${attachment.name}');
            break;
          case 'folder':
            buffer.write('[文件夹: ${attachment.name}');
            break;
          default:
            buffer.write('[文件: ${attachment.name}');
        }

        // 文件大小
        if (attachment.size != null && attachment.size! > 0) {
          buffer.write(', 大小: ${_formatFileSize(attachment.size!)}');
        }

        buffer.write(']\n');

        // 添加文件内容
        if (attachment.content != null && attachment.content!.isNotEmpty) {
          // 限制附件内容长度，避免消息过长
          const maxContentLength = 8000; // 每个附件最大8000字符
          String attachmentContent = attachment.content!;

          if (attachmentContent.length > maxContentLength) {
            attachmentContent =
                '${attachmentContent.substring(0, maxContentLength)}\n...[内容过长，已截断]';
          }

          buffer.write(attachmentContent);
        } else if (attachment.content == 'ERROR_PROCESSING') {
          buffer.write('[文件处理失败]');
        } else {
          buffer.write('[文件处理中...]');
        }

        attachmentInfos.add(buffer.toString());
      }

      // 将附件信息添加到消息开头
      content = '${attachmentInfos.join('\n\n')}\n\n用户问题: $content';
    }

    return content;
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 发送消息到本地模型（Ollama）
  static Future<String> sendMessageToLocalModel({
    required String message,
    required String modelName,
    required String apiUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': modelName,
              'prompt': message,
              'stream': false,
            }),
          )
          .timeout(const Duration(milliseconds: timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? '抱歉，没有收到回复';
      } else {
        return '请求失败：${response.statusCode}';
      }
    } catch (e) {
      return '连接错误：$e';
    }
  }

  // 流式发送消息到本地模型（Ollama）
  static Stream<String> sendMessageToLocalModelStream({
    required String message,
    required String modelName,
    required String apiUrl,
    ChatModel? model,
  }) async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5); // 流式响应可能较长

      // 构建完整的提示词，包括系统提示词和语言设置
      String finalPrompt = message;
      if (model != null) {
        // 直接用 _buildMessages 逻辑拼接 systemPrompt，无需单独调用 _buildSystemPrompt
        final systemParts = <String>[];
        if (model.chatSettings?.systemPrompt != null &&
            model.chatSettings!.systemPrompt.isNotEmpty) {
          systemParts.add(model.chatSettings!.systemPrompt);
        }
        String replyLanguage = model.chatSettings?.replyLanguage ?? 'auto';
        if (replyLanguage != 'auto' && replyLanguage.isNotEmpty) {
          switch (replyLanguage) {
            case 'zh':
            case '中文':
              systemParts.add('请用中文回复。');
              break;
            case 'en':
            case '英文':
              systemParts.add('Please reply in English.');
              break;
            case 'ja':
            case '日文':
              systemParts.add('日本語で回答してください。');
              break;
            case 'ko':
              systemParts.add('한국어로 답변해주세요.');
              break;
          }
        }

        final systemPrompt = systemParts.join('\n\n');
        if (systemPrompt.isNotEmpty) {
          finalPrompt = '$systemPrompt\n\n$message';
        }
      }

      final response = await dio.post<ResponseBody>(
        '$apiUrl/api/generate',
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.stream,
        ),
        data: {
          'model': modelName,
          'prompt': finalPrompt,
          'stream': true,
          'options': {'temperature': model?.chatSettings?.temperature ?? 0.7},
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          // 正确处理UTF-8编码
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;

          // 处理完整的JSON行
          final lines = buffer.split('\n');
          buffer = lines.removeLast(); // 保留可能不完整的最后一行

          for (final line in lines) {
            if (line.trim().isNotEmpty) {
              try {
                final data = jsonDecode(line);
                if (data['response'] != null &&
                    data['response'].toString().isNotEmpty) {
                  yield data['response'];
                }
                if (data['done'] == true) {
                  return;
                }
              } catch (e) {
                // 忽略解析错误，继续处理下一行
                print('JSON解析错误: $e, 行内容: $line');
              }
            }
          }
        }
      } else {
        yield '请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield '连接错误：$e';
    }
  }

  // 流式发送消息到在线模型
  Stream<String> sendMessageToOnlineModelStream() async* {
    final provider = chatSession.chatModel?.provider;
    switch (provider) {
      case 'modelscope':
        yield* _sendToModelScopeStream();
        break;
      case 'deepseek':
        yield* _sendToDeepSeekStream();
        break;
      case 'openai':
        yield* _sendToOpenAIStream();
        break;
      case 'anthropic':
        yield* _sendToAnthropicStream();
        break;
      case 'gemini':
        yield* _sendToGeminiStream();
        break;
      case 'qwen':
        yield* _sendToQwenStream();
        break;
      case 'zhipu':
        yield* _sendToZhipuStream();
        break;

      default:
        yield '不支持的模型提供商：$provider';
    }
  }

  // ModelScope API 流式调用
  Stream<String> _sendToModelScopeStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);

      final requestData = {
        'model': chatSession.chatModel?.model,
        'messages': _buildMessages(),
        'temperature': chatSession.chatModel?.chatSettings?.temperature ?? 0.7,
        'max_tokens': 2000,
        'stream': true, // 启用流式响应
      };

      // 如果启用了MCP工具，添加tools字段（魔塔兼容OpenAI格式）
      debugPrint(
        'ModelScope MCP检查: isMcpToolsEnabled=${chatSession.mcpServer != null}, hasGlobalServices=${McpService.hasGlobalMcpServices}',
      );
      if (chatSession.mcpServer != null &&
          McpService.hasGlobalMcpServices) {
        final tools = McpService.buildOpenAIToolsFormat(chatSession);
        debugPrint('ModelScope 构建的tools数量: ${tools.length}');
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto'; // 让AI自动决定是否使用工具
          debugPrint('ModelScope 已添加tools字段到请求数据');
        } else {
          debugPrint('ModelScope tools为空，未添加到请求数据');
        }
      } else {
        debugPrint('ModelScope MCP条件不满足，未添加tools字段');
      }

      //打印完整的请求数据
      debugPrint('ModelScope API 请求数据: ${jsonEncode(requestData)}');
      final response = await dio.post<ResponseBody>(
        chatSession.chatModel!.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${chatSession.chatModel!.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream, // 设置为流式响应
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.trim().startsWith('data: ')) {
              final dataStr = line.trim().substring(6);
              if (dataStr == '[DONE]') {
                return;
              }
              try {
                final data = jsonDecode(dataStr);
                final content = _processOpenAIStreamResponse(data);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                print('ModelScope流式解析错误: $e, 数据: $dataStr');
              }
            }
          }
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  // DeepSeek API 流式调用
  Stream<String> _sendToDeepSeekStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 使用模型设置
      final double temperature = chatModel.chatSettings?.temperature ?? 0.7;
      int maxTokens = 2000;

      //创建消息
      // 构建请求数据，使用支持MCP服务的方法
      final messages = _buildMessages();

      // 构建请求数据
      final requestData = {
        'model': chatModel.model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      };

      // 如果启用了MCP工具，添加tools字段
      if (chatSession.mcpServer != null &&
          McpService.hasGlobalMcpServices) {
        final tools = McpService.buildOpenAIToolsFormat(chatSession);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto'; // 让AI自动决定是否使用工具
        }
      }
      //打印发送的消息
      print('DeepSeek API 请求数据: ${jsonEncode(requestData)}');
      // 调试信息：打印请求数据的大小和内容概要
      final requestJson = jsonEncode(requestData);
      print('DeepSeek API 请求大小: ${requestJson.length} 字符');
      print('DeepSeek API 请求消息数量: ${messages.length}');

      // 如果有附件，打印附件信息
      if (userMessage.attachments.isNotEmpty) {
        print('附件数量: ${userMessage.attachments.length}');
        for (int i = 0; i < userMessage.attachments.length; i++) {
          final attachment = userMessage.attachments[i];
          print(
            '附件 $i: ${attachment.name}, 内容长度: ${attachment.content?.length ?? 0}',
          );
        }
      }

      final response = await dio.post<ResponseBody>(
        chatModel.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${chatModel.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );
      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.trim().startsWith('data: ')) {
              final dataStr = line.trim().substring(6);
              if (dataStr == '[DONE]') {
                return;
              }
              try {
                final data = jsonDecode(dataStr);
                final content = _processOpenAIStreamResponse(data);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                print('DeepSeek流式解析错误: $e, 数据: $dataStr');
              }
            }
          }
        }
      } else {
        yield 'API 请求失败：{response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  // 其他API流式方法同步调整为ChatSession参数
  Stream<String> _sendToOpenAIStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 使用模型设置
      final double temperature = chatModel.chatSettings?.temperature ?? 0.7;
      int maxTokens = 2000;

      // 构建请求数据，使用支持MCP服务的方法
      final messages = _buildMessages();

      final requestData = {
        'model': chatModel.model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      };

      // 如果启用了MCP工具，添加tools字段
      if (chatSession.mcpServer != null &&
          McpService.hasGlobalMcpServices) {
        final tools = McpService.buildOpenAIToolsFormat(chatSession);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto'; // 让AI自动决定是否使用工具
        }
      }

      final response = await dio.post<ResponseBody>(
        chatModel.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${chatModel.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.trim().startsWith('data: ')) {
              final dataStr = line.trim().substring(6);
              if (dataStr == '[DONE]') {
                return;
              }
              try {
                final data = jsonDecode(dataStr);
                final content = _processOpenAIStreamResponse(data);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                print('OpenAI流式解析错误: $e, 数据: $dataStr');
              }
            }
          }
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  Stream<String> _sendToAnthropicStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 注意：Claude需要特殊的消息格式处理
      final userContent = _buildUserContent();

      final requestData = {
        'model': chatModel.model,
        'max_tokens': 2000,
        'messages': [
          {'role': 'user', 'content': userContent},
        ],
      };

      final response = await dio.post(
        chatModel.apiUrl!,
        options: Options(
          headers: {
            'x-api-key': chatModel.apiKey,
            'Content-Type': 'application/json',
            'anthropic-version': '2023-06-01',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['content'] != null && data['content'].isNotEmpty) {
          yield data['content'][0]['text'] ?? '抱歉，没有收到回复';
        } else {
          yield '抱歉，没有收到回复';
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  Stream<String> _sendToGeminiStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 使用MCP服务处理消息
      final processedMessage = _buildUserContent();

      final requestData = {
        'contents': [
          {
            'parts': [
              {'text': processedMessage},
            ],
          },
        ],
      };

      final response = await dio.post(
        chatModel.apiUrl!, // 已包含key参数
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content['parts'] != null && content['parts'].isNotEmpty) {
            yield content['parts'][0]['text'] ?? '抱歉，没有收到回复';
          } else {
            yield '抱歉，没有收到回复';
          }
        } else {
          yield '抱歉，没有收到回复';
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  Stream<String> _sendToQwenStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 使用模型设置
      final double temperature = chatModel.chatSettings?.temperature ?? 0.7;

      // 构建请求数据，使用支持MCP服务的方法
      final messages = _buildMessages();

      final requestData = {
        'model': chatModel.model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': 2000,
        'stream': true, // 启用流式响应
      };

      final response = await dio.post<ResponseBody>(
        chatModel.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${chatModel.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream, // 设置为流式响应
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.trim().startsWith('data: ')) {
              final dataStr = line.trim().substring(6);
              if (dataStr == '[DONE]') {
                return;
              }
              try {
                final data = jsonDecode(dataStr);
                if (data['choices'] != null && data['choices'].isNotEmpty) {
                  final delta = data['choices'][0]['delta'];
                  if (delta != null &&
                      delta['content'] != null &&
                      delta['content'].toString().isNotEmpty) {
                    yield delta['content'];
                  }
                }
              } catch (e) {
                print('Qwen流式解析错误: $e, 数据: $dataStr');
              }
            }
          }
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  Stream<String> _sendToZhipuStream() async* {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(milliseconds: timeout);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      final chatModel = chatSession.chatModel!;

      // 使用模型设置
      final double temperature = chatModel.chatSettings?.temperature ?? 0.7;

      // 构建请求数据，使用支持MCP服务的方法
      final messages = _buildMessages();

      final requestData = {
        'model': chatModel.model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': 2000,
        'stream': true, // 启用流式响应
      };

      // 如果启用了MCP工具，添加tools字段（魔塔兼容OpenAI格式）
      if (chatSession.mcpServer != null &&
          McpService.hasGlobalMcpServices) {
        final tools = McpService.buildOpenAIToolsFormat(chatSession);
        if (tools.isNotEmpty) {
          requestData['tools'] = tools;
          requestData['tool_choice'] = 'auto'; // 让AI自动决定是否使用工具
        }
      }

      //打印完整的请求数据
      debugPrint('ModelScope API 请求数据: ${jsonEncode(requestData)}');
      final response = await dio.post<ResponseBody>(
        chatModel.apiUrl!,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${chatModel.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream, // 设置为流式响应
        ),
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        String buffer = '';
        await for (final chunk in response.data!.stream) {
          final chunkString = utf8.decode(chunk);
          buffer += chunkString;
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.trim().startsWith('data: ')) {
              final dataStr = line.trim().substring(6);
              if (dataStr == '[DONE]') {
                return;
              }
              try {
                final data = jsonDecode(dataStr);
                final content = _processOpenAIStreamResponse(data);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                print('ModelScope流式解析错误: $e, 数据: $dataStr');
              }
            }
          }
        }
      } else {
        yield 'API 请求失败：${response.statusCode}';
      }
    } catch (e) {
      yield _handleApiError(e);
    }
  }

  /// 处理API错误的通用方法
  String _handleApiError(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('DioException')) {
      if (errorString.contains('CONNECT_TIMEOUT')) {
        return '网络连接超时，请检查网络设置';
      } else if (errorString.contains('RECEIVE_TIMEOUT')) {
        return 'API 响应超时，请稍后重试';
      } else if (errorString.contains('RESPONSE')) {
        return 'API 请求失败，请检查配置和网络';
      } else {
        return '网络连接错误：$error';
      }
    } else if (errorString.contains('401') ||
        errorString.contains('Unauthorized')) {
      return 'API 密钥无效，请检查密钥配置';
    } else if (errorString.contains('403') ||
        errorString.contains('Forbidden')) {
      return 'API 访问被拒绝，请检查权限设置';
    } else if (errorString.contains('404') ||
        errorString.contains('Not Found')) {
      return 'API 地址不存在，请检查 URL 配置';
    } else if (errorString.contains('429') ||
        errorString.contains('Too Many Requests')) {
      return 'API 调用频率过高，请稍后重试';
    } else if (errorString.contains('500') ||
        errorString.contains('Internal Server Error')) {
      return 'API 服务器内部错误，请稍后重试';
    } else {
      return 'API 错误：$error';
    }
  }
}
