import 'dart:io';
import 'dart:math' as math;
import 'package:llmwork/models/bigmodel/chat_model.dart';
import 'package:llmwork/models/chat/mcp_config.dart';

import './chat_message.dart';
import './chat_attachment.dart';
import './chat_setting.dart';
import './scheduled_task.dart';
import './memory_turn.dart';
import './contract_info.dart';

const List<String> kSessionEmojis = [
  // 表情
  '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😊',
  '😇', '🥰', '😍', '🤩', '😘', '😗', '😋', '😛', '😜', '🤪',
  '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🫡', '🤐', '🤨', '😐',
  '😑', '😶', '🫥', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔',
  '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶',
  '😎', '🤓', '🧐', '😕', '😟', '🙁', '😮', '😯', '😲', '😳',
  // 手势
  '👍', '👎', '👏', '🙌', '🫶', '🤝', '💪', '✌️', '🤞', '🤟',
  '🤙', '👋', '🖐️', '✋', '🖖', '🫰', '👊', '✊', '🤛', '🤜',
  // 物品
  '💡', '🔦', '🕯️', '📱', '💻', '🖥️', '⌨️', '🖱️', '📷', '🎥',
  '📡', '🔑', '🔒', '🔓', '📦', '📫', '✏️', '🖊️', '📝', '📌',
  // 科技
  '🚀', '🛸', '⚡', '💎', '🤖', '👾', '🎮', '🎯', '🧩', '🎲',
  // 自然
  '🌍', '🌎', '🌏', '🌙', '⭐', '🌟', '✨', '💫', '🌈', '☀️',
  '🌤️', '⛅', '🌥️', '🌧️', '⛈️', '❄️', '🔥', '💧', '🌊', '🍀',
  // 植物
  '🌸', '🌺', '🌻', '🌹', '🌷', '🌱', '🌿', '🍃', '🍂', '🍁',
  // 动物
  '🦊', '🐱', '🐶', '🐻', '🐼', '🐨', '🦁', '🐯', '🐮', '🐷',
  '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇',
  '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
  '🐢', '🐍', '🦎', '🐙',   '🦑', '🦐', '🦀', '🐬', '🐳', '🐋',
  '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🐘', '🦏', '🐪', '🐫',
  // 食物
  '🍕', '🍔', '🍟', '🌭', '🍿', '🧀', '🥚', '🍳', '🥞', '🥓',
  '🥩', '🍗', '🍖', '🌮', '🌯', '🥙', '🥗', '🍣', '🍱', '🍜',
  '🍝', '🍛', '🍲', '🥘', '🥟', '🍦', '🍩', '🎂', '🍰', '🧁',
  '🥧', '🍫', '🍬', '🍭', '☕', '🍵', '🥤', '🍺', '🍷', '🥂',
  // 运动
  '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
  '🥊', '🥋', '🎿', '🛹', '🏄', '🏊', '🚴', '🏋️', '🥇', '🏆',
  // 乐器
  '🎸', '🎹', '🎷', '🎺', '🎻', '🥁', '🪗', '🪘', '🎵', '🎶',
  // 艺术
  '🎨', '🖼️', '🎭', '🎪', '🎬', '🎤', '🎧', '🎼', '📸', '🎞️',
  // 交通
  '🚗', '🚕', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚',
  '✈️', '🛩️', '🚁', '⛵', '🚂', '🚊', '🚉', '🏠', '🏰', '🗼',
  // 符号
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
  '❤️‍🔥', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
  '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️',
  '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🩷',
  '🩵', '🩶', '🔶', '🔷', '🔸', '🔹', '💠', '🔘', '🏁', '🚩',
];

