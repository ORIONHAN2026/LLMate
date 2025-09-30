import 'chat_attachment.dart';

enum MessageRole { user, bot, tool }

// AI消息生成状态
enum AiMessageStatus {
  init, // 初始状态，等待生成
  working, // 正在生成中
  done, // 生成完成
}

class ChatMessage {
  final String msgId;
  final MessageRole role;
  String content;
  String think; // 思考内容，必填字段，默认为空字符串
  String? organizedDocument; // 该AI消息生成的整理文档内容（若有）
  final DateTime timestamp;
  final String? repoId;
  final bool? isTyping;
  final String? sessionId;
  final bool isError;
  final List<ChatAttachment> attachments; // 消息的附件列表
   
  // 消息关联字段
  final String? pairedMsgId; // 配对的消息ID（用于关联用户消息和AI回复）
  
  // AI消息状态字段
  final AiMessageStatus? aiStatus; // AI消息生成状态（仅对bot类型消息有效）
   
  // 工具调用相关字段
  final String? toolName; // 工具名称（用于tool类型消息）
  final Map<String, dynamic>? toolArguments; // 工具参数（用于tool类型消息）

  // 性能统计字段
  final DateTime? generationStartTime; // 生成开始时间
  final DateTime? generationEndTime; // 生成结束时间
  final int? totalTokens; // 总token数（输入+输出）
  final int? inputTokens; // 输入token数
  final int? outputTokens; // 输出token数
  final Duration? generationDuration; // 生成耗时

  ChatMessage({
    required this.msgId,
    required this.role,
    required this.content,
    this.think = '', // 思考内容，默认为空字符串
    this.organizedDocument,
    required this.timestamp,
    this.repoId,
    this.isTyping = false,
    this.sessionId,
    this.isError = false,
    this.attachments = const [], // 默认为空列表
    this.pairedMsgId, // 配对的消息ID（可选）
    this.aiStatus, // AI消息状态（可选）
    this.toolName, // 工具名称（可选）
    this.toolArguments, // 工具参数（可选）
    this.generationStartTime,
    this.generationEndTime,
    this.totalTokens,
    this.inputTokens,
    this.outputTokens,
    this.generationDuration,
  });

  /// 计算生成速度（token/秒）
  double? get tokensPerSecond {
    if (outputTokens == null ||
        generationDuration == null ||
        generationDuration!.inMilliseconds == 0) {
      return null;
    }
    return outputTokens! / (generationDuration!.inMilliseconds / 1000.0);
  }

  /// 获取格式化的耗时字符串
  String? get formattedDuration {
    if (generationDuration == null) return null;
    final seconds = generationDuration!.inMilliseconds / 1000.0;
    return '${seconds.toStringAsFixed(3)} 秒';
  }

