import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/database.dart';
import '../models/system_setting.dart';

// 供既有调用方沿用：直接 `import 'settings_controller.dart'` 即可访问
// [SystemSetting]，无需额外导入 models。
export '../models/system_setting.dart';

/// 统一设置控制器
///
/// 所有设置（服务设置 + 其他设置）统一存放在 [SystemSetting] 聚合对象中，
/// 本控制器只负责对该对象进行读写、应用运行时状态（主题/语言）与持久化。
///
/// 数据持久化于 Drift / SQLite 数据库 `~/.llmate/llmate.sqlite` 的
/// `setting_rows` 表（聚合对象序列化为单条记录，`key = 'systemSetting'`），
/// 不再使用原先分散的多个 key。
///
/// 为兼容既有调用方，本控制器保留了与旧字段同名的 getter：[isDarkMode]
/// [useSystemTheme] [domain] [locale] 等，均直接返回 [SystemSetting]
/// 内部对应的响应式字段（[Rx]），因此 UI 层无需改动即可继续观察设置变化。
class SettingsController extends GetxController {
  /// 设置聚合对象（服务设置 + 其他设置），所有读写都作用于它
  final systemSetting = SystemSetting();

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
    Locale('th'),
    Locale('vi'),
    Locale('ko'),
    Locale('fr'),
    Locale('de'),
  ];

  // ── 兼容旧调用方的 getter（直接返回聚合对象内部字段/值）──
  RxBool get isDarkMode => systemSetting.isDarkMode;
  RxBool get useSystemTheme => systemSetting.useSystemTheme;
  Rx<Locale> get locale => systemSetting.locale;
  bool get isConfigured => systemSetting.isConfigured;
  String get effectiveBaseUrl => systemSetting.effectiveBaseUrl;
  ThemeMode get themeMode => systemSetting.themeMode;

  // ── 服务设置（域名 / 端口 / 证书）扁平字段 ──
  RxString get domain => systemSetting.domain;
  RxnString get certPath => systemSetting.certPath;
  RxnString get keyPath => systemSetting.keyPath;
  RxBool get httpsEnabled => systemSetting.httpsEnabled;
  RxInt get httpPort => systemSetting.httpPort;
  RxInt get httpsPort => systemSetting.httpsPort;

  /// 写入单条设置（值为任意可 JSON 序列化对象）
  Future<void> _putSetting(String key, Object value) async {
    await appDatabase.putSettingRaw(key, value);
  }

  /// 读取单条设置，不存在则返回 null
  Future<Object?> _getSetting(String key) async {
    return await appDatabase.getSettingRaw(key);
  }

  /// 将整个 [SystemSetting] 持久化为单条记录
  Future<void> _saveSystemSetting() async {
    try {
      await _putSetting('systemSetting', systemSetting.toJson());
    } catch (e) {
      debugPrint('❌ 保存系统设置失败: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final json = await _getSetting('systemSetting');
    if (json is Map<String, dynamic>) {
      systemSetting.assign(SystemSetting.fromJson(json));
    }
    // 应用运行时状态
    Get.changeThemeMode(systemSetting.themeMode);
    Get.updateLocale(systemSetting.locale.value);
    await _ensureDefaultSettings();
  }

  /// 首次启动（db 中尚无 `systemSetting` 记录）时落地默认配置
  Future<void> _ensureDefaultSettings() async {
    try {
      final existing = await _getSetting('systemSetting');
      if (existing != null) return; // 已有配置或已迁移，不覆盖
      await _saveSystemSetting();
      debugPrint('🌱 [Settings] 已写入首次启动默认配置至 SQLite');
    } catch (e) {
      debugPrint('⚠️ [Settings] 写入默认设置失败: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 主题（操作 systemSetting）
  // ════════════════════════════════════════════════════════

  /// 设置主题模式
  void setThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        systemSetting.useSystemTheme.value = true;
        systemSetting.isDarkMode.value = false;
        break;
      case ThemeMode.dark:
        systemSetting.useSystemTheme.value = false;
        systemSetting.isDarkMode.value = true;
        break;
      case ThemeMode.light:
        systemSetting.useSystemTheme.value = false;
        systemSetting.isDarkMode.value = false;
        break;
    }
    _saveSystemSetting();
    Get.changeThemeMode(mode);
  }

  /// 切换主题模式
  void toggleTheme() {
    if (systemSetting.useSystemTheme.value) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      setThemeMode(
          brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
      return;
    }
    setThemeMode(systemSetting.isDarkMode.value ? ThemeMode.light : ThemeMode.dark);
  }

  // ════════════════════════════════════════════════════════
  // 域名 / 服务（操作 systemSetting 扁平字段）
  // ════════════════════════════════════════════════════════

  /// 保存域名配置
  Future<void> saveConfig({
    required String domain,
    String? certPath,
    String? keyPath,
    required bool httpsEnabled,
    required int httpPort,
    required int httpsPort,
  }) async {
    systemSetting.domain.value = domain;
    systemSetting.certPath.value = certPath;
    systemSetting.keyPath.value = keyPath;
    systemSetting.httpsEnabled.value = httpsEnabled;
    systemSetting.httpPort.value = httpPort;
    systemSetting.httpsPort.value = httpsPort;
    await _saveSystemSetting();
    debugPrint('✅ 域名配置已保存: ${systemSetting.baseUrl}');
  }

  /// 清除域名配置（重置为默认值，仍保留单条记录）
  Future<void> clearConfig() async {
    systemSetting.domain.value = '';
    systemSetting.certPath.value = null;
    systemSetting.keyPath.value = null;
    systemSetting.httpsEnabled.value = false;
    systemSetting.httpPort.value = 80;
    systemSetting.httpsPort.value = 443;
    await _saveSystemSetting();
    debugPrint('✅ 域名配置已清除');
  }

  // ════════════════════════════════════════════════════════
  // 语言（操作 systemSetting.locale）
  // ════════════════════════════════════════════════════════

  /// 切换语言
  void setLocale(Locale newLocale) {
    systemSetting.locale.value = newLocale;
    _saveSystemSetting();
    Get.updateLocale(newLocale);
  }
}
