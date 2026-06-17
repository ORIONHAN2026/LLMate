import 'chat_attachment.dart';
import 'content_block.dart';

enum MessageRole { user, bot, tool }

class ChatMessage {
  final String msgId;
  final MessageRole role;
  String content;
  String think; // 思考内容，必填字段，默认为空字符串
  List<ContentBlock> contentBlocks; // 按时间顺序排列的内容块（think/tool/content）
  final DateTime timestamp;
  final String? sessionId;
  final bool isError;
  final List<ChatAttachment> attachments; // 消息的附件列表
   
  // 消息关联字段
  final String? pairedMsgId; // 配对的消息ID（用于关联用户消息和AI回复）

  // 工具调用相关字段
  final String? toolName; // 工具名称（用于tool类型消息）
  final String? toolCallId; // 工具调用ID（用于tool类型消息，匹配 tool_calls 中的 id）
  bool isToolCalling; // 是否正在调用工具，默认为 false

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
    this.contentBlocks = const [], // 内容块列表，默认为空
    required this.timestamp,
    this.sessionId,
    this.isError = false,
    this.attachments = const [], // 默认为空列表
    this.pairedMsgId, // 配对的消息ID（可选）
    this.toolName, // 工具名称（可选）
    this.toolCallId, // 工具调用ID（可选）
    this.isToolCalling = false, // 是否正在调用工具，默认为 false
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
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      sessionId: json['sessionId'],
      isError: json['isError'] ?? false,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((attachmentJson) => ChatAttachment.fromJson(attachmentJson))
              .toList() ??
          [],
      pairedMsgId: json['pairedMessageId'],
      toolName: json['toolName'],
      toolCallId: json['toolCallId'],
      isToolCalling: json['isToolCalling'] ?? false,
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
      contentBlocks:
          (json['contentBlocks'] as List<dynamic>?)
              ?.map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
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

  Map<String, dynamic> toJson() {
    return {
      'id': msgId,
      'role': _roleToString(role),
      'content': content,
      'think': think, // 思考内容
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'isError': isError,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'pairedMessageId': pairedMsgId,
      'toolName': toolName,
      'toolCallId': toolCallId,
      'isToolCalling': isToolCalling,
      'generationStartTime': generationStartTime?.toIso8601String(),
      'generationEndTime': generationEndTime?.toIso8601String(),
      'totalTokens': totalTokens,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'generationDurationMs': generationDuration?.inMilliseconds,
      'contentBlocks': contentBlocks.map((b) => b.toJson()).toList(),
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

  ChatMessage copyWith({
    String? msgId,
    MessageRole? role,
    String? content,
    String? think, // 思考内容
    List<ContentBlock>? contentBlocks, // 内容块列表
    DateTime? timestamp,
    String? sessionId,
    bool? isError,
    List<ChatAttachment>? attachments,
    String? pairedMsgId, // 配对的消息ID
    String? toolName,
    String? toolCallId,
    bool? isToolCalling,
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
      contentBlocks: contentBlocks ?? this.contentBlocks, // 内容块列表
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      isError: isError ?? this.isError,
      attachments: attachments ?? this.attachments,
      pairedMsgId: pairedMsgId ?? this.pairedMsgId, // 配对的消息ID
      toolName: toolName ?? this.toolName,
      toolCallId: toolCallId ?? this.toolCallId,
      isToolCalling: isToolCalling ?? this.isToolCalling,
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
