import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/session_controller.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/skill.dart';
import '../services/model_storage_service.dart';
import '../utils/snackbar_utils.dart';

/// 技能管理页面
///
/// 管理当前模型绑定的技能列表，支持：
/// - 浏览预设技能
/// - 添加自定义技能
/// - 编辑/删除技能
class SkillManagementPage extends StatefulWidget {
  const SkillManagementPage({super.key});

  @override
  State<SkillManagementPage> createState() => _SkillManagementPageState();
}

class _SkillManagementPageState extends State<SkillManagementPage> {
  final sessionController = Get.find<SessionController>();
  late List<Skill> _skills;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  ChatModel? get _currentModel => sessionController.currentSession.value?.chatModel;

  void _loadSkills() {
    setState(() {
      _skills = List<Skill>.from(_currentModel?.skills ?? []);
      _isLoading = false;
    });
  }

  Future<void> _saveSkills(List<Skill> skills) async {
    final model = _currentModel;
    if (model == null) return;

    final updatedModel = model.copyWith(skills: skills);
    sessionController.updateSession(
      sessionController.currentSession.value!.copyWith(chatModel: updatedModel),
    );

    // 持久化保存
    final models = await ModelStorageService.loadModels();
    final updatedModels = models.map((m) {
      final cm = ChatModel.fromMap(m);
      if (cm.modelId == model.modelId) {
        return updatedModel.toMap();
      }
      return m;
    }).toList();
    await ModelStorageService.saveModels(updatedModels);

    setState(() => _skills = List<Skill>.from(skills));
  }

  Future<void> _addPresetSkill(Skill preset) async {
    final existingIds = _skills.map((s) => s.id).toSet();
    if (existingIds.contains(preset.id)) {
      if (mounted) {
        SnackBarUtils.showInfo(context, '技能 "${preset.name}" 已存在');
      }
      return;
    }
    final updated = [..._skills, preset];
    await _saveSkills(updated);
    if (mounted) {
      SnackBarUtils.showInfo(context, '已添加技能: ${preset.name}');
    }
  }

  Future<void> _deleteSkill(Skill skill) async {
    final updated = _skills.where((s) => s.id != skill.id).toList();
    await _saveSkills(updated);
    if (mounted) {
      SnackBarUtils.showInfo(context, '已删除技能: ${skill.name}');
    }
  }

  void _showAddCustomSkillDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final promptController = TextEditingController();
    String selectedIcon = 'star';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加自定义技能'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '技能名称',
                    hintText: '例如：代码审查专家',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '技能描述',
                    hintText: '简要描述这个技能的功能',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  SnackBarUtils.showError(context, '请输入技能名称');
                  return;
                }
                final newSkill = Skill.create(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  prompt: promptController.text.trim(),
                  icon: selectedIcon,
                );
                await _saveSkills([..._skills, newSkill]);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  SnackBarUtils.showInfo(context, '已添加技能: ${newSkill.name}');
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSkillDialog(Skill skill) {
    final nameController = TextEditingController(text: skill.name);
    final descController = TextEditingController(text: skill.description);
    final promptController = TextEditingController(text: skill.prompt);
    String selectedIcon = skill.icon;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('编辑技能'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '技能名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '技能描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: promptController,
                  decoration: const InputDecoration(
                    labelText: '系统提示词',
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  SnackBarUtils.showError(context, '请输入技能名称');
                  return;
                }
                final updatedSkill = skill.copyWith(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  prompt: promptController.text.trim(),
                  icon: selectedIcon,
                  updatedAt: DateTime.now(),
                );
                final updated = _skills.map((s) => s.id == skill.id ? updatedSkill : s).toList();
                await _saveSkills(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  SnackBarUtils.showInfo(context, '已更新技能: ${updatedSkill.name}');
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSkill(Skill skill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除技能'),
        content: Text('确定要删除技能 "${skill.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSkill(skill);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const Text('技能管理'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            tooltip: '添加自定义技能',
            onPressed: _showAddCustomSkillDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final presetSkills = Skill.getPresetSkills();
    final existingIds = _skills.map((s) => s.id).toSet();

    if (_skills.isEmpty && _currentModel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.wand_stars,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '请先选择一个会话并绑定模型',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前模型信息
          if (_currentModel != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.cube_box,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前模型: ${_currentModel!.displayName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${_skills.length} 个技能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // 已添加的技能
          if (_skills.isNotEmpty) ...[
            _buildSectionTitle('已添加的技能 (${_skills.length})'),
            const SizedBox(height: 8),
            ...List.generate(_skills.length, (index) {
              final skill = _skills[index];
              return _buildSkillCard(skill, isCustom: true);
            }),
            const SizedBox(height: 24),
          ],

          // 预设技能库
          _buildSectionTitle('预设技能库'),
          const SizedBox(height: 8),
          ...presetSkills.map((preset) {
            final isAdded = existingIds.contains(preset.id);
            return _buildPresetSkillCard(preset, isAdded: isAdded);
          }),
          const SizedBox(height: 24),

          // 自定义技能
          _buildSectionTitle('操作'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddCustomSkillDialog,
              icon: const Icon(CupertinoIcons.add, size: 16),
              label: const Text('添加自定义技能'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSkillCard(Skill skill, {bool isCustom = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _getSkillEmoji(skill.icon),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    skill.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 操作按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () => _showEditSkillDialog(skill),
                  tooltip: '编辑',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: Icon(
                    CupertinoIcons.delete,
                    size: 16,
                    color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                  ),
                  onPressed: () => _confirmDeleteSkill(skill),
                  tooltip: '删除',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSkillCard(Skill preset, {required bool isAdded}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAdded
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdded
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _getSkillEmoji(preset.icon),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isAdded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '已添加',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isAdded)
              FilledButton.icon(
                onPressed: () => _addPresetSkill(preset),
                icon: const Icon(CupertinoIcons.add, size: 14),
                label: const Text('添加', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}
