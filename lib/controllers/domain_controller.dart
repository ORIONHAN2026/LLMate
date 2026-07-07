import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/storage_service.dart';

/// 域名配置数据模型
class DomainConfig {
  String domain; // 域名（不带协议）
  String? certPath; // 证书文件路径
  String? keyPath; // 私钥文件路径
  bool httpsEnabled; // 是否开启 HTTPS（上传证书后自动开启）

  DomainConfig({
    this.domain = '',
    this.certPath,
    this.keyPath,
    this.httpsEnabled = false,
  });

  /// 获取完整的 base URL（含协议和端口）
  String get baseUrl {
    if (domain.isEmpty) return '';
    final scheme = httpsEnabled ? 'https' : 'http';
    final port = httpsEnabled ? 443 : 80;
    return '$scheme://$domain:$port';
  }

  bool get isEmpty => domain.isEmpty;

  Map<String, dynamic> toJson() => {
        'domain': domain,
        'certPath': certPath,
        'keyPath': keyPath,
        'httpsEnabled': httpsEnabled,
      };

  factory DomainConfig.fromJson(Map<String, dynamic> json) => DomainConfig(
        domain: json['domain'] as String? ?? '',
        certPath: json['certPath'] as String?,
        keyPath: json['keyPath'] as String?,
        httpsEnabled: json['httpsEnabled'] as bool? ?? false,
      );
}

/// 域名管理 Controller
///
/// 负责域名配置的持久化（存储到 settings.json），
/// 以及为 LLM 请求提供 base URL。
class DomainController extends GetxController {
  static const _keyDomainConfig = 'domainConfig';

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
    // 上传证书后自动开启 HTTPS
    if (config.certPath != null &&
        config.certPath!.isNotEmpty &&
        config.keyPath != null &&
        config.keyPath!.isNotEmpty) {
      domainConfig.value = config; // httpsEnabled 已在外部设置
    }
    try {
      final store = StorageService.instance.store;
      await store.isarSettings.putAll({
        _keyDomainConfig: _encodeConfig(config),
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
      await store.isarSettings.delete(_keyDomainConfig);
      debugPrint('✅ 域名配置已清除');
    } catch (e) {
      debugPrint('❌ 清除域名配置失败: $e');
    }
  }

  /// 从持久化存储加载配置
  Future<void> _loadConfig() async {
    try {
      final store = StorageService.instance.store;
      final setting = await store.isarSettings.getByKey(_keyDomainConfig);
      if (setting != null) {
        final config = _decodeConfig(setting['value'] as String);
        domainConfig.value = config;
        debugPrint('✅ 域名配置已加载: ${config.baseUrl}');
      }
    } catch (e) {
      debugPrint('❌ 加载域名配置失败: $e');
    }
  }

  String _encodeConfig(DomainConfig config) {
    return '${config.domain}|${config.certPath ?? ''}|${config.keyPath ?? ''}|${config.httpsEnabled}';
  }

  DomainConfig _decodeConfig(String raw) {
    final parts = raw.split('|');
    return DomainConfig(
      domain: parts.isNotEmpty ? parts[0] : '',
      certPath: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
      keyPath: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
      httpsEnabled: parts.length > 3 ? parts[3] == 'true' : false,
    );
  }
}
