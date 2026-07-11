import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/storage_service.dart';

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

/// 域名管理 Controller
///
/// 负责域名配置的持久化（存储到 settings.json），
/// 以及为 LLM 请求提供 base URL。
class DomainController extends GetxController {
  static const _keyDomain = 'domainConfig_domain';
  static const _keyHttpPort = 'domainConfig_httpPort';
  static const _keyHttpsPort = 'domainConfig_httpsPort';
  static const _keyCertPath = 'domainConfig_certPath';
  static const _keyKeyPath = 'domainConfig_keyPath';
  static const _keyHttpsEnabled = 'domainConfig_httpsEnabled';

  final domainConfig = DomainConfig().obs;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  /// 获取当前有效的 base URL
  String get effectiveBaseUrl => domainConfig.value.baseUrl;

  /// 是否配置了域名
  bool get isConfigured => !domainConfig.value.isEmpty;

  /// 保存域名配置
  Future<void> saveConfig(DomainConfig config) async {
    domainConfig.value = config;
    try {
      final store = StorageService.instance.store;
      await store.isarSettings.putAll({
        _keyDomain: config.domain,
        _keyHttpPort: config.httpPort.toString(),
        _keyHttpsPort: config.httpsPort.toString(),
        _keyCertPath: config.certPath ?? '',
        _keyKeyPath: config.keyPath ?? '',
        _keyHttpsEnabled: config.httpsEnabled.toString(),
      });
      debugPrint('✅ 域名配置已保存: ${config.baseUrl}');
    } catch (e) {
      debugPrint('❌ 保存域名配置失败: $e');
    }
  }

  /// 清除域名配置
  Future<void> clearConfig() async {
    domainConfig.value = DomainConfig();
    try {
      final store = StorageService.instance.store;
      await store.isarSettings.delete(_keyDomain);
      await store.isarSettings.delete(_keyHttpPort);
      await store.isarSettings.delete(_keyHttpsPort);
      await store.isarSettings.delete(_keyCertPath);
      await store.isarSettings.delete(_keyKeyPath);
      await store.isarSettings.delete(_keyHttpsEnabled);
      debugPrint('✅ 域名配置已清除');
    } catch (e) {
      debugPrint('❌ 清除域名配置失败: $e');
    }
  }

  /// 从持久化存储加载配置
  Future<void> _loadConfig() async {
    try {
      final store = StorageService.instance.store;

      final domainEntry = await store.isarSettings.getByKey(_keyDomain);
      final httpPortEntry = await store.isarSettings.getByKey(_keyHttpPort);
      final httpsPortEntry = await store.isarSettings.getByKey(_keyHttpsPort);
      final certEntry = await store.isarSettings.getByKey(_keyCertPath);
      final keyEntry = await store.isarSettings.getByKey(_keyKeyPath);
      final httpsEntry = await store.isarSettings.getByKey(_keyHttpsEnabled);

      final domain = domainEntry?['value'] as String? ?? '';
      final httpPort = int.tryParse(httpPortEntry?['value'] as String? ?? '') ?? 80;
      final httpsPort = int.tryParse(httpsPortEntry?['value'] as String? ?? '') ?? 443;
      final certPath = certEntry?['value'] as String?;
      final keyPath = keyEntry?['value'] as String?;
      final httpsEnabled = httpsEntry?['value'] == 'true';

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
}
