import 'package:flutter/foundation.dart';

import './storage_paths.dart';
import './file_storage.dart';

export './storage_paths.dart' show StoragePaths;

/// 本地文件存储服务（单例）
///
/// 替代原 Isar 数据库，使用 ~/.llmate/ 目录下的 JSON 文件存储数据。
///
/// 存储结构：
/// ```
/// ~/.llmate/
/// ├── models.json              # 所有模型配置
/// ├── mcp.json                 # 所有 MCP 服务配置
/// ├── settings.json            # 通用设置（主题、语言等）
/// ├── vendor_keys.json         # 供应商 API 密钥
/// └── chats/                   # 会话目录
///     └── {sessionId}/
///         ├── session.json     # 会话元数据
///         ├── message.json     # 消息列表
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
    debugPrint('✅ FileStorage 初始化完成: ${StoragePaths.root}');
  }

  /// 获取 isar 兼容的存储访问对象（新接口）
  FileStore get store => FileStore.instance;

  /// 关闭（文件存储无需显式关闭）
  Future<void> close() async {
    _initialized = false;
  }

  // ── 供应商密钥便捷方法 ──

  static Future<String?> getVendorKey(String vendorId) async {
    final record = await instance.store.isarVendorKeys.getByVendorId(vendorId);
    return record?['apiKey'] as String?;
  }

  static Future<void> saveVendorKey(String vendorId, String apiKey) async {
    await instance.store.isarVendorKeys.put(vendorId, apiKey);
  }

  static Future<void> deleteVendorKey(String vendorId) async {
    await instance.store.isarVendorKeys.delete(vendorId);
  }

}

/// 文件存储访问对象 — 替代原 Isar 实例
///
/// 提供与原 Isar 相似的访问模式，但底层使用 JSON 文件。
class FileStore {
  static final FileStore _instance = FileStore._();
  static FileStore get instance => _instance;
  FileStore._();

  // ── 模型 ──
  // 注意：模型配置已迁移至 ~/.llmate/models.db（见 ModelController），不再使用文件存储。

  // ── MCP ──
  // 注意：MCP 配置已迁移至 ~/.llmate/mcps.db（见 McpStorageManager），不再使用目录式存储。

  // ── 会话 / 消息 / 设置 ──
  // 注意：会话、消息、设置已分别迁移至 sessions.db / messages.db / settings.db，
  // 不再使用目录式存储（详见 SessionController / MessageController / SettingsController）。

  // ── 供应商密钥 ──
  final VendorKeyStore isarVendorKeys = VendorKeyStore();
}

// ══════════════════════════════════════════════════════════
// 供应商密钥存储
// ══════════════════════════════════════════════════════════

class VendorKeyStore {
  Map<String, Map<String, dynamic>> _cache = {};
  bool _loaded = false;

  Future<Map<String, dynamic>?> getByVendorId(String vendorId) async {
    if (!_loaded) await _load();
    return _cache[vendorId];
  }

  Future<void> put(String vendorId, String apiKey) async {
    if (!_loaded) await _load();
    _cache[vendorId] = {
      'vendorId': vendorId,
      'apiKey': apiKey,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _save();
  }

  Future<void> delete(String vendorId) async {
    if (!_loaded) await _load();
    _cache.remove(vendorId);
    await _save();
  }

  Future<void> _load() async {
    final data = await FileStorage.readJsonList(StoragePaths.vendorKeysFile);
    if (data != null) {
      for (final item in data) {
        final map = item as Map<String, dynamic>;
        final vid = map['vendorId'] as String?;
        if (vid != null) _cache[vid] = map;
      }
    }
    _loaded = true;
  }

  Future<void> _save() async {
    await FileStorage.writeJsonList(
        StoragePaths.vendorKeysFile, _cache.values.toList());
  }
}

// ══════════════════════════════════════════════════════════
// 会话扩展 — 提供 session.json 中额外字段的读写
// ══════════════════════════════════════════════════════════
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
