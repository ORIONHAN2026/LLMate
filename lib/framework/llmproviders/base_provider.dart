import 'dart:async';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';

/// 基础 LLM 提供商抽象类
///
/// 定义所有 LLM 提供商必须实现的接口。
/// **不包含任何具体业务逻辑**。
///
/// 所有具体实现位于各子类或 common/ 目录下的共享工具中：
/// - OpenAI 兼容协议：[OpenAICompatibleMixin]
/// - 消息构建：[MessageBuilder]
/// - 公共系统提示词：[CommonSystemPrompts]
abstract class BaseLlmProvider {
  /// 连接超时（毫秒）
  static const int defaultTimeout = 30000;

  /// 代码文件类型集合
  static const Set<String> codeFileExtensions = {
    '.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.hpp',
    '.go', '.mod', '.sum', '.rs', '.rb', '.php', '.swift', '.kt',
    '.scala', '.html', '.css', '.json', '.xml', '.yaml', '.yml', '.toml',
    '.ini', '.sh', '.bash', '.zsh', '.fish', '.ps1', '.bat', '.cmd',
    '.sql', '.r', '.m', '.mm', '.pl', '.lua', '.vim', '.asm',
    '.conf', '.config', '.cfg', '.env', '.properties', '.dockerfile',
    '.gitignore', '.gitattributes', '.makefile', '.cmake', '.gradle',
  };

  /// 当前配置的模型
  ChatModel? _model;

  /// 获取当前配置的模型
  ChatModel? get model => _model;

  /// 提供商显示名称（子类必须重写）
  String get providerName;

  /// 配置模型
  void configure(ChatModel model) {
    _model = model;
    onConfigure(model);
  }

  /// 子类可重写此方法处理配置
  void onConfigure(ChatModel model) {}

  // ── 子类必须实现的抽象方法 ──

  /// 发送消息 - 流式响应
  Stream<Map<String, String?>> sendMessageStream({
    required ChatMessage userMessage,
    ChatSession? session,
  });

  /// 发送预构建消息列表 - 流式响应（用于 MCP tool call follow-up 等场景）
  Stream<Map<String, String?>> sendMessageStreamWithMessages(
    List<Map<String, dynamic>> messages, {
    ChatSession? session,
  });

  /// 发送消息 - 非流式响应
  Future<String?> sendMessage({
    required ChatMessage userMessage,
    ChatSession? session,
  });

  /// 验证配置
  Future<bool> validateConfiguration();

  /// 构建系统提示词
  String buildSystemPrompt(ChatSession? session);

  /// 构建消息列表（系统提示词 + 历史 + 用户消息）
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  });

  /// 解析 AI 响应中的工具调用
  Map<String, dynamic> parseToolCalls(String response);

  // ── 可选重写的方法（有默认实现） ──

  /// 获取支持的功能列表
  List<String> getSupportedFeatures() {
    return [LlmFeatures.textGeneration, LlmFeatures.streaming];
  }

  /// 检查是否支持某项功能
  bool supportsFeature(String feature) {
    return getSupportedFeatures().contains(feature);
  }

  /// 获取模型信息
  Future<Map<String, dynamic>?> getModelInfo() async {
    return null;
  }
}

/// 支持的功能常量
class LlmFeatures {
  LlmFeatures._();
  static const String textGeneration = 'text_generation';
  static const String streaming = 'streaming';
  static const String toolCalling = 'tool_calling';
  static const String imageAnalysis = 'image_analysis';
  static const String codeGeneration = 'code_generation';
  static const String functionCalling = 'function_calling';
  static const String embeddings = 'embeddings';
  static const String fineTuning = 'fine_tuning';
}
