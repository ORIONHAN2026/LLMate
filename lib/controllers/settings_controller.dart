import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../data/file_storage.dart';
import '../data/storage_paths.dart';

/// 域名配置数据模型
class DomainConfig {
  String domain; // 域名（不带协议）
  String? certPath; // 证书文件路径
  String? keyPath; // 私钥文件路径
  bool httpsEnabled; // 是否开启 HTTPS（上传证书后自动开启）
  int httpPort; // HTTP 端口（默认 80）
  int httpsPort; // HTTPS 端口（默认 443）

  DomainConfig({
    this.domain = '',
    this.certPath,
    this.keyPath,
    this.httpsEnabled = false,
    this.httpPort = 80,
    this.httpsPort = 443,
  });

  /// 获取完整的 base URL（含协议和端口）
  String get baseUrl {
    if (domain.isEmpty) return '';
    final scheme = httpsEnabled ? 'https' : 'http';
    final port = httpsEnabled ? httpsPort : httpPort;
    return '$scheme://$domain:$port';
  }

  bool get isEmpty => domain.isEmpty;
}

/// 统一设置控制器
///
/// 合并原 [ThemeController]（主题）、[DomainController]（域名/服务管理）、
/// [LocaleController]（语言切换）三类设置，所有内容统一持久化到嵌入式
/// NoSQL 数据库 `~/.llmate/settings.db`（sembast，`settings` store，
/// 每条记录以设置名为 key，值为 `{'value': ...}`）。
///
/// 公开字段与方法与原三个控制器保持一致，便于调用方平滑迁移：
///   - 主题： [isDarkMode] [useSystemTheme] [themeMode] [setThemeMode] [toggleTheme]
///   - 域名： [domainConfig] [effectiveBaseUrl] [isConfigured] [saveConfig] [clearConfig]
///   - 语言： [locale] [supportedLocales] [setLocale]
class SettingsController extends GetxController {
  // ── 主题 ──
  final isDarkMode = false.obs;
  final useSystemTheme = false.obs;

  // ── 域名/服务 ──
  final domainConfig = DomainConfig().obs;

