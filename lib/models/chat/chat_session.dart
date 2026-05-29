import 'dart:io';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/bigmodel/mcp_config.dart';

import 'chat_message.dart';
import 'chat_attachment.dart';
import 'chat_setting.dart';
import 'skill_session_config.dart';
import 'web_search_session_config.dart';
import 'rag_session_config.dart';

// 聊天会话类
class ChatSession {
  final String sessionId;
  String name;
  final DateTime createdAt;
  final bool isFavorite;
  final String inputContent;
  final List<ChatAttachment> attachments;
  final bool isSending;
  final bool shouldStopResponse;
  final double scrollPosition;
  final String? lastSelectedDirectory;

  // === 会话级功能配置 ===

  /// 绑定的 MCP 服务（null = 未绑定）
  final McpServerConfig? mcpServer;

  /// 联网搜索配置
  final WebSearchSessionConfig webSearchConfig;

  /// RAG 搜索配置
  final RagSessionConfig ragConfig;

  /// 技能配置
  final SkillSessionConfig skillConfig;

  // ============================

  final ChatModel? chatModel;
  final List<ChatMessage> messages;
  final List<ChatCommand> sessionQuickCommands;

  ChatSession({
    required this.sessionId,
    required this.name,
    required this.createdAt,
    required this.messages,
    this.chatModel,
    this.isFavorite = false,
    this.inputContent = '',
    this.attachments = const [],
    this.isSending = false,
    this.shouldStopResponse = false,
    this.scrollPosition = 0.0,
    this.lastSelectedDirectory,
    this.mcpServer,
    this.webSearchConfig = const WebSearchSessionConfig(),
    this.ragConfig = const RagSessionConfig(),
    this.skillConfig = const SkillSessionConfig(),
    this.sessionQuickCommands = const [],
  });

  // 获取会话的预览文本
  String get previewText {
    if (messages.isEmpty) return '新对话';
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.role == MessageRole.user,
      orElse: () => messages.first,
    );
    return firstUserMessage.content.length > 20
        ? '${firstUserMessage.content.substring(0, 20)}...'
        : firstUserMessage.content;
  }

  DateTime get lastMessageTime {
    if (messages.isEmpty) return createdAt;
    return messages.last.timestamp;
  }

  String get modelName {
    if (chatModel != null) {
      return chatModel!.name.isNotEmpty ? chatModel!.name : chatModel!.model;
    }
    return '';
  }

  String get modelDisplayInfo {
    if (chatModel != null && chatModel!.model.isNotEmpty) {
      return chatModel!.name;
    } else {
      return '未设置对话大模型';
    }
  }

  ChatSession copyWith({
    String? sessionId,
    String? title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
    bool? isFavorite,
    String? inputContent,
    List<ChatAttachment>? attachments,
    bool? isSending,
    bool? shouldStopResponse,
    double? scrollPosition,
    String? lastSelectedDirectory,
    McpServerConfig? mcpServer,
    bool clearMcpServer = false,
    WebSearchSessionConfig? webSearchConfig,
    RagSessionConfig? ragConfig,
    SkillSessionConfig? skillConfig,
    ChatModel? chatModel,
    bool clearChatModel = false,
    List<ChatCommand>? sessionQuickCommands,
  }) {
    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      name: title ?? name,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      isFavorite: isFavorite ?? this.isFavorite,
      inputContent: inputContent ?? this.inputContent,
      attachments: attachments ?? this.attachments,
      isSending: isSending ?? this.isSending,
      shouldStopResponse: shouldStopResponse ?? this.shouldStopResponse,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      lastSelectedDirectory:
          lastSelectedDirectory ?? this.lastSelectedDirectory,
      mcpServer: clearMcpServer ? null : (mcpServer ?? this.mcpServer),
      webSearchConfig: webSearchConfig ?? this.webSearchConfig,
      ragConfig: ragConfig ?? this.ragConfig,
      skillConfig: skillConfig ?? this.skillConfig,
      chatModel: clearChatModel ? null : (chatModel ?? this.chatModel),
      sessionQuickCommands: sessionQuickCommands ?? this.sessionQuickCommands,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['id'] ?? '',
      name: json['name'] ?? '新对话',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((messageJson) => ChatMessage.fromJson(messageJson))
              .toList() ??
          [],
      isFavorite: json['isFavorite'] ?? false,
      inputContent: json['inputContent'] ?? '',
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((attachmentJson) => ChatAttachment.fromJson(attachmentJson))
              .toList() ??
          [],
      isSending: json['isSending'] ?? false,
      shouldStopResponse: json['shouldStopResponse'] ?? false,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      lastSelectedDirectory: json['lastSelectedDirectory'],
      mcpServer: json['mcpServer'] is Map<String, dynamic>
          ? McpServerConfig.fromMap(json['mcpServer'])
          : null,
      webSearchConfig: json['webSearchConfig'] is Map<String, dynamic>
          ? WebSearchSessionConfig.fromJson(json['webSearchConfig'])
          : const WebSearchSessionConfig(),
      ragConfig: json['ragConfig'] is Map<String, dynamic>
          ? RagSessionConfig.fromJson(json['ragConfig'])
          : const RagSessionConfig(),
      skillConfig: json['skillConfig'] is Map<String, dynamic>
          ? SkillSessionConfig.fromJson(json['skillConfig'])
          : const SkillSessionConfig(),
      sessionQuickCommands:
          (json['sessionQuickCommands'] as List<dynamic>?)
              ?.map((commandJson) => ChatCommand.fromJson(commandJson))
              .toList() ??
          [],
      chatModel:
          json['chatModel'] != null
              ? ChatModel.fromMap(json['chatModel'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': sessionId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'isFavorite': isFavorite,
      'inputContent': inputContent,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'isSending': isSending,
      'shouldStopResponse': shouldStopResponse,
      'scrollPosition': scrollPosition,
      'lastSelectedDirectory': lastSelectedDirectory,
      if (mcpServer != null) 'mcpServer': mcpServer!.toJson(),
      'webSearchConfig': webSearchConfig.toJson(),
      'ragConfig': ragConfig.toJson(),
      'skillConfig': skillConfig.toJson(),
      'sessionQuickCommands':
          sessionQuickCommands.map((command) => command.toJson()).toList(),
      'chatModel': chatModel?.toMap(),
    };
  }

  String? getInitialDirectory() {
    if (lastSelectedDirectory != null) {
      try {
        if (Directory(lastSelectedDirectory!).existsSync()) {
          return lastSelectedDirectory;
        }
      } catch (e) {}
    }
    return null;
  }
}
