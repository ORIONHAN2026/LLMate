import 'dart:convert';
import 'mcp_config.dart';

/// AI Skill 模型
///
/// 每个技能对应 `skills/` 目录下的一个文件夹：
/// ```
/// skills/
///   flutter-add-widget-preview/
///     SKILL.md          ← YAML 头 (name, description) + markdown 正文 (prompt)
/// ```
///
/// - skillId = 文件夹名（用于会话关联）
/// - name/description/prompt/icon/createdAt/updatedAt 从 content 解析
/// - tools = 技能可调用工具列表（结构和 MCP 工具一致）
class Skill {
  /// 数据库/文件系统原始 JSON 内容
  final String? content;

  /// 唯一标识（文件夹名，用于会话关联）
  final String skillId;

  // ── 以下字段运行时从 content 解析，不独立持久化 ──
  final String name;
  final String description;
  final String prompt;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String path; // 文件夹路径（原 folderPath）
  final List<McpToolInfo>? tools; // 技能工具列表（和 MCP 工具结构一致）

  const Skill({
    this.content,
    required this.skillId,
    required this.name,
    required this.description,
    required this.prompt,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
    required this.path,
    this.tools,
  });

  /// 从 SKILL.md 内容解析 YAML 头部
  static ({String name, String description}) parseFrontmatter(String rawMd) {
    String name = '';
    String description = '';
    final lines = rawMd.split('\n');
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      int end = lines.indexWhere((l) => l.trim() == '---', 1);
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

  /// 从 content JSON 反序列化（核心入口）
  factory Skill.fromContent(String content) {
    final map = jsonDecode(content) as Map<String, dynamic>;
    return Skill.fromJson(map, content: content);
  }

  Skill copyWith({
    String? content,
    String? skillId,
    String? name,
    String? description,
    String? prompt,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? path,
    List<McpToolInfo>? tools,
  }) {
    return Skill(
      content: content ?? this.content,
      skillId: skillId ?? this.skillId,
      name: name ?? this.name,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      path: path ?? this.path,
      tools: tools ?? this.tools,
    );
  }

  /// 序列化为 JSON（优先直接返回 content）
  Map<String, dynamic> toJson() {
    if (content != null && content!.isNotEmpty) {
      return jsonDecode(content!) as Map<String, dynamic>;
    }
    final map = <String, dynamic>{
      'skillId': skillId,
      'name': name,
      'description': description,
      'prompt': prompt,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'path': path,
    };
    if (tools != null) {
      map['tools'] = tools!.map((t) => t.toJson()).toList();
    }
    return map;
  }

  /// JSON 反序列化
  factory Skill.fromJson(Map<String, dynamic> json, {String? content}) {
    final toolsList = json['tools'] as List<dynamic>?;
    return Skill(
      content: content ?? jsonEncode(json),
      skillId: json['skillId'] as String? ?? json['id'] as String? ?? '',
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
      path: json['path'] as String? ?? json['folderPath'] as String? ?? '',
      tools:
          toolsList
              ?.map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Skill && other.skillId == skillId;
  }

  @override
  int get hashCode => skillId.hashCode;

  @override
  String toString() {
    return 'Skill{skillId: $skillId, name: $name}';
  }
}
