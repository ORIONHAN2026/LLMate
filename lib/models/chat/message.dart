import 'package:llmate/models/chat/session.dart';

import '../../features/chat/widgets/message_widgets/content_block.dart';

enum MessageRole { user, bot, tool }

class ChatMessage {
  final String msgId;
  final MessageRole role;
  String content;
  String reason; // 思考内容，必填字段，默认为空字符串
  List<ContentBlock> contentBlocks; // 按时间顺序排列的内容块（reason/tool/content）
  final DateTime timestamp;
  final String? sessionId;

  /// 消息所属模型ID，与所属会话的 modelId 保持一致，用于区分消息来源模型
  final String? model;

  final bool isError;

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
  final int? promptTokens; // 输入token数
  final int? completionTokens; // 输出token数
  final Duration? generationDuration; // 生成耗时

  ChatMessage({
    required this.msgId,
    required this.role,
    required this.content,
    this.reason = '', // 思考内容，默认为空字符串
    this.contentBlocks = const [], // 内容块列表，默认为空
    required this.timestamp,
    this.sessionId,
    this.model,
    this.isError = false,
    this.pairedMsgId, // 配对的消息ID（可选）
    this.toolName, // 工具名称（可选）
    this.toolCallId, // 工具调用ID（可选）
    this.isToolCalling = false, // 是否正在调用工具，默认为 false
    this.generationStartTime,
    this.generationEndTime,
    this.totalTokens,
    this.promptTokens,
    this.completionTokens,
    this.generationDuration,
  });

  /// 计算生成速度（token/秒）
  double? get tokensPerSecond {
    if (completionTokens == null ||
        generationDuration == null ||
        generationDuration!.inMilliseconds == 0) {
      return null;
    }
    return completionTokens! / (generationDuration!.inMilliseconds / 1000.0);
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
      reason: json['think'] ?? '', // 思考内容，默认为空字符串
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      sessionId: json['sessionId'],
      model: json['model'] as String?,
      isError: json['isError'] ?? false,
      pairedMsgId: json['pairedMessageId'],
      toolName: json['toolName'],
      toolCallId: json['toolCallId'],
      isToolCalling: false, // 重启后强制重置为非执行状态
      generationStartTime:
          json['generationStartTime'] != null
              ? DateTime.tryParse(json['generationStartTime'])
              : null,
      generationEndTime:
          json['generationEndTime'] != null
              ? DateTime.tryParse(json['generationEndTime'])
              : null,
      totalTokens: json['totalTokens'],
      promptTokens: json['promptTokens'],
      completionTokens: json['completionTokens'],
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
      'reason': reason, // 思考内容
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'model': model,
      'isError': isError,
      'pairedMessageId': pairedMsgId,
      'toolName': toolName,
      'toolCallId': toolCallId,
      'isToolCalling': isToolCalling,
      'generationStartTime': generationStartTime?.toIso8601String(),
      'generationEndTime': generationEndTime?.toIso8601String(),
      'totalTokens': totalTokens,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
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
    String? reason, // 思考内容
    List<ContentBlock>? contentBlocks, // 内容块列表
    DateTime? timestamp,
    String? sessionId,
    String? model,
    bool? isError,
    String? pairedMsgId, // 配对的消息ID
    String? toolName,
    String? toolCallId,
    bool? isToolCalling,
    DateTime? generationStartTime,
    DateTime? generationEndTime,
    int? totalTokens,
    int? promptTokens,
    int? completionTokens,
    Duration? generationDuration,
  }) {
    return ChatMessage(
      msgId: msgId ?? this.msgId,
      role: role ?? this.role,
      content: content ?? this.content,
      reason: reason ?? this.reason, // 思考内容
      contentBlocks: contentBlocks ?? this.contentBlocks, // 内容块列表
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      model: model ?? this.model,
      isError: isError ?? this.isError,
      pairedMsgId: pairedMsgId ?? this.pairedMsgId, // 配对的消息ID
      toolName: toolName ?? this.toolName,
      toolCallId: toolCallId ?? this.toolCallId,
      isToolCalling: isToolCalling ?? this.isToolCalling,
      generationStartTime: generationStartTime ?? this.generationStartTime,
      generationEndTime: generationEndTime ?? this.generationEndTime,
      totalTokens: totalTokens ?? this.totalTokens,
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
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
