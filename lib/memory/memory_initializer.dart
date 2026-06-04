import 'package:flutter/foundation.dart';
import '../models/bigmodel/chat_model.dart';
import 'memory_models.dart';
import 'memory_service.dart';

/// 记忆系统初始化器
/// 
/// 负责在应用启动时初始化和配置记忆系统
/// 
/// 使用示例：
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // 初始化记忆系统
///   await MemoryInitializer.initialize();
///   
///   runApp(MyApp());
/// }
/// ```
class MemoryInitializer {
  static MemoryService? _service;

  /// 获取记忆服务实例
  static MemoryService? get service => _service;

  /// 是否已初始化
  static bool get isInitialized => _service?.isInitialized ?? false;

  /// 初始化记忆系统
  /// 
  /// [extractionModel]: 用于记忆提取的模型，如果为null则禁用自动提取
  /// [config]: 记忆系统配置
  static Future<void> initialize({
    ChatModel? extractionModel,
    MemoryConfig? config,
  }) async {
    try {
      debugPrint('🧠 Initializing memory system...');

      // 如果没有指定提取模型，尝试从设置中获取默认模型
      extractionModel ??= _getDefaultExtractionModel();

      // 创建并初始化服务
      _service = MemoryService(
        extractionModel: extractionModel,
        config: config ?? _getDefaultConfig(),
      );

      await _service!.initialize();

      debugPrint('✅ Memory system initialized');
    } catch (e) {
      debugPrint('❌ Memory system initialization failed: $e');
      // 记忆系统初始化失败不应该阻止应用启动
      _service = null;
    }
  }

  /// 获取默认提取模型
  /// 
  /// 优先使用轻量级模型进行记忆提取以节省成本
  static ChatModel? _getDefaultExtractionModel() {
    // 从服务定位器或全局状态获取默认模型
    // 这里简化处理，返回null让调用方处理
    return null;
  }

  /// 获取默认配置
  static MemoryConfig _getDefaultConfig() {
    return const MemoryConfig(
      enabled: true,
      storeBackend: 'sqlite',
      recallStrategy: 'hybrid',
      maxRecallResults: 5,
      extractionInterval: 5,
      l2TriggerThreshold: 10,
      l3TriggerThreshold: 5,
      l1IdleTimeoutSeconds: 600,
      enableDeduplication: true,
    );
  }

  /// 关闭记忆系统
  static Future<void> dispose() async {
    if (_service != null) {
      await _service!.dispose();
      _service = null;
      debugPrint('📝 Memory system disposed');
    }
  }

  /// 获取记忆服务（确保已初始化）
  /// 
  /// 如果未初始化，会尝试初始化
  static Future<MemoryService> ensureInitialized() async {
    if (_service == null || !_service!.isInitialized) {
      await initialize();
    }
    
    if (_service == null) {
      throw StateError('Memory system failed to initialize');
    }
    
    return _service!;
  }
}
