import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/bigmodel/mcp_config.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

/// MCP 服务独立存储服务（Isar 后端，独立字段存储）
///
/// MCP 配置与会话/模型解耦，全局独立存储。
/// 不再使用 JSON 大对象，各字段独立存储。
class McpStorageService {
  // ── 工具方法 ──

  static String _argsToJson(List<String> args) => jsonEncode(args);

  static List<String> _jsonToArgs(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static String? _mapToJson(Map<String, String>? map) {
    if (map == null || map.isEmpty) return null;
    return jsonEncode(map);
  }

  static Map<String, String>? _jsonToMap(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return null;
    }
  }

  static String? _toolsToJson(List<McpToolInfo>? tools) {
    if (tools == null || tools.isEmpty) return null;
    return jsonEncode(tools.map((t) => t.toJson()).toList());
  }

  static List<McpToolInfo>? _jsonToTools(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((t) => McpToolInfo.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // ── CRUD ──

  /// 从 Isar 加载所有 MCP 服务配置
  static Future<List<Mcp>> loadMcpServices() async {
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

  /// 保存所有 MCP 服务配置到 Isar
  static Future<void> saveMcpServices(List<Mcp> services) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        await isar.isarMcpServices.clear();
        for (final service in services) {
          await isar.isarMcpServices.put(_mcpToEntity(service));
        }
      });
      debugPrint('✅ 已保存 ${services.length} 个 MCP 服务');
    } catch (e) {
      debugPrint('❌ 保存 MCP 服务失败: $e');
    }
  }

  /// 添加一个 MCP 服务
  static Future<void> addMcpService(Mcp service) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(service.mcpId);
        if (existing != null) {
          // 更新已有记录
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

  /// 移除一个 MCP 服务
  static Future<void> removeMcpService(String mcpId) async {
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

  /// 更新一个 MCP 服务
  static Future<void> updateMcpService(
    String oldMcpId,
    Mcp newService,
  ) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices.getByMcpId(oldMcpId);
        if (existing != null) {
          // 如果 mcpId 有变化，先删除旧记录
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

  // ── 内部转换 ──

  static IsarMcpService _mcpToEntity(Mcp mcp) {
    return IsarMcpService()
      ..mcpId = mcp.mcpId
      ..name = mcp.name
      ..command = mcp.command
      ..argsJson = _argsToJson(mcp.args)
      ..envJson = _mapToJson(mcp.env)
      ..workingDirectory = mcp.workingDirectory
      ..timeout = mcp.timeout
      ..url = mcp.url
      ..headersJson = _mapToJson(mcp.headers)
      ..toolsJson = _toolsToJson(mcp.tools)
      ..lastUpdated = mcp.lastUpdated;
  }

  static Mcp _entityToMcp(IsarMcpService entity) {
    return Mcp(
      mcpId: entity.mcpId,
      name: entity.name,
      command: entity.command,
      args: _jsonToArgs(entity.argsJson),
      env: _jsonToMap(entity.envJson),
      workingDirectory: entity.workingDirectory,
      timeout: entity.timeout,
      url: entity.url,
      headers: _jsonToMap(entity.headersJson),
      tools: _jsonToTools(entity.toolsJson),
      lastUpdated: entity.lastUpdated,
    );
  }
}
