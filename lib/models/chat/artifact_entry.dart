import 'dart:convert';

/// 会话产物条目 — 可以是单个文件或包含多个文件的目录
class ArtifactEntry {
  /// 唯一标识
  final String id;

  /// 产物名称（文件名或目录名）
  final String name;

  /// 路径（文件路径或目录路径）
  final String path;

  /// 是否为目录（代码生成等批量产出场景）
  final bool isDirectory;

  /// 包含的文件路径列表（仅当 isDirectory=true 时有意义）
  final List<String> files;

  /// 创建时间
  final DateTime createdAt;

  const ArtifactEntry({
    required this.id,
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.files = const [],
    required this.createdAt,
  });

  /// 从工具执行结果中提取的所有路径，每个文件单独作为一个产物条目
  static List<ArtifactEntry> fromPaths(List<String> allPaths) {
    if (allPaths.isEmpty) return [];

    final now = DateTime.now();
    final result = <ArtifactEntry>[];
    final seen = <String>{};
    int idx = 0;

    for (final path in allPaths) {
      if (seen.contains(path)) continue;
      seen.add(path);

      final fileName =
          path.contains('/')
              ? path.substring(path.lastIndexOf('/') + 1)
              : path;

      result.add(
        ArtifactEntry(
          id: 'artifact_${now.millisecondsSinceEpoch}_${idx++}',
          name: fileName,
          path: path,
          isDirectory: false,
          files: [path],
          createdAt: now,
        ),
      );
    }

    // 按文件名排序
    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'isDirectory': isDirectory,
    'files': files,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ArtifactEntry.fromJson(Map<String, dynamic> json) {
    return ArtifactEntry(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      isDirectory: json['isDirectory'] as bool? ?? false,
      files:
          (json['files'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  /// JSON encode helper
  static String encode(List<ArtifactEntry> artifacts) {
    return jsonEncode(artifacts.map((a) => a.toJson()).toList());
  }

  /// JSON decode helper
  static List<ArtifactEntry> decode(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => ArtifactEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
