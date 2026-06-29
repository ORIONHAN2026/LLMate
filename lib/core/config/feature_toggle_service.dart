import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 功能开关服务
///
/// 从 assets/config/feature_toggles.json 读取配置，
/// 控制 UI 中可选功能的显示/隐藏。
class FeatureToggleService {
  static final FeatureToggleService _instance = FeatureToggleService._();
  factory FeatureToggleService() => _instance;
  FeatureToggleService._();

  bool _initialized = false;
  bool _memoryConfigEnabled = false;
  bool _scheduledTaskEnabled = true;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 记忆配置入口是否可见
  bool get isMemoryConfigEnabled {
    _ensureInitialized();
    return _memoryConfigEnabled;
  }

  /// 定时任务入口是否可见
  bool get isScheduledTaskEnabled {
    _ensureInitialized();
    return _scheduledTaskEnabled;
  }

  /// 确保已初始化（若未初始化则使用默认值，不阻塞 UI）
  void _ensureInitialized() {
    if (!_initialized) {
      // 未初始化时使用默认值，异步触发加载
      init();
    }
  }

  /// 从 assets 加载配置文件
  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/config/feature_toggles.json',
      );
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _memoryConfigEnabled = map['memory_config'] as bool? ?? false;
      _scheduledTaskEnabled = map['scheduled_task'] as bool? ?? true;
      _initialized = true;
    } catch (_) {
      // 加载失败时使用默认值
      _memoryConfigEnabled = false;
      _scheduledTaskEnabled = true;
      _initialized = true;
    }
  }
}