  // ── 语言 ──
  final locale = const Locale('zh').obs;
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

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版 settings.json 中的设置迁移进 settings.db
  ///
  /// 仅当数据库中尚不存在同名记录时写入，避免覆盖；旧文件保留作备份。
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final data = await FileStorage.readJson(StoragePaths.settingsFile);
      if (data == null || data.isEmpty) return;
      int migrated = 0;
      for (final entry in data.entries) {
        final key = entry.key;
        final existing = await _store.record(key).get(db);
        if (existing == null) {
          await _store.record(key).put(db, {'value': entry.value.toString()});
          migrated++;
        }
      }
      if (migrated > 0) {
        debugPrint('📦 [Settings] 已迁移 $migrated 条旧设置至 settings.db');
      }
    } catch (e) {
      debugPrint('⚠️ [Settings] 迁移旧 settings.json 失败: $e');
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

  /// 删除单条设置
  Future<void> _deleteSetting(String key) async {
    final db = await _database;
    await _store.record(key).delete(db);
  }

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadThemeMode();
    await _loadConfig();
    await _loadLocale();
    // 首次启动（db 中无任何设置记录）时写入默认配置，确保 settings.db 有初始数据
    await _ensureDefaultSettings();
  }

  /// 首次启动落地默认设置。
  ///
  /// 仅当 settings.db 中不存在任何记录时写入默认值（主题/语言/域名），
  /// 之后用户修改会覆盖；已存在记录则不写入，避免覆盖用户配置。
  Future<void> _ensureDefaultSettings() async {
    try {
      final db = await _database;
      final count = await _store.count(db);
      if (count > 0) return; // 已有设置（迁移或旧用户），不覆盖

      await _putSetting('useSystemTheme', useSystemTheme.value.toString());
      await _putSetting('isDarkMode', isDarkMode.value.toString());
      await _putSetting('appLanguage', locale.value.languageCode);
      // 域名配置默认空（DomainConfig 默认值），保留占位以便 UI 识别已初始化
      await _putSetting('domainConfig_domain', '');
      await _putSetting('domainConfig_httpPort', '80');
      await _putSetting('domainConfig_httpsPort', '443');
      await _putSetting('domainConfig_certPath', '');
      await _putSetting('domainConfig_keyPath', '');
      await _putSetting('domainConfig_httpsEnabled', 'false');
      debugPrint('🌱 [Settings] 已写入首次启动默认配置至 settings.db');
    } catch (e) {
      debugPrint('⚠️ [Settings] 写入默认设置失败: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 主题
  // ════════════════════════════════════════════════════════

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
      final useSysSetting = await _getSetting('useSystemTheme');
      if (useSysSetting != null && useSysSetting == 'true') {
        useSystemTheme.value = true;
        isDarkMode.value = false;
        Get.changeThemeMode(ThemeMode.system);
        return;
      }

      final setting = await _getSetting('isDarkMode');
      if (setting != null) {
        isDarkMode.value = setting == 'true';
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
      await _putSetting('useSystemTheme', useSystemTheme.value.toString());
      await _putSetting('isDarkMode', isDarkMode.value.toString());
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 域名 / 服务
  // ════════════════════════════════════════════════════════

  /// 获取当前有效的 base URL
  String get effectiveBaseUrl => domainConfig.value.baseUrl;

  /// 是否配置了域名
  bool get isConfigured => !domainConfig.value.isEmpty;

  /// 保存域名配置
  Future<void> saveConfig(DomainConfig config) async {
    domainConfig.value = config;
    try {
      await _putSetting('domainConfig_domain', config.domain);
      await _putSetting('domainConfig_httpPort', config.httpPort.toString());
      await _putSetting('domainConfig_httpsPort', config.httpsPort.toString());
      await _putSetting('domainConfig_certPath', config.certPath ?? '');
      await _putSetting('domainConfig_keyPath', config.keyPath ?? '');
      await _putSetting(
          'domainConfig_httpsEnabled', config.httpsEnabled.toString());
      debugPrint('✅ 域名配置已保存: ${config.baseUrl}');
    } catch (e) {
      debugPrint('❌ 保存域名配置失败: $e');
    }
  }

  /// 清除域名配置
  Future<void> clearConfig() async {
    domainConfig.value = DomainConfig();
    try {
      await _deleteSetting('domainConfig_domain');
      await _deleteSetting('domainConfig_httpPort');
      await _deleteSetting('domainConfig_httpsPort');
      await _deleteSetting('domainConfig_certPath');
      await _deleteSetting('domainConfig_keyPath');
      await _deleteSetting('domainConfig_httpsEnabled');
      debugPrint('✅ 域名配置已清除');
    } catch (e) {
      debugPrint('❌ 清除域名配置失败: $e');
    }
  }

  /// 从持久化存储加载配置
  Future<void> _loadConfig() async {
    try {
      final domain = (await _getSetting('domainConfig_domain')) as String? ?? '';
      final httpPort =
          int.tryParse((await _getSetting('domainConfig_httpPort')) as String? ?? '') ?? 80;
      final httpsPort =
          int.tryParse((await _getSetting('domainConfig_httpsPort')) as String? ?? '') ?? 443;
      final certEntry = await _getSetting('domainConfig_certPath');
      final keyEntry = await _getSetting('domainConfig_keyPath');
      final httpsEnabled = (await _getSetting('domainConfig_httpsEnabled')) == 'true';

      final certPath = certEntry as String?;
      final keyPath = keyEntry as String?;

      if (domain.isNotEmpty || certPath != null || keyPath != null) {
        domainConfig.value = DomainConfig(
          domain: domain,
          httpPort: httpPort,
          httpsPort: httpsPort,
          certPath: certPath?.isNotEmpty == true ? certPath : null,
          keyPath: keyPath?.isNotEmpty == true ? keyPath : null,
          httpsEnabled: httpsEnabled,
        );
        debugPrint('✅ 域名配置已加载: ${domainConfig.value.baseUrl}');
      }
    } catch (e) {
      debugPrint('❌ 加载域名配置失败: $e');
    }
  }

  // ════════════════════════════════════════════════════════
  // 语言
  // ════════════════════════════════════════════════════════

  /// 切换语言
  void setLocale(Locale newLocale) {
    locale.value = newLocale;
    _saveLocale();
    Get.updateLocale(newLocale);
  }

  /// 从持久化存储加载语言设置
  Future<void> _loadLocale() async {
    try {
      final lang = await _getSetting('appLanguage');
      if (lang != null) {
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
      await _putSetting('appLanguage', locale.value.languageCode);
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }
  }
}
