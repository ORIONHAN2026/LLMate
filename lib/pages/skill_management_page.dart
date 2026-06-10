import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../models/chat/skill.dart';
import '../services/skill_service.dart';
import '../services/skill_storage_service.dart';
import '../utils/snackbar_utils.dart';
import '../l10n/app_localizations.dart';
import '../widgets/common/confirm_delete_dialog.dart';

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
  final GlobalKey _marketplaceButtonKey = GlobalKey();

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

  void _showSkillMarketplaceMenu() {
    final RenderBox? button =
        _marketplaceButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonPosition.dx - 60,
        buttonPosition.dy + kToolbarHeight,
        140,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      items: [
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://bailian.console.aliyun.com/'));
          },
          child: Row(
            children: [
              const Text('阿里云', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://console.cloud.tencent.com/'));
          },
          child: Row(
            children: [
              const Text('腾讯云', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          height: 48,
          onTap: () {
            launchUrl(Uri.parse('https://modelscope.cn/'));
          },
          child: Row(
            children: [
              const Text('魔塔', style: TextStyle(fontSize: 12)),
              const Spacer(),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ],
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
        if (mounted) SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotReadFilePath);
        return;
      }

      if (mounted) {
        SnackBarUtils.showInfo(context, AppLocalizations.of(context)!.extractingImport);
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
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.skillImported);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.importFailed(e.toString()));
      }
    }
  }

  Future<void> _confirmDeleteSkill(Skill skill) async {
    final shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.deleteSkillTitle,
      itemName: skill.name,
      description: AppLocalizations.of(context)!.deleteSkillConfirm,
      warningMessage: AppLocalizations.of(context)!.irreversibleAction,
      icon: CupertinoIcons.delete,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      try {
        await SkillService.deleteSkill(skill.skillId);
        await _refreshSkills();
        if (mounted) {
          SnackBarUtils.showInfo(context, AppLocalizations.of(context)!.skillDeleted(skill.name));
        }
      } catch (e) {
        if (mounted) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.deleteSkillFailed(e.toString()));
        }
      }
    }
  }

  void _showSkillDetail(Skill skill) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.skillDetail,
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
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      skill.description.isNotEmpty
                                          ? skill.description
                                          : AppLocalizations.of(context)!.folderPath(skill.skillId),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
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
                              AppLocalizations.of(context)!.toolList(tools.length),
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
                                            ? AppLocalizations.of(context)!.toolNameDesc(t.name, t.description)
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
                                  AppLocalizations.of(context)!.moreXTools(tools.length - 50),
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

                          // 技能描述
                          if (skill.prompt.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.skillDescription,
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
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                skill.prompt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // 删除按钮
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDeleteSkill(skill);
                              },
                              icon: const Icon(CupertinoIcons.delete, size: 16),
                              label: Text(AppLocalizations.of(context)!.deleteSkillTitle),
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
        title: Text(
          AppLocalizations.of(context)!.skillManagementTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.addSkill,
            onPressed: () => _importSkillZip(),
            icon: Icon(
              CupertinoIcons.add,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          IconButton(
            key: _marketplaceButtonKey,
            tooltip: '应用市场',
            onPressed: () => _showSkillMarketplaceMenu(),
            icon: Icon(
              CupertinoIcons.shopping_cart,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
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
              AppLocalizations.of(context)!.noSkills,
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
              AppLocalizations.of(context)!.clickAddSkillHint,
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
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 3.0,
        ),
        itemCount: _skills.length,
        itemBuilder: (context, index) {
          final skill = _skills[index];
          return _buildSkillCard(skill);
        },
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    return _SkillCard(
      skill: skill,
      onTap: () => _showSkillDetail(skill),
      onEdit: () {
        final filePath = p.join(
          SkillStorageService.skillsRootDir,
          skill.skillId,
          'SKILL.md',
        );
        launchUrl(Uri.file(filePath));
      },
      onDelete: () => _confirmDeleteSkill(skill),
    );
  }
}

class _SkillCard extends StatefulWidget {
  final Skill skill;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SkillCard({
    required this.skill,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final description = skill.description.isNotEmpty ? skill.description : null;
    final subtitle = skill.skillId;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _isHovered
                ? Theme.of(context).colorScheme.primary.withOpacity(0.06)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.35)
                  : Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.65),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // 编辑 & 删除按钮（上下排列）
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.pencil,
                        size: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 10,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
