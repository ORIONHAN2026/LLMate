import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/isar_service.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  var useSystemTheme = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  /// 设置主题模式
  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        useSystemTheme.value = true;
        isDarkMode.value = false;
        break;
      case ThemeMode.dark:
        useSystemTheme.value = false;
        isDarkMode.value = true;
        break;
      case ThemeMode.light:
        useSystemTheme.value = false;
        isDarkMode.value = false;
        break;
    }
    _saveThemeMode();
    Get.changeThemeMode(mode);
  }

  /// 切换主题模式
  void toggleTheme() {
    if (useSystemTheme.value) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      setThemeMode(
          brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
      return;
    }
    setThemeMode(isDarkMode.value ? ThemeMode.light : ThemeMode.dark);
  }

  /// 获取当前主题模式
  ThemeMode get themeMode {
    if (useSystemTheme.value) return ThemeMode.system;
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  /// 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    try {
      final store = IsarService.instance.store;
      final useSysSetting =
          await store.isarSettings.getByKey('useSystemTheme');
      if (useSysSetting != null && useSysSetting['value'] == 'true') {
        useSystemTheme.value = true;
        isDarkMode.value = false;
        Get.changeThemeMode(ThemeMode.system);
        return;
      }

      final setting = await store.isarSettings.getByKey('isDarkMode');
      if (setting != null) {
        isDarkMode.value = setting['value'] == 'true';
        Get.changeThemeMode(
            isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      }
    } catch (e) {
      debugPrint('加载主题模式失败: $e');
    }
  }

  /// 保存主题模式
  Future<void> _saveThemeMode() async {
    try {
      final store = IsarService.instance.store;
      await store.isarSettings
          .put('useSystemTheme', useSystemTheme.value.toString());
      await store.isarSettings
          .put('isDarkMode', isDarkMode.value.toString());
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }
}
