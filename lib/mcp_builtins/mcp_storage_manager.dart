import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../storage/storage_paths.dart';

/// MCP 存储结构管理器
///
/// 目录结构: ~/.llmwork/mcps/{mcp_name}/
///   ├── server.json     # MCP 脚本配置（command/args/env 等）
///   └── config.json     # MCP 元信息（name/description/tools 等）
class McpStorageManager {
  /// 获取所有已安装的 MCP
  static Future<List<McpData>> loadAll() async {
    final mcpsDir = Directory(StoragePaths.mcpsDir);
    if (!await mcpsDir.exists()) return [];

    final list = <McpData>[];
    await for (final entity in mcpsDir.list()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        final data = await _loadMcp(entity.path, name);
        if (data != null) list.add(data);
      }
    }
    return list;
  }

  /// 加载单个 MCP
  static Future<McpData?> _loadMcp(String dirPath, String name) async {
    final serverFile = File('$dirPath/server.json');
    final configFile = File('$dirPath/config.json');

    if (!await serverFile.exists()) return null;

    try {
      final serverJson = jsonDecode(await serverFile.readAsString());
      final configJson = await configFile.exists()
          ? jsonDecode(await configFile.readAsString())
          : {};

      return McpData(
        name: name,
        server: serverJson,
        config: configJson,
        directory: dirPath,
      );
    } catch (e) {
      debugPrint('⚠️ 加载 MCP 失败: $name, $e');
      return null;
    }
  }

  /// 保存 MCP
  static Future<void> save(McpData mcp) async {
    final dir = Directory('${StoragePaths.mcpsDir}/${mcp.name}');
    await dir.create(recursive: true);

    // 保存 server.json
    final serverFile = File('${dir.path}/server.json');
    await serverFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(mcp.server),
    );

    // 保存 config.json
    final configFile = File('${dir.path}/config.json');
    await configFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(mcp.config),
    );
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
}

/// MCP 数据
class McpData {
  final String name;
  final Map<String, dynamic> server; // server.json 内容
  final Map<String, dynamic> config; // config.json 内容
  final String? directory;

  McpData({
    required this.name,
    required this.server,
    required this.config,
    this.directory,
  });

  /// 获取描述
  String? get description => config['description'] as String?;

  /// 获取工具列表
  List<Map<String, dynamic>> get tools {
    final tools = config['tools'] as List?;
    return tools?.cast<Map<String, dynamic>>() ?? [];
  }

  /// 获取 command
  String? get command {
    // 从 mcpServers 中提取
    final mcpServers = server['mcpServers'] as Map<String, dynamic>?;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      final firstServer = mcpServers.values.first as Map<String, dynamic>;
      return firstServer['command'] as String?;
    }
    return server['command'] as String?;
  }

  /// 获取 args
  List<String>? get args {
    final mcpServers = server['mcpServers'] as Map<String, dynamic>?;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      final firstServer = mcpServers.values.first as Map<String, dynamic>;
      final argsList = firstServer['args'] as List?;
      return argsList?.cast<String>();
    }
    final argsList = server['args'] as List?;
    return argsList?.cast<String>();
  }

  /// 获取环境变量
  Map<String, String>? get env {
    final mcpServers = server['mcpServers'] as Map<String, dynamic>?;
    if (mcpServers != null && mcpServers.isNotEmpty) {
      final firstServer = mcpServers.values.first as Map<String, dynamic>;
      final envMap = firstServer['env'] as Map<String, dynamic>?;
      return envMap?.map((k, v) => MapEntry(k, v.toString()));
    }
    final envMap = server['env'] as Map<String, dynamic>?;
    return envMap?.map((k, v) => MapEntry(k, v.toString()));
  }

  /// 更新工具列表
  void updateTools(List<Map<String, dynamic>> newTools) {
    config['tools'] = newTools;
    config['lastUpdated'] = DateTime.now().toIso8601String();
  }

  /// 转换为 Mcp 模型需要的格式
  Map<String, dynamic> toMcpMap() {
    return {
      'mcpId': 'mcp_$name',
      'name': name,
      'description': description,
      'code': jsonEncode(server),
      'command': command,
      'args': args,
      'env': env,
    };
  }
}
