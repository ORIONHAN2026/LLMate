import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/chat/skill.dart';
import '../services/skill_service.dart';
import '../utils/snackbar_utils.dart';

/// 技能管理页面
///
/// 技能以 `skills/` 目录下的文件夹形式管理。
/// - 列表显示所有已安装技能
/// - 右上角 + 号创建自定义技能
/// - 编辑/删除技能
class SkillManagementPage extends StatefulWidget {
  const SkillManagementPage({super.key});

  @override
  State<SkillManagementPage> createState() => _SkillManagementPageState();
}

class _SkillManagementPageState extends State<SkillManagementPage> {
  List<Skill> _skills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    await SkillService.ensureLoaded();
    if (mounted) {
      setState(() {
        _skills = List<Skill>.from(SkillService.skills);
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSkills() async {
    SkillService.reset();
    await _loadSkills();
  }

  void _showAddSkillDialog({Skill? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final promptCtrl = TextEditingController(text: existing?.prompt ?? '');
    String selectedIcon = existing?.icon ?? 'star';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? '编辑技能' : '创建技能'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    enabled: !isEdit,
                    decoration: InputDecoration(
                      labelText: '技能名称',
                      hintText: '例如：代码审查专家',
                      border: const OutlineInputBorder(),
                      helperText: isEdit ? '创建后名称不可修改' : null,
                      helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: '技能描述',
                      hintText: '简要描述这个技能的功能',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: promptCtrl,
                    decoration: const InputDecoration(
                      labelText: '系统提示词',
                      hintText: '注入到AI对话中的提示内容',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  const Text('图标', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _iconOptions.map((icon) {
                      final isSelected = selectedIcon == icon['key'];
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedIcon = icon['key'] as String),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(icon['emoji'] as String, style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  SnackBarUtils.showError(context, '请输入技能名称');
                  return;
                }
                Navigator.pop(ctx);
                if (isEdit) {
                  final updated = existing.copyWith(
                    description: descCtrl.text.trim(),
                    prompt: promptCtrl.text.trim(),
                    icon: selectedIcon,
                    updatedAt: DateTime.now(),
                  );
                  await SkillService.updateSkill(updated);
                } else {
                  await SkillService.addSkill(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    prompt: promptCtrl.text.trim(),
                    icon: selectedIcon,
                  );
                }
                await _refreshSkills();
                if (mounted) {
                  SnackBarUtils.showInfo(
                    context,
                    isEdit ? '已更新技能: ${nameCtrl.text.trim()}' : '已创建技能: ${nameCtrl.text.trim()}',
                  );
                }
              },
              child: Text(isEdit ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSkill(Skill skill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除技能'),
        content: Text('确定要删除 "${skill.name}" 吗？此操作将删除整个技能文件夹，不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await SkillService.deleteSkill(skill.id);
      await _refreshSkills();
      if (mounted) {
        SnackBarUtils.showInfo(context, '已删除技能: ${skill.name}');
      }
    }
  }

  void _showSkillDetail(Skill skill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _getSkillEmoji(skill.icon),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(skill.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            '文件夹: ${skill.id}',
                            style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey[500]),
                          ),
                          if (skill.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(skill.description, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (skill.prompt.isNotEmpty) ...[
                  Text(
                    '系统提示词',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill.prompt,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFD4D4D4), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'JSON 数据',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(skill.toJson()),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFD4D4D4), height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddSkillDialog(existing: skill);
                    },
                    icon: const Icon(CupertinoIcons.pencil, size: 16),
                    label: const Text('编辑技能'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _confirmDeleteSkill(skill);
                    },
                    icon: const Icon(CupertinoIcons.delete, size: 16),
                    label: const Text('删除技能'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('技能管理'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled, size: 22),
            tooltip: '创建技能',
            onPressed: () => _showAddSkillDialog(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.folder,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无技能',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右上角 + 号创建自定义技能',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'skills/ 共 ${_skills.length} 个技能',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showAddSkillDialog(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, size: 15, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('创建技能', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _skills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final skill = _skills[index];
              return _buildSkillCard(skill);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    final hasPrompt = skill.prompt.isNotEmpty;

    return GestureDetector(
      onTap: () => _showSkillDetail(skill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasPrompt
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(_getSkillEmoji(skill.icon), style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    skill.id,
                    style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (skill.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasPrompt) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                      ),
                      child: Text(
                        '已配置提示词',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showAddSkillDialog(existing: skill),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.pencil, size: 14, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _confirmDeleteSkill(skill),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.delete, size: 14, color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSkillEmoji(String icon) {
    for (final option in _iconOptions) {
      if (option['key'] == icon) return option['emoji']!;
    }
    return '⭐';
  }

  static const List<Map<String, String>> _iconOptions = [
    {'key': 'code', 'emoji': '💻'},
    {'key': 'globe', 'emoji': '🌐'},
    {'key': 'pencil', 'emoji': '✏️'},
    {'key': 'chart', 'emoji': '📊'},
    {'key': 'lightbulb', 'emoji': '💡'},
    {'key': 'doc', 'emoji': '📄'},
    {'key': 'star', 'emoji': '⭐'},
    {'key': 'search', 'emoji': '🔍'},
    {'key': 'image', 'emoji': '🖼️'},
    {'key': 'gear', 'emoji': '⚙️'},
    {'key': 'wand', 'emoji': '🪄'},
  ];
}
