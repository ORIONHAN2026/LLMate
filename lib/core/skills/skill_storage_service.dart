import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../models/chat/skill.dart';

/// Skill 文件系统存储服务
///
/// 技能以文件夹形式存储在应用文档目录下，每个技能文件夹内有一个 `SKILL.md`。
/// 内置技能从 assets/skills/ 复制到文档目录。
class SkillStorageService {
  /// 获取 skills 根目录（~/.llmwork/skills/）
  static Future<String> getSkillsRootDir() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    final skillsDir = Directory(p.join(home!, '.llmwork', 'skills'));
    if (!await skillsDir.exists()) {
      await skillsDir.create(recursive: true);
    }
    return skillsDir.path;
  }

  /// 复制内置技能到可写目录（覆盖模式）
  /// 自动动态复制 assets/skills/ 目录下的所有内置技能到可写目录（覆盖模式）
  static Future<void> copyBuiltinSkillsFromAssets() async {
    final skillsRoot = await getSkillsRootDir();

    // 1. 加载 Flutter 资源清单
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = assetManifest.listAssets();

    int copiedCount = 0;
    final Set<String> detectedSkills = {}; // 用于统计识别到了多少个独立技能文件夹

    debugPrint('📂 开始扫描内置技能资源...');

    // 2. 过滤出所有属于 skills 目录的资源文件
    // 兼容处理：检查路径中是否包含 'skills/'
    final skillAssets =
        allAssets.where((path) => path.contains('skills/')).toList();

    for (final assetPath in skillAssets) {
      try {
        // 3. 定位 'skills/' 在路径中的位置，动态计算相对路径
        final skillsIndex = assetPath.indexOf('skills/');
        if (skillsIndex == -1) continue;

        // 截取后得到如: skills/skill-creator/SKILL.md
        final relativePathWithSkills = assetPath.substring(skillsIndex);

        // 进一步去掉 'skills/'，得到真实的相对路径: skill-creator/SKILL.md
        final relativePath = relativePathWithSkills.substring('skills/'.length);

        // 如果相对路径为空或者是纯空字符串，则跳过
        if (relativePath.trim().isEmpty) continue;

        // 统计识别到的技能文件夹名称（第一级子目录）
        final firstSegment = p.split(relativePath).first;
        detectedSkills.add(firstSegment);

        // 4. 构建目标写入路径
        final targetFile = File(p.join(skillsRoot, relativePath));

        // 5. 读取并写入文件
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();

        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(bytes);

        copiedCount++;
      } catch (e) {
        debugPrint('  ⚠️ 复制文件失败: $assetPath, 错误: $e');
      }
    }

    debugPrint(
      '✅ SkillStorageService: 扫描到 ${detectedSkills.length} 个技能文件夹 (${detectedSkills.toList()})',
    );
    debugPrint('✅ 成功从 assets 复制了 $copiedCount 个文件到沙盒目录。');
  }

  /// 打印可写目录中的技能列表（调试用）
  static Future<void> debugPrintSkillsDir() async {
    final skillsRoot = await getSkillsRootDir();
    debugPrint('📂 技能目录: $skillsRoot');

    final dir = Directory(skillsRoot);
    if (!await dir.exists()) {
      debugPrint('  ❌ 目录不存在');
      return;
    }

    final entries = await dir.list().toList();
    debugPrint('  找到 ${entries.length} 个条目:');

    for (final entry in entries) {
      if (entry is Directory) {
        final mdFile = File(p.join(entry.path, 'SKILL.md'));
        final hasSkillMd = await mdFile.exists();
        debugPrint(
          '  📁 ${p.basename(entry.path)} ${hasSkillMd ? "✅" : "❌ (无 SKILL.md)"}',
        );
      }
    }
  }

  /// 扫描 skills/ 目录，解析所有技能的 SKILL.md
  static Future<List<Skill>> loadSkills() async {
    final skills = <Skill>[];
    final skillsRoot = await getSkillsRootDir();
    final root = Directory(skillsRoot);

    if (!await root.exists()) {
      debugPrint('⚠️ SkillStorageService: skills 目录不存在: $skillsRoot');
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

        final skill = Skill(
          skillId: folderName,
          name: frontmatter.name.isNotEmpty ? frontmatter.name : folderName,
          description: frontmatter.description,
          prompt: body,
          icon: Skill.deriveIcon(folderName),
          createdAt: stat.changed,
          updatedAt: stat.changed,
          path: entry.path,
        );
        skills.add(skill.copyWith(content: jsonEncode(skill.toJson())));
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
    final skillsRoot = await getSkillsRootDir();
    final folderName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final folder = Directory(p.join(skillsRoot, folderName));

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

    final skill = Skill(
      skillId: folderName,
      name: name,
      description: description,
      prompt: prompt,
      icon: icon,
      createdAt: stat.changed,
      updatedAt: stat.changed,
      path: folder.path,
    );
    return skill.copyWith(content: jsonEncode(skill.toJson()));
  }

  /// 更新技能的 SKILL.md
  static Future<void> updateSkill(Skill skill) async {
    final mdFile = File(p.join(skill.path, 'SKILL.md'));
    if (!await mdFile.exists()) {
      throw Exception('SKILL.md 不存在: ${skill.path}');
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
  static Future<void> deleteSkill(String path) async {
    final folder = Directory(path);
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }
}
