/// 联网搜索会话级配置
///
/// 控制当前会话的联网搜索启用状态及搜索引擎选择，
/// 后续可扩展支持不同搜索 API（Google、Bing、DuckDuckGo 等）。
class WebSearchSessionConfig {
  /// 是否启用联网搜索
  final bool isEnabled;

  /// 搜索引擎标识（如 "google", "bing", "duckduckgo"），预留扩展
  final String engine;

  /// 搜索 API 的额外配置，预留扩展
  final Map<String, dynamic>? engineConfig;

  const WebSearchSessionConfig({
    this.isEnabled = false,
    this.engine = 'google',
    this.engineConfig,
  });

  /// 是否有效
  bool get isEffective => isEnabled;

  WebSearchSessionConfig copyWith({
    bool? isEnabled,
    String? engine,
    Map<String, dynamic>? engineConfig,
  }) {
    return WebSearchSessionConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      engine: engine ?? this.engine,
      engineConfig: engineConfig ?? this.engineConfig,
    );
  }

  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'engine': engine,
    if (engineConfig != null) 'engineConfig': engineConfig,
  };

  factory WebSearchSessionConfig.fromJson(Map<String, dynamic> json) {
    return WebSearchSessionConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      engine: json['engine'] as String? ?? 'google',
      engineConfig: json['engineConfig'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebSearchSessionConfig &&
          isEnabled == other.isEnabled &&
          engine == other.engine;

  @override
  int get hashCode => Object.hash(isEnabled, engine);
}
