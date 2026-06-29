import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../models/chat/mcp_config.dart';
import '../builtins/mcp_storage_manager.dart';

/// MCP 服务配置全局控制器
class McpController extends GetxController {
  var configs = <Mcp>[].obs;
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadAll();
  }

  Future<void> loadAll() async {
    final mcpDataList = await McpStorageManager.loadAll();

    configs.value = mcpDataList.map((data) {
      return Mcp(
        mcpId: 'mcp_${data.name}',
        name: data.name,
        description: data.description,
        code: data.server.isNotEmpty ? jsonEncode(data.server) : '{}',
        command: data.command,
        args: data.args,
        url: data.url,
        headers: data.headers,
        env: data.env,
      );
    }).toList();

    _loaded = true;
    debugPrint('📦 McpController: 已加载 ${configs.length} 个 MCP 服务');
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
    final name = mcpId.replaceFirst('mcp_', '');
    return ['filesystem', 'git', 'shell', 'fetch', 'sqlite'].contains(name);
  }

  bool get hasServices => configs.isNotEmpty;

  /// 添加 MCP（从 server.json 配置添加）
  Future<void> addService(Mcp service, {Map<String, dynamic>? serverJson}) async {
    final data = McpData(
      name: service.name,
      server: serverJson ?? {'command': service.command, 'args': service.args},
      config: {
        'name': service.name,
        'description': service.description,
        'tools': service.tools?.map((t) => t.toJson()).toList() ?? [],
      },
    );
    await McpStorageManager.save(data);

    final existing = getMcpById(service.mcpId);
    if (existing != null) {
      final idx = configs.indexWhere((c) => c.mcpId == service.mcpId);
      if (idx != -1) configs[idx] = service;
    } else {
      configs.add(service);
    }
  }

  /// 移除 MCP
  Future<void> removeService(String mcpId) async {
    if (mcpId.isEmpty) return;
    final name = mcpId.replaceFirst('mcp_', '');
    await McpStorageManager.delete(name);
    configs.removeWhere((c) => c.mcpId == mcpId);
  }

  /// 更新 MCP 配置
  Future<void> updateService(String mcpId, Mcp newService) async {
    final existingData = await _loadMcpData(mcpId);
    if (existingData != null) {
      existingData.config['name'] = newService.name;
      existingData.config['description'] = newService.description;
      if (newService.tools != null) {
        existingData.config['tools'] = newService.tools!.map((t) => t.toJson()).toList();
      }
      await McpStorageManager.save(existingData);
    }

    final idx = configs.indexWhere((c) => c.mcpId == mcpId);
    if (idx != -1) configs[idx] = newService;
  }

  /// 更新 MCP 脚本配置（server.json）
  Future<void> updateServerConfig(String mcpId, Map<String, dynamic> serverJson) async {
    final name = mcpId.replaceFirst('mcp_', '');
    final data = await McpStorageManager.loadAll().then(
      (list) => list.where((d) => d.name == name).firstOrNull,
    );
    if (data != null) {
      data.server.clear();
      data.server.addAll(serverJson);
      await McpStorageManager.save(data);
    }
  }

  Future<McpData?> _loadMcpData(String mcpId) async {
    final name = mcpId.replaceFirst('mcp_', '');
    final list = await McpStorageManager.loadAll();
    return list.where((d) => d.name == name).firstOrNull;
  }
}

/// 辅助扩展
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}
