/// 消息内容块的类型
enum ContentBlockType { think, tool, content }

/// 按时间顺序记录的消息内容块
/// 用于在 UI 中按实际生成的顺序展示 思考/工具执行/正文
class ContentBlock {
  final ContentBlockType type;
  String text;

  ContentBlock({required this.type, required this.text});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
      };

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: ContentBlockType.values.byName(json['type'] as String),
      text: json['text'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ContentBlock(type: $type, text: ${text.length} chars)';
}
