import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_attachment.dart';
import '../../services/mcp_service.dart';

/// 基础LLM提供商抽象类
/// 定义了所有LLM提供商必须实现的接口
abstract class BaseLlmProvider {
  static const int defaultTimeout = 30000; // 30秒超时

  /// 当前配置的模型
  ChatModel? _model;

  /// 代码文件类型集合
  static const Set<String> codeFileExtensions = {
    '.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.hpp',
    '.go', '.mod', '.sum', '.rs', '.rb', '.php', '.swift', '.kt', '.scala',
    '.html', '.css', '.json', '.xml', '.yaml', '.yml', '.toml', '.ini',
    '.sh', '.bash', '.zsh', '.fish', '.ps1', '.bat', '.cmd',
    '.sql', '.r', '.m', '.mm', '.pl', '.lua', '.vim', '.asm',
    '.conf', '.config', '.cfg', '.env', '.properties',
    '.dockerfile', '.gitignore', '.gitattributes', '.makefile', '.cmake', '.gradle'
  };

  /// 构造函数
  BaseLlmProvider();

  /// 获取当前配置的模型
  ChatModel? get model => _model;

  /// 获取HTTP客户端
  Dio get dio {
    // 简化方式：每次都创建新的 Dio 实例，避免管理复杂性
    final client = Dio();
    client.options.connectTimeout = const Duration(
      milliseconds: defaultTimeout,
    );
    client.options.receiveTimeout = const Duration(minutes: 5);
    client.options.sendTimeout = const Duration(minutes: 5);

    // 添加拦截器来处理错误
    client.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          if (kDebugMode) {
            print('=== Dio拦截器捕获错误 ===');
            print('错误类型: ${error.type}');
            print('错误消息: ${error.message}');
            print('请求URL: ${error.requestOptions.uri}');
            print('=======================');
          }
          handler.next(error);
        },
      ),
    );

    return client;
  }

  /// 配置模型
  void configure(ChatModel model) {
    _model = model;
    onConfigure(model);
  }

  /// 子类可以重写此方法来处理配置
  void onConfigure(ChatModel model) {}

  /// 发送消息 - 流式响应（必须实现）
  /// 返回包含 content 和 think 两个字段的数据流
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  });

  /// 发送预构建消息列表 - 流式响应（用于 MCP tool call follow-up 等场景）
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  );

  /// 发送消息 - 非流式响应（必须实现）
  /// 返回完整的响应内容
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  });

  /// 发送简单文本消息并获取完整响应（用于代码描述等场景）
  Future<String?> sendSimpleMessage(String prompt) async {
    try {
      // 创建临时消息
      final message = ChatMessage(
        msgId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        content: prompt,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      // 直接使用非流式请求
      final result = await sendMessage(userMessage: message);
      return result?.trim().isNotEmpty == true ? result!.trim() : null;
    } catch (e) {
      if (kDebugMode) {
        print('简单消息发送失败: $e');
      }
      return null;
    }
  }

  /// 验证配置（必须实现）
  Future<bool> validateConfiguration() async {
    // 基本配置检查
    if (_model == null) {
      if (kDebugMode) {
        print('配置验证失败: 模型未配置');
      }
      return false;
    }

    // 检查必要的配置项
    if (_model!.apiUrl == null || _model!.apiUrl!.isEmpty) {
      if (kDebugMode) {
        print('配置验证失败: API URL 未配置');
      }
      return false;
    }

    // 检查API Key（如果需要）
    if (_model!.apiKey == null || _model!.apiKey!.isEmpty) {
      if (kDebugMode) {
        print('配置验证失败: API Key 未配置');
      }
      return false;
    }

    // 检查模型名称
    if (_model!.model.isEmpty) {
      if (kDebugMode) {
        print('配置验证失败: 模型名称未配置');
      }
      return false;
    }

    // 子类可以重写此方法进行更详细的验证
    return await performDetailedValidation();
  }

  /// 执行详细的配置验证（子类可以重写）
  Future<bool> performDetailedValidation() async {
    // 不进行实际的网络请求验证，因为模型在添加时已经验证过了
    // 只做基本的配置完整性检查
    try {
      if (kDebugMode) {
        print('=== 配置验证检查 ===');
        print('提供商: ${_model!.provider}');
        print('模型: ${_model!.model}');
        print('API URL: ${_model!.apiUrl}');
        print('API Key: ${_model!.apiKey != null ? '已配置' : '未配置'}');
        print('==================');
      }

      // 基本配置检查通过即可，不发送实际网络请求
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('=== 配置验证异常 ===');
        print('错误: $e');
        print('错误类型: ${e.runtimeType}');
        print('==================');
      }
      return false;
    }
  }

  /// 获取模型信息（可选实现）
  Future<Map<String, dynamic>?> getModelInfo() async {
    return null;
  }

  /// 获取支持的功能列表
  List<String> getSupportedFeatures() {
    return ['text_generation', 'streaming'];
  }

  /// 检查是否支持某项功能
  bool supportsFeature(String feature) {
    return getSupportedFeatures().contains(feature);
  }

  /// 构建系统提示词
  String buildSystemPrompt({String? customPrompt, ChatSession? session}) {
    final List<String> systemParts = [];
    final chatModel = _model;

    // 用户自定义系统提示词
    if (customPrompt != null && customPrompt.isNotEmpty) {
      systemParts.add(customPrompt);
    } else if (chatModel?.chatSettings?.systemPrompt != null &&
        chatModel!.chatSettings!.systemPrompt.isNotEmpty) {
      systemParts.add(chatModel.chatSettings!.systemPrompt);
    }

    // 语言指令
    if (chatModel?.chatSettings?.replyLanguage != null &&
        chatModel!.chatSettings!.replyLanguage.isNotEmpty) {
      systemParts.add('请使用 ${chatModel.chatSettings!.replyLanguage} 回复。');
    }

    // MCP 工具信息：将可用工具的描述注入到系统提示词中
    if (session != null && session.mcpServer != null) {
      final mcpToolsInfo = McpService.buildMcpToolsInfoForApi(session);
      if (mcpToolsInfo.isNotEmpty) {
        systemParts.add(mcpToolsInfo);
      }
    }

    systemParts.add('请严格遵照系统提示词进行回答。');

    return systemParts.join('\n\n');
  }

  /// 构建消息列表（包含会话历史，实现"记忆"能力）
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    final messages = <Map<String, dynamic>>[];

    // 添加系统提示词（传入 session 以支持 MCP 工具信息注入）
    final systemPrompt = buildSystemPrompt(session: session);
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    // 添加会话历史（当前用户消息之前的所有消息）
    if (session != null && session.messages.isNotEmpty) {
      _appendHistoryMessages(messages, session, userMessage);
    }

    // 构建包含附件信息的用户消息内容
    final userContent = _buildUserContentWithAttachments(userMessage);
    messages.add({'role': 'user', 'content': userContent});

    return messages;
  }

  /// 将当前消息之前的会话历史追加到消息列表中（滑动窗口）
  void _appendHistoryMessages(
    List<Map<String, dynamic>> messages,
    ChatSession session,
    ChatMessage currentUserMessage,
  ) {
    // 找到当前用户消息在历史中的位置（从此位置之前截取历史）
    int userMsgIndex = session.messages.length;
    for (int i = session.messages.length - 1; i >= 0; i--) {
      if (session.messages[i].msgId == currentUserMessage.msgId) {
        userMsgIndex = i;
        break;
      }
    }

    // 没有有效历史则跳过
    if (userMsgIndex <= 0) return;

    final historyMessages = session.messages.sublist(0, userMsgIndex);

    // 保留最近 20 轮对话（以 user 消息为轮次边界）
    const int maxRounds = 20;
    int roundCount = 0;
    int historyStart = historyMessages.length;

    for (int i = historyMessages.length - 1; i >= 0; i--) {
      if (historyMessages[i].role == MessageRole.user) {
        roundCount++;
        if (roundCount >= maxRounds) {
          historyStart = i;
          break;
        }
      }
    }

    final included = historyMessages.sublist(historyStart);

    // 按时间顺序添加历史消息
    for (final msg in included) {
      // 跳过空内容消息（如占位 bot 消息）
      if (msg.content.isEmpty) continue;
      final apiRole = _toOpenAIRole(msg.role);
      if (apiRole == null) continue;

      final msgData = <String, dynamic>{'role': apiRole, 'content': msg.content};

      // tool 角色消息：附加 tool_call_id
      if (msg.role == MessageRole.tool && msg.toolName != null) {
        msgData['tool_call_id'] = msg.toolName;
      }

      messages.add(msgData);
    }
  }

  /// 将内部角色映射为 OpenAI 兼容的 API 角色
  String? _toOpenAIRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.bot:
        return 'assistant';
      case MessageRole.tool:
        return 'tool';
    }
  }

  /// 构建包含附件信息的用户消息内容
  String _buildUserContentWithAttachments(ChatMessage userMessage) {
    if (userMessage.attachments.isEmpty) {
      return userMessage.content;
    }

    final attachmentInfos = userMessage.attachments
        .map(_buildSingleAttachmentInfo)
        .toList();

    return '${attachmentInfos.join('\n\n')}\n\n ${userMessage.content}';
  }

  /// 构建单个附件信息
  String _buildSingleAttachmentInfo(ChatAttachment attachment) {
    final buffer = StringBuffer();
    
    // 添加文件类型和基本信息
    _addAttachmentHeader(buffer, attachment);
    
    // 添加文件大小信息
    _addAttachmentSize(buffer, attachment);
    
    buffer.write(']\n');
    
    // 添加文件内容
    _addAttachmentContent(buffer, attachment);
    
    return buffer.toString();
  }

  /// 添加附件头部信息
  void _addAttachmentHeader(StringBuffer buffer, ChatAttachment attachment) {
    final typeLabels = {
      'image': '图片文件',
      'document': '文档文件',
      'text': '文档文件', 
      'code': '代码文件',
      'web': '网页链接',
      'folder': '文件夹',
    };
    
    final label = typeLabels[attachment.type] ?? '文件';
    buffer.write('[$label: ${attachment.name}');
  }

  /// 添加附件大小信息
  void _addAttachmentSize(StringBuffer buffer, ChatAttachment attachment) {
    if (attachment.size != null && attachment.size! > 0) {
      buffer.write(', 大小: ${_formatFileSize(attachment.size!)}');
    }
  }

  /// 添加附件内容
  void _addAttachmentContent(StringBuffer buffer, ChatAttachment attachment) {
    if (attachment.content == null || attachment.content!.isEmpty) {
      buffer.write('[文件处理中...]');
    } else if (attachment.content == 'ERROR_PROCESSING') {
      buffer.write('[文件处理失败]');
    } else {
      buffer.write(attachment.content!);
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 处理工具调用（MCP支持）
  Future<Map<String, dynamic>?> handleToolCall({
    required Map<String, dynamic> toolCall,
    ChatSession? session,
  }) async {
    if (!supportsFeature('tool_calling')) {
      return null;
    }

    // 默认实现 - 子类可以重写
    return null;
  }

  /// 构建工具列表（MCP支持）
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    if (session == null || session.mcpServer == null) {
      return [];
    }

    return McpService.buildOpenAIToolsFormat(session);
  }

  /// 处理API错误
  String handleApiError(dynamic error) {
    final errorString = error.toString();

    if (kDebugMode) {
      _logApiError(error, errorString);
    }

    return _categorizeAndFormatError(errorString);
  }

  /// 记录API错误详情
  void _logApiError(dynamic error, String errorString) {
    print('=== API错误详情 ===');
    print('错误: $error');
    print('错误类型: ${error.runtimeType}');
    print('错误字符串: $errorString');
    print('================');
  }

  /// 分类并格式化错误信息
  String _categorizeAndFormatError(String errorString) {
    // 检查特殊的Dio客户端错误
    if (_isDioClientClosedError(errorString)) {
      return '连接错误，请重试发送消息';
    }

    // 检查DioException错误
    if (_isDioException(errorString)) {
      return _handleDioException(errorString);
    }

    // 检查HTTP状态码错误
    if (_isHttpStatusError(errorString)) {
      return _handleHttpStatusError(errorString);
    }

    // 检查其他网络错误
    if (_isNetworkError(errorString)) {
      return _handleNetworkError(errorString);
    }

    // 默认错误处理
    return 'API 错误：$errorString';
  }

  /// 检查是否是Dio客户端关闭错误
  bool _isDioClientClosedError(String errorString) {
    return errorString.contains(
      'Dio can\'t establish a new connection after it was closed',
    );
  }

  /// 检查是否是DioException
  bool _isDioException(String errorString) {
    return errorString.contains('DioException') || 
           errorString.contains('DioError');
  }

  /// 处理DioException错误
  String _handleDioException(String errorString) {
    final dioErrors = {
      'CONNECT_TIMEOUT': '网络连接超时，请检查网络设置',
      'RECEIVE_TIMEOUT': 'API 响应超时，请稍后重试',
      'RESPONSE': 'API 请求失败，请检查配置和网络',
      'CONNECTION_ERROR': '网络连接被拒绝，请检查网络连接和API地址',
      'Connection refused': '网络连接被拒绝，请检查网络连接和API地址',
      'Network is unreachable': '网络不可达，请检查网络连接',
    };

    for (final entry in dioErrors.entries) {
      if (errorString.contains(entry.key)) {
        return entry.value;
      }
    }

    return '网络连接错误：请检查网络设置和API配置';
  }

  /// 检查是否是HTTP状态码错误
  bool _isHttpStatusError(String errorString) {
    final statusCodes = ['401', '403', '404', '429', '500'];
    final statusMessages = ['Unauthorized', 'Forbidden', 'Not Found', 
                           'Too Many Requests', 'Internal Server Error'];
    
    return statusCodes.any((code) => errorString.contains(code)) ||
           statusMessages.any((msg) => errorString.contains(msg));
  }

  /// 处理HTTP状态码错误
  String _handleHttpStatusError(String errorString) {
    final httpErrors = {
      '401': 'API 密钥无效，请检查密钥配置',
      'Unauthorized': 'API 密钥无效，请检查密钥配置',
      '403': 'API 访问被拒绝，请检查权限设置',
      'Forbidden': 'API 访问被拒绝，请检查权限设置',
      '404': 'API 地址不存在，请检查 URL 配置',
      'Not Found': 'API 地址不存在，请检查 URL 配置',
      '429': 'API 调用频率过高，请稍后重试',
      'Too Many Requests': 'API 调用频率过高，请稍后重试',
      '500': 'API 服务器内部错误，请稍后重试',
      'Internal Server Error': 'API 服务器内部错误，请稍后重试',
    };

    for (final entry in httpErrors.entries) {
      if (errorString.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'HTTP 错误，请检查API配置';
  }

  /// 检查是否是网络错误
  bool _isNetworkError(String errorString) {
    return errorString.contains('SocketException') ||
           errorString.contains('HandshakeException') ||
           errorString.contains('FormatException') ||
           errorString.contains('Invalid JSON');
  }

  /// 处理网络错误
  String _handleNetworkError(String errorString) {
    if (errorString.contains('SocketException') || 
        errorString.contains('HandshakeException')) {
      return '网络连接失败，请检查网络设置和证书配置';
    }
    
    if (errorString.contains('FormatException') || 
        errorString.contains('Invalid JSON')) {
      return 'API 响应格式错误，请检查API配置';
    }

    return '网络错误，请检查网络连接';
  }
}

/// 支持的功能常量
class LlmFeatures {
  static const String textGeneration = 'text_generation';
  static const String streaming = 'streaming';
  static const String toolCalling = 'tool_calling';
  static const String imageAnalysis = 'image_analysis';
  static const String codeGeneration = 'code_generation';
  static const String functionCalling = 'function_calling';
  static const String embeddings = 'embeddings';
  static const String fineTuning = 'fine_tuning';
}
