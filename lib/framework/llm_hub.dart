import 'dart:async';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_message.dart';
import 'llmproviders/base_provider.dart';
import 'llmproviders/openai_provider.dart';
import 'llmproviders/deepseek_provider.dart';
import 'llmproviders/anthropic_provider.dart';
import 'llmproviders/modelscope_provider.dart';
import 'llmproviders/gemini_provider.dart';
import 'llmproviders/qwen_provider.dart';
import 'llmproviders/zhipu_provider.dart';
import 'llmproviders/ollama_provider.dart';

/// LLM Hub - 大模型统一调用框架
class LlmHub {
  final Map<String, BaseLlmProvider> _providers = {};

  /// 私有构造函数
  LlmHub._internal() {
    _initializeProviders();
  }

  /// 单例实例
  static final LlmHub _instance = LlmHub._internal();

  /// 获取单例实例
  static LlmHub get instance => _instance;

  /// 工厂构造函数
  factory LlmHub() => _instance;

  /// 初始化所有提供商
  void _initializeProviders() {
    _providers['openai'] = OpenAiProvider();
    _providers['deepseek'] = DeepSeekProvider();
    _providers['anthropic'] = AnthropicProvider();
    _providers['modelscope'] = ModelScopeProvider();
    _providers['gemini'] = GeminiProvider();
    _providers['qwen'] = QwenProvider();
    _providers['zhipu'] = ZhipuProvider();
    _providers['ollama'] = OllamaProvider();
  }

 
  /// 直接通过 ChatModel 创建客户端（推荐方式）
  LlmClient createClient(ChatModel model) {
    print("=== LlmHub.createClient 被调用 ===");
    print("模型提供商: ${model.provider}");
    print("模型名称: ${model.name}");
    print("模型ID: ${model.model}");
    print("可用提供商: ${_providers.keys.toList()}");
    
    if (model.provider == null || model.provider!.isEmpty) {
      throw ArgumentError('模型必须指定提供商');
    }
    
    final llmProvider = _providers[model.provider];
    print("找到的提供商: ${llmProvider.runtimeType}");
    
    if (llmProvider == null) {
      throw UnsupportedError('不支持的提供商: ${model.provider}');
    }
    
    final client = LlmClient._(llmProvider);
    client.configure(model);
    print("客户端配置完成");
    return client;
  }

  /// 根据 ChatSession 创建客户端
  LlmClient createClientFromSession(ChatSession session) {
    if (session.chatModel == null) {
      throw ArgumentError('会话必须绑定模型');
    }
    return createClient(session.chatModel!);
  }

  /// 获取所有支持的提供商
  List<String> getSupportedProviders() {
    return _providers.keys.toList();
  }

  /// 检查提供商是否支持
  bool isProviderSupported(String provider) {
    return _providers.containsKey(provider);
  }
}

/// LLM 客户端 - 用于具体的模型调用
class LlmClient {
  final BaseLlmProvider _llmProvider;
  ChatModel? _model;

  /// 内部构造函数
  LlmClient._(this._llmProvider);

  /// 清理资源
  Future<void> dispose() async {}

  /// 便捷的静态工厂方法 - 直接通过 ChatModel 创建客户端
  static LlmClient fromModel(ChatModel model) {
    return LlmHub.instance.createClient(model);
  }

 
  /// 便捷的静态工厂方法 - 通过 ChatSession 创建客户端
  static LlmClient fromSession(ChatSession session) {
    return LlmHub.instance.createClientFromSession(session);
  }

  /// 配置模型
  void configure(ChatModel model, {String? ragId}) {
    _model = model;
    _llmProvider.configure(model);
  }

  /// 设置RAG知识库（已废弃，保留兼容性）
  @Deprecated('RAG功能已移除')
  void setRagKnowledgeBase(String? ragId) {}

  /// 获取当前配置的模型
  ChatModel? get model => _model;

  /// 发送消息 - 流式响应
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    print("=== LlmClient.sendMessageStream 被调用 ===");
    print("提供商类型: ${_llmProvider.runtimeType}");
    print("用户消息: ${userMessage.content}");
    
    if (_model == null) {
      print("错误: 客户端未配置模型");
      throw StateError('客户端未配置模型');
    }

