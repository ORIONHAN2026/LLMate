import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

/// 内置 MCP 工具定义
class BuiltinMcpTool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final bool isRemote;
  final String? command;
  final List<String>? args;

  const BuiltinMcpTool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.isRemote = false,
    this.command,
    this.args,
  });
}

/// 内置 MCP 工具注册表
class BuiltinMcpRegistry {
  static String _projectRoot = '';

  static void setProjectRoot(String root) {
    _projectRoot = root;
  }

  /// 获取服务器脚本目录
  static String get _serversDir {
    // 开发模式：直接使用源码目录
    if (_projectRoot.isNotEmpty) {
      return '$_projectRoot/lib/mcp_builtins/servers';
    }
    // 打包后：使用可执行文件所在目录
    return p.join(
      p.dirname(Platform.resolvedExecutable),
      'data',
      'mcp_servers',
    );
  }

  static List<BuiltinMcpTool> get tools => [
    BuiltinMcpTool(
      id: 'filesystem',
      name: '文件系统',
      description: '文件系统访问服务，读取、写入和管理本地文件',
      icon: CupertinoIcons.folder_fill,
      color: const Color(0xFFFF9800),
      category: '文件系统',
      command: 'dart',
      args: ['${_serversDir}/filesystem_server.dart'],
    ),
    BuiltinMcpTool(
      id: 'git',
      name: 'Git',
      description: 'Git 仓库操作，支持状态查看、提交、分支管理',
      icon: CupertinoIcons.device_laptop,
      color: const Color(0xFFF05032),
      category: '开发工具',
      command: 'dart',
      args: ['${_serversDir}/git_server.dart'],
    ),
    BuiltinMcpTool(
      id: 'shell',
      name: 'Shell',
      description: '执行任意 shell 命令和脚本',
      icon: CupertinoIcons.chevron_left_slash_chevron_right,
      color: const Color(0xFF4EAA25),
      category: '开发工具',
      command: 'dart',
      args: ['${_serversDir}/shell_server.dart'],
    ),
    BuiltinMcpTool(
      id: 'fetch',
      name: 'Fetch',
      description: '获取网页内容和 JSON API 数据',
      icon: CupertinoIcons.globe,
      color: const Color(0xFF2196F3),
      category: '网络工具',
      command: 'dart',
      args: ['${_serversDir}/fetch_server.dart'],
    ),
    BuiltinMcpTool(
      id: 'sqlite',
      name: 'SQLite',
      description: 'SQLite 数据库操作，支持查询、修改、导出',
      icon: CupertinoIcons.square_stack_3d_down_right_fill,
      color: const Color(0xFF003B57),
      category: '数据库',
      command: 'dart',
      args: ['${_serversDir}/sqlite_server.dart'],
    ),
    BuiltinMcpTool(
      id: 'writepage',
      name: 'WritePage',
      description: '将 Markdown 内容生成可访问的网页链接',
      icon: CupertinoIcons.doc_text,
      color: const Color(0xFF9C27B0),
      category: '内容生成',
      isRemote: true,
    ),
  ];

  static List<BuiltinMcpTool> get localTools =>
      tools.where((t) => !t.isRemote).toList();

  static List<BuiltinMcpTool> get remoteTools =>
      tools.where((t) => t.isRemote).toList();

  static Map<String, List<BuiltinMcpTool>> get toolsByCategory {
    final map = <String, List<BuiltinMcpTool>>{};
    for (final tool in tools) {
      map.putIfAbsent(tool.category, () => []).add(tool);
    }
    return map;
  }

  static BuiltinMcpTool? getById(String id) {
    try {
      return tools.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
