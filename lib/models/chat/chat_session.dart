import 'dart:io';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/bigmodel/mcp_config.dart';
import 'package:chathub/models/chat/skill.dart';

import 'chat_message.dart';
import 'chat_attachment.dart';
import 'chat_setting.dart';

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

  /// 工作目录：会话产生的文件默认保存到此目录
  final String? workDirectory;

  /// 绑定的 MCP 服务（null = 未绑定）
  final McpServerConfig? mcpServer;

  /// 绑定的技能（null = 未绑定）
  final Skill? skill;

  /// 记忆轮数（0 = 无记忆，默认 20）
  final int memoryRounds;

  /// 深度思考模式（默认关闭）
  final bool deepThink;

  // ============================

  /// 绑定的模型ID，用于动态加载 chatModel
  final String? modelId;

  /// 运行时动态解析的模型对象（不持久化，由 modelId 解析而来）
  final ChatModel? chatModel;
  final List<ChatMessage> messages;
  final List<ChatCommand> sessionQuickCommands;

  ChatSession({
    required this.sessionId,
    required this.name,
    required this.createdAt,
    required this.messages,
    String? modelId,
    this.chatModel,
    this.isFavorite = false,
    this.inputContent = '',
    this.attachments = const [],
    this.isSending = false,
    this.shouldStopResponse = false,
    this.scrollPosition = 0.0,
    this.lastSelectedDirectory,
    this.workDirectory,
    this.mcpServer,
    this.skill,
    this.memoryRounds = 20,
    this.deepThink = false,
    this.sessionQuickCommands = const [],
  }) : modelId = modelId ?? chatModel?.modelId;

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
    String? workDirectory,
    bool clearWorkDirectory = false,
    McpServerConfig? mcpServer,
    bool clearMcpServer = false,
    Skill? skill,
    bool clearSkill = false,
    ChatModel? chatModel,
    bool clearChatModel = false,
    int? memoryRounds,
    bool? deepThink,
    List<ChatCommand>? sessionQuickCommands,
  }) {
    // 当显式设置 chatModel 时，自动同步 modelId
    final String? resolvedModelId;
    final ChatModel? resolvedChatModel;
    if (clearChatModel) {
      resolvedModelId = null;
      resolvedChatModel = null;
    } else if (chatModel != null) {
      resolvedModelId = chatModel.modelId;
      resolvedChatModel = chatModel;
    } else {
      resolvedModelId = modelId;
      resolvedChatModel = this.chatModel;
    }

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
      workDirectory:
          clearWorkDirectory ? null : (workDirectory ?? this.workDirectory),
      mcpServer: clearMcpServer ? null : (mcpServer ?? this.mcpServer),
      skill: clearSkill ? null : (skill ?? this.skill),
      modelId: resolvedModelId,
      chatModel: resolvedChatModel,
      memoryRounds: memoryRounds ?? this.memoryRounds,
      deepThink: deepThink ?? this.deepThink,
      sessionQuickCommands: sessionQuickCommands ?? this.sessionQuickCommands,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    // 优先从 modelId 字段读取，兼容旧数据的 chatModel 字段提取 modelId
    final String? modelId = json['modelId'] as String? ??
        (json['chatModel'] is Map<String, dynamic>
            ? (json['chatModel'] as Map<String, dynamic>)['modelId'] as String?
            : null);

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
      workDirectory: json['workDirectory'],
      mcpServer: json['mcpServer'] is Map<String, dynamic>
          ? McpServerConfig.fromMap(json['mcpServer'])
          : null,
      skill: json['skill'] is Map<String, dynamic>
          ? Skill.fromJson(json['skill'])
          : null,
      memoryRounds: json['memoryRounds'] as int? ?? 20,
      deepThink: json['deepThink'] as bool? ?? false,
      sessionQuickCommands:
          (json['sessionQuickCommands'] as List<dynamic>?)
              ?.map((commandJson) => ChatCommand.fromJson(commandJson))
              .toList() ??
          [],
      modelId: modelId,
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
      if (workDirectory != null) 'workDirectory': workDirectory,
      if (mcpServer != null) 'mcpServer': mcpServer!.toJson(),
      if (skill != null) 'skill': skill!.toJson(),
      'memoryRounds': memoryRounds,
      'deepThink': deepThink,
      'sessionQuickCommands':
          sessionQuickCommands.map((command) => command.toJson()).toList(),
      if (modelId != null) 'modelId': modelId,
      'chatModel': chatModel?.toMap(),
    };
  }

  String? getInitialDirectory() {
    if (lastSelectedDirectory != null) {
      try {
        if (Directory(lastSelectedDirectory!).existsSync()) {
          return lastSelectedDirectory;
        }
      } catch (e) {
        // 目录不存在或无法访问，返回 null
      }
    }
    return null;
  }
}
