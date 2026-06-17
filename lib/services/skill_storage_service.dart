import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/chat/skill.dart';

/// Skill 文件系统存储服务
///
/// 技能以文件夹形式存储在应用文档目录下，每个技能文件夹内有一个 `SKILL.md`。
/// 内置技能从 assets/skills/ 复制到文档目录。
class SkillStorageService {
  /// 获取 skills 根目录（应用支持目录下的 skills/）
  static Future<String> getSkillsRootDir() async {
    try {
      // 优先使用 path_provider 的 Application Support 目录
      final appSupportDir = await getApplicationSupportDirectory();
      final skillsDir = Directory(p.join(appSupportDir.path, 'skills'));
      if (!await skillsDir.exists()) {
        await skillsDir.create(recursive: true);
      }
      debugPrint('📂 技能目录: ${skillsDir.path}');
      return skillsDir.path;
    } catch (e) {
      // 备用方案：手动构建路径
      debugPrint('⚠️ path_provider 失败: $e，使用备用方案');
      final home = Platform.environment['HOME'];
      if (home != null) {
        // macOS: ~/Library/Application Support/[bundleId]/skills
        // 尝试从 info.plist 读取 bundleId，默认为 com.llmwork.app
        final bundleId = 'com.llmwork.app'; // 可以从 Plist 读取，暂时硬编码
        final fallbackDir = Directory(p.join(home, 'Library', 'Application Support', bundleId, 'skills'));
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        debugPrint('📂 备用技能目录: ${fallbackDir.path}');
        return fallbackDir.path;
      }
      // 最后备用：当前目录下的 skills/
      final cwd = Directory.current.path;
      final fallbackDir = Directory(p.join(cwd, 'skills'));
      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }
      debugPrint('📂 最后备用技能目录: ${fallbackDir.path}');
      return fallbackDir.path;
    }
  }

  /// 复制 assets/skills/ 中的内置技能到可写目录（仅复制不存在的技能）
  /// 启动时动态扫描 assets/skills/ 目录，自动发现所有内置技能文件夹
  static Future<void> copyBuiltinSkillsFromAssets() async {
    final skillsRoot = await getSkillsRootDir();
    
    // 动态扫描 assets/skills/ 下的所有文件夹，获取内置技能列表
    final builtinSkills = await scanBuiltinSkillFolders();
    
    if (builtinSkills.isEmpty) {
      debugPrint('⚠️ SkillStorageService: assets/skills/ 中没有发现内置技能');
      return;
    }
    
    int copiedCount = 0;
    
    // 复制每个技能文件夹（仅复制不存在的）
    for (final folderName in builtinSkills) {
      final targetDir = Directory(p.join(skillsRoot, folderName));
      if (!await targetDir.exists()) {
        await _copySkillFolderFromAssets(folderName, skillsRoot);
        copiedCount++;
      }
    }
    
    debugPrint('✅ SkillStorageService: 已从 assets 复制 $copiedCount 个内置技能（共 ${builtinSkills.length} 个）');
  }
  
  /// 动态扫描 assets/skills/ 下的所有子文件夹，返回文件夹名列表
  static Future<List<String>> scanBuiltinSkillFolders() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = assetManifest.listAssets();
      
      // 筛选 assets/skills/ 下的文件，提取一级子文件夹名
      final folderNames = <String>{};
      for (final assetPath in allAssets) {
        if (assetPath.startsWith('assets/skills/')) {
          final relative = assetPath.substring('assets/skills/'.length);
          final slashIndex = relative.indexOf('/');
          if (slashIndex > 0) {
            folderNames.add(relative.substring(0, slashIndex));
          }
        }
      }
      
      final sorted = folderNames.toList()..sort();
      debugPrint('📦 扫描到 ${sorted.length} 个内置技能: ${sorted.join(", ")}');
      return sorted;
    } catch (e, stackTrace) {
      debugPrint('⚠️ 扫描内置技能失败: $e');
      debugPrint('  堆栈: $stackTrace');
      return [];
    }
  }
  
  /// 复制单个技能文件夹从 assets 到可写目录
  static Future<void> _copySkillFolderFromAssets(String folderName, String skillsRoot) async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final prefix = 'assets/skills/$folderName/';
    final skillAssets = assetManifest.listAssets()
        .where((path) => path.startsWith(prefix))
        .toList();
    
    debugPrint('📦 复制技能: $folderName, 文件数: ${skillAssets.length}');
    
    for (final assetPath in skillAssets) {
      try {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        
        // 计算相对路径
        final relativePath = assetPath.substring('assets/skills/'.length);
        final targetFile = File(p.join(skillsRoot, relativePath));
        
        // 确保父目录存在
        await targetFile.parent.create(recursive: true);
        
        // 写入文件
        await targetFile.writeAsBytes(bytes);
        debugPrint('  ✅ 已复制: $relativePath');
      } catch (e) {
        debugPrint('  ⚠️ 复制失败: $assetPath, 错误: $e');
      }
    }
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
        debugPrint('  📁 ${p.basename(entry.path)} ${hasSkillMd ? "✅" : "❌ (无 SKILL.md)"}');
      }
    }
  }

  /// 扫描 skills/ 目录，解析所有技能的 SKILL.md
  /// [builtinFolderNames] 为内置技能文件夹名集合，用于标记 isBuiltin
  static Future<List<Skill>> loadSkills({Set<String>? builtinFolderNames}) async {
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
        final isBuiltin = builtinFolderNames?.contains(folderName) ?? false;

        final skill = Skill(
          skillId: folderName,
          name: frontmatter.name.isNotEmpty ? frontmatter.name : folderName,
          description: frontmatter.description,
          prompt: body,
          icon: Skill.deriveIcon(folderName),
          createdAt: stat.changed,
          updatedAt: stat.changed,
          path: entry.path,
          isBuiltin: isBuiltin,
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
