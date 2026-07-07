import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../data/storage_paths.dart';
import 'package:llmwork/models/chat/mcp_config.dart';

/// MCP 存储结构管理器
///
/// 目录结构: ~/.llmwork/mcps/{mcp_name}/
///   └── server.json     # 合并后的完整配置（连接配置 + 元信息）
///
/// 旧版本中元信息存放在独立的 config.json，现已合并进 server.json，
/// 加载时若发现 config.json 会自动迁移并删除。
class McpStorageManager {
  /// 获取所有已安装的 MCP
  static Future<List<Mcp>> loadAll() async {
    final mcpsDir = Directory(StoragePaths.mcpsDir);
    if (!await mcpsDir.exists()) return [];

    final list = <Mcp>[];
    await for (final entity in mcpsDir.list()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        final data = await _loadMcp(entity.path, name);
        if (data != null) list.add(data.mcp);
      }
    }
    return list;
  }

  /// 加载单个 MCP（合并 server.json + config.json，并迁移）
  static Future<McpData?> _loadMcp(String dirPath, String name) async {
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

        // 迁移：写回合并后的 server.json 并删除旧的 config.json
        await serverFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(merged),
        );
        await configFile.delete();
        serverJson = merged;
      }

      final mcp = Mcp.fromJson(name, serverJson);
      return McpData(name: name, mcp: mcp, directory: dirPath);
    } catch (e) {
      debugPrint('⚠️ 加载 MCP 失败: $name, $e');
      return null;
    }
  }

  /// 保存 MCP（仅写入 server.json，并清理旧的 config.json）
  static Future<void> save(Mcp mcp) async {
    final dir = Directory('${StoragePaths.mcpsDir}/${mcp.name}');
    await dir.create(recursive: true);

    final serverFile = File('${dir.path}/server.json');
    await serverFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(mcp.toJson()),
    );

    // 迁移清理：删除已合并的 config.json
    final configFile = File('${dir.path}/config.json');
    if (await configFile.exists()) await configFile.delete();
  }

  /// 合并连接配置（serverJson）与元信息（config）后保存
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

  /// 从 Mcp 直接保存（内部构造合并后的 server.json）
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
    final dir = Directory('${StoragePaths.mcpsDir}/$name');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 检查 MCP 是否存在
  static Future<bool> exists(String name) async {
    final dir = Directory('${StoragePaths.mcpsDir}/$name');
    return dir.exists();
  }

  /// 按文件夹名加载单个 MCP 数据（合并后的 server.json）
  static Future<Mcp?> loadByName(String name) async {
    final dir = Directory('${StoragePaths.mcpsDir}/$name');
    if (!await dir.exists()) return null;
    final data = await _loadMcp(dir.path, name);
    return data?.mcp;
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
