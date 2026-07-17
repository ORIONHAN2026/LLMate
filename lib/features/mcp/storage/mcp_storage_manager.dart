import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import '../../../data/storage_paths.dart';
import 'package:llmate/models/chat/mcp.dart';

/// MCP 存储结构管理器
///
/// 数据持久化于嵌入式 NoSQL 数据库 `~/.llmate/mcps.db`（sembast，`mcps` store，
/// 每条 record 的 key 为 MCP 名称，value 为合并后的完整配置 `mcp.toJson()`）。
///
/// 旧版本使用目录结构 `~/.llmate/mcps/{mcp_name}/server.json` 存储，
/// 首次打开数据库时会自动将旧目录中的数据迁移进 mcps.db（旧目录保留作备份）。
class McpStorageManager {
  /// MCP 数据库路径：~/.llmate/mcps.db
  static String get _dbPath => p.join(StoragePaths.root, 'mcps.db');

  /// sembast store 名称（每条 record 的 key 为 MCP 名称）
  static const String _storeName = 'mcps';
  static final _store = stringMapStoreFactory.store(_storeName);

  static Database? _db;
  static bool _migrated = false;

  /// 懒加载并打开 sembast 数据库（单例）
  static Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版目录 `mcps/{name}/server.json` 迁移进 mcps.db
  ///
  /// 仅在数据库中尚不存在同名记录时写入，避免覆盖新数据；旧目录保留作备份。
  static Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final mcpsDir = Directory(StoragePaths.mcpsDir);
      if (!await mcpsDir.exists()) return;

      int migrated = 0;
      await for (final entity in mcpsDir.list()) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        final data = await _loadMcpFromDir(entity.path, name);
        if (data == null) continue;

        final existing = await _store.record(name).get(db);
        if (existing == null) {
          await _store.record(name).put(db, data.mcp.toJson());
          migrated++;
        }
      }
      if (migrated > 0) {
        debugPrint('📦 [MCP] 已迁移 $migrated 个旧 MCP 配置至 mcps.db');
      }
    } catch (e) {
      debugPrint('⚠️ [MCP] 迁移旧 mcps 目录失败: $e');
    }
  }

  /// 从旧版目录加载单个 MCP（合并 server.json + config.json）—— 仅供迁移使用
  static Future<McpData?> _loadMcpFromDir(String dirPath, String name) async {
    final serverFile = File('$dirPath/server.json');
    if (!await serverFile.exists()) return null;

    try {
      var serverJson =
          jsonDecode(await serverFile.readAsString()) as Map<String, dynamic>;

      final configFile = File('$dirPath/config.json');
      if (await configFile.exists()) {
        final configJson =
            jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
        final merged = <String, dynamic>{...serverJson};
        merged['name'] =
            serverJson['name'] as String? ?? configJson['name'] as String? ?? name;
        if (configJson['description'] != null) {
          merged['description'] ??= configJson['description'];
        }
        merged['tools'] = configJson['tools'] ?? [];
        if (configJson['version'] != null) merged['version'] = configJson['version'];
        if (configJson['prompt'] != null) merged['prompt'] = configJson['prompt'];
        if (configJson['lastUpdated'] != null) {
          merged['lastUpdated'] = configJson['lastUpdated'];
        }
        serverJson = merged;
      }

      final mcp = Mcp.fromJson(name, serverJson);
      return McpData(name: name, mcp: mcp, directory: dirPath);
    } catch (e) {
      debugPrint('⚠️ 加载旧 MCP 失败: $name, $e');
      return null;
    }
  }

  /// 获取所有已安装的 MCP（从 mcps.db 读取）
  static Future<List<Mcp>> loadAll() async {
    try {
      final db = await _database;
      final records = await _store.find(db);
      final list = <Mcp>[];
      for (final rec in records) {
        try {
          final value = rec.value;
          final name = value['name'] as String? ?? rec.key;
          list.add(Mcp.fromJson(name, value));
        } catch (e) {
          debugPrint('⚠️ 解析 MCP 记录失败: ${rec.key}, $e');
        }
      }
      return list;
    } catch (e) {
      debugPrint('⚠️ 加载 MCP 列表失败: $e');
      return [];
    }
  }

  /// 保存 MCP（写入 mcps.db，key 为 mcp.name）
  static Future<void> save(Mcp mcp) async {
    final db = await _database;
    await _store.record(mcp.name).put(db, mcp.toJson());
  }

  /// 合并连接配置（serverJson）与元信息（config）
  static Map<String, dynamic> _mergeConfigMeta(
    Map<String, dynamic> serverJson,
    Mcp config,
  ) {
    final m = <String, dynamic>{...serverJson};
    m['name'] = config.name;
    if (config.description != null) m['description'] = config.description!;
    if (config.tools != null) {
      m['tools'] = config.tools!.map((t) => t.toJson()).toList();
    }
    if (config.version != null) m['version'] = config.version!;
    if (config.prompt != null) m['prompt'] = config.prompt!;
    if (config.lastUpdated != null) {
      m['lastUpdated'] = config.lastUpdated!.toIso8601String();
    }
    return m;
  }

  /// 从 Mcp 直接保存（内部构造合并后的配置）
  static Future<void> saveConfig(Mcp config,
      {Map<String, dynamic>? serverJson}) async {
    final Mcp mcp;
    if (serverJson != null) {
      final merged = _mergeConfigMeta(serverJson, config);
      mcp = Mcp.fromJson(config.name, merged);
    } else {
      mcp = config;
    }
    await save(mcp);
  }

  /// 删除 MCP
  static Future<void> delete(String name) async {
    if (name.isEmpty) return;
    final db = await _database;
    await _store.record(name).delete(db);
  }

  /// 检查 MCP 是否存在
  static Future<bool> exists(String name) async {
    if (name.isEmpty) return false;
    final db = await _database;
    return _store.record(name).exists(db);
  }

  /// 按名称加载单个 MCP 数据
  static Future<Mcp?> loadByName(String name) async {
    if (name.isEmpty) return null;
    try {
      final db = await _database;
      final value = await _store.record(name).get(db);
      if (value == null) return null;
      return Mcp.fromJson(value['name'] as String? ?? name, value);
    } catch (e) {
      debugPrint('⚠️ 加载 MCP 失败: $name, $e');
      return null;
    }
  }
}

/// MCP 数据（内部包装，便于 UI 访问）
class McpData {
  final String name;
  final Mcp mcp;
  final String? directory;

  McpData({required this.name, required this.mcp, this.directory});

  /// 获取描述
  String? get description => mcp.description;

  /// 获取工具列表
  List<Map<String, dynamic>> get tools =>
      mcp.tools?.map((t) => t.toJson()).toList() ?? [];

  /// 获取完整 server.json 内容
  Map<String, dynamic> get server => mcp.toJson();

  /// 获取 command
  String? get command => mcp.command;

  /// 获取 args
  List<String>? get args => mcp.args;

  /// 获取 URL
  String? get url => mcp.url;

  /// 获取 headers
  Map<String, String>? get headers => mcp.headers;

  /// 获取环境变量
  Map<String, String>? get env => mcp.env;
}
