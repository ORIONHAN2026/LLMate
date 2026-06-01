import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/chat/skill.dart';
import 'skill_storage_service.dart';

/// 技能管理内置工具
///
/// 提供 LLM 可调用的技能 CRUD 操作，包括列出、读取、创建、更新、删除技能。
/// 涉及技能修改时统一走此工具，确保 SKILL.md 格式一致。
class SkillToolService {
  // ── 操作入口 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> execute({
    required String action,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    switch (action) {
      case 'list':
        return _list(callId, arguments);
      case 'read':
        return _read(callId, arguments);
      case 'create':
        return await _create(callId, arguments);
      case 'update':
        return await _update(callId, arguments);
      case 'delete':
        return await _delete(callId, arguments);
      default:
        return _error(callId, arguments, '不支持的操作: $action，可用: list/read/create/update/delete');
    }
  }

  // ── 列出所有技能 ──────────────────────────────────────────

  static Map<String, dynamic> _list(String callId, Map<String, dynamic> args) {
    final root = Directory(SkillStorageService.skillsRootDir);
    if (!root.existsSync()) {
      return _ok(callId, args, {'skills': [], 'message': 'skills 目录不存在'});
    }

    final skills = <Map<String, dynamic>>[];
    for (final entity in root.listSync().whereType<Directory>()) {
      final mdFile = File(p.join(entity.path, 'SKILL.md'));
      if (!mdFile.existsSync()) continue;

      try {
        final raw = mdFile.readAsStringSync();
        final fm = Skill.parseFrontmatter(raw);
        final folderName = p.basename(entity.path);
        skills.add({
          'id': folderName,
          'name': fm.name.isNotEmpty ? fm.name : folderName,
          'description': fm.description,
        });
      } catch (_) {}
    }

    return _ok(callId, args, {
      'skills': skills,
      'total': skills.length,
      'message': '共 ${skills.length} 个技能',
    });
  }

  // ── 读取技能内容 ──────────────────────────────────────────

  static Map<String, dynamic> _read(String callId, Map<String, dynamic> args) {
    final skillId = _stringArg(args, 'skillId').trim();
    if (skillId.isEmpty) {
      return _error(callId, args, 'skillId 参数不能为空');
    }

    final mdFile = File(p.join(SkillStorageService.skillsRootDir, skillId, 'SKILL.md'));
    if (!mdFile.existsSync()) {
      return _error(callId, args, '技能不存在: $skillId');
    }

    final raw = mdFile.readAsStringSync();
    final fm = Skill.parseFrontmatter(raw);
    final body = Skill.extractBody(raw);

    return _ok(callId, args, {
      'id': skillId,
      'name': fm.name,
      'description': fm.description,
      'content': body,
      'rawMarkdown': raw,
      'message': '已读取技能: ${fm.name}',
    });
  }

  // ── 创建技能 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _create(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final name = _stringArg(args, 'name').trim();
    final description = _stringArg(args, 'description').trim();
    final content = _stringArg(args, 'content').trim();

    if (name.isEmpty) {
      return _error(callId, args, 'name 参数不能为空');
    }
    if (content.isEmpty) {
      return _error(callId, args, 'content 参数不能为空');
    }

    try {
      // 生成文件夹名：中文/英文均支持
      final folderName = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');

      final folder = Directory(
        p.join(SkillStorageService.skillsRootDir, folderName),
      );

      if (folder.existsSync()) {
        return _error(callId, args, '技能已存在: $folderName，如需修改请使用 update 操作');
      }

      await folder.create(recursive: true);

      final mdContent = _buildSkillMarkdown(
        name: name,
        description: description.isNotEmpty ? description : name,
        content: content,
      );

      final mdFile = File(p.join(folder.path, 'SKILL.md'));
      await mdFile.writeAsString(mdContent);

      if (kDebugMode) {
        debugPrint('🛠️ [SkillTool] 创建技能: $name → ${folder.path}');
      }

      return _ok(callId, args, {
        'id': folderName,
        'name': name,
        'path': mdFile.path,
        'message': '技能 "$name" 已创建',
      });
    } catch (e) {
      return _error(callId, args, '创建技能失败: $e');
    }
  }

  // ── 更新技能 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _update(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final skillId = _stringArg(args, 'skillId').trim();
    if (skillId.isEmpty) {
      return _error(callId, args, 'skillId 参数不能为空');
    }

    final mdFile = File(
      p.join(SkillStorageService.skillsRootDir, skillId, 'SKILL.md'),
    );
    if (!mdFile.existsSync()) {
      return _error(callId, args, '技能不存在: $skillId');
    }

    try {
      // 读取现有内容
      final raw = mdFile.readAsStringSync();
      final fm = Skill.parseFrontmatter(raw);

      // 合并更新字段
      final name = _stringArg(args, 'name').trim();
      final description = _stringArg(args, 'description').trim();
      final content = _stringArg(args, 'content').trim();

      if (name.isEmpty && description.isEmpty && content.isEmpty) {
        return _error(callId, args, '至少需要提供 name、description 或 content 之一');
      }

      final newName = name.isNotEmpty ? name : fm.name;
      final newDesc = description.isNotEmpty ? description : fm.description;
      final newContent = content.isNotEmpty ? content : Skill.extractBody(raw);

      final mdContent = _buildSkillMarkdown(
        name: newName,
        description: newDesc,
        content: newContent,
      );

      await mdFile.writeAsString(mdContent);

      if (kDebugMode) {
        debugPrint('🛠️ [SkillTool] 更新技能: $skillId');
      }

      return _ok(callId, args, {
        'id': skillId,
        'name': newName,
        'path': mdFile.path,
        'message': '技能 "$newName" 已更新',
      });
    } catch (e) {
      return _error(callId, args, '更新技能失败: $e');
    }
  }

  // ── 删除技能 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _delete(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final skillId = _stringArg(args, 'skillId').trim();
    if (skillId.isEmpty) {
      return _error(callId, args, 'skillId 参数不能为空');
    }

    final folder = Directory(
      p.join(SkillStorageService.skillsRootDir, skillId),
    );
    if (!folder.existsSync()) {
      return _error(callId, args, '技能不存在: $skillId');
    }

    try {
      await folder.delete(recursive: true);

      if (kDebugMode) {
        debugPrint('🛠️ [SkillTool] 删除技能: $skillId');
      }

      return _ok(callId, args, {
        'id': skillId,
        'message': '技能 "$skillId" 已删除',
      });
    } catch (e) {
      return _error(callId, args, '删除技能失败: $e');
    }
  }

  // ── 工具方法 ──────────────────────────────────────────────

  static String _buildSkillMarkdown({
    required String name,
    required String description,
    required String content,
  }) {
    return '''---
name: $name
description: $description
agent_created: true
---

$content''';
  }

  static String _stringArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    return value == null ? '' : value.toString();
  }

  static Map<String, dynamic> _ok(
    String callId,
    Map<String, dynamic> args,
    Map<String, dynamic> data,
  ) {
    return {
      'id': callId,
      'name': 'skill_manager',
      'args': args,
      'result': jsonEncode(data),
      'isError': false,
    };
  }

  static Map<String, dynamic> _error(
    String callId,
    Map<String, dynamic> args,
    String message,
  ) {
    return {
      'id': callId,
      'name': 'skill_manager',
      'args': args,
      'result': message,
      'isError': true,
    };
  }
}
