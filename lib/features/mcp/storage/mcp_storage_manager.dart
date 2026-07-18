import 'package:flutter/foundation.dart';
import 'package:llmate/models/chat/mcp.dart';
import 'package:llmate/data/database.dart';

/// MCP 存储结构管理器
///
/// 数据持久化于 Drift / SQLite 单例数据库 [appDatabase]（~/.llmate/llmate.sqlite，
/// `mcps` 表，每条记录的主键为 MCP 名称，data 为合并后的完整配置 `mcp.toJson()`）。
class McpStorageManager {
  /// 获取所有已安装的 MCP（从 SQLite 读取）
  static Future<List<Mcp>> loadAll() async {
    try {
      return await appDatabase.getAllMcps();
    } catch (e) {
      debugPrint('⚠️ 加载 MCP 列表失败: $e');
      return [];
    }
  }

  /// 保存 MCP（写入 SQLite，主键为 mcp.name）
  static Future<void> save(Mcp mcp) async {
    await appDatabase.upsertMcp(mcp);
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
    await appDatabase.deleteMcp(name);
  }

  /// 检查 MCP 是否存在
  static Future<bool> exists(String name) async {
    if (name.isEmpty) return false;
    return await appDatabase.getMcp(name) != null;
  }

  /// 按名称加载单个 MCP 数据
  static Future<Mcp?> loadByName(String name) async {
    if (name.isEmpty) return null;
    try {
      return await appDatabase.getMcp(name);
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

  McpData({required this.name, required this.mcp});

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
