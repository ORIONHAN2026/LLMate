// 聊天设置数据类
class ChatSettings {
  String conversationName;
  String systemPrompt;
  double temperature;

  String replyLanguage;

  /// 安全设置：开启后，请求/响应中的手机号将被 * 号脱敏
  bool maskPhone;

  /// 安全设置：开启后，请求/响应中的身份证号将被 * 号脱敏
  bool maskIdCard;

  ChatSettings({
    required this.conversationName,
    required this.systemPrompt,
    required this.temperature,

    required this.replyLanguage,
    this.maskPhone = false,
    this.maskIdCard = false,
  });

  ChatSettings copyWith({
    String? conversationName,
    String? systemPrompt,
    double? temperature,

    String? replyLanguage,
    bool? maskPhone,
    bool? maskIdCard,
  }) {
    return ChatSettings(
      conversationName: conversationName ?? this.conversationName,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,

      replyLanguage: replyLanguage ?? this.replyLanguage,
      maskPhone: maskPhone ?? this.maskPhone,
      maskIdCard: maskIdCard ?? this.maskIdCard,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'conversationName': conversationName,
      'systemPrompt': systemPrompt,
      'temperature': temperature,

      'replyLanguage': replyLanguage,
      'maskPhone': maskPhone,
      'maskIdCard': maskIdCard,
    };
  }

  // JSON 反序列化
  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      conversationName: json['conversationName'] ?? '新对话',
      systemPrompt: json['systemPrompt'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,

      replyLanguage: json['replyLanguage'] ?? '助手设置（默认）',
      maskPhone: json['maskPhone'] as bool? ?? false,
      maskIdCard: json['maskIdCard'] as bool? ?? false,
    );
  }

  // 获取默认设置
  static ChatSettings getDefault() {
    return ChatSettings(
      conversationName: '新对话',
      systemPrompt: '',
      temperature: 1.0,

      replyLanguage: '助手设置（默认）',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSettings &&
        other.conversationName == conversationName &&
        other.systemPrompt == systemPrompt &&
        other.temperature == temperature &&
        other.replyLanguage == replyLanguage &&
        other.maskPhone == maskPhone &&
        other.maskIdCard == maskIdCard;
  }

  @override
  int get hashCode {
    return Object.hash(
      conversationName,
      systemPrompt,
      temperature,

      replyLanguage,
      maskPhone,
      maskIdCard,
    );
  }

  @override
  String toString() {
    return 'ChatSettings{conversationName: $conversationName, systemPrompt: $systemPrompt, temperature: $temperature, replyLanguage: $replyLanguage, maskPhone: $maskPhone, maskIdCard: $maskIdCard}';
  }
}

// 快捷指令数据类
class ChatCommand {
  final String id;
  final String name;
  final String content;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatCommand({
    required this.id,
    required this.name,
    required this.content,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  // 生成唯一的指令ID
  static String generateCommandId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'cmd_${timestamp}_$random';
  }

  // 创建新的快捷指令
  static ChatCommand create({
    required String name,
    required String content,
    String icon = '💬',
  }) {
    final now = DateTime.now();
    return ChatCommand(
      id: generateCommandId(),
      name: name,
      content: content,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
  }

  // 复制并修改部分字段
  ChatCommand copyWith({
    String? id,
    String? name,
    String? content,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatCommand(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // JSON 反序列化
  factory ChatCommand.fromJson(Map<String, dynamic> json) {
    return ChatCommand(
      id: json['id'] ?? generateCommandId(),
      name: json['name'] ?? '',
      content: json['content'] ?? '',
      icon: json['icon'] ?? '💬',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatCommand && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  @override
  String toString() {
    return 'ChatCommand{id: $id, name: $name, content: $content, icon: $icon}';
  }
}
