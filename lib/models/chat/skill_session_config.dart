/// 技能会话级配置
///
/// 控制当前会话的技能启用状态及所选技能列表。
class SkillSessionConfig {
  /// 是否启用技能
  final bool isEnabled;

  /// 已选技能 ID 列表
  final List<String> selectedSkillIds;

  const SkillSessionConfig({
    this.isEnabled = false,
    this.selectedSkillIds = const [],
  });

  /// 没有任何技能被选中
  bool get isEmpty => selectedSkillIds.isEmpty;

  /// 是否有技能可用
  bool get isEffective => isEnabled && !isEmpty;

  SkillSessionConfig copyWith({
    bool? isEnabled,
    List<String>? selectedSkillIds,
  }) {
    return SkillSessionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedSkillIds: selectedSkillIds ?? this.selectedSkillIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'selectedSkillIds': selectedSkillIds,
  };

  factory SkillSessionConfig.fromJson(Map<String, dynamic> json) {
    return SkillSessionConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      selectedSkillIds:
          (json['selectedSkillIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillSessionConfig &&
          isEnabled == other.isEnabled &&
          _listEquals(selectedSkillIds, other.selectedSkillIds);

  @override
  int get hashCode => Object.hash(isEnabled, Object.hashAll(selectedSkillIds));
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
