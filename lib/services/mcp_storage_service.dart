import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/bigmodel/mcp_config.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

/// MCP 服务独立存储服务（Isar 后端）
///
/// MCP 配置与会话/模型解耦，全局独立存储。
class McpStorageService {

  /// 从 Isar 加载所有 MCP 服务配置
  static Future<List<McpServerConfig>> loadMcpServices() async {
    try {
      final isar = IsarService.instance.isar;
      final entities = await isar.isarMcpServices.buildQuery<IsarMcpService>().findAll();
      return entities.map((e) {
        final map = jsonDecode(e.configJson) as Map<String, dynamic>;
        return McpServerConfig.fromJson(e.name, map);
      }).toList();
    } catch (e) {
      debugPrint('❌ 加载 MCP 服务失败: $e');
      return [];
    }
  }

  /// 保存所有 MCP 服务配置到 Isar
  static Future<void> saveMcpServices(List<McpServerConfig> services) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        // 清除旧数据
        await isar.isarMcpServices.clear();
        // 写入新数据
        for (final service in services) {
          final json = service.toJson();
          json['name'] = service.name;
          await isar.isarMcpServices.put(IsarMcpService()
            ..name = service.name
            ..configJson = jsonEncode(json));
        }
      });
      debugPrint('✅ 已保存 ${services.length} 个 MCP 服务');
    } catch (e) {
      debugPrint('❌ 保存 MCP 服务失败: $e');
    }
  }

  /// 添加一个 MCP 服务
  static Future<void> addMcpService(McpServerConfig service) async {
    try {
      final isar = IsarService.instance.isar;
      final json = service.toJson();
      json['name'] = service.name;

      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices
            .getByName(service.name);
        if (existing != null) {
          existing.configJson = jsonEncode(json);
          await isar.isarMcpServices.put(existing);
        } else {
          await isar.isarMcpServices.put(IsarMcpService()
            ..name = service.name
            ..configJson = jsonEncode(json));
        }
      });
    } catch (e) {
      debugPrint('❌ 添加 MCP 服务失败: $e');
    }
  }

  /// 移除一个 MCP 服务
  static Future<void> removeMcpService(String serviceName) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices
            .getByName(serviceName);
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
    String serviceName,
    McpServerConfig newService,
  ) async {
    try {
      final isar = IsarService.instance.isar;
      final json = newService.toJson();
      json['name'] = newService.name;

      await isar.writeTxn(() async {
        final existing = await isar.isarMcpServices
            .getByName(serviceName);
        if (existing != null) {
          // 如果名称有变化，需要删除旧记录
          if (serviceName != newService.name) {
            await isar.isarMcpServices.delete(existing.id);
          }
          await isar.isarMcpServices.put(IsarMcpService()
            ..name = newService.name
            ..configJson = jsonEncode(json));
        }
      });
    } catch (e) {
      debugPrint('❌ 更新 MCP 服务失败: $e');
    }
  }
}
