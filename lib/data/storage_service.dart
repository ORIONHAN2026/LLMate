import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import './storage_paths.dart';
import './file_storage.dart';

export './storage_paths.dart' show StoragePaths;

/// 本地文件存储服务（单例）
///
/// 替代原 Isar 数据库，使用 ~/.llmwork/ 目录下的 JSON 文件存储数据。
///
/// 存储结构：
/// ```
/// ~/.llmwork/
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
  final ModelStore isarChatModels = ModelStore();

  // ── 会话 ──
  final SessionStore isarChatSessions = SessionStore();

  // ── 消息 ──
  final MessageStore isarChatMessages = MessageStore();

  // ── MCP ──
  final McpStore isarMcpServices = McpStore();

  // ── 设置 ──
  final SettingsStore isarSettings = SettingsStore();

  // ── 供应商密钥 ──
  final VendorKeyStore isarVendorKeys = VendorKeyStore();
}

// ══════════════════════════════════════════════════════════
// 模型存储
// ══════════════════════════════════════════════════════════

class ModelStore {
  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  Future<List<Map<String, dynamic>>> findAll() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_cache);
  }

  Future<Map<String, dynamic>?> getByModelId(String modelId) async {
    if (!_loaded) await _load();
    try {
      return _cache.firstWhere((m) => m['modelId'] == modelId);
    } catch (_) {
      return null;
    }
  }

  Future<void> putAll(List<Map<String, dynamic>> models) async {
    _cache = List.from(models);
    _loaded = true;
    await _save();
  }

  Future<void> put(Map<String, dynamic> model) async {
    if (!_loaded) await _load();
    final idx = _cache.indexWhere((m) => m['modelId'] == model['modelId']);
    if (idx >= 0) {
      _cache[idx] = model;
    } else {
      _cache.add(model);
    }
    await _save();
  }

  Future<void> delete(String modelId) async {
    if (!_loaded) await _load();
    _cache.removeWhere((m) => m['modelId'] == modelId);
    await _save();
  }

  Future<void> clear() async {
    _cache = [];
    _loaded = true;
    await _save();
  }

  Future<int> count() async {
    if (!_loaded) await _load();
    return _cache.length;
  }

  Future<void> _load() async {
    final data = await FileStorage.readJsonList(StoragePaths.modelsFile);
    _cache = data?.cast<Map<String, dynamic>>() ?? [];
    _loaded = true;
  }

  Future<void> _save() async {
    await FileStorage.writeJsonList(StoragePaths.modelsFile, _cache);
  }
}

// ══════════════════════════════════════════════════════════
// 会话存储
// ══════════════════════════════════════════════════════════

class SessionStore {
  /// 所有会话的元数据缓存（不含消息）
  List<Map<String, dynamic>> _cache = [];
  bool _loaded = false;

