import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

/// 模型本地持久化存储服务（Isar 后端）
class ModelStorageService {

  /// 保存所有模型数据
  static Future<void> saveModels(List<Map<String, dynamic>> models) async {
    try {
      final isar = IsarService.instance.isar;
      final isarModels = models.map((map) => _mapToIsar(map)).toList();

      await isar.writeTxn(() async {
        // 清除旧数据
        await isar.isarChatModels.clear();
        // 写入新数据
        await isar.isarChatModels.putAll(isarModels);
      });
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 加载所有模型数据
  static Future<List<Map<String, dynamic>>> loadModels() async {
    try {
      final isar = IsarService.instance.isar;
      final isarModels = await isar.isarChatModels.buildQuery<IsarChatModel>().findAll();
      return isarModels.map((m) => _isarToMap(m)).toList();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      return [];
    }
  }

  /// 添加新模型并保存
  static Future<void> addModel(
    List<Map<String, dynamic>> models,
    Map<String, dynamic> newModel,
  ) async {
    models.add(newModel);
    await saveModels(models);
  }

  /// 更新模型并保存
  static Future<void> updateModel(
    List<Map<String, dynamic>> models,
    int index,
    Map<String, dynamic> updatedModel,
  ) async {
    if (index >= 0 && index < models.length) {
      models[index] = updatedModel;
      await saveModels(models);
    }
  }

  /// 删除模型并保存
  static Future<void> deleteModel(
    List<Map<String, dynamic>> models,
    int index,
  ) async {
    if (index >= 0 && index < models.length) {
      final modelId = models[index]['modelId'] as String?;
      try {
        final isar = IsarService.instance.isar;
        await isar.writeTxn(() async {
          final entity = await isar.isarChatModels
              .getByModelId(modelId ?? '');
          if (entity != null) {
            await isar.isarChatModels.delete(entity.id);
          }
        });
      } catch (e) {
        debugPrint('从 Isar 删除模型失败: $e');
      }
      models.removeAt(index);
    }
  }

  /// 根据ID查找模型索引
  static int findModelIndexById(List<Map<String, dynamic>> models, String id) {
    return models.indexWhere((model) => model['modelId'] == id);
  }

  /// 根据ID获取模型
  static Map<String, dynamic>? getModelById(
    List<Map<String, dynamic>> models,
    String id,
  ) {
    final index = findModelIndexById(models, id);
    return index >= 0 ? models[index] : null;
  }

  /// 清除所有模型数据
  static Future<void> clearAllModels() async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        await isar.isarChatModels.clear();
      });
    } catch (e) {
      debugPrint('清除模型数据失败: $e');
    }
  }

  /// 检查模型名称是否已存在
  static bool isModelNameExists(
    List<Map<String, dynamic>> models,
    String name, {
    String? excludeId,
  }) {
    return models.any(
      (model) =>
          (model['name'] as String).toLowerCase() == name.toLowerCase() &&
          (excludeId == null || model['modelId'] != excludeId),
    );
  }

  /// 生成唯一的模型ID
  static String generateModelId() {
    return 'model_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ========== 内部转换方法 ==========

  static IsarChatModel _mapToIsar(Map<String, dynamic> map) {
    return IsarChatModel()
      ..modelId = (map['modelId'] as String?) ?? ''
      ..name = (map['name'] as String?) ?? ''
      ..model = (map['model'] as String?) ?? (map['fullName'] as String?) ?? ''
      ..status = (map['status'] as String?) ?? 'inactive'
      ..type = map['type'] as String?
      ..provider = map['provider'] as String?
      ..platform = map['platform'] as String?
      ..apiKey = map['apiKey'] as String?
      ..apiUrl = map['apiUrl'] as String?
      ..createdAt = map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null
      ..description = map['description'] as String?
      ..chatSettingsJson =
          map['chatSettings'] != null ? jsonEncode(map['chatSettings']) : null
      ..mcpServicesJson =
          map['mcpServices'] != null ? jsonEncode(map['mcpServices']) : null
      ..chatCommandsJson =
          map['chatCommands'] != null ? jsonEncode(map['chatCommands']) : null
      ..skillsJson = map['skills'] != null ? jsonEncode(map['skills']) : null;
  }

  static Map<String, dynamic> _isarToMap(IsarChatModel m) {
    return {
      'modelId': m.modelId,
      'name': m.name,
      'model': m.model,
      'fullName': m.model, // 兼容旧 key
      'status': m.status,
      if (m.type != null) 'type': m.type,
      if (m.provider != null) 'provider': m.provider,
      if (m.platform != null) 'platform': m.platform,
      if (m.apiKey != null) 'apiKey': m.apiKey,
      if (m.apiUrl != null) 'apiUrl': m.apiUrl,
      if (m.createdAt != null) 'createdAt': m.createdAt!.toIso8601String(),
      if (m.updatedAt != null) 'updatedAt': m.updatedAt!.toIso8601String(),
      if (m.description != null) 'description': m.description,
      if (m.chatSettingsJson != null)
        'chatSettings': jsonDecode(m.chatSettingsJson!),
      if (m.mcpServicesJson != null)
        'mcpServices': jsonDecode(m.mcpServicesJson!),
      if (m.chatCommandsJson != null)
        'chatCommands': jsonDecode(m.chatCommandsJson!),
      if (m.skillsJson != null) 'skills': jsonDecode(m.skillsJson!),
    };
  }
}
