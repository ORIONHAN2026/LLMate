import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bigmodel/mcp_config.dart';

/// MCP 服务独立存储服务
///
/// MCP 配置与会话/模型解耦，全局独立存储。
class McpStorageService {
  static const String _storageKey = 'mcp_services';

  /// 从 SharedPreferences 加载所有 MCP 服务配置
  static Future<List<McpServerConfig>> loadMcpServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .whereType<Map<String, dynamic>>()
          .map((map) {
            final name = map['name'] as String? ?? '';
            return McpServerConfig.fromJson(name, map);
          })
          .toList();
    } catch (e) {
      debugPrint('❌ 加载 MCP 服务失败: $e');
      return [];
    }
  }

  /// 保存所有 MCP 服务配置到 SharedPreferences
  static Future<void> saveMcpServices(List<McpServerConfig> services) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = services.map((service) {
        final json = service.toJson();
        json['name'] = service.name;
        return json;
      }).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      debugPrint('✅ 已保存 ${services.length} 个 MCP 服务');
    } catch (e) {
      debugPrint('❌ 保存 MCP 服务失败: $e');
    }
  }

  /// 添加一个 MCP 服务
  static Future<void> addMcpService(McpServerConfig service) async {
    final services = await loadMcpServices();
    // 检查是否已存在同名服务
    final existingIndex = services.indexWhere((s) => s.name == service.name);
    if (existingIndex != -1) {
      services[existingIndex] = service; // 更新
    } else {
      services.add(service);
    }
    await saveMcpServices(services);
  }

  /// 移除一个 MCP 服务
  static Future<void> removeMcpService(String serviceName) async {
    final services = await loadMcpServices();
    services.removeWhere((s) => s.name == serviceName);
    await saveMcpServices(services);
  }

  /// 更新一个 MCP 服务
  static Future<void> updateMcpService(
    String serviceName,
    McpServerConfig newService,
  ) async {
    final services = await loadMcpServices();
    final index = services.indexWhere((s) => s.name == serviceName);
    if (index != -1) {
      services[index] = newService;
      await saveMcpServices(services);
    }
  }
}
