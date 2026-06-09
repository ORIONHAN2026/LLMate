import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../models/chat/skill.dart';
import '../services/skill_service.dart';
import '../services/skill_storage_service.dart';
import '../utils/snackbar_utils.dart';
import 'skill_marketplace_page.dart';

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
    try {
      // 强制重新扫描文件系统以获取最新技能列表
      SkillService.reset();
      await SkillService.ensureLoaded();
    } catch (e) {
      // 加载失败时静默处理，避免崩溃
      debugPrint('加载技能列表失败: $e');
    }
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

  void _showAddSkillChoice() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(CupertinoIcons.archivebox),
                    title: const Text('从压缩包导入'),
                    subtitle: const Text('选择 .zip 文件，解压到 skills/ 目录'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _importSkillZip();
                    },
                  ),
                  ListTile(
                    leading: const Icon(CupertinoIcons.pencil),
                    title: const Text('创建自定义技能'),
                    subtitle: const Text('手动填写技能名称、描述和提示词'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddSkillDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _importSkillZip() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        if (mounted) SnackBarUtils.showError(context, '无法读取文件路径');
        return;
      }

      if (mounted) {
        SnackBarUtils.showInfo(context, '正在解压导入...');
      }

      final zipFile = File(file.path!);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          // 跳过顶层文件，只处理目录结构
          final fileName = archiveFile.name;
          if (!fileName.contains('/')) continue;

          // 构建目标路径
          final targetPath = p.join(
            SkillStorageService.skillsRootDir,
            fileName,
          );
          final targetFile = File(targetPath);

          // 确保父目录存在
          await targetFile.parent.create(recursive: true);

          // 写入文件
          await targetFile.writeAsBytes(archiveFile.content as List<int>);
        }
      }

      // 重新加载技能列表
      await _refreshSkills();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已导入技能');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '导入失败: $e');
      }
    }
  }

  void _showAddSkillDialog({Skill? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final promptCtrl = TextEditingController(text: existing?.prompt ?? '');
    String selectedIcon = existing?.icon ?? 'star';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
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
                              helperStyle: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
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
                          const Text(
                            '图标',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _iconOptions.map((icon) {
                                  final isSelected =
                                      selectedIcon == icon['key'];
                                  return GestureDetector(
                                    onTap:
                                        () => setDialogState(
                                          () =>
                                              selectedIcon =
                                                  icon['key'] as String,
                                        ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                  : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Text(
                                        icon['emoji'] as String,
                                        style: const TextStyle(fontSize: 20),
                                      ),
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
                        final skillName = nameCtrl.text.trim();
                        Navigator.pop(ctx);
                        try {
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
                              name: skillName,
                              description: descCtrl.text.trim(),
                              prompt: promptCtrl.text.trim(),
                              icon: selectedIcon,
                            );
                          }
                          await _refreshSkills();
                          if (mounted) {
                            SnackBarUtils.showInfo(
                              context,
                              isEdit
                                  ? '已更新技能: $skillName'
                                  : '已创建技能: $skillName',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackBarUtils.showError(
                              context,
                              isEdit ? '更新技能失败: $e' : '创建技能失败: $e',
                            );
                          }
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
      builder:
          (ctx) => AlertDialog(
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
      try {
        await SkillService.deleteSkill(skill.skillId);
        await _refreshSkills();
        if (mounted) {
          SnackBarUtils.showInfo(context, '已删除技能: ${skill.name}');
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, '删除技能失败: $e');
        }
      }
    }
  }

  void _showSkillDetail(Skill skill) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '技能详情',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                final tools = skill.tools;
                final hasTools = tools != null && tools.isNotEmpty;
                final emoji = _getSkillEmoji(skill.icon);

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 700,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                  ),
                  child: Material(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 头部
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            skill.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      skill.description.isNotEmpty
                                          ? skill.description
                                          : '文件夹: ${skill.skillId}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 工具列表
                          if (hasTools) ...[
                            Text(
                              '工具列表 (${tools.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  tools.take(50).map((t) {
                                    final label =
                                        t.description.isNotEmpty
                                            ? '${t.name} · ${t.description}'
                                            : t.name;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            if (tools.length > 50)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '... 还有 ${tools.length - 50} 个工具',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            const Divider(),
                            const SizedBox(height: 12),
                          ],

                          // 系统提示词
                          if (skill.prompt.isNotEmpty) ...[
                            Text(
                              '系统提示词',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
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
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFFD4D4D4),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // JSON 配置
                          Text(
                            'JSON 数据',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
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
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(skill.toJson()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: Color(0xFFD4D4D4),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 删除按钮
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
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
        title: const Text('技能管理(SKILL)'),
        actions: [
          TextButton(
            onPressed: _showAddSkillChoice,
            child: const Text('添加技能', style: TextStyle(fontSize: 14)),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SkillMarketplacePage()),
            ),
            child: const Text('应用市场', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          _isLoading
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点击右上角 + 号创建自定义技能',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.35),
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
          Text(
            'skills/ 共 ${_skills.length} 个技能',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
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
    final emoji = _getSkillEmoji(skill.icon);
    final description = skill.description.isNotEmpty ? skill.description : null;
    final subtitle = skill.skillId;

    return GestureDetector(
      onTap: () => _showSkillDetail(skill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          skill.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (description != null)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 编辑按钮
            GestureDetector(
              onTap: () => _showAddSkillDialog(existing: skill),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 删除按钮
            GestureDetector(
              onTap: () => _confirmDeleteSkill(skill),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.delete,
                  size: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
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
