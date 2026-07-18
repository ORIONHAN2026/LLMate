import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 系统设置聚合对象
///
/// 将原先分散在 `SettingsController` 中的「服务设置」与「其他设置」统一定义于此，
/// 所有字段均**扁平地**直接作为 [SystemSetting] 的响应式字段：
///   - 服务设置：[domain] / [certPath] / [keyPath] / [httpsEnabled] /
///     [httpPort] / [httpsPort]。
///   - 其他设置：主题模式（[useSystemTheme] / [isDarkMode]）、界面语言（[locale]）。
///
/// 各字段均使用 GetX 的 `.obs` 包装，因此既是可被 UI 直接观察的响应式对象，
/// 又能由 `SettingsController` 统一读写与持久化。整个对象序列化为 settings.db
/// 中的单条记录（`systemSetting`），替代原先分散的多个 key。
class SystemSetting {
  // ── 其他设置 ──
  /// 是否跟随系统主题
  final useSystemTheme = false.obs;

  /// 是否深色模式（useSystemTheme 为 true 时此值无效）
  final isDarkMode = false.obs;

  /// 界面语言（'zh' / 'en'）
  final locale = const Locale('zh').obs;

  // ── 服务设置（域名 / 端口 / 证书，扁平字段）──
  /// 域名（不带协议）
  final domain = ''.obs;

  /// 证书文件路径
  final certPath = RxnString();

  /// 私钥文件路径
  final keyPath = RxnString();

  /// 是否开启 HTTPS（上传证书后自动开启）
  final httpsEnabled = false.obs;

  /// HTTP 端口（默认 80）
  final httpPort = 80.obs;

  /// HTTPS 端口（默认 443）
  final httpsPort = 443.obs;

  SystemSetting();

  /// 从聚合 JSON 构造（字段缺省时使用默认值）
  ///
  /// 兼容两种格式：新版扁平字段，以及旧版嵌套的 `domainConfig`。
  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    final s = SystemSetting();
    s.useSystemTheme.value = _asBool(json['useSystemTheme']) ?? false;
    s.isDarkMode.value = _asBool(json['isDarkMode']) ?? false;
    final lang = json['appLanguage'] as String? ?? 'zh';
    Locale toLocale(String l) {
      switch (l) {
        case 'en':
          return const Locale('en');
        case 'ja':
          return const Locale('ja');
        case 'th':
          return const Locale('th');
        case 'vi':
          return const Locale('vi');
        case 'ko':
          return const Locale('ko');
        case 'fr':
          return const Locale('fr');
        case 'de':
          return const Locale('de');
        default:
          return const Locale('zh');
      }
    }

    s.locale.value = toLocale(lang);

    // 域名字段：优先读旧版嵌套 domainConfig，其次读新版扁平字段
    final dc = json['domainConfig'];
    final src = dc is Map ? dc.cast<String, dynamic>() : json;
    s.domain.value = src['domain'] as String? ?? '';
    s.certPath.value = src['certPath'] as String?;
    s.keyPath.value = src['keyPath'] as String?;
    s.httpsEnabled.value = _asBool(src['httpsEnabled']) ?? false;
    s.httpPort.value = (src['httpPort'] as num?)?.toInt() ?? 80;
    s.httpsPort.value = (src['httpsPort'] as num?)?.toInt() ?? 443;
    return s;
  }

  /// 序列化为聚合 JSON（单条记录，域名字段扁平存放）
  Map<String, dynamic> toJson() => {
        'useSystemTheme': useSystemTheme.value,
        'isDarkMode': isDarkMode.value,
        'appLanguage': locale.value.languageCode,
        'domain': domain.value,
        if (certPath.value != null) 'certPath': certPath.value,
        if (keyPath.value != null) 'keyPath': keyPath.value,
        'httpsEnabled': httpsEnabled.value,
        'httpPort': httpPort.value,
        'httpsPort': httpsPort.value,
      };

  /// 当前主题模式
  ThemeMode get themeMode {
    if (useSystemTheme.value) return ThemeMode.system;
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  /// 是否配置了服务域名
  bool get isConfigured => domain.value.isNotEmpty;

  /// 完整的 base URL（含协议和端口）
  String get baseUrl {
    if (domain.value.isEmpty) return '';
    final scheme = httpsEnabled.value ? 'https' : 'http';
    final port = httpsEnabled.value ? httpsPort.value : httpPort.value;
    return '$scheme://${domain.value}:$port';
  }

  /// 当前有效的 base URL
  String get effectiveBaseUrl => baseUrl;

  /// 将 [other] 的字段值复制到本对象（保持 Rx 实例不变，确保响应式不中断）
  void assign(SystemSetting other) {
    useSystemTheme.value = other.useSystemTheme.value;
    isDarkMode.value = other.isDarkMode.value;
    locale.value = other.locale.value;
    domain.value = other.domain.value;
    certPath.value = other.certPath.value;
    keyPath.value = other.keyPath.value;
    httpsEnabled.value = other.httpsEnabled.value;
    httpPort.value = other.httpPort.value;
    httpsPort.value = other.httpsPort.value;
  }

  /// 将可能为 bool / String 的值统一解析为 bool
  static bool? _asBool(Object? v) {
    if (v is bool) return v;
    if (v is String) return v == 'true';
    return null;
  }
}
