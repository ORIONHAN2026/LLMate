import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/chat/mcp_config.dart';
import '../storage/isar_service.dart';
import '../mcp_builtins/builtin_mcp_registry.dart';

/// MCP 服务配置全局控制器
class McpController extends GetxController {
  var configs = <Mcp>[].obs;
  bool _loaded = false;
  bool _builtinInitialized = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadAll();
  }

  Future<void> loadAll() async {
    // 获取应用支持目录，用于存放 MCP 服务器脚本
    final appDir = Directory(Platform.resolvedExecutable).parent.parent.path;
    final serversDir = '$appDir/data/mcp_servers';

    // 复制内置服务器脚本到应用目录
    await _copyBuiltinServers(serversDir);

    // 设置项目根目录
    BuiltinMcpRegistry.setProjectRoot(appDir);

    configs.value = await _loadMcpServices();
    _loaded = true;
    debugPrint('📦 McpController: 已加载 ${configs.length} 个 MCP 服务');

    if (!_builtinInitialized) {
      await _ensureBuiltinTools();
      _builtinInitialized = true;
    }
  }

  /// 复制内置服务器脚本到应用目录
  Future<void> _copyBuiltinServers(String targetDir) async {
    try {
      final target = Directory(targetDir);
      if (!await target.exists()) {
        await target.create(recursive: true);
      }

      // 服务器脚本列表
      final servers = [
        'filesystem_server.dart',
        'git_server.dart',
        'shell_server.dart',
        'fetch_server.dart',
        'sqlite_server.dart',
        'email_server.dart',
        'writepage_server.dart',
        'protocol.dart',
      ];

      // 尝试从包资源目录复制（打包后的路径）
      for (final server in servers) {
        final targetFile = File('$targetDir/$server');
        if (!await targetFile.exists()) {
          // 如果目标文件不存在，创建一个占位脚本
          // 实际打包时应该将脚本作为 assets 嵌入
          debugPrint('⚠️ 服务器脚本不存在: $server');
        }
      }
    } catch (e) {
      debugPrint('❌ 复制服务器脚本失败: $e');
    }
  }

  /// 自动安装所有内置工具
  Future<void> _ensureBuiltinTools() async {
    try {
      final allTools = BuiltinMcpRegistry.localTools;
      int addedCount = 0;

      for (final tool in allTools) {
        final existing = getMcpByName(tool.name);
        if (existing == null) {
          final code = jsonEncode({
            'command': tool.command,
            'args': tool.args,
          });

          final mcp = Mcp(
            mcpId: 'builtin_${tool.id}',
            name: tool.name,
            description: tool.description,
            code: code,
            command: tool.command,
            args: tool.args,
          );

          configs.add(mcp);
          await _addMcpService(mcp);
          addedCount++;
          debugPrint('🔧 已自动安装工具: ${tool.name}');
        }
      }

      if (addedCount > 0) {
        debugPrint('📦 McpController: 自动安装了 $addedCount 个工具');
      }
    } catch (e) {
      debugPrint('❌ 自动安装工具失败: $e');
    }
  }

  Mcp? getMcpByName(String name) {
    for (final c in configs) {
      if (c.name == name) return c;
    }
    return null;
  }

  Mcp? getMcpById(String mcpId) {
    for (final c in configs) {
      if (c.mcpId == mcpId) return c;
    }
    return null;
  }

  bool isBuiltin(String mcpId) {
    return mcpId.startsWith('builtin_');
  }

  bool isRemote(String mcpId) {
    return mcpId.startsWith('remote_');
  }

  bool get hasServices => configs.isNotEmpty;

  Future<void> addService(Mcp service) async {
    final existing = getMcpById(service.mcpId);
    if (existing != null) {
      final idx = configs.indexWhere((c) => c.mcpId == service.mcpId);
      if (idx != -1) configs[idx] = service;
    } else {
      configs.add(service);
    }
    await _addMcpService(service);
  }

  Future<void> removeService(String mcpId) async {
    if (mcpId.isEmpty) return;
    if (isBuiltin(mcpId)) {
      debugPrint('⚠️ 内置工具不允许移除: $mcpId');
      return;
    }
    configs.removeWhere((c) => c.mcpId == mcpId);
    await _removeMcpService(mcpId);
  }

  Future<void> updateService(String oldMcpId, Mcp newService) async {
    final idx = configs.indexWhere((c) => c.mcpId == oldMcpId);
    if (idx != -1) {
      configs[idx] = newService;
    }
    await _updateMcpService(oldMcpId, newService);
  }

  static Map<String, dynamic> _mcpToMap(Mcp mcp) {
    return {
      'mcpId': mcp.mcpId,
      'name': mcp.name,
      'description': mcp.description,
      'code': mcp.code,
      'command': mcp.command,
      'args': mcp.args,
      'env': mcp.env,
      'workingDirectory': mcp.workingDirectory,
      'timeout': mcp.timeout,
      'url': mcp.url,
      'headers': mcp.headers,
      'body': mcp.body,
      'type': mcp.type?.value,
      'version': mcp.version,
      'tools': mcp.tools?.map((t) => t.toJson()).toList(),
      'lastUpdated': mcp.lastUpdated?.toIso8601String(),
      'prompt': mcp.prompt,
    };
  }

  static Mcp _mapToMcp(Map<String, dynamic> map) {
    return Mcp(
      mcpId: (map['mcpId'] as String?)?.isNotEmpty == true
          ? map['mcpId'] as String
          : 'mcp_unknown',
      name: (map['name'] as String?)?.isNotEmpty == true
          ? map['name'] as String
          : (map['mcpId'] as String?) ?? 'unknown',
      description: map['description'] as String?,
      code: map['code'] as String? ?? '{}',
      command: map['command'] as String?,
      args: map['args'] != null ? List<String>.from(map['args']) : null,
      env: map['env'] != null ? Map<String, String>.from(map['env'] as Map) : null,
      workingDirectory: map['workingDirectory'] as String?,
      timeout: map['timeout'] as int?,
      url: map['url'] as String?,
      headers: map['headers'] != null ? Map<String, String>.from(map['headers'] as Map) : null,
      body: map['body'] != null ? Map<String, dynamic>.from(map['body'] as Map) : null,
      type: McpTransportTypeExt.fromString(map['type'] as String?),
      version: map['version'] as String?,
      tools: (map['tools'] as List<dynamic>?)?.map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>)).toList(),
      lastUpdated: map['lastUpdated'] != null ? DateTime.tryParse(map['lastUpdated'] as String) : null,
      prompt: map['prompt'] as String?,
    );
  }

  static Future<List<Mcp>> _loadMcpServices() async {
    try {
      final store = IsarService.instance.store;
      final entities = await store.isarMcpServices.findAll();
      return entities.map((e) => _mapToMcp(e)).toList();
    } catch (e) {
      debugPrint('❌ 加载 MCP 服务失败: $e');
      return [];
    }
  }

  static Future<void> _addMcpService(Mcp service) async {
    try {
      final store = IsarService.instance.store;
      await store.isarMcpServices.put(_mcpToMap(service));
    } catch (e) {
      debugPrint('❌ 添加 MCP 服务失败: $e');
    }
  }

  static Future<void> _removeMcpService(String mcpId) async {
    if (mcpId.isEmpty) return;
    try {
      final store = IsarService.instance.store;
      await store.isarMcpServices.delete(mcpId);
    } catch (e) {
      debugPrint('❌ 删除 MCP 服务失败: $e');
    }
  }

  static Future<void> _updateMcpService(String oldMcpId, Mcp newService) async {
    try {
      final store = IsarService.instance.store;
      if (oldMcpId != newService.mcpId) {
        await store.isarMcpServices.delete(oldMcpId);
      }
      await store.isarMcpServices.put(_mcpToMap(newService));
    } catch (e) {
      debugPrint('❌ 更新 MCP 服务失败: $e');
    }
  }
}
