import 'dart:io';
import 'package:chathub/models/bigmodel/chat_model.dart';

import 'chat_message.dart';
import 'chat_attachment.dart';
import 'chat_setting.dart';

// 聊天会话类
class ChatSession {
  final String sessionId;
  String name;
  final DateTime createdAt;
  final bool isFavorite;
  final String inputContent; // 会话绑定的输入框内容
  final List<ChatAttachment> attachments; // 会话绑定的附件列表
  final bool isSending; // 会话绑定的发送状态
  final bool shouldStopResponse; // 会话绑定的停止响应标志
  final double scrollPosition; // 会话绑定的滚动位置
  final String? lastSelectedDirectory; // 会话绑定的最后选择的文件目录
  final bool isWebSearchEnabled; // 会话绑定的联网搜索开关
  final bool isMcpToolsEnabled; // 会话绑定的MCP工具开关
  final List<String> selectedMcpServiceIds; // 会话绑定的已选MCP服务名称列表 (服务级选择，向下兼容)
  final List<String> selectedMcpToolIds; // 会话绑定的已选MCP工具ID列表 (工具级选择，格式: "serviceName::toolName")
  final bool isRagEnabled; // 会话绑定的RAG功能开关
  final bool isSkillEnabled; // 会话绑定的技能开关
  final List<String> selectedSkillIds; // 会话绑定的已选技能ID列表

  final ChatModel? chatModel; // 会话绑定的模型信息
  final List<ChatMessage> messages;
  final List<ChatCommand> sessionQuickCommands; // 会话级别的快捷指令

  ChatSession({
    required this.sessionId,
    required this.name,
    required this.createdAt,
    required this.messages,
    this.chatModel,
    this.isFavorite = false,
    this.inputContent = '', // 默认为空字符串
    this.attachments = const [], // 默认为空列表
    this.isSending = false, // 默认为false
    this.shouldStopResponse = false, // 默认为false
    this.scrollPosition = 0.0, // 默认滚动位置为0
    this.lastSelectedDirectory, // 允许为空，默认为null
    this.isWebSearchEnabled = false, // 默认为false
    this.isMcpToolsEnabled = false, // 默认为false
    this.selectedMcpServiceIds = const [], // 默认为空列表
    this.selectedMcpToolIds = const [], // 默认为空列表
    this.isRagEnabled = false, // 默认为false
    this.isSkillEnabled = false, // 默认为false
    this.selectedSkillIds = const [], // 默认为空列表

    this.sessionQuickCommands = const [], // 默认为空列表
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

  // 获取最后一条消息的时间
  DateTime get lastMessageTime {
    if (messages.isEmpty) return createdAt;
    return messages.last.timestamp;
  }

  // 获取使用的模型名称（优先使用会话绑定的模型，否则使用默认模型）
  String get modelName {
    // 使用 chatModel 中的模型名称
    if (chatModel != null) {
      return chatModel!.name.isNotEmpty ? chatModel!.name : chatModel!.model;
    }

    // 如果没有绑定模型，使用默认模型
    return '';
  }

  // 获取模型显示信息：配置名称和真实模型名称
  String get modelDisplayInfo {
    if (chatModel != null && chatModel!.model.isNotEmpty) {
      return chatModel!.name;
    } else {
      return '未设置对话大模型';
    }

    // 兼容旧数据
  }

  // 创建副本并允许修改某些字段
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
    bool? isWebSearchEnabled,
    bool? isRagEnabled,
    bool? isMcpToolsEnabled,
    List<String>? selectedMcpServiceIds,
    List<String>? selectedMcpToolIds,
    ChatModel? chatModel,
    bool clearChatModel = false, // 用于显式清空chatModel
    bool? isSkillEnabled,
    List<String>? selectedSkillIds,
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
      isWebSearchEnabled: isWebSearchEnabled ?? this.isWebSearchEnabled,
      isMcpToolsEnabled: isMcpToolsEnabled ?? this.isMcpToolsEnabled,
      selectedMcpServiceIds: selectedMcpServiceIds ?? this.selectedMcpServiceIds,
      selectedMcpToolIds: selectedMcpToolIds ?? this.selectedMcpToolIds,
      isRagEnabled: isRagEnabled ?? this.isRagEnabled,
      isSkillEnabled: isSkillEnabled ?? this.isSkillEnabled,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
      chatModel: clearChatModel ? null : (chatModel ?? this.chatModel),
      sessionQuickCommands: sessionQuickCommands ?? this.sessionQuickCommands,
    );
  }

