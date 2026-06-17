import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_session.dart';
import '../models/chat/skill.dart';
import 'skill_storage_service.dart';

/// Skill 业务逻辑服务
///
/// 技能以 `skills/` 目录下的文件夹形式管理，每个技能文件夹内含 `SKILL.md`。
///
/// - 扫描文件系统加载技能
/// - 内存缓存加速读取
/// - CRUD 操作直接操作文件系统
/// - 技能 prompt 注入能力
///
/// 使用方式：
/// ```dart
/// await SkillService.ensureLoaded();
/// final allSkills = SkillService.skills;
/// ```
class SkillService {
  // ======== 内存缓存 ========

  /// 已加载的所有技能
  static List<Skill> _skills = [];
  static bool _loaded = false;

  /// 所有技能列表
  static List<Skill> get skills => List.unmodifiable(_skills);

  /// 是否已加载
  static bool get isLoaded => _loaded;

  // ======== 加载 ========

  /// 确保技能已从文件系统加载（延迟初始化，幂等）
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadSkills();
  }

  /// 从文件系统加载技能（强制刷新）
  static Future<void> loadSkills() async {
    _skills = await SkillStorageService.loadSkills();
    _loaded = true;
    debugPrint('✅ SkillService: 加载了 ${_skills.length} 个技能');
  }

  // ======== 查询 ========

  /// 按 skillId（文件夹名）查找技能
  static Skill? getSkillById(String skillId) {
    return skills.cast<Skill?>().firstWhere(
      (s) => s!.skillId == skillId,
      orElse: () => null,
    );
  }

  /// 按名称模糊搜索
  static List<Skill> searchSkills(String query) {
    final lower = query.toLowerCase();
    return skills.where((s) {
      return s.name.toLowerCase().contains(lower) ||
          s.description.toLowerCase().contains(lower);
    }).toList();
  }

  // ======== 写入 ========

  /// 创建新技能（文件夹 + SKILL.md）
  static Future<Skill> addSkill({
    required String name,
    required String description,
    required String prompt,
    String icon = 'star',
  }) async {
    final skill = await SkillStorageService.createSkill(
      name: name,
      description: description,
      prompt: prompt,
      icon: icon,
    );
    _skills.add(skill);
    debugPrint('✅ SkillService: 创建技能 "${skill.name}"');
    return skill;
  }

  /// 更新技能（修改 SKILL.md）
  static Future<void> updateSkill(Skill skill) async {
    await SkillStorageService.updateSkill(skill);
    final index = _skills.indexWhere((s) => s.skillId == skill.skillId);
    if (index != -1) {
      _skills[index] = skill;
    }
    debugPrint('✅ SkillService: 更新技能 "${skill.name}"');
  }

  /// 删除技能（删除文件夹）
  static Future<void> deleteSkill(String skillId) async {
    final skill = getSkillById(skillId);
    if (skill == null) return;

    await SkillStorageService.deleteSkill(skill.path);
    _skills.removeWhere((s) => s.skillId == skillId);
    debugPrint('✅ SkillService: 删除技能 "${skill.name}"');
  }

  // ======== Prompt 构建 ========

  /// 将技能注入到 system prompt 中，附带技能目录文件清单
  static String buildSkillPrompt(Skill? activeSkill) {
    if (activeSkill == null || activeSkill.prompt.isEmpty) {
      return '';
    }
    final inventory = _buildFileInventory(activeSkill.path);
    final buffer = StringBuffer();
    buffer.writeln('\n\n【当前技能】${activeSkill.name}');
    buffer.writeln(activeSkill.prompt);
    if (inventory.isNotEmpty) {
      buffer.writeln();
      buffer.write(inventory);
    }
    return buffer.toString();
  }

  /// 批量构建多个技能的 prompt，附带各技能目录的文件清单
  static String buildMultiSkillPrompt(List<Skill> activeSkills) {
    if (activeSkills.isEmpty) return '';
    final buffer = StringBuffer('\n\n【已激活技能】');
    for (final skill in activeSkills) {
      if (skill.prompt.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('## ${skill.name}');
        buffer.writeln(skill.prompt);
        final inventory = _buildFileInventory(skill.path);
        if (inventory.isNotEmpty) {
          buffer.writeln();
          buffer.write(inventory);
        }
      }
    }
    return buffer.toString();
  }

  /// 扫描技能目录并生成文件清单，供大模型了解已存在的脚本和资源
  static String _buildFileInventory(String skillPath) {
    if (skillPath.isEmpty) return '';
    final dir = Directory(skillPath);
    if (!dir.existsSync()) return '';

    // 需要忽略的文件/目录
    const ignoreNames = {'SKILL.md', '_meta.json', '.DS_Store'};

    final List<_FileEntry> entries = [];
    _collectFiles(dir, dir.path, entries, ignoreNames);

    if (entries.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('【技能目录文件清单 - 请直接使用已有脚本，避免重复创建】');
    buffer.writeln('技能路径: $skillPath');

    // 按目录分组
    final groups = <String, List<_FileEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent(e.relDir, () => []).add(e);
    }

    for (final entry in groups.entries) {
      final label = entry.key.isEmpty ? '根目录' : entry.key;
      buffer.writeln('\n[$label]');
      for (final file in entry.value) {
        buffer.writeln('  ${file.name}  (${_formatSize(file.size)})');
      }
    }

    // 如果有 requirements.txt，读取内容
    _appendRequirementsContent(buffer, dir);

    return buffer.toString();
  }

  /// 递归收集目录下的文件
  static void _collectFiles(
    Directory dir,
    String rootPath,
    List<_FileEntry> entries,
    Set<String> ignoreNames,
  ) {
    final list = dir.listSync();
    for (final entity in list) {
      final name = entity.uri.pathSegments.last;
      if (ignoreNames.contains(name)) continue;
      if (entity is File) {
        final relPath = entity.path.substring(rootPath.length + 1);
        final parts = relPath.split(Platform.pathSeparator);
        final fileName = parts.last;
        final relDir =
            parts.length > 1
                ? parts
                    .sublist(0, parts.length - 1)
                    .join(Platform.pathSeparator)
                : '';
        entries.add(
          _FileEntry(name: fileName, relDir: relDir, size: entity.lengthSync()),
        );
      } else if (entity is Directory) {
        _collectFiles(entity, rootPath, entries, ignoreNames);
      }
    }
  }

  /// 如果存在 requirements.txt，追加其内容
  static void _appendRequirementsContent(StringBuffer buffer, Directory dir) {
    final reqFile = File('${dir.path}/requirements.txt');
    if (!reqFile.existsSync()) return;
    // 也检查子目录中的 requirements.txt
    for (final sub in dir.listSync(recursive: true)) {
      if (sub is File && sub.uri.pathSegments.last == 'requirements.txt') {
        try {
          final content = sub.readAsStringSync().trim();
          if (content.isNotEmpty) {
            final relPath = sub.path.substring(dir.path.length + 1);
            buffer.writeln(
              '\n[依赖: $relPath]\n$content\n(安装命令: cd "${dir.path}" && pip install -r "$relPath")',
            );
          }
        } catch (_) {}
      }
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ======== 工具方法 ========

  /// 将会话绑定的技能转为 OpenAI function-calling 工具列表
  ///
  /// 目前为占位实现：技能尚未内建工具定义，仅以技能名称/描述作为无参工具暴露。
  /// 后续需解析 SKILL.md 中的工具声明块来填充真实的 parameters schema。
  static List<Map<String, dynamic>> buildSkillTools(ChatSession? session) {
    if (session == null) return [];
    final tools = <Map<String, dynamic>>[];

    // 会话绑定的技能
    if (session.skill != null) {
      final t = _skillToTool(session.skill!);
      if (t != null) tools.add(t);
    }
    // 模型绑定的技能
    final modelSkills = session.chatModel?.skills;
    if (modelSkills != null) {
      for (final skill in modelSkills) {
        final t = _skillToTool(skill);
        if (t != null) tools.add(t);
      }
    }
    return tools;
  }

  /// 将单个 Skill 转为 OpenAI function-calling 工具定义（占位）
  static Map<String, dynamic>? _skillToTool(Skill skill) {
    // OpenAI function name 仅允许 [a-zA-Z0-9_-]
    final raw = skill.skillId.isNotEmpty ? skill.skillId : skill.name;
    if (raw.isEmpty) return null;
    final safeName = _sanitizeToolName(raw);
    if (safeName.isEmpty) return null;

    final desc =
        skill.description.isNotEmpty
            ? '${skill.name}: ${skill.description}'
            : skill.name;

    return {
      'type': 'function',
      'function': {
        'name': safeName,
        'description': desc,
        'parameters': {
          'type': 'object',
          'properties': <String, dynamic>{},
          'required': <String>[],
        },
      },
    };
  }

  /// 将任意字符串转为合法的 OpenAI function name（仅保留 [a-zA-Z0-9_-]）
  static String _sanitizeToolName(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (cleaned.isEmpty) return '';
    // 确保不以数字开头
    if (RegExp(r'^\d').hasMatch(cleaned)) {
      return 'skill_$cleaned';
    }
    return cleaned;
  }

  /// 重置缓存（强制重新扫描文件系统）
  static void reset() {
    _skills = [];
    _loaded = false;
  }
}

/// 文件条目（仅用于生成文件清单）
class _FileEntry {
  final String name;
  final String relDir;
  final int size;
  const _FileEntry({
    required this.name,
    required this.relDir,
    required this.size,
  });
}
