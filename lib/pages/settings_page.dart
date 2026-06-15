import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../controllers/theme_controller.dart';
import '../controllers/locale_controller.dart';
import 'modelssetting.dart';
import 'mcp_management_page.dart';
import 'skill_management_page.dart';

/// 设置页面 - 左侧导航 + 右侧内容区
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  /// 当前选中页面的 actions（由子页面通过回调设置）
  List<Widget> _currentActions = [];

  /// 各页面的 actions 缓存（key = index）
  final Map<int, List<Widget>> _cachedActions = {};

  List<_SettingsNavItem> _buildNavItems() {
    final l10n = AppLocalizations.of(context)!;
    return [
      _SettingsNavItem(
        icon: CupertinoIcons.sparkles,
        label: l10n.modelManagement,
        builder: (_) => const ModelSettingPage(embedded: true),
      ),
      _SettingsNavItem(
        icon: CupertinoIcons.link,
        label: l10n.connectorManagement,
        builder: (actions) => McpManagementPage(
          embedded: true,
          onActionsChanged: actions,
        ),
      ),
      _SettingsNavItem(
        icon: CupertinoIcons.wand_stars,
        label: l10n.skillManagement,
        builder: (actions) => SkillManagementPage(
          embedded: true,
          onActionsChanged: actions,
        ),
      ),
      _SettingsNavItem(
        icon: CupertinoIcons.slider_horizontal_3,
        label: l10n.otherSettings,
        builder: (_) => const _GeneralSettingsTab(),
      ),
      _SettingsNavItem(
        icon: CupertinoIcons.mail,
        label: l10n.feedback,
        builder: (_) => const _FeedbackTab(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final navItems = _buildNavItems();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 44,
        leadingWidth: Platform.isMacOS ? 70 + 20 + 15 : 44,
        leading: Padding(
          padding: EdgeInsets.only(left: Platform.isMacOS ? 70 : 0),
          child: Transform.translate(
            offset: const Offset(0, -5),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              icon: const Icon(CupertinoIcons.back, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Transform.translate(
          offset: const Offset(0, -5),
          child: Text(
            l10n.settings,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          ..._currentActions,
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // 左侧导航栏
          Container(
            width: 200,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                ...List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = _selectedIndex == index;
                  return _buildNavItem(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    colorScheme: colorScheme,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        // 切换时从缓存恢复该页面的 actions
                        _currentActions = _cachedActions[index] ?? [];
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          // 右侧内容区
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(navItems.length, (i) {
                return navItems[i].builder(
                  (actions) {
                    // 缓存每个页面的 actions
                    _cachedActions[i] = actions;
                    // 只有当前选中页面的 actions 才立即生效
                    if (_selectedIndex == i && mounted) {
                      setState(() => _currentActions = actions);
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置导航项
class _SettingsNavItem {
  final IconData icon;
  final String label;
  final Widget Function(void Function(List<Widget>)) builder;

  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.builder,
  });
}

/// 通用设置 Tab（原 OtherSettingsPage 的内容，去掉 AppBar）
class _GeneralSettingsTab extends StatelessWidget {
  const _GeneralSettingsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
        ],
      ),
    );
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
    LocaleController localeController,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
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
        return Column(
          children: [
            _buildLangTile(
              colorScheme,
              title: l10n.chinese,
              subtitle: l10n.chineseDesc,
              selected: currentLang == 'zh',
              isFirst: true,
              isLast: false,
              onTap: () => localeController.setLocale(const Locale('zh')),
            ),
            _buildDivider(colorScheme),
            _buildLangTile(
              colorScheme,
              title: l10n.english,
              subtitle: l10n.englishDesc,
              selected: currentLang == 'en',
              isFirst: false,
              isLast: true,
              onTap: () => localeController.setLocale(const Locale('en')),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLangTile(
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required bool selected,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 22,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinOptions(
    ThemeController themeController,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
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

        return Column(
          children: [
            _buildSkinTile(
              colorScheme,
              icon: CupertinoIcons.arrow_2_circlepath,
              title: l10n.followSystem,
              subtitle: l10n.followSystemDesc,
              selected: isSys,
              isFirst: true,
              isLast: false,
              onTap: () => themeController.setThemeMode(ThemeMode.system),
            ),
            _buildDivider(colorScheme),
            _buildSkinTile(
              colorScheme,
              icon: CupertinoIcons.sun_max,
              title: l10n.lightMode,
              subtitle: l10n.lightModeDesc,
              selected: !isSys && !isDark,
              isFirst: false,
              isLast: false,
              onTap: () => themeController.setThemeMode(ThemeMode.light),
            ),
            _buildDivider(colorScheme),
            _buildSkinTile(
              colorScheme,
              icon: CupertinoIcons.moon,
              title: l10n.darkMode,
              subtitle: l10n.darkModeDesc,
              selected: !isSys && isDark,
              isFirst: false,
              isLast: true,
              onTap: () => themeController.setThemeMode(ThemeMode.dark),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSkinTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
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
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                size: 22,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 1,
      indent: 50,
      endIndent: 16,
      color: colorScheme.outlineVariant.withValues(alpha: 0.15),
    );
  }
}

/// 反馈 Tab
class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab();

  Future<void> _sendFeedbackEmail(BuildContext context) async {
    const String feedbackEmail = 'hanxinyc@gmail.com';
    const String subject = 'ChatHub App Feedback';
    const String body = '''

-----------------------------
Thank you for your feedback on ChatHub. We take every feedback seriously.

Thanks!
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.mail,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.feedback,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'hanxinyc@gmail.com',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _sendFeedbackEmail(context),
              icon: const Icon(CupertinoIcons.mail, size: 16),
              label: Text(l10n.feedback),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
