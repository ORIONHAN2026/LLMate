import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/services/backup_service.dart';
import '../core/services/storage_paths.dart';
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
  bool get isMailConfigured =>
      systemSetting.smtpHost.value.trim().isNotEmpty &&
      systemSetting.smtpPort.value > 0 &&
      systemSetting.smtpSenderEmail.value.trim().isNotEmpty;
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
  RxnString get backupDirectory => systemSetting.backupDirectory;
  RxBool get autoBackupEnabled => systemSetting.autoBackupEnabled;
  RxInt get autoBackupKeepCount => systemSetting.autoBackupKeepCount;
  RxnString get autoBackupLastAt => systemSetting.autoBackupLastAt;
  String get effectiveBackupDirectory =>
      systemSetting.backupDirectory.value ??
      '${StoragePaths.home}/.llmate_backups';

  Timer? _autoBackupTimer;
  bool _autoBackupRunning = false;

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
    _restartAutoBackupTimer();
    Future.microtask(_runAutoBackupIfNeeded);
  }

  @override
  void onClose() {
    _autoBackupTimer?.cancel();
    super.onClose();
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
        brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );
      return;
    }
    setThemeMode(
      systemSetting.isDarkMode.value ? ThemeMode.light : ThemeMode.dark,
    );
  }

  // ════════════════════════════════════════════════════════
  // 域名 / 服务（操作 systemSetting 扁平字段）
  // ════════════════════════════════════════════════════════

  /// 保存域名配置
  Future<void> saveConfig({
    required String domain,
    String? certPath,
    String? keyPath,
    bool? httpsEnabled,
    required int httpPort,
    int? httpsPort,
  }) async {
    systemSetting.domain.value = domain;
    systemSetting.certPath.value = certPath;
    systemSetting.keyPath.value = keyPath;
    systemSetting.httpsEnabled.value =
        httpsEnabled ?? systemSetting.httpsEnabled.value;
    systemSetting.httpPort.value = httpPort;
    systemSetting.httpsPort.value = httpsPort ?? systemSetting.httpsPort.value;
    await _saveSystemSetting();
    debugPrint('✅ 域名配置已保存: ${systemSetting.baseUrl}');
  }

  /// 保存检测到的本机内网 / 外网 IP 到系统配置（持久化）
  Future<void> saveAddresses({String? lanIp, String? publicIp}) async {
    systemSetting.lanIp.value = lanIp;
    systemSetting.publicIp.value = publicIp;
    await _saveSystemSetting();
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

  Future<void> saveMailConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String senderEmail,
    required String senderName,
    required String security,
  }) async {
    systemSetting.smtpHost.value = host.trim();
    systemSetting.smtpPort.value = port;
    systemSetting.smtpUsername.value = username.trim();
    systemSetting.smtpPassword.value = password;
    systemSetting.smtpSenderEmail.value = senderEmail.trim();
    systemSetting.smtpSenderName.value = senderName.trim();
    systemSetting.smtpSecurity.value = security;
    await _saveSystemSetting();
  }

  /// 设置备份目录
  Future<void> setBackupDirectory(String path) async {
    systemSetting.backupDirectory.value = path;
    await _saveSystemSetting();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final previous = systemSetting.autoBackupEnabled.value;
    systemSetting.autoBackupEnabled.value = enabled;
    await _saveSystemSetting();
    _restartAutoBackupTimer();
    if (enabled) {
      try {
        await _runAutoBackupIfNeeded(force: true, rethrowErrors: true);
      } catch (_) {
        systemSetting.autoBackupEnabled.value = previous;
        await _saveSystemSetting();
        _restartAutoBackupTimer();
        rethrow;
      }
    }
  }

  Future<void> setAutoBackupKeepCount(int count) async {
    systemSetting.autoBackupKeepCount.value = count.clamp(1, 30);
    await _saveSystemSetting();
    await BackupService.pruneAutomaticBackups(
      outputDirectory: effectiveBackupDirectory,
      keepLatest: systemSetting.autoBackupKeepCount.value,
    );
  }

  Future<void> runAutomaticBackupNow() async {
    await _runAutoBackupIfNeeded(force: true, rethrowErrors: true);
  }

  void _restartAutoBackupTimer() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = null;
    if (!systemSetting.autoBackupEnabled.value) return;

    _autoBackupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _runAutoBackupIfNeeded();
    });
  }

  Future<void> _runAutoBackupIfNeeded({
    bool force = false,
    bool rethrowErrors = false,
  }) async {
    if (!force && !systemSetting.autoBackupEnabled.value) return;
    if (_autoBackupRunning) return;

    final lastAt = DateTime.tryParse(
      systemSetting.autoBackupLastAt.value ?? '',
    );
    if (!force && _hasBackedUpAfterTodayMidnight(lastAt)) {
      return;
    }

    _autoBackupRunning = true;
    try {
      final file = await BackupService.createAutomaticBackup(
        outputDirectory: effectiveBackupDirectory,
        keepLatest:
            systemSetting.autoBackupKeepCount.value.clamp(1, 30).toInt(),
      );
      systemSetting.autoBackupLastAt.value = DateTime.now().toIso8601String();
      await _saveSystemSetting();
      debugPrint('✅ [Backup] 自动备份完成: ${file.path}');
    } catch (e) {
      debugPrint('⚠️ [Backup] 自动备份失败: $e');
      if (rethrowErrors) rethrow;
    } finally {
      _autoBackupRunning = false;
    }
  }

  bool _hasBackedUpAfterTodayMidnight(DateTime? lastAt) {
    if (lastAt == null) return false;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    return !lastAt.isBefore(todayMidnight);
  }
}
