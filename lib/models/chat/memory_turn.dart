/// 单轮记忆记录，存储一条 user 或 assistant 消息的文本摘要
class MemoryTurn {
  /// 'user' 或 'assistant'
  final String role;

  /// 消息文本内容
  final String content;

  /// 消息时间戳
  final DateTime timestamp;

  const MemoryTurn({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  MemoryTurn copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
  }) {
    return MemoryTurn(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MemoryTurn.fromJson(Map<String, dynamic> json) {
    return MemoryTurn(
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  /// 计算 1 轮 = 1 user + 1 assistant
  /// 返回当前 memory 列表对应的轮次数
  static int roundCount(List<MemoryTurn> memory) {
    int rounds = 0;
    for (final turn in memory) {
      if (turn.role == 'user') rounds++;
    }
    return rounds;
  }
}