    print("准备调用提供商的 sendMessageStream 方法");
    return _llmProvider.sendMessageStream(
      userMessage: userMessage,
      session: session,
    );
  }

  /// 发送消息 - 一次性响应
  Future<String> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  }) async {
    final buffer = StringBuffer();
    await for (final chunkMap in sendMessageStream(
      userMessage: userMessage,
      session: session,
    )) {
      buffer.write(chunkMap['content'] ?? '');
    }
    return buffer.toString();
  }

  /// 验证配置
  Future<bool> validateConfiguration() async {
    print("=== LlmClient.validateConfiguration 被调用 ===");
    
    if (_model == null) {
      print('LlmClient 验证失败: 客户端未配置模型');
      throw StateError('客户端未配置模型');
    }

    print('开始验证配置...');
    print('提供商: ${_model!.provider}');
    print('模型: ${_model!.model}');
    print('API URL: ${_model!.apiUrl}');
    if (_model!.apiKey != null && _model!.apiKey!.isNotEmpty) {
      print('API Key: ${_model!.apiKey!.substring(0, _model!.apiKey!.length > 10 ? 10 : _model!.apiKey!.length)}...');
    } else {
      print('API Key: 未设置或为空');
    }

    try {
      print('调用提供商的 validateConfiguration 方法...');
      final isValid = await _llmProvider.validateConfiguration();

      print('配置验证结果: ${isValid ? '成功' : '失败'}');

      return isValid;
    } catch (e) {
      print('配置验证过程中发生错误: $e');
      return false;
    }
  }

  /// 获取模型信息
  Future<Map<String, dynamic>?> getModelInfo() async {
    if (_model == null) {
      throw StateError('客户端未配置模型');
    }
    return _llmProvider.getModelInfo();
  }

  /// 获取支持的功能
  List<String> getSupportedFeatures() {
    return _llmProvider.getSupportedFeatures();
  }

  /// 检查是否支持某项功能
  bool supportsFeature(String feature) {
    return _llmProvider.supportsFeature(feature);
  }

  /// 构建系统提示词
  String buildSystemPrompt({String? customPrompt, ChatSession? session}) {
    return _llmProvider.buildSystemPrompt(customPrompt: customPrompt, session: session);
  }

  /// 构建消息列表
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    return _llmProvider.buildMessages(userMessage: userMessage, session: session);
  }

  /// 发送预构建的消息列表（用于 MCP tool call follow-up 等场景）
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages,
  ) {
    if (_model == null) {
      throw StateError('客户端未配置模型');
    }
    return _llmProvider.sendMessageStreamWithMessages(messages);
  }

  /// 处理工具调用（MCP）
  Future<Map<String, dynamic>?> handleToolCall({
    required Map<String, dynamic> toolCall,
    ChatSession? session,
  }) async {
    if (!supportsFeature('tool_calling')) {
      return null;
    }
    return _llmProvider.handleToolCall(toolCall: toolCall, session: session);
  }
}

/// 使用示例和便捷方法
class LlmHubExamples {
  /// 示例：使用新的简化方式创建客户端（推荐）
  static Future<void> simplifiedExample() async {
    // 创建模型配置
    final model = ChatModel.create(
      name: 'GPT-4',
      model: 'gpt-4',
      provider: 'openai',
      apiKey: 'your-api-key',
      apiUrl: 'https://api.openai.com/v1',
    );

    // 方式1：使用静态工厂方法（最简单）
    final client = LlmClient.fromModel(model);

    // 方式2：使用 LlmHub（等价于方式1）
    // final client = LlmHub.instance.createClientFromModel(model);

    // 验证配置
    final isValid = await client.validateConfiguration();
    if (!isValid) {
      print('配置验证失败');
      return;
    }

    // 发送消息
    final userMessage = ChatMessage(
      msgId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      content: '你好！请简单介绍一下你自己。',
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    // 流式响应
    print('AI回复: ');
    await for (final chunkMap in client.sendMessageStream(userMessage: userMessage)) {
      print(chunkMap['content'] ?? '');
    }

    // 释放资源
    client.dispose();
  }

  }