  Future<List<Map<String, dynamic>>> findAll() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_cache);
  }

  Future<Map<String, dynamic>?> getBySessionId(String sessionId) async {
    if (!_loaded) await _load();
    try {
      return _cache.firstWhere((s) => s['sessionId'] == sessionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> put(Map<String, dynamic> session) async {
    if (!_loaded) await _load();
    final sid = session['sessionId'] as String;
    final idx = _cache.indexWhere((s) => s['sessionId'] == sid);
    if (idx >= 0) {
      _cache[idx] = session;
    } else {
      _cache.add(session);
    }
    // 写入文件
    await StoragePaths.ensureSessionDir(sid);
    await FileStorage.writeJson(StoragePaths.sessionFile(sid), session);
    await _saveIndex();
  }

  Future<void> delete(String sessionId) async {
    if (!_loaded) await _load();
    _cache.removeWhere((s) => s['sessionId'] == sessionId);
    await FileStorage.deleteDir(StoragePaths.sessionDir(sessionId));
    await _saveIndex();
  }

  Future<void> clear() async {
    _cache = [];
    _loaded = true;
    // 删除所有会话目录
    final ids = await StoragePaths.listSessionIds();
    for (final id in ids) {
      await FileStorage.deleteDir(StoragePaths.sessionDir(id));
    }
    await _saveIndex();
  }

  Future<int> count() async {
    if (!_loaded) await _load();
    return _cache.length;
  }

  Future<void> _load() async {
    // 从 chats/ 目录扫描所有会话
    final ids = await StoragePaths.listSessionIds();
    _cache = [];
    for (final sid in ids) {
      final data = await FileStorage.readJson(StoragePaths.sessionFile(sid));
      if (data != null) {
        _cache.add(data);
      }
    }
    _loaded = true;
  }

  Future<void> _saveIndex() async {
    // 索引已通过各会话文件维护，无需额外索引文件
  }
}

// ══════════════════════════════════════════════════════════
// 消息存储
// ══════════════════════════════════════════════════════════

class MessageStore {
  Future<List<Map<String, dynamic>>> getBySessionId(String sessionId) async {
    final data =
        await FileStorage.readJsonList(StoragePaths.messageFile(sessionId));
    return data?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<void> putAll(
      String sessionId, List<Map<String, dynamic>> messages) async {
    await StoragePaths.ensureSessionDir(sessionId);
    await FileStorage.writeJsonList(StoragePaths.messageFile(sessionId), messages);
  }

  /// 删除指定会话的消息文件（并删除整个会话目录）
  Future<void> delete(String sessionId) async {
    await FileStorage.deleteDir(StoragePaths.sessionDir(sessionId));
  }
}

// ══════════════════════════════════════════════════════════
// MCP 存储
// ══════════════════════════════════════════════════════════

class McpStore {
  Map<String, Map<String, dynamic>> _cache = {};
  bool _loaded = false;

  Future<List<Map<String, dynamic>>> findAll() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_cache.values);
  }

  Future<Map<String, dynamic>?> getByMcpId(String mcpId) async {
    if (!_loaded) await _load();
    return _cache[mcpId];
  }

  Future<void> put(Map<String, dynamic> mcp) async {
    if (!_loaded) await _load();
    final mid = mcp['mcpId'] as String;
    _cache[mid] = mcp;
    await _saveOne(mid, mcp);
  }

  Future<void> delete(String mcpId) async {
    if (!_loaded) await _load();
    _cache.remove(mcpId);
    await _deleteOne(mcpId);
  }

  Future<void> clear() async {
    _cache = {};
    _loaded = true;
    await _clearAll();
  }

  Future<void> _load() async {
    await StoragePaths.ensureMcpsDir();
    final dir = Directory(StoragePaths.mcpsDir);
    _cache = {};

    if (await dir.exists()) {
      final files = await dir.list().where((e) => e.path.endsWith('.json')).toList();
      for (final file in files) {
        try {
          final data = await FileStorage.readJson(file.path);
          if (data != null) {
            final mcpId = data['mcpId'] as String?;
            if (mcpId != null && mcpId.isNotEmpty) {
              // 检查是否有无效的 builtin:// URL，如果有则删除旧文件
              final url = data['url'] as String?;
              if (url != null && url.startsWith('builtin://')) {
                // 旧格式，删除文件，下次会重新创建
                await file.delete();
                continue;
              }
              _cache[mcpId] = data;
            }
          }
        } catch (e) {
          debugPrint('⚠️ 加载 MCP 文件失败: ${file.path}, $e');
        }
      }
    }
    _loaded = true;
  }

  Future<void> _saveOne(String mcpId, Map<String, dynamic> data) async {
    await StoragePaths.ensureMcpsDir();
    // 使用 mcpId 作为文件名
    final file = File(p.join(StoragePaths.mcpsDir, '$mcpId.json'));
    await FileStorage.writeJson(file.path, data);
  }

  Future<void> _deleteOne(String mcpId) async {
    final file = File(p.join(StoragePaths.mcpsDir, '$mcpId.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _clearAll() async {
    final dir = Directory(StoragePaths.mcpsDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await StoragePaths.ensureMcpsDir();
  }
}

// ══════════════════════════════════════════════════════════
// 设置存储
// ══════════════════════════════════════════════════════════

class SettingsStore {
  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  Future<Map<String, dynamic>?> getByKey(String key) async {
    if (!_loaded) await _load();
    final value = _cache[key];
    if (value == null) return null;
    return {'key': key, 'value': value.toString()};
  }

  Future<void> put(String key, String value) async {
    if (!_loaded) await _load();
    _cache[key] = value;
    await _save();
  }

  Future<void> putAll(Map<String, String> entries) async {
    if (!_loaded) await _load();
    _cache.addAll(entries);
    await _save();
  }

  Future<void> delete(String key) async {
    if (!_loaded) await _load();
    _cache.remove(key);
    await _save();
  }

  Future<void> _load() async {
    final data = await FileStorage.readJson(StoragePaths.settingsFile);
    _cache = data?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    _loaded = true;
  }

  Future<void> _save() async {
    await FileStorage.writeJson(StoragePaths.settingsFile, _cache);
  }
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
