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

  // ── Isar 存储内部方法 ──

  /// Mcp → IsarMcpService
  static IsarMcpService _mcpToEntity(Mcp mcp) {
    return IsarMcpService()
      ..mcpId = mcp.mcpId
      ..name = mcp.name
      ..description = mcp.description
      ..code = mcp.code
      ..command = mcp.command
      ..args = mcp.args
      ..env = mcp.env != null && mcp.env!.isNotEmpty
          ? jsonEncode(mcp.env)
          : null
      ..workingDirectory = mcp.workingDirectory
      ..timeout = mcp.timeout
      ..url = mcp.url
      ..headers = mcp.headers != null && mcp.headers!.isNotEmpty
          ? jsonEncode(mcp.headers)
          : null
      ..body = mcp.body != null && mcp.body!.isNotEmpty
          ? jsonEncode(mcp.body)
          : null
      ..type = mcp.type?.value
      ..version = mcp.version
      ..tools = mcp.tools != null && mcp.tools!.isNotEmpty
          ? jsonEncode(mcp.tools!.map((t) => t.toJson()).toList())
          : null
      ..lastUpdated = mcp.lastUpdated
      ..prompt = mcp.prompt;
  }

  /// IsarMcpService → Mcp
  static Mcp _entityToMcp(IsarMcpService entity) {
    List<McpToolInfo>? tools;
    if (entity.tools != null && entity.tools!.isNotEmpty) {
      try {
        final list = jsonDecode(entity.tools!) as List<dynamic>;
        tools = list
            .map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('⚠️ 解析 tools 失败: $e');
      }
    }

    Map<String, String>? env;
    if (entity.env != null && entity.env!.isNotEmpty) {
      try {
        env = Map<String, String>.from(jsonDecode(entity.env!) as Map);
      } catch (_) {}
    }

    Map<String, String>? headers;
    if (entity.headers != null && entity.headers!.isNotEmpty) {
      try {
        headers = Map<String, String>.from(jsonDecode(entity.headers!) as Map);
      } catch (_) {}
    }

    Map<String, dynamic>? body;
    if (entity.body != null && entity.body!.isNotEmpty) {
      try {
        body = Map<String, dynamic>.from(jsonDecode(entity.body!) as Map);
      } catch (_) {}
    }

    return Mcp(
      mcpId: entity.mcpId.isNotEmpty ? entity.mcpId : 'mcp_unknown',
      name: entity.name.isNotEmpty ? entity.name : entity.mcpId,
      description: entity.description,
      code: entity.code ?? jsonEncode({
        'mcpId': entity.mcpId,
        'name': entity.name,
        'command': entity.command,
        'url': entity.url,
      }),
      args: entity.args,
      env: env,
      workingDirectory: entity.workingDirectory,
      timeout: entity.timeout,
      url: entity.url,
      headers: headers,
      body: body,
      type: McpTransportTypeExt.fromString(entity.type),
      version: entity.version,
      tools: tools,
      lastUpdated: entity.lastUpdated,
      prompt: entity.prompt,
    );
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
    if (mcpId.isEmpty) {
      debugPrint('⚠️ _removeMcpService: mcpId 为空，跳过删除');
      return;
    }
    final isar = IsarService.instance.isar;
    await isar.writeTxn(() async {
      final existing = await isar.isarMcpServices.getByMcpId(mcpId);
      if (existing != null) {
        await isar.isarMcpServices.delete(existing.id);
      }
    });
  }

  static Future<void> _updateMcpService(String oldMcpId, Mcp newService) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(oldMcpId);
        final entity = _mcpToEntity(newService);
        if (existing != null) {
          if (oldMcpId != newService.mcpId) {
            await isar.isarMcpServices.delete(existing.id);
          } else {
            entity.id = existing.id;
          }
        }
        await isar.isarMcpServices.put(entity);
      });
    } catch (e) {
      debugPrint('❌ 更新 MCP 服务失败: $e');
    }
  }
}
