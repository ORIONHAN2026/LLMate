import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/chat/mcp_config.dart';
import '../storage/isar_models.dart';
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

  // ── Isar 存储内部方法 ──

  static IsarMcpService _mcpToEntity(Mcp mcp) {
    return IsarMcpService()
      ..mcpId = mcp.mcpId
      ..content = jsonEncode(mcp.toFullJson());
  }

  static Mcp _entityToMcp(IsarMcpService entity) {
    try {
      return Mcp.fromContent(entity.content);
    } catch (e) {
      debugPrint('❌ 解析 MCP content 失败 (${entity.mcpId}): $e');
      return Mcp(
        mcpId: entity.mcpId,
        name: entity.mcpId,
        command: '',
        args: [],
      );
    }
  }

  static Future<List<Mcp>> _loadMcpServices() async {
    try {
      final isar = IsarService.instance.isar;
      final entities =
          await isar.isarMcpServices.buildQuery<IsarMcpService>().findAll();
      return entities.map((e) => _entityToMcp(e)).toList();
    } catch (e) {
      debugPrint('❌ 加载 MCP 服务失败: $e');
      return [];
    }
  }

  static Future<void> _addMcpService(Mcp service) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(service.mcpId);
        if (existing != null) {
          final updated = _mcpToEntity(service);
          updated.id = existing.id;
          await isar.isarMcpServices.put(updated);
        } else {
          await isar.isarMcpServices.put(_mcpToEntity(service));
        }
      });
    } catch (e) {
      debugPrint('❌ 添加 MCP 服务失败: $e');
    }
  }

  static Future<void> _removeMcpService(String mcpId) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(mcpId);
        if (existing != null) {
          await isar.isarMcpServices.delete(existing.id);
        }
      });
    } catch (e) {
      debugPrint('❌ 移除 MCP 服务失败: $e');
    }
  }

  static Future<void> _updateMcpService(String oldMcpId, Mcp newService) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(oldMcpId);
        if (existing != null) {
          if (oldMcpId != newService.mcpId) {
            await isar.isarMcpServices.delete(existing.id);
          }
          await isar.isarMcpServices.put(_mcpToEntity(newService));
        }
      });
    } catch (e) {
      debugPrint('❌ 更新 MCP 服务失败: $e');
    }
  }
}
