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
  /// 图片 base64 数据（用于多模态 LLM 发送图片原文）
  final String? base64Data;
  /// 图片 MIME 类型（如 image/png），配合 base64Data 使用
  final String? mimeType;
  /// OSS 上传后的访问 URL
  final String? ossUrl;
  /// OSS 存储的 key
  final String? ossKey;

  ChatAttachment({
    required this.id,
    required this.name,
    required this.type,
    this.filePath,
    this.url,
    this.content,
    this.size,
    required this.createdAt,
    this.base64Data,
    this.mimeType,
    this.ossUrl,
    this.ossKey,
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
    String? base64Data,
    String? mimeType,
    String? ossUrl,
    String? ossKey,
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
      base64Data: base64Data ?? this.base64Data,
      mimeType: mimeType ?? this.mimeType,
      ossUrl: ossUrl ?? this.ossUrl,
      ossKey: ossKey ?? this.ossKey,
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
      base64Data: json['base64Data'],
      mimeType: json['mimeType'],
      ossUrl: json['ossUrl'],
      ossKey: json['ossKey'],
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
      // 不序列化 base64Data 以避免 JSON 膨胀，仅在运行时使用
      // 'base64Data': base64Data,
      'mimeType': mimeType,
      if (ossUrl != null) 'ossUrl': ossUrl,
      if (ossKey != null) 'ossKey': ossKey,
    };
  }
}
