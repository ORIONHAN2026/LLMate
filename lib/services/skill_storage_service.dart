import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/chat/skill.dart';

/// Skill 文件系统存储服务
///
/// 技能以文件夹形式存储在 `skills/` 目录下，每个技能文件夹内有一个 `SKILL.md`。
class SkillStorageService {
  /// 获取 skills 根目录
  static String get skillsRootDir {
    // 在开发/运行时，skills/ 位于项目根目录
    final cwd = Directory.current.path;
    // 尝试从当前运行目录找到 skills/
    return p.join(cwd, 'skills');
  }

  /// 扫描 skills/ 目录，解析所有技能的 SKILL.md
  static Future<List<Skill>> loadSkills() async {
    final skills = <Skill>[];
    final root = Directory(skillsRootDir);

    if (!await root.exists()) {
      debugPrint('⚠️ SkillStorageService: skills 目录不存在: $skillsRootDir');
      return skills;
    }

    final entries = await root.list().toList();
    for (final entry in entries) {
      if (entry is! Directory) continue;
      final mdFile = File(p.join(entry.path, 'SKILL.md'));
      if (!await mdFile.exists()) continue;

      try {
        final raw = await mdFile.readAsString();
        final frontmatter = Skill.parseFrontmatter(raw);
        final body = Skill.extractBody(raw);
        final folderName = p.basename(entry.path);
        final stat = await entry.stat();

        skills.add(Skill(
          id: folderName,
          name: frontmatter.name.isNotEmpty ? frontmatter.name : folderName,
          description: frontmatter.description,
          prompt: body,
          icon: Skill.deriveIcon(folderName),
          createdAt: stat.changed,
          updatedAt: stat.changed,
          folderPath: entry.path,
        ));
      } catch (e) {
        debugPrint('⚠️ 解析技能失败 (${p.basename(entry.path)}): $e');
      }
    }

    return skills;
  }

  /// 创建新技能文件夹 + SKILL.md
  static Future<Skill> createSkill({
    required String name,
    required String description,
    required String prompt,
    String icon = 'star',
  }) async {
    final folderName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final folder = Directory(p.join(skillsRootDir, folderName));

    if (await folder.exists()) {
      throw Exception('技能文件夹已存在: $folderName');
    }

    await folder.create(recursive: true);

    final mdContent = '''---
name: $name
description: $description
---

$prompt
''';

    final mdFile = File(p.join(folder.path, 'SKILL.md'));
    await mdFile.writeAsString(mdContent);

    final stat = await folder.stat();

    return Skill(
      id: folderName,
      name: name,
      description: description,
      prompt: prompt,
      icon: icon,
      createdAt: stat.changed,
      updatedAt: stat.changed,
      folderPath: folder.path,
    );
  }

  /// 更新技能的 SKILL.md
  static Future<void> updateSkill(Skill skill) async {
    final mdFile = File(p.join(skill.folderPath, 'SKILL.md'));
    if (!await mdFile.exists()) {
      throw Exception('SKILL.md 不存在: ${skill.folderPath}');
    }

    final mdContent = '''---
name: ${skill.name}
description: ${skill.description}
---

${skill.prompt}
''';

    await mdFile.writeAsString(mdContent);
  }

  /// 删除技能文件夹
  static Future<void> deleteSkill(String folderPath) async {
    final folder = Directory(folderPath);
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
