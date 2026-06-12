import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:get/get.dart';

import '../controllers/theme_controller.dart';
import '../controllers/locale_controller.dart';

/// 其他设置页面，包含语言设置和皮肤设置
class OtherSettingsPage extends StatelessWidget {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return Scaffold(
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
            l10n.otherSettings,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        centerTitle: false,
      ),
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
          ],
        ),
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
              Icon(CupertinoIcons.checkmark_alt_circle_fill,
                  size: 22, color: colorScheme.primary),
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
              onTap: () =>
                  themeController.setThemeMode(ThemeMode.system),
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
              onTap: () =>
                  themeController.setThemeMode(ThemeMode.light),
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
              onTap: () =>
                  themeController.setThemeMode(ThemeMode.dark),
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
            Icon(icon, size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.6)),
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
              Icon(CupertinoIcons.checkmark_alt_circle_fill,
                  size: 22, color: colorScheme.primary),
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
