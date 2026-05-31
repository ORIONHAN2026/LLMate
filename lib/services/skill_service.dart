import 'package:flutter/foundation.dart';

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
    debugPrint('✅ SkillService: 从 skills/ 加载了 ${_skills.length} 个技能');
  }

  // ======== 查询 ========

  /// 按 ID（文件夹名）查找技能
  static Skill? getSkillById(String skillId) {
    return skills.cast<Skill?>().firstWhere(
      (s) => s!.id == skillId,
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
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index != -1) {
      _skills[index] = skill;
    }
    debugPrint('✅ SkillService: 更新技能 "${skill.name}"');
  }

  /// 删除技能（删除文件夹）
  static Future<void> deleteSkill(String skillId) async {
    final skill = getSkillById(skillId);
    if (skill == null) return;

    await SkillStorageService.deleteSkill(skill.folderPath);
    _skills.removeWhere((s) => s.id == skillId);
    debugPrint('✅ SkillService: 删除技能 "${skill.name}"');
  }

  // ======== Prompt 构建 ========

  /// 将技能注入到 system prompt 中
  static String buildSkillPrompt(Skill? activeSkill) {
    if (activeSkill == null || activeSkill.prompt.isEmpty) {
      return '';
    }
    return '\n\n【当前技能】${activeSkill.name}\n${activeSkill.prompt}';
  }

  /// 批量构建多个技能的 prompt
  static String buildMultiSkillPrompt(List<Skill> activeSkills) {
    if (activeSkills.isEmpty) return '';
    final buffer = StringBuffer('\n\n【已激活技能】');
    for (final skill in activeSkills) {
      if (skill.prompt.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('## ${skill.name}');
        buffer.writeln(skill.prompt);
      }
    }
    return buffer.toString();
  }

  // ======== 工具方法 ========

  /// 重置缓存（强制重新扫描文件系统）
  static void reset() {
    _skills = [];
    _loaded = false;
  }
}
