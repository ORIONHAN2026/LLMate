// 聊天附件类
class ChatAttachment {
  final String id;
  final String name;
  final String type; // 'image', 'document', 'code', 'web', 'folder', 'file'
  final String? filePath;
  final String? url;
  final String? content;
  final int? size;
  final DateTime createdAt;

  ChatAttachment({
    required this.id,
    required this.name,
    required this.type,
    this.filePath,
    this.url,
    this.content,
    this.size,
    required this.createdAt,
  });

  // 创建副本
  ChatAttachment copyWith({
    String? id,
    String? name,
    String? type,
    String? filePath,
    String? url,
    String? content,
    int? size,
    DateTime? createdAt,
  }) {
    return ChatAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      content: content ?? this.content,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // JSON 序列化
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'file',
      filePath: json['filePath'],
      url: json['url'],
      content: json['content'],
      size: json['size'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'filePath': filePath,
      'url': url,
      'content': content,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
