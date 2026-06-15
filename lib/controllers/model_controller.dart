import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/bigmodel/chat_model.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

class ModelController extends GetxController {
  var models = <ChatModel>[].obs;
  var selectedModel = ''.obs;
  var apiUrl = ''.obs;

  void setModels(List<ChatModel> newModels) {
    models.value = newModels;
    if (newModels.isNotEmpty && selectedModel.isEmpty) {
      selectedModel.value = newModels.first.name;
    }
  }

  void setSelectedModel(String modelName) {
    selectedModel.value = modelName;
  }

  void setApiUrl(String url) {
    apiUrl.value = url;
  }

  // ========== 模型持久化存储操作（原 ModelStorageService） ==========

  /// 保存所有模型数据到 Isar
  Future<void> saveModels() async {
    try {
      final isar = IsarService.instance.isar;
      final isarModels =
          models.map((model) => _mapToIsar(model.toMap())).toList();

      await isar.writeTxn(() async {
        await isar.isarChatModels.clear();
        await isar.isarChatModels.putAll(isarModels);
      });
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 从 Isar 加载所有模型数据
  Future<List<Map<String, dynamic>>> loadModels() async {
    try {
      final isar = IsarService.instance.isar;
      final isarModels =
          await isar.isarChatModels.buildQuery<IsarChatModel>().findAll();
      return isarModels.map((m) => _isarToMap(m)).toList();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      return [];
    }
  }

  /// 保存指定的模型列表数据到 Isar
  Future<void> saveModelsData(List<Map<String, dynamic>> modelsData) async {
    try {
      final isar = IsarService.instance.isar;
      final isarModels = modelsData.map((map) => _mapToIsar(map)).toList();

      await isar.writeTxn(() async {
        await isar.isarChatModels.clear();
        await isar.isarChatModels.putAll(isarModels);
      });
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 根据 modelId 从 Isar 删除单个模型
  Future<void> deleteModelById(String modelId) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final entity = await isar.isarChatModels.getByModelId(modelId);
        if (entity != null) {
          await isar.isarChatModels.delete(entity.id);
        }
      });
    } catch (e) {
      debugPrint('从 Isar 删除模型失败: $e');
    }
  }

  /// 清除所有模型数据
  Future<void> clearAllModels() async {
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
  bool isModelNameExists(String name, {String? excludeId}) {
    return models.any(
      (model) =>
          model.name.toLowerCase() == name.toLowerCase() &&
          (excludeId == null || model.modelId != excludeId),
    );
  }

  /// 根据 ID 获取模型
  ChatModel? getModelById(String id) {
    final index = models.indexWhere((model) => model.modelId == id);
    return index >= 0 ? models[index] : null;
  }

  // ========== 内部转换方法 ==========

  static IsarChatModel _mapToIsar(Map<String, dynamic> map) {
    return IsarChatModel()
      ..modelId = (map['modelId'] as String?) ?? ''
      ..name = (map['name'] as String?) ?? ''
      ..model = (map['model'] as String?) ?? (map['fullName'] as String?) ?? ''
      ..type = map['type'] as String?
      ..platform = map['platform'] as String?
      ..protocol = map['protocol'] as String?
      ..apiKey = map['apiKey'] as String?
      ..apiUrl = map['apiUrl'] as String?
      ..createdAt = map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null
      ..updatedAt = map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null
      ..chatSettingsJson =
          map['chatSettings'] != null ? jsonEncode(map['chatSettings']) : null
      ..mcpServicesJson =
          map['mcpServices'] != null ? jsonEncode(map['mcpServices']) : null
      ..chatCommandsJson =
          map['chatCommands'] != null ? jsonEncode(map['chatCommands']) : null
      ..skillsJson = map['skills'] != null ? jsonEncode(map['skills']) : null;
  }

  static dynamic _tryJsonDecode(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      debugPrint('JSON 解码失败，忽略: $jsonStr');
      return null;
    }
  }

  static Map<String, dynamic> _isarToMap(IsarChatModel m) {
    return {
      'modelId': m.modelId,
      'name': m.name,
      'model': m.model,
      'fullName': m.model, // 兼容旧 key
      if (m.type != null) 'type': m.type,
      if (m.platform != null) 'platform': m.platform,
      if (m.protocol != null) 'protocol': m.protocol,
      if (m.apiKey != null) 'apiKey': m.apiKey,
      if (m.apiUrl != null) 'apiUrl': m.apiUrl,
      if (m.createdAt != null) 'createdAt': m.createdAt!.toIso8601String(),
      if (m.updatedAt != null) 'updatedAt': m.updatedAt!.toIso8601String(),
      if (m.chatSettingsJson != null)
        'chatSettings': _tryJsonDecode(m.chatSettingsJson!),
      if (m.mcpServicesJson != null)
        'mcpServices': _tryJsonDecode(m.mcpServicesJson!),
      if (m.chatCommandsJson != null)
        'chatCommands': _tryJsonDecode(m.chatCommandsJson!),
      if (m.skillsJson != null) 'skills': _tryJsonDecode(m.skillsJson!),
    };
  }
}
