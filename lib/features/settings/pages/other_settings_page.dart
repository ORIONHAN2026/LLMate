import 'package:llmate/features/widgets/standard_app_bar.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:get/get.dart';

import '../../../controllers/settings_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/model_controller.dart';
import '../../../controllers/mcp_controller.dart';
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
            _buildSectionTitle(l10n.resetSystem, colorScheme),
            const SizedBox(height: 8),
            _buildResetSection(context, colorScheme, l10n),
          ],
        ),
      ),
    );
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
          builder: (itemContext) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showLanguagePicker(
              itemContext,
              localeController,
              colorScheme,
              l10n,
              options,
              currentLang,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
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
        final currentMode = isSys
            ? ThemeMode.system
            : (isDark ? ThemeMode.dark : ThemeMode.light);
        final current = options.firstWhere(
          (o) => o.mode == currentMode,
          orElse: () => options.first,
        );

        return Builder(
          builder: (itemContext) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showThemePicker(
              itemContext,
              themeController,
              colorScheme,
              options,
              currentMode,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
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
