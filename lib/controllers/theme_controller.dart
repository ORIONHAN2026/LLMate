import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  /// 切换主题模式
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _saveThemeMode();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// 获取当前主题模式
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  /// 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    try {
      final isar = IsarService.instance.isar;
      final setting = await isar.isarSettings
          .getByKey('isDarkMode');
      if (setting != null) {
        isDarkMode.value = setting.value == 'true';
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
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarSettings
            .getByKey('isDarkMode');
        if (existing != null) {
          existing.value = isDarkMode.value.toString();
          await isar.isarSettings.put(existing);
        } else {
          await isar.isarSettings.put(IsarSettings()
            ..key = 'isDarkMode'
            ..value = isDarkMode.value.toString());
        }
      });
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }
}
