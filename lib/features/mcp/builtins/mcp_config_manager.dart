import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../../data/storage_paths.dart';

/// MCP 配置文件管理器
///
/// 存储结构: ~/.llmwork/mcps/{name}/
///   ├── config.yaml    # MCP 配置
///   └── {name}         # 可执行文件（可选）
class McpFolderManager {
  /// 获取所有已安装的 MCP 配置
  static Future<List<McpFolderConfig>> loadAll() async {
    final mcpsDir = Directory(StoragePaths.mcpsDir);
    if (!await mcpsDir.exists()) return [];

    final configs = <McpFolderConfig>[];
    await for (final entity in mcpsDir.list()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        final configFile = File('${entity.path}/config.yaml');
        if (await configFile.exists()) {
          try {
            final content = await configFile.readAsString();
            final config = McpFolderConfig.fromYaml(content, name);
            config.directory = entity.path;
            configs.add(config);
          } catch (e) {
            debugPrint('⚠️ 加载 MCP 配置失败: $name, $e');
          }
        }
      }
    }
    return configs;
  }

  /// 保存 MCP 配置
  static Future<void> save(McpFolderConfig config) async {
    final dir = Directory('${StoragePaths.mcpsDir}/${config.name}');
    await dir.create(recursive: true);

    final file = File('${dir.path}/config.yaml');
    await file.writeAsString(config.toYaml());
  }

  /// 删除 MCP 配置及其文件
  static Future<void> delete(String name) async {
    final dir = Directory('${StoragePaths.mcpsDir}/$name');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  /// 检查 MCP 是否已安装
  static Future<bool> exists(String name) async {
    final dir = Directory('${StoragePaths.mcpsDir}/$name');
    return dir.exists();
  }

  /// 获取可执行文件路径
  static String getExecutablePath(String name) {
    final dirPath = '${StoragePaths.mcpsDir}/$name';
    return '$dirPath/$name';
  }
}

/// MCP 配置（文件夹结构）
class McpFolderConfig {
  final String name;
  String? description;
  String? command;
  List<String>? args;
  Map<String, String>? env;
  String? workingDirectory;
  String? directory;

  McpFolderConfig({
    required this.name,
    this.description,
    this.command,
    this.args,
    this.env,
    this.workingDirectory,
    this.directory,
  });

  /// 从 YAML 字符串解析
  factory McpFolderConfig.fromYaml(String yaml, String name) {
    final lines = yaml.split('\n');
    final config = McpFolderConfig(name: name);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex == -1) continue;

      final key = trimmed.substring(0, colonIndex).trim();
      final value = trimmed.substring(colonIndex + 1).trim();

      switch (key) {
        case 'description':
          config.description = value;
          break;
        case 'command':
          // 将相对路径转为绝对路径
          if (value.startsWith('./')) {
            final dirPath = '${StoragePaths.mcpsDir}/$name';
            config.command = '$dirPath/${value.substring(2)}';
          } else {
            config.command = value;
          }
          break;
        case 'workingDirectory':
          config.workingDirectory = value;
          break;
      }
    }

    // 解析 args（多行）
    final argsIndex = yaml.indexOf('args:');
    if (argsIndex != -1) {
      final argsSection = yaml.substring(argsIndex);
      final argsMatches = RegExp(r'-\s+"?([^"\n]+)"?').allMatches(argsSection);
      config.args = argsMatches.map((m) => m.group(1)!).toList();
    }

    // 解析 env（多行）
    final envIndex = yaml.indexOf('env:');
    if (envIndex != -1) {
      final envSection = yaml.substring(envIndex);
      final envMatches = RegExp(r'(\w+):\s+"?([^"\n]+)"?').allMatches(envSection);
      config.env = {};
      for (final match in envMatches) {
        config.env![match.group(1)!] = match.group(2)!;
      }
    }

    return config;
  }

  /// 转换为 YAML 字符串
  String toYaml() {
    final buffer = StringBuffer();
    buffer.writeln('# MCP 配置文件');
    buffer.writeln('name: $name');
    if (description != null) buffer.writeln('description: "$description"');
    if (command != null) buffer.writeln('command: $command');
    if (args != null && args!.isNotEmpty) {
      buffer.writeln('args:');
      for (final arg in args!) {
        buffer.writeln('  - "$arg"');
      }
    }
    if (env != null && env!.isNotEmpty) {
      buffer.writeln('env:');
      for (final entry in env!.entries) {
        buffer.writeln('  ${entry.key}: "${entry.value}"');
      }
    }
    if (workingDirectory != null) buffer.writeln('workingDirectory: $workingDirectory');
    return buffer.toString();
  }

  /// 转换为 Mcp 模型需要的 code JSON
  String toCodeJson() {
    return jsonEncode({
      if (command != null) 'command': command,
      if (args != null) 'args': args,
      if (env != null) 'env': env,
      if (workingDirectory != null) 'workingDirectory': workingDirectory,
    });
  }
}
