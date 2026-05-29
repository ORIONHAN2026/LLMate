/// RAG（检索增强生成）会话级配置
///
/// 控制当前会话的 RAG 功能启用状态及相关设置。
class RagSessionConfig {
  /// 是否启用 RAG 搜索
  final bool isEnabled;

  /// 已选知识库 ID 列表（预留，后续可支持知识库选择）
  final List<String> selectedKnowledgeBaseIds;

  const RagSessionConfig({
    this.isEnabled = false,
    this.selectedKnowledgeBaseIds = const [],
  });

  /// 是否有效
  bool get isEffective => isEnabled;

  RagSessionConfig copyWith({
    bool? isEnabled,
    List<String>? selectedKnowledgeBaseIds,
  }) {
    return RagSessionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedKnowledgeBaseIds: selectedKnowledgeBaseIds ?? this.selectedKnowledgeBaseIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'selectedKnowledgeBaseIds': selectedKnowledgeBaseIds,
  };

  factory RagSessionConfig.fromJson(Map<String, dynamic> json) {
    return RagSessionConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      selectedKnowledgeBaseIds:
          (json['selectedKnowledgeBaseIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RagSessionConfig && isEnabled == other.isEnabled;

  @override
  int get hashCode => isEnabled.hashCode;
}
