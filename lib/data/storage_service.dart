import 'package:flutter/foundation.dart';

import './storage_paths.dart';
import './file_storage.dart';
import './database.dart';

export './storage_paths.dart' show StoragePaths;

/// 本地文件存储服务（单例）
///
/// 负责会话级附加文件（memory.md / mcp.json / business.md）的读写，
/// 以及供应商密钥的便捷访问（统一委托给 Drift / SQLite 数据库
/// [appDatabase] 的 `vendor_key_rows` 表）。
///
/// 结构：
/// ```
/// ~/.llmate/
/// ├── llmate.sqlite          # 主数据库（会话 / 消息 / 模型 / MCP / 设置 / 审计 / 用量 / 供应商密钥）
/// └── chats/                 # 会话目录
///     └── {sessionId}/
///         ├── memory.md        # 压缩记忆（markdown）
///         ├── mcp.json         # MCP 绑定
///         └── business.json    # 商务合同内容
/// ```
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

/// 文件存储访问对象 — 会话目录级附加文件（memory / mcp / business 等）。
///
/// 注意：会话元数据、消息、模型、MCP、设置、审计、用量均已迁移至
/// Drift / SQLite（[appDatabase]），此处仅保留目录式附加文件读写。
class FileStore {
  static final FileStore _instance = FileStore._();
  static FileStore get instance => _instance;
  FileStore._();
}

/// ═══════════════════════════════════════════════════════
/// 会话扩展 — 提供 session.json 中额外字段的读写
/// ═══════════════════════════════════════════════════════
class SessionFileStore {
  /// 读取 memory.md
  static Future<String?> readMemory(String sessionId) async {
    return FileStorage.readText(StoragePaths.memoryFile(sessionId));
  }

  /// 写入 memory.md
  static Future<void> writeMemory(String sessionId, String content) async {
    await StoragePaths.ensureSessionDir(sessionId);
    await FileStorage.writeText(StoragePaths.memoryFile(sessionId), content);
  }

  /// 读取 mcp.json（会话级）
  static Future<Map<String, dynamic>?> readMcp(String sessionId) async {
    return FileStorage.readJson(StoragePaths.sessionMcpFile(sessionId));
  }

  /// 写入 mcp.json（会话级）
  static Future<void> writeMcp(
      String sessionId, Map<String, dynamic> data) async {
    await StoragePaths.ensureSessionDir(sessionId);
    await FileStorage.writeJson(StoragePaths.sessionMcpFile(sessionId), data);
  }

  /// 读取 business.md
  static Future<String?> readBusiness(String sessionId) async {
    return FileStorage.readText(StoragePaths.businessFile(sessionId));
  }

  /// 写入 business.md
  static Future<void> writeBusiness(
      String sessionId, String content) async {
    await StoragePaths.ensureSessionDir(sessionId);
    await FileStorage.writeText(StoragePaths.businessFile(sessionId), content);
  }
}
