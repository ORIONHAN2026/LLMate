import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../data/file_storage.dart';
import '../data/storage_paths.dart';
import '../models/system_setting.dart';

// 供既有调用方沿用：直接 `import 'settings_controller.dart'` 即可访问
// [SystemSetting]，无需额外导入 models。
export '../models/system_setting.dart';

/// 统一设置控制器
///
/// 所有设置（服务设置 + 其他设置）统一存放在 [SystemSetting] 聚合对象中，
/// 本控制器只负责对该对象进行读写、应用运行时状态（主题/语言）与持久化。
///
/// 数据持久化于嵌入式 NoSQL 数据库 `~/.llmate/settings.db`（sembast，
/// `settings` store），整个 [SystemSetting] 序列化为**单条记录**（`systemSetting`），
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
  ];

  /// 设置数据库路径：~/.llmate/settings.db
  static String get _dbPath => p.join(StoragePaths.root, 'settings.db');

  /// sembast store 名称（每条记录 key 为设置名，value 为 {'value': ...}）
  static const String _storeName = 'settings';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;
  static bool _migrated = false;

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

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版设置（settings.json 或分散 key）迁移进单条 `systemSetting` 记录。
  ///
  /// 仅当数据库尚不存在 `systemSetting` 记录时执行；迁移成功后写入聚合记录，
  /// 并把值填充到当前 [systemSetting] 对象。仅执行一次。
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      if (await _store.record('systemSetting').get(db) != null) return;

      final Map<String, dynamic> legacyJson = {'appLanguage': 'zh'};
      // 1) 旧版 settings.json
      final data = await FileStorage.readJson(StoragePaths.settingsFile);
      if (data != null && data.isNotEmpty) {
        legacyJson['useSystemTheme'] = _b(data['useSystemTheme']) ?? false;
        legacyJson['isDarkMode'] = _b(data['isDarkMode']) ?? false;
        legacyJson['appLanguage'] = (data['appLanguage'] == 'en') ? 'en' : 'zh';
        if (data['domainConfig'] is Map<String, dynamic>) {
          final dc = data['domainConfig'] as Map<String, dynamic>;
          legacyJson['domain'] = _emptyToNull(dc['domain']) ?? '';
          legacyJson['certPath'] = _emptyToNull(dc['certPath']);
          legacyJson['keyPath'] = _emptyToNull(dc['keyPath']);
          legacyJson['httpsEnabled'] = _b(dc['httpsEnabled']) ?? false;
          legacyJson['httpPort'] =
              int.tryParse(dc['httpPort']?.toString() ?? '') ?? 80;
          legacyJson['httpsPort'] =
              int.tryParse(dc['httpsPort']?.toString() ?? '') ?? 443;
        } else {
          legacyJson['domain'] = _emptyToNull(data['domainConfig_domain']) ?? '';
          legacyJson['certPath'] = _emptyToNull(data['domainConfig_certPath']);
          legacyJson['keyPath'] = _emptyToNull(data['domainConfig_keyPath']);
          legacyJson['httpsEnabled'] =
              _b(data['domainConfig_httpsEnabled']) ?? false;
          legacyJson['httpPort'] =
              int.tryParse(data['domainConfig_httpPort']?.toString() ?? '') ?? 80;
          legacyJson['httpsPort'] =
              int.tryParse(data['domainConfig_httpsPort']?.toString() ?? '') ?? 443;
        }
      } else {
        // 2) 旧版 settings.db 中的分散 key
        legacyJson['domain'] =
            _emptyToNull(await _getSetting('domainConfig_domain')) ?? '';
        legacyJson['useSystemTheme'] =
            _b(await _getSetting('useSystemTheme')) ?? false;
        legacyJson['isDarkMode'] = _b(await _getSetting('isDarkMode')) ?? false;
        legacyJson['appLanguage'] =
            (await _getSetting('appLanguage') == 'en') ? 'en' : 'zh';
        legacyJson['certPath'] = _emptyToNull(await _getSetting('domainConfig_certPath'));
        legacyJson['keyPath'] = _emptyToNull(await _getSetting('domainConfig_keyPath'));
        legacyJson['httpsEnabled'] =
            _b(await _getSetting('domainConfig_httpsEnabled')) ?? false;
        legacyJson['httpPort'] =
            int.tryParse((await _getSetting('domainConfig_httpPort'))?.toString() ?? '') ??
                80;
        legacyJson['httpsPort'] =
            int.tryParse((await _getSetting('domainConfig_httpsPort'))?.toString() ?? '') ??
                443;
      }

      systemSetting.assign(SystemSetting.fromJson(legacyJson));
      await _putSetting('systemSetting', systemSetting.toJson());
      debugPrint('📦 [Settings] 已迁移旧设置为单条 systemSetting 记录');
    } catch (e) {
      debugPrint('⚠️ [Settings] 迁移旧设置失败: $e');
    }
  }

  /// 写入单条设置（值为任意可 JSON 序列化对象）
  Future<void> _putSetting(String key, Object value) async {
    final db = await _database;
    await _store.record(key).put(db, {'value': value});
  }

  /// 读取单条设置，不存在则返回 null
  Future<Object?> _getSetting(String key) async {
    final db = await _database;
    final rec = await _store.record(key).get(db);
    if (rec == null) return null;
    return (rec as Map<String, dynamic>)['value'];
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
    // 从单条记录加载（迁移逻辑已在 _database 中完成）
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
      debugPrint('🌱 [Settings] 已写入首次启动默认配置至 settings.db');
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

  /// 将空白字符串转为 null（迁移辅助）
  static String? _emptyToNull(Object? v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// 将可能为 bool / String 的值统一解析为 bool（迁移辅助）
  static bool? _b(Object? v) {
    if (v is bool) return v;
    if (v is String) return v == 'true';
    return null;
  }
}
