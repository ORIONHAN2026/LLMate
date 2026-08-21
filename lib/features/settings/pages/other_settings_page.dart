import 'package:llmate/features/widgets/standard_app_bar.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import 'package:get/get.dart';

import '../../../controllers/settings_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/model_controller.dart';
import '../../../controllers/mcp_controller.dart';
import '../../../core/services/backup_service.dart';
import '../../utils/snackbar_utils.dart';

/// 其他设置页面，包含语言设置和皮肤设置
class OtherSettingsPage extends StatelessWidget {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeController = Get.find<SettingsController>();
    final localeController = Get.find<SettingsController>();

    return Scaffold(
      appBar: StandardAppBar(title: l10n.otherSettings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.languageSettings, colorScheme),
            const SizedBox(height: 8),
            _buildLanguageOption(context, localeController, colorScheme, l10n),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.skinSettings, colorScheme),
            const SizedBox(height: 8),
            _buildSkinOptions(themeController, colorScheme, l10n),
            const SizedBox(height: 32),
            _buildSectionTitle('备份管理', colorScheme),
            const SizedBox(height: 8),
            _buildBackupSection(context, colorScheme),
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.resetSystem, colorScheme),
            const SizedBox(height: 8),
            _buildResetSection(context, colorScheme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context, ColorScheme colorScheme) {
    final settings = Get.find<SettingsController>();
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Obx(
            () => _buildActionTile(
              colorScheme,
              icon: Icons.folder_outlined,
              title: '备份目录',
              subtitle: settings.effectiveBackupDirectory,
              isFirst: true,
              isLast: false,
              trailing: Tooltip(
                message: '打开备份目录',
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: () => _openBackupDirectory(context),
                  icon: Icon(
                    Icons.open_in_new_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ),
              onTap: () => _chooseBackupDirectory(context),
            ),
          ),
          _buildDivider(colorScheme),
          Obx(
            () => _buildSwitchTile(
              colorScheme,
              icon: Icons.schedule_outlined,
              title: '自动备份',
              subtitle: _autoBackupSubtitle(settings),
              value: settings.autoBackupEnabled.value,
              isFirst: false,
              isLast: false,
              onChanged: (enabled) => _setAutoBackup(context, enabled),
            ),
          ),
          _buildDivider(colorScheme),
          _buildActionTile(
            colorScheme,
            icon: Icons.archive_outlined,
            title: '创建全量备份',
            subtitle: '备份模型、会话、MCP、设置、用量和审计数据',
            isFirst: false,
            isLast: false,
            onTap: () => _createBackup(context),
          ),
          _buildDivider(colorScheme),
          _buildActionTile(
            colorScheme,
            icon: Icons.restore_outlined,
            title: '从备份恢复',
            subtitle: '选择 .llmate-backup 文件，恢复后需要重启应用',
            isFirst: false,
            isLast: true,
            onTap: () => _restoreBackup(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isFirst,
    required bool isLast,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
          ],
        ),
      ),
    );
  }

  String _autoBackupSubtitle(SettingsController settings) {
    if (!settings.autoBackupEnabled.value) {
      return '关闭后只会手动创建备份';
    }

    final keepCount = settings.autoBackupKeepCount.value;
    final lastAt = DateTime.tryParse(settings.autoBackupLastAt.value ?? '');
    if (lastAt == null) {
      return '每日 0 点自动备份，保留最近 $keepCount 份';
    }
    return '每日 0 点自动备份，保留最近 $keepCount 份；上次 ${_formatDateTime(lastAt)}';
  }

  Future<void> _setAutoBackup(BuildContext context, bool enabled) async {
    final settings = Get.find<SettingsController>();
    try {
      await settings.setAutoBackupEnabled(enabled);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, enabled ? '自动备份已开启' : '自动备份已关闭');
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '设置自动备份失败: $e');
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    final settings = Get.find<SettingsController>();
    final dir = Directory(settings.effectiveBackupDirectory);
    final path = p.join(dir.path, BackupService.defaultFileName());

    try {
      await dir.create(recursive: true);
      final file = await BackupService.createFullBackup(outputPath: path);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, '备份已创建: ${file.path}');
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '备份失败: $e');
    }
  }

  Future<void> _chooseBackupDirectory(BuildContext context) async {
    final settings = Get.find<SettingsController>();
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择备份目录',
      initialDirectory: settings.effectiveBackupDirectory,
    );
    if (selected == null) return;
    try {
      await Directory(selected).create(recursive: true);
      await settings.setBackupDirectory(selected);
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, '备份目录已更新');
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '设置备份目录失败: $e');
    }
  }

  Future<void> _openBackupDirectory(BuildContext context) async {
    final settings = Get.find<SettingsController>();
    final dir = Directory(settings.effectiveBackupDirectory);

    try {
      await dir.create(recursive: true);
      final uri = Uri.directory(dir.absolute.path);
      final opened = await launchUrl(uri);
      if (!context.mounted) return;
      if (!opened) {
        SnackBarUtils.showError(context, '无法打开备份目录');
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '打开备份目录失败: $e');
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择 LLMate 备份文件',
      type: FileType.custom,
      allowedExtensions: [BackupService.extension],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    if (!context.mounted) return;

    BackupManifest manifest;
    try {
      manifest = await BackupService.readManifest(path);
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '备份文件无效: $e');
      return;
    }

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('确认恢复备份'),
            content: Text(
              '备份时间: ${_formatDateTime(manifest.createdAt)}\n'
              '平台: ${manifest.platform}\n\n'
              '恢复会覆盖当前 LLMate 数据。系统会先自动创建一份当前数据的安全备份。\n'
              '恢复完成后请重启应用生效。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('确认恢复'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      final restore = await BackupService.restoreFullBackup(
        path,
        safetyBackupDirectory:
            Get.find<SettingsController>().effectiveBackupDirectory,
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('恢复完成'),
              content: Text(
                '备份已恢复，请重启应用后继续使用。\n\n'
                '当前数据的安全备份已保存到:\n${restore.safetyBackupPath}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('知道了'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, '恢复失败: $e');
    }
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  Widget _buildResetSection(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final danger = const Color(0xFFEF4444);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildResetTile(
            colorScheme,
            danger: danger,
            icon: Icons.chat_bubble_outline,
            title: l10n.resetAllSessions,
            isFirst: true,
            isLast: false,
            onTap:
                () => _confirmReset(
                  context,
                  colorScheme,
                  l10n,
                  action: l10n.resetAllSessions,
                  onConfirm: () async {
                    await Get.find<SessionController>().resetAllSessions();
                  },
                ),
          ),
          _buildDivider(colorScheme),
          _buildResetTile(
            colorScheme,
            danger: danger,
            icon: Icons.smart_toy_outlined,
            title: l10n.resetAllModels,
            isFirst: false,
            isLast: false,
            onTap:
                () => _confirmReset(
                  context,
                  colorScheme,
                  l10n,
                  action: l10n.resetAllModels,
                  onConfirm: () async {
                    await Get.find<ModelController>().resetAllModels();
                  },
                ),
          ),
          _buildDivider(colorScheme),
          _buildResetTile(
            colorScheme,
            danger: danger,
            icon: Icons.hub_outlined,
            title: l10n.resetAllMcp,
            isFirst: false,
            isLast: false,
            onTap:
                () => _confirmReset(
                  context,
                  colorScheme,
                  l10n,
                  action: l10n.resetAllMcp,
                  onConfirm: () async {
                    await Get.find<McpController>().resetAllMcps();
                  },
                ),
          ),
          _buildDivider(colorScheme),
          _buildResetTile(
            colorScheme,
            danger: danger,
            icon: Icons.restart_alt,
            title: l10n.resetAll,
            isFirst: false,
            isLast: true,
            onTap:
                () => _confirmReset(
                  context,
                  colorScheme,
                  l10n,
                  action: l10n.resetAll,
                  onConfirm: () async {
                    await Get.find<SessionController>().resetAllSessions();
                    await Get.find<ModelController>().resetAllModels();
                    await Get.find<McpController>().resetAllMcps();
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetTile(
    ColorScheme colorScheme, {
    required Color danger,
    required IconData icon,
    required String title,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: danger,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n, {
    required String action,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.confirmReset),
            content: Text(l10n.resetConfirmMsg(action)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: Text(l10n.confirm),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await onConfirm();
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.xDone(action));
    } catch (e) {
      if (!context.mounted) return;
      SnackBarUtils.showError(context, l10n.xFailed(action, e.toString()));
    }
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsController localeController,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final options = _languageOptions(l10n);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Obx(() {
        final currentLang = localeController.locale.value.languageCode;
        final current = options.firstWhere(
          (o) => o.code == currentLang,
          orElse: () => options.first,
        );
        return Builder(
          builder:
              (itemContext) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap:
                    () => _showLanguagePicker(
                      itemContext,
                      localeController,
                      colorScheme,
                      l10n,
                      options,
                      currentLang,
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
        );
      }),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    SettingsController localeController,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    List<_LanguageOption> options,
    String currentLang,
  ) async {
    // 以触发条目为锚点，菜单宽度与条目一致
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final itemBox = context.findRenderObject() as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

    final selectedCode = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(itemRect, Offset.zero & overlayBox.size),
      constraints: BoxConstraints(
        minWidth: itemRect.width,
        maxWidth: itemRect.width,
      ),
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.code,
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (option.code == currentLang)
                  Icon(Icons.check, size: 20, color: colorScheme.primary),
              ],
            ),
          ),
      ],
    );
    if (selectedCode == null || selectedCode == currentLang) return;
    localeController.setLocale(Locale(selectedCode));
  }

  List<_LanguageOption> _languageOptions(AppLocalizations l10n) => [
    _LanguageOption('zh', l10n.chinese, l10n.chineseDesc),
    _LanguageOption('en', l10n.english, l10n.englishDesc),
    _LanguageOption('ja', l10n.japanese, l10n.japaneseDesc),
    _LanguageOption('th', l10n.thai, l10n.thaiDesc),
    _LanguageOption('vi', l10n.vietnamese, l10n.vietnameseDesc),
    _LanguageOption('ko', l10n.korean, l10n.koreanDesc),
    _LanguageOption('fr', l10n.french, l10n.frenchDesc),
    _LanguageOption('de', l10n.german, l10n.germanDesc),
  ];

  Widget _buildSkinOptions(
    SettingsController themeController,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final options = _themeOptions(l10n);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Obx(() {
        final isSys = themeController.useSystemTheme.value;
        final isDark = themeController.isDarkMode.value;
        final currentMode =
            isSys
                ? ThemeMode.system
                : (isDark ? ThemeMode.dark : ThemeMode.light);
        final current = options.firstWhere(
          (o) => o.mode == currentMode,
          orElse: () => options.first,
        );

        return Builder(
          builder:
              (itemContext) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap:
                    () => _showThemePicker(
                      itemContext,
                      themeController,
                      colorScheme,
                      options,
                      currentMode,
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        current.icon,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
        );
      }),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    SettingsController themeController,
    ColorScheme colorScheme,
    List<_ThemeOption> options,
    ThemeMode currentMode,
  ) async {
    // 以触发条目为锚点，菜单宽度与条目一致
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final itemBox = context.findRenderObject() as RenderBox;
    final itemRect = itemBox.localToGlobal(Offset.zero) & itemBox.size;

    final selectedMode = await showMenu<ThemeMode>(
      context: context,
      position: RelativeRect.fromRect(itemRect, Offset.zero & overlayBox.size),
      constraints: BoxConstraints(
        minWidth: itemRect.width,
        maxWidth: itemRect.width,
      ),
      items: [
        for (final option in options)
          PopupMenuItem<ThemeMode>(
            value: option.mode,
            height: 56,
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (option.mode == currentMode)
                  Icon(Icons.check, size: 20, color: colorScheme.primary),
              ],
            ),
          ),
      ],
    );
    if (selectedMode == null || selectedMode == currentMode) return;
    themeController.setThemeMode(selectedMode);
  }

  List<_ThemeOption> _themeOptions(AppLocalizations l10n) => [
    _ThemeOption(
      ThemeMode.system,
      Icons.sync,
      l10n.followSystem,
      l10n.followSystemDesc,
    ),
    _ThemeOption(
      ThemeMode.light,
      Icons.light_mode_outlined,
      l10n.lightMode,
      l10n.lightModeDesc,
    ),
    _ThemeOption(
      ThemeMode.dark,
      Icons.dark_mode_outlined,
      l10n.darkMode,
      l10n.darkModeDesc,
    ),
  ];

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
    );
  }
}

/// 语言选项数据
class _LanguageOption {
  final String code;
  final String title;
  final String subtitle;

  const _LanguageOption(this.code, this.title, this.subtitle);
}

/// 外观选项数据
class _ThemeOption {
  final ThemeMode mode;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ThemeOption(this.mode, this.icon, this.title, this.subtitle);
}
