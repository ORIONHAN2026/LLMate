import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/bigmodel/mcp_config.dart';
import '../services/mcp_storage_service.dart';

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
    configs.value = await McpStorageService.loadMcpServices();
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
      // 更新已有
      final idx = configs.indexWhere((c) => c.mcpId == service.mcpId);
      if (idx != -1) configs[idx] = service;
    } else {
      configs.add(service);
    }
    await McpStorageService.addMcpService(service);
  }

  /// 移除 MCP 服务
  Future<void> removeService(String mcpId) async {
    configs.removeWhere((c) => c.mcpId == mcpId);
    await McpStorageService.removeMcpService(mcpId);
  }

  /// 更新 MCP 服务
  Future<void> updateService(String oldMcpId, Mcp newService) async {
    final idx = configs.indexWhere((c) => c.mcpId == oldMcpId);
    if (idx != -1) {
      configs[idx] = newService;
    }
    await McpStorageService.updateMcpService(oldMcpId, newService);
  }
}
