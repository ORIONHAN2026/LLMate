import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/chat/mcp_config.dart';
import '../storage/isar_service.dart';

/// MCP 服务配置全局控制器
///
/// 管理 MCP 配置列表（全局、与会话独立），负责加载/保存/查询。
/// 运行时连接管理仍由 [McpService] 负责。
class McpController extends GetxController {
  /// 所有 MCP 配置（全局）
  var configs = <Mcp>[].obs;

  /// 是否已从存储加载
  bool _loaded = false;

  /// 确保已加载
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadAll();
  }

  /// 从存储加载所有 MCP 配置
  Future<void> loadAll() async {
    configs.value = await _loadMcpServices();
    _loaded = true;
    debugPrint('📦 McpController: 已加载 ${configs.length} 个 MCP 服务');
  }

  /// 按名称查找 MCP 配置
  Mcp? getMcpByName(String name) {
    for (final c in configs) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// 按 mcpId 查找 MCP 配置
  Mcp? getMcpById(String mcpId) {
    for (final c in configs) {
      if (c.mcpId == mcpId) return c;
    }
    return null;
  }

  /// 是否有任何 MCP 服务
  bool get hasServices => configs.isNotEmpty;

  /// 添加 MCP 服务
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

  /// 移除 MCP 服务
  Future<void> removeService(String mcpId) async {
    if (mcpId.isEmpty) {
      debugPrint('⚠️ removeService: mcpId 为空，跳过删除');
      return;
    }
    configs.removeWhere((c) => c.mcpId == mcpId);
    await _removeMcpService(mcpId);
  }

  /// 更新 MCP 服务
  Future<void> updateService(String oldMcpId, Mcp newService) async {
    final idx = configs.indexWhere((c) => c.mcpId == oldMcpId);
    if (idx != -1) {
      configs[idx] = newService;
    }
    await _updateMcpService(oldMcpId, newService);
  }

  // ── 文件存储内部方法 ──

  /// Mcp → Map（用于 JSON 序列化）
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

  /// Map → Mcp
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
      env: map['env'] != null
          ? Map<String, String>.from(map['env'] as Map)
          : null,
      workingDirectory: map['workingDirectory'] as String?,
      timeout: map['timeout'] as int?,
      url: map['url'] as String?,
      headers: map['headers'] != null
          ? Map<String, String>.from(map['headers'] as Map)
          : null,
      body: map['body'] != null
          ? Map<String, dynamic>.from(map['body'] as Map)
          : null,
      type: McpTransportTypeExt.fromString(map['type'] as String?),
      version: map['version'] as String?,
      tools: (map['tools'] as List<dynamic>?)
          ?.map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>))
          .toList(),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String)
          : null,
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
