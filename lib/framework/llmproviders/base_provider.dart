import 'dart:async';
import 'package:get/get.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_attachment.dart';
import '../../services/system_tool_service.dart';
import '../../services/skill_service.dart';
import 'common/message_builder.dart';
import 'common/system_prompts.dart';

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

  /// 安全函数名 → 原始函数名 映射（用于还原 MCP/Skill 工具名中的非法字符）
  static final Map<String, String> _safeNameToOriginal = {};

  /// 根据安全名称还原原始工具名；若未映射则原样返回
  static String resolveOriginalToolName(String safeName) {
    return _safeNameToOriginal[safeName] ?? safeName;
  }

  /// 代码文件类型集合
  static const Set<String> codeFileExtensions = {
    '.dart',
    '.js',
    '.ts',
    '.py',
    '.java',
    '.cpp',
    '.c',
    '.h',
    '.hpp',
    '.go',
    '.mod',
    '.sum',
    '.rs',
    '.rb',
    '.php',
    '.swift',
    '.kt',
    '.scala',
    '.html',
    '.css',
    '.json',
    '.xml',
    '.yaml',
    '.yml',
    '.toml',
    '.ini',
    '.sh',
    '.bash',
    '.zsh',
    '.fish',
    '.ps1',
    '.bat',
    '.cmd',
    '.sql',
    '.r',
    '.m',
    '.mm',
    '.pl',
    '.lua',
    '.vim',
    '.asm',
    '.conf',
    '.config',
    '.cfg',
    '.env',
    '.properties',
    '.dockerfile',
    '.gitignore',
    '.gitattributes',
    '.makefile',
    '.cmake',
    '.gradle',
  };

  /// 当前配置的模型
  ChatModel? _model;

  /// 是否启用深度思考模式（由会话设置控制）
  bool _thinkEnabled = false;

  /// 会话工作目录（用于文件生成默认路径）
  String? _workDir;

  /// 获取当前配置的模型
  ChatModel? get model => _model;

  /// 获取深度思考模式是否启用
  bool get thinkEnabled => _thinkEnabled;

  /// 提供商显示名称（子类必须重写）
  String get providerName;

  /// 配置模型
  void configure(ChatModel model) {
    _model = model;
    onConfigure(model);
  }

  /// 根据会话设置更新 provider 状态
  void applySessionSettings(ChatSession session) {
    _thinkEnabled = session.deepThink;
    _workDir =
        (session.workDirectory != null &&
                session.workDirectory!.trim().isNotEmpty)
            ? session.workDirectory!.trim()
            : null;
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

  /// 构建系统提示词字符串（合并所有系统消息）
  String buildSystemPrompt(ChatSession? session) {
    return MessageBuilder.buildSystemPrompt(
      model: model,
      session: session,
      providerPrompt: providerPrompt,
    );
  }

  /// 构建消息列表（系统提示词 + 历史 + 用户消息）
  ///
  /// 按顺序组装：模型 systemPrompt → provider 提示词 → 公共规则 →
  /// 技能提示词 → 深度思考 → 工具信息 → 历史消息 → 用户消息 →
  /// 模型设置覆盖。
  /// 子类可覆写以自定义消息构建策略。
  List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    ChatSession? session,
  }) {
    var messages = <Map<String, dynamic>>[];
    final m = model;

    // ── 1. 系统提示词（按优先级排列，最重要的放最后） ──
    // 1a. 模型级自定义 system prompt
    if (m?.chatSettings?.systemPrompt != null &&
        m!.chatSettings!.systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': m.chatSettings!.systemPrompt});
    }

    // 1b. Provider 特有提示词
    if (providerPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': providerPrompt});
    }

    // 1c. 回复语言
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(Get.locale?.languageCode ?? 'zh'),
    });

    // 1d. 技能提示词
    if (session?.skill != null) {
      final sp = SkillService.buildSkillPrompt(session!.skill);
      if (sp.isNotEmpty) {
        messages.add({'role': 'system', 'content': sp});
      }
    }

    // 1e. 深度思考模式
    if (_thinkEnabled) {
      messages.add({
        'role': 'system',
        'content': CommonSystemPrompts.deepThink,
      });
    }

    // 1f. 工作目录
    if (_workDir != null) {
      messages.add({
        'role': 'system',
        'content': CommonSystemPrompts.workDirectory(_workDir!),
      });
    }

    // 1g. 记忆上下文
    if (session != null) {
      final memoryCtx = _buildMemoryContext(session);
      if (memoryCtx.isNotEmpty) {
        messages.add({'role': 'system', 'content': memoryCtx});
      }
    }

    // ── 2. 历史消息（滑动窗口，保留 user/assistant/tool） ──
    if (session != null && session.messages.isNotEmpty) {
      _appendHistoryMessages(messages, session, userMessage);
    }

    // ── 3. 核心规则（放在用户消息紧前面，优先级最高） ──
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.coreRules,
    });

    // ── 4. 当前用户消息 + 附件 ──
    final userContent = _buildUserContent(userMessage);
    messages.add({'role': 'user', 'content': userContent});

    // ── 4. 模型设置覆盖（子类可覆写） ──
    messages = _applyModelOverrides(messages);

    return messages;
  }

  /// 构建记忆上下文，合并压缩记忆和最近记忆，注入系统提示词
  static String _buildMemoryContext(ChatSession session) {
    final buf = StringBuffer();
    var hasContent = false;

    if (session.compressedMemory != null &&
        session.compressedMemory!.isNotEmpty) {
      buf.writeln('## 📝 对话历史记忆（压缩摘要）');
      buf.writeln(session.compressedMemory);
      hasContent = true;
    }

    if (session.memory.isNotEmpty) {
      if (hasContent) buf.writeln();
      buf.writeln('## 💬 最近对话记录');
      for (final turn in session.memory) {
        final label = turn.role == 'user' ? '👤 用户' : '🤖 助手';
        buf.writeln('$label: ${turn.content}');
      }
    }

    return buf.toString();
  }

  /// 构建 OpenAI 兼容的请求体
  ///
  /// 首次请求传 [userMessage]，内部调用 [buildMessages] 自动组装。
  /// 工具回调时传 [messages] 使用预构建消息。
  /// 子类（anthropic/gemini/ollama）可覆写以适配各自的 API 格式。
  Map<String, dynamic> buildRequestData({
    ChatMessage? userMessage,
    List<Map<String, dynamic>>? messages,
    required bool stream,
    ChatSession? session,
    Map<String, dynamic>? extra,
  }) {
    final msgs =
        messages ?? buildMessages(userMessage: userMessage!, session: session);

    final data = <String, dynamic>{
      'model': model!.model,
      'messages': msgs,
      'stream': stream,
      'max_tokens': 4000,
      'temperature': model!.chatSettings?.temperature ?? 0.7,
    };

    if (session != null) {
      var tools = buildTools(session);

      // 根据用户输入分词，过滤不相关的工具
      // final userText = _extractUserText(userMessage, msgs);
      // if (userText.isNotEmpty && tools.length > 1) {
      //   tools = _filterToolsByUserInput(userText, tools);
      // }

      if (tools.isNotEmpty) {
        data['tools'] = tools;
        data['tool_choice'] = 'auto';
      }
      if (session.deepThink) {
        data['thinking'] = {'type': 'enabled'};
      } else {
        data['thinking'] = {'type': 'disabled'};
      }
    }

    if (extra != null) data.addAll(extra);
    return data;
  }

  /// 构建 OpenAI 兼容的认证头
  ///
  /// 子类（anthropic/gemini/ollama）可覆写以适配各自的认证方式。
  Map<String, String> buildAuthHeaders() {
    return {
      'Authorization': 'Bearer ${model!.apiKey}',
      'Content-Type': 'application/json',
    };
  }

  /// Provider 特有的提示词，会注入到系统消息中
  /// 子类可覆写以添加模型特定的指令
  String get providerPrompt => '';

  /// 构建可用工具列表（OpenAI function-calling 格式）
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    final allTools = <Map<String, dynamic>>[];
    // 系统内置工具始终可用（包括 DWG 读取等专用工具）
    allTools.addAll(SystemToolService.buildOpenAIToolsFormat());
    // MCP 服务工具（直接使用 session.mcp.tools）
    final mcp = session?.mcp;
    if (mcp != null && mcp.tools != null && mcp.tools!.isNotEmpty) {
      for (final tool in mcp.tools!) {
        // OpenAI function calling 要求函数名仅含 [a-zA-Z0-9_-]，将不合法字符替换为下划线
        final safeName = tool.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        if (safeName != tool.name) {
          _safeNameToOriginal[safeName] = tool.name;
        }
        final schema = <String, dynamic>{
          'type': 'function',
          'function': <String, dynamic>{
            'name': safeName,
            'description': tool.description,
          },
        };
        if (tool.inputSchema.isNotEmpty) {
          final s = Map<String, dynamic>.from(tool.inputSchema);
          if (!s.containsKey('type')) s['type'] = 'object';
          if (!s.containsKey('properties')) {
            s['properties'] = <String, dynamic>{};
          }
          schema['function']['parameters'] = s;
        } else {
          schema['function']['parameters'] = {
            'type': 'object',
            'properties': <String, dynamic>{},
            'required': <String>[],
          };
        }

        allTools.add(schema);
      }
    }
    // 技能工具（遍历 skill.tools，和 MCP 一样）
    if (session?.skill != null && session!.skill!.tools != null) {
      for (final tool in session.skill!.tools!) {
        // OpenAI function calling 要求函数名仅含 [a-zA-Z0-9_-]，将不合法字符替换为下划线
        final safeName = tool.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        if (safeName != tool.name) {
          _safeNameToOriginal[safeName] = tool.name;
        }
        final schema = <String, dynamic>{
          'type': 'function',
          'function': <String, dynamic>{
            'name': safeName,
            'description': tool.description,
          },
        };
        if (tool.inputSchema.isNotEmpty) {
          final s = Map<String, dynamic>.from(tool.inputSchema);
          if (!s.containsKey('type')) s['type'] = 'object';
          if (!s.containsKey('properties'))
            s['properties'] = <String, dynamic>{};
          schema['function']['parameters'] = s;
        } else {
          schema['function']['parameters'] = {
            'type': 'object',
            'properties': <String, dynamic>{},
            'required': <String>[],
          };
        }
        allTools.add(schema);
      }
    }
    return allTools;
  }

  /// 模型设置覆盖消息列表（最后一步，子类可覆写）
  ///
  /// 例如：某些模型需要修改消息格式、追加特定指令等。
  List<Map<String, dynamic>> _applyModelOverrides(
    List<Map<String, dynamic>> messages,
  ) {
    return messages;
  }

  // ── 历史消息处理 ──

  /// 将当前消息之前的会话历史追加到消息列表中（滑动窗口）
  void _appendHistoryMessages(
    List<Map<String, dynamic>> messages,
    ChatSession session,
    ChatMessage currentUserMessage,
  ) {
    // 定位当前用户消息在 session.messages 中的位置
    int userMsgIndex = session.messages.length;
    for (int i = session.messages.length - 1; i >= 0; i--) {
      if (session.messages[i].msgId == currentUserMessage.msgId) {
        userMsgIndex = i;
        break;
      }
    }

    if (userMsgIndex <= 0) return;

    final historyMessages = session.messages.sublist(0, userMsgIndex);
    final int maxRounds = session.memoryRounds;
    if (maxRounds <= 0) return;

    // 按轮数截断（从后往前数 user 消息轮次）
    int roundCount = 0;
    int historyStart = 0;
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
    for (final msg in included) {
      // 保留 user/assistant/tool 消息
      if (msg.content.isEmpty && msg.attachments.isEmpty) continue;
      final apiRole = _toOpenAIRole(msg.role);
      if (apiRole == null) continue;

      if (msg.role == MessageRole.user && msg.attachments.isNotEmpty) {
        final msgContent = _buildUserContent(msg);
        messages.add({'role': apiRole, 'content': msgContent});
      } else if (msg.role == MessageRole.tool) {
        // tool 消息需要 tool_call_id（如果有的话）
        messages.add({
          'role': 'tool',
          'tool_call_id': msg.toolCallId ?? msg.msgId,
          'content': msg.content,
        });
      } else {
        messages.add({'role': apiRole, 'content': msg.content});
      }
    }
  }

  static String? _toOpenAIRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.bot:
        return 'assistant';
      case MessageRole.tool:
        return 'tool';
    }
  }

  // ── 用户消息 + 附件内容构建 ──

  /// 构建包含附件信息的用户消息内容
  static dynamic _buildUserContent(ChatMessage userMessage) {
    if (userMessage.attachments.isEmpty) {
      return userMessage.content;
    }

    final hasImageAttachment = userMessage.attachments.any(
      (a) =>
          a.type == 'image' && a.base64Data != null && a.base64Data!.isNotEmpty,
    );

    if (hasImageAttachment) {
      final parts = <Map<String, dynamic>>[];
      for (final a in userMessage.attachments) {
        if (a.type == 'image' &&
            a.base64Data != null &&
            a.base64Data!.isNotEmpty) {
          final dataUri =
              'data:${a.mimeType ?? "image/png"};base64,${a.base64Data}';
          parts.add({
            'type': 'image_url',
            'image_url': {'url': dataUri},
          });
          if (a.content != null && a.content!.isNotEmpty) {
            final path =
                (a.filePath != null && a.filePath!.isNotEmpty)
                    ? a.filePath!
                    : a.name;
            parts.add({'type': 'text', 'text': '[图片: $path] ${a.content}'});
          }
        } else {
          parts.add({'type': 'text', 'text': _buildAttachmentInfo(a)});
        }
      }
      parts.add({'type': 'text', 'text': userMessage.content});
      return parts;
    }

    final infos = userMessage.attachments.map(_buildAttachmentInfo).toList();
    return '${infos.join('\n\n')}\n\n ${userMessage.content}';
  }

  static String _buildAttachmentInfo(ChatAttachment a) {
    final buf = StringBuffer();
    const labels = {
      'image': '图片文件',
      'document': '文档文件',
      'text': '文档文件',
      'code': '代码文件',
      'web': '网页链接',
      'folder': '文件夹',
    };
    final label = labels[a.type] ?? '文件';
    final path =
        (a.filePath != null && a.filePath!.isNotEmpty) ? a.filePath! : a.name;
    buf.write('[$label: $path');
    if (a.size != null && a.size! > 0) {
      buf.write(', 大小: ${_formatFileSize(a.size!)}');
    }
    buf.write(']\n');

    if (a.content == null || a.content!.isEmpty) {
      buf.write('[文件处理中...]');
    } else if (a.content == 'ERROR_PROCESSING') {
      buf.write('[文件处理失败]');
    } else {
      buf.write(a.content!);
    }
    return buf.toString();
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

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
