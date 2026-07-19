import 'package:flutter/foundation.dart';

import './storage_paths.dart';
import '../data/database.dart';

export './storage_paths.dart' show StoragePaths;

/// 本地存储服务（单例）
///
/// 集中提供供应商密钥的便捷访问，统一委托给 Drift / SQLite 数据库
/// [appDatabase] 的 `vendor_key_rows` 表；并暴露 [StoragePaths] 供各模块
/// 解析 ~/.llmate 下的文件路径。
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  static StorageService get instance => _instance;
  StorageService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 初始化（确保目录存在）
  Future<void> initialize() async {
    if (_initialized) return;
    await StoragePaths.ensureRoot();
    _initialized = true;
    debugPrint('✅ StorageService 初始化完成: ${StoragePaths.root}');
  }

  /// 关闭（文件存储无需显式关闭）
  Future<void> close() async {
    _initialized = false;
  }

  // ── 供应商密钥便捷方法（委托 Drift / SQLite）──

  static Future<String?> getVendorKey(String vendorId) async {
    return appDatabase.getVendorKey(vendorId);
  }

  static Future<void> saveVendorKey(String vendorId, String apiKey) async {
    await appDatabase.putVendorKey(vendorId, apiKey);
  }

  static Future<void> deleteVendorKey(String vendorId) async {
    await appDatabase.deleteVendorKey(vendorId);
  }
}


