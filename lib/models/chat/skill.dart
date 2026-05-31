/// AI Skill 模型
///
/// 每个技能对应 `skills/` 目录下的一个文件夹：
/// ```
/// skills/
///   flutter-add-widget-preview/
///     SKILL.md          ← YAML 头 (name, description) + markdown 正文 (prompt)
/// ```
///
/// - id = 文件夹名
/// - name/description 从 SKILL.md YAML 头部解析
/// - prompt = SKILL.md 的 markdown 正文
class Skill {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String folderPath;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.folderPath,
  });

  /// 从 SKILL.md 内容解析 YAML 头部
  static ({String name, String description}) parseFrontmatter(String rawMd) {
    String name = '';
    String description = '';
    final lines = rawMd.split('\n');
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      int end = lines.indexWhere(
        (l) => l.trim() == '---',
        1,
      );
      if (end > 1) {
        for (int i = 1; i < end; i++) {
          final line = lines[i].trim();
          if (line.startsWith('name:')) {
            name = line.substring('name:'.length).trim();
          } else if (line.startsWith('description:')) {
            description = line.substring('description:'.length).trim();
          }
        }
      }
    }
    return (name: name, description: description);
  }

  /// 提取 SKILL.md 中 YAML 头部之后的正文（prompt）
  static String extractBody(String rawMd) {
    final lines = rawMd.split('\n');
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      int end = lines.indexWhere((l) => l.trim() == '---', 1);
      if (end >= 0 && end + 1 < lines.length) {
        return lines.sublist(end + 1).join('\n').trim();
      }
    }
    return rawMd.trim();
  }

  /// 生成 icon key（基于技能名称）
  static String deriveIcon(String id) {
    if (id.contains('widget') || id.contains('preview')) return 'code';
    if (id.contains('test')) return 'search';
    if (id.contains('architecture') || id.contains('routing')) return 'gear';
    if (id.contains('layout') || id.contains('responsive')) return 'image';
    if (id.contains('json') || id.contains('serialization')) return 'doc';
    if (id.contains('localization')) return 'globe';
    if (id.contains('http') || id.contains('api')) return 'globe';
    if (id.contains('integration')) return 'wand';
    return 'star';
  }

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? prompt,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? folderPath,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderPath: folderPath ?? this.folderPath,
    );
  }

  // JSON 序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prompt': prompt,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'folderPath': folderPath,
    };
  }

  // JSON 反序列化
  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      prompt: json['prompt'] ?? '',
      icon: json['icon'] ?? 'star',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
      folderPath: json['folderPath'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Skill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Skill{id: $id, name: $name}';
  }
}