String randomEmoji() {
  return kSessionEmojis[math.Random().nextInt(kSessionEmojis.length)];
}

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

  /// 绑定的 MCP 服务（null = 未绑定，运行时由 mcpId 动态解析）
  final Mcp? mcp;

  /// 触发记忆压缩的轮数（0 = 禁用记忆压缩，默认 20）
  /// 当累积的记忆达到此轮数时，自动触发 LLM 压缩
  final int memoryRounds;

  /// 深度思考模式（默认关闭）
  final bool deepThink;

  /// 连接器的关联关系描述提示词
  final String? connectPrompt;

  // === 计费统计 ===

  /// 累计输入token数
  final int totalInputTokens;

  /// 累计输出token数
  final int totalOutputTokens;

  /// 累计费用（美元）
  final double totalCost;

  // === 记忆压缩 ===

  /// 最近对话记忆（user + assistant 轮次）
  final List<MemoryTurn> memory;

  /// 压缩后的记忆摘要（由 LLM 生成）
  final String? compressedMemory;

  /// 合约要点列表（商务模式下，由 contract_inspect 工具写入）
  final List<ContractInfo>? contracts;

  // ============================

  /// 绑定的模型ID，用于动态加载 chatModel
  final String? modelId;

  /// 绑定的 MCP 服务名称（ID）
  final String? mcpId;

  /// 会话头像 emoji
  final String emoji;

  /// 运行时动态解析的模型对象（不持久化，由 modelId 解析而来）
  final ChatModel? chatModel;
  final List<ChatMessage> messages;
  final List<ChatCommand> sessionQuickCommands;
  final ScheduledTask? scheduledTask;

  ChatSession({
    required this.sessionId,
    required this.name,
    required this.createdAt,
    required this.messages,
    String? modelId,
    String? mcpId,
    this.chatModel,
    this.mcp,
    this.isFavorite = false,
    this.inputContent = '',
    this.attachments = const [],
    this.isSending = false,
    this.shouldStopResponse = false,
    this.scrollPosition = 0.0,
    this.lastSelectedDirectory,
    this.workDirectory,
    this.memoryRounds = 100,
    this.deepThink = false,
    this.connectPrompt,
    this.sessionQuickCommands = const [],
    this.scheduledTask,
    this.memory = const [],
    this.compressedMemory,
    this.contracts,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCost = 0.0,
    String? emoji,
  }) : modelId = modelId ?? chatModel?.modelId,
       mcpId = mcpId ?? mcp?.mcpId,
       emoji = emoji ?? randomEmoji();

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
    Mcp? mcp,
    bool clearMcp = false,
    ChatModel? chatModel,
    bool clearChatModel = false,
    int? memoryRounds,
    bool? deepThink,
    String? connectPrompt,
    bool clearConnectPrompt = false,
    List<ChatCommand>? sessionQuickCommands,
    ScheduledTask? scheduledTask,
    bool clearScheduledTask = false,
    List<MemoryTurn>? memory,
    bool clearMemory = false,
    String? compressedMemory,
    bool clearCompressedMemory = false,
    List<ContractInfo>? contracts,
    bool clearContracts = false,
    int? totalInputTokens,
    int? totalOutputTokens,
    double? totalCost,
    String? emoji,
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

    // 自动同步 mcpId
    final String? resolvedMcpId;
    final Mcp? resolvedMcp;
    if (clearMcp) {
      resolvedMcpId = null;
      resolvedMcp = null;
    } else if (mcp != null) {
      resolvedMcpId = mcp.mcpId;
      resolvedMcp = mcp;
    } else {
      resolvedMcpId = mcpId;
      resolvedMcp = this.mcp;
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
      mcp: resolvedMcp,
      modelId: resolvedModelId,
      mcpId: resolvedMcpId,
      chatModel: resolvedChatModel,
      memoryRounds: memoryRounds ?? this.memoryRounds,
      deepThink: deepThink ?? this.deepThink,
      connectPrompt:
          clearConnectPrompt ? null : (connectPrompt ?? this.connectPrompt),
      sessionQuickCommands: sessionQuickCommands ?? this.sessionQuickCommands,
      scheduledTask:
          clearScheduledTask ? null : (scheduledTask ?? this.scheduledTask),
      memory: clearMemory ? [] : (memory ?? this.memory),
      compressedMemory:
          clearCompressedMemory ? null : (compressedMemory ?? this.compressedMemory),
      contracts:
          clearContracts ? null : (contracts ?? this.contracts),
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      totalCost: totalCost ?? this.totalCost,
      emoji: emoji ?? this.emoji,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final String? modelId = json['modelId'] as String?;
    final String? mcpId = json['mcpId'] as String?;

    // 兼容旧数据
    final ChatModel? chatModel =
        json['chatModel'] != null ? ChatModel.fromMap(json['chatModel']) : null;
    final Mcp? parsedMcp =
        json['mcp'] is Map<String, dynamic> ? Mcp.fromMap(json['mcp']) : null;

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
      memoryRounds: json['memoryRounds'] as int? ?? 100,
      deepThink: json['deepThink'] as bool? ?? false,
      connectPrompt: json['connectPrompt'] as String?,
      sessionQuickCommands:
          (json['sessionQuickCommands'] as List<dynamic>?)
              ?.map((commandJson) => ChatCommand.fromJson(commandJson))
              .toList() ??
          [],
      scheduledTask:
          json['scheduledTask'] is Map<String, dynamic>
              ? ScheduledTask.fromJson(json['scheduledTask'])
              : null,
      memory:
          (json['memory'] as List<dynamic>?)
              ?.map((t) => MemoryTurn.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      compressedMemory: json['compressedMemory'] as String?,
      contracts:
          (json['contracts'] as List<dynamic>?)
              ?.map(
                (c) => ContractInfo.fromJson(c as Map<String, dynamic>),
              )
              .toList(),
      totalInputTokens: json['totalInputTokens'] as int? ?? 0,
      totalOutputTokens: json['totalOutputTokens'] as int? ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      modelId: modelId,
      mcpId: mcpId,
      chatModel: chatModel,
      mcp: parsedMcp,
      emoji: json['emoji'] as String?,
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
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'isSending': isSending,
      'shouldStopResponse': shouldStopResponse,
      'scrollPosition': scrollPosition,
      'lastSelectedDirectory': lastSelectedDirectory,
      if (workDirectory != null) 'workDirectory': workDirectory,
      'memoryRounds': memoryRounds,
      'deepThink': deepThink,
      if (connectPrompt != null) 'connectPrompt': connectPrompt,
      'sessionQuickCommands':
          sessionQuickCommands.map((command) => command.toJson()).toList(),
      if (scheduledTask != null) 'scheduledTask': scheduledTask!.toJson(),
      'memory': memory.map((t) => t.toJson()).toList(),
      if (compressedMemory != null) 'compressedMemory': compressedMemory,
      if (contracts != null)
        'contracts': contracts!.map((c) => c.toJson()).toList(),
      'totalInputTokens': totalInputTokens,
      'totalOutputTokens': totalOutputTokens,
      'totalCost': totalCost,
      if (modelId != null) 'modelId': modelId,
      if (mcpId != null) 'mcpId': mcpId,
      'chatModel': chatModel?.toMap(),
      if (mcp != null) 'mcp': mcp!.toJson(),
      'emoji': emoji,
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