  /// 获取格式化的速度字符串
  String? get formattedTokensPerSecond {
    final speed = tokensPerSecond;
    if (speed == null) return null;
    return '${speed.toStringAsFixed(1)} token/秒';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      msgId: json['id'] ?? '',
      role: _parseRole(json['role']),
      content: json['content'] ?? '',
      think: json['think'] ?? '', // 思考内容，默认为空字符串
      organizedDocument: json['organizedDocument'],
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      repoId: json['repoId'],
      isTyping: json['isTyping'] ?? false,
      sessionId: json['sessionId'],
      isError: json['isError'] ?? false,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((attachmentJson) => ChatAttachment.fromJson(attachmentJson))
              .toList() ??
          [],
      pairedMsgId: json['pairedMessageId'],
      aiStatus: _parseAiStatus(json['aiStatus']),
      toolName: json['toolName'],
      toolArguments:
          json['toolArguments'] != null
              ? Map<String, dynamic>.from(json['toolArguments'])
              : null,
      generationStartTime:
          json['generationStartTime'] != null
              ? DateTime.tryParse(json['generationStartTime'])
              : null,
      generationEndTime:
          json['generationEndTime'] != null
              ? DateTime.tryParse(json['generationEndTime'])
              : null,
      totalTokens: json['totalTokens'],
      inputTokens: json['inputTokens'],
      outputTokens: json['outputTokens'],
      generationDuration:
          json['generationDurationMs'] != null
              ? Duration(milliseconds: json['generationDurationMs'])
              : null,
    );
  }

  static MessageRole _parseRole(String? role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'bot':
        return MessageRole.bot;
      case 'tool':
        return MessageRole.tool;
      default:
        return MessageRole.bot;
    }
  }

  static AiMessageStatus? _parseAiStatus(String? status) {
    switch (status) {
      case 'init':
        return AiMessageStatus.init;
      case 'working':
        return AiMessageStatus.working;
      case 'done':
        return AiMessageStatus.done;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': msgId,
      'role': _roleToString(role),
      'content': content,
      'think': think, // 思考内容
      'organizedDocument': organizedDocument,
      'timestamp': timestamp.toIso8601String(),
      'repoId': repoId,
      'isTyping': isTyping,
      'sessionId': sessionId,
      'isError': isError,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'pairedMessageId': pairedMsgId,
      'aiStatus': _aiStatusToString(aiStatus),
      'toolName': toolName,
      'toolArguments': toolArguments,
      'generationStartTime': generationStartTime?.toIso8601String(),
      'generationEndTime': generationEndTime?.toIso8601String(),
      'totalTokens': totalTokens,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'generationDurationMs': generationDuration?.inMilliseconds,
    };
  }

  static String _roleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.bot:
        return 'bot';
      case MessageRole.tool:
        return 'tool';
    }
  }

  static String? _aiStatusToString(AiMessageStatus? status) {
    switch (status) {
      case AiMessageStatus.init:
        return 'init';
      case AiMessageStatus.working:
        return 'working';
      case AiMessageStatus.done:
        return 'done';
      default:
        return null;
    }
  }

  ChatMessage copyWith({
    String? msgId,
    MessageRole? role,
    String? content,
    String? think, // 思考内容
    String? organizedDocument,
    DateTime? timestamp,
    String? repoId,
    bool? isTyping,
    String? sessionId,
    bool? isError,
    List<ChatAttachment>? attachments,
    String? pairedMsgId, // 配对的消息ID
    AiMessageStatus? aiStatus, // AI消息状态
    String? toolName,
    Map<String, dynamic>? toolArguments,
    DateTime? generationStartTime,
    DateTime? generationEndTime,
    int? totalTokens,
    int? inputTokens,
    int? outputTokens,
    Duration? generationDuration,
  }) {
    return ChatMessage(
      msgId: msgId ?? this.msgId,
      role: role ?? this.role,
      content: content ?? this.content,
      think: think ?? this.think, // 思考内容
  organizedDocument: organizedDocument ?? this.organizedDocument,
      timestamp: timestamp ?? this.timestamp,
      repoId: repoId ?? this.repoId,
      isTyping: isTyping ?? this.isTyping,
      sessionId: sessionId ?? this.sessionId,
      isError: isError ?? this.isError,
      attachments: attachments ?? this.attachments,
      pairedMsgId: pairedMsgId ?? this.pairedMsgId, // 配对的消息ID
      aiStatus: aiStatus ?? this.aiStatus, // AI消息状态
      toolName: toolName ?? this.toolName,
      toolArguments: toolArguments ?? this.toolArguments,
      generationStartTime: generationStartTime ?? this.generationStartTime,
      generationEndTime: generationEndTime ?? this.generationEndTime,
      totalTokens: totalTokens ?? this.totalTokens,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      generationDuration: generationDuration ?? this.generationDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.msgId == msgId;
  }

  @override
  int get hashCode => msgId.hashCode;

  @override
  String toString() {
    return 'ChatMessage(msgId: $msgId, role: $role, content: $content, timestamp: $timestamp)';
  }
}
