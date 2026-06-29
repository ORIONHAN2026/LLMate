import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/storage_service.dart';

/// 管理应用语言切换
class LocaleController extends GetxController {
  var locale = const Locale('zh').obs;

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  /// 切换语言
  void setLocale(Locale newLocale) {
    locale.value = newLocale;
    _saveLocale();
    Get.updateLocale(newLocale);
  }

  /// 从持久化存储加载语言设置
  Future<void> _loadLocale() async {
    try {
      final store = StorageService.instance.store;
      final setting = await store.isarSettings.getByKey('appLanguage');
      if (setting != null) {
        final lang = setting['value'];
        if (lang == 'en') {
          locale.value = const Locale('en');
          Get.updateLocale(const Locale('en'));
        }
      }
    } catch (e) {
      debugPrint('加载语言设置失败: $e');
    }
  }

  /// 保存语言设置到持久化存储
  Future<void> _saveLocale() async {
    try {
      final store = StorageService.instance.store;
      await store.isarSettings.put('appLanguage', locale.value.languageCode);
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }
  }
}