  // JSON 序列化
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
      inputContent: json['inputContent'] ?? '', // 从JSON加载输入内容，默认为空字符串
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((attachmentJson) => ChatAttachment.fromJson(attachmentJson))
              .toList() ??
          [], // 从JSON加载附件列表，默认为空列表
      isSending: json['isSending'] ?? false, // 从JSON加载发送状态，默认为false
      shouldStopResponse:
          json['shouldStopResponse'] ?? false, // 从JSON加载停止响应标志，默认为false
      scrollPosition:
          (json['scrollPosition'] as num?)?.toDouble() ??
          0.0, // 从JSON加载滚动位置，默认为0
      lastSelectedDirectory:
          json['lastSelectedDirectory'], // 从JSON加载最后选择的目录，允许为null
      isWebSearchEnabled:
          json['isWebSearchEnabled'] ?? false, // 从JSON加载联网搜索开关，默认为false
      isMcpToolsEnabled:
          json['isMcpToolsEnabled'] ?? false, // 从JSON加载MCP工具开关，默认为false
      selectedMcpServiceIds:
          (json['selectedMcpServiceIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [], // 从JSON加载已选MCP服务ID列表，默认为空
      selectedMcpToolIds:
          (json['selectedMcpToolIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [], // 从JSON加载已选MCP工具ID列表，默认为空
      isRagEnabled: json['isRagEnabled'] ?? false, // 从JSON加载RAG搜索开关，默认为false
      isSkillEnabled:
          json['isSkillEnabled'] ?? false, // 从JSON加载技能开关，默认为false
      selectedSkillIds:
          (json['selectedSkillIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [], // 从JSON加载已选技能ID列表，默认为空
      sessionQuickCommands:
          (json['sessionQuickCommands'] as List<dynamic>?)
              ?.map((commandJson) => ChatCommand.fromJson(commandJson))
              .toList() ??
          [], // 从JSON加载会话快捷指令，默认为空列表
      chatModel:
          json['chatModel'] != null
              ? ChatModel.fromMap(json['chatModel'])
              : null, // 从JSON加载模型对象，允许为null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': sessionId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'isFavorite': isFavorite,
      'inputContent': inputContent, // 保存输入内容到JSON
      'attachments':
          attachments
              .map((attachment) => attachment.toJson())
              .toList(), // 保存附件列表到JSON
      'isSending': isSending, // 保存发送状态到JSON
      'shouldStopResponse': shouldStopResponse, // 保存停止响应标志到JSON
      'scrollPosition': scrollPosition, // 保存滚动位置到JSON
      'lastSelectedDirectory': lastSelectedDirectory, // 保存最后选择的目录到JSON，允许为null
      'isWebSearchEnabled': isWebSearchEnabled, // 保存联网搜索开关到JSON
      'isMcpToolsEnabled': isMcpToolsEnabled, // 保存MCP工具开关到JSON
      'selectedMcpServiceIds': selectedMcpServiceIds, // 保存已选MCP服务ID列表到JSON
      'selectedMcpToolIds': selectedMcpToolIds, // 保存已选MCP工具ID列表到JSON
      'isRagEnabled': isRagEnabled, // 保存RAG搜索开关到JSON
      'isSkillEnabled': isSkillEnabled, // 保存技能开关到JSON
      'selectedSkillIds': selectedSkillIds, // 保存已选技能ID列表到JSON
      'sessionQuickCommands':
          sessionQuickCommands
              .map((command) => command.toJson())
              .toList(), // 保存会话快捷指令到JSON
      'chatModel': chatModel?.toMap(), // 保存模型对象到JSON，允许为null
    };
  }

  // 获取文件选择的初始目录
  String? getInitialDirectory() {
    if (lastSelectedDirectory != null) {
      try {
        if (Directory(lastSelectedDirectory!).existsSync()) {
          return lastSelectedDirectory;
        }
      } catch (e) {
        // 如果目录检查失败，返回null使用系统默认目录
      }
    }
    return null; // 使用系统默认目录
  }
}
