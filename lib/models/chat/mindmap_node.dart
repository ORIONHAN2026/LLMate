/// 脑图数据节点
class MindMapNode {
  final String title;
  final List<MindMapNode> children;

  const MindMapNode({
    required this.title,
    this.children = const [],
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      title: json['title'] as String? ?? '',
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (children.isNotEmpty)
        'children': children.map((e) => e.toJson()).toList(),
    };
  }
}
