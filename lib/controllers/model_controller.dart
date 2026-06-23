import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/bigmodel/chat_model.dart';
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

  // ========== 模型持久化存储操作 ==========

  /// 保存所有模型数据
  Future<void> saveModels() async {
    try {
      final store = IsarService.instance.store;
      final modelsData = models.map((m) => m.toMap()).toList();
      await store.isarChatModels.putAll(modelsData);
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 加载所有模型数据
  Future<List<Map<String, dynamic>>> loadModels() async {
    try {
      final store = IsarService.instance.store;
      return await store.isarChatModels.findAll();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      return [];
    }
  }

  /// 保存指定的模型列表数据
  Future<void> saveModelsData(List<Map<String, dynamic>> modelsData) async {
    try {
      final store = IsarService.instance.store;
      await store.isarChatModels.putAll(modelsData);
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 根据 modelId 删除单个模型
  Future<void> deleteModelById(String modelId) async {
    try {
      final store = IsarService.instance.store;
      await store.isarChatModels.delete(modelId);
    } catch (e) {
      debugPrint('从存储删除模型失败: $e');
    }
  }

  /// 清除所有模型数据
  Future<void> clearAllModels() async {
    try {
      final store = IsarService.instance.store;
      await store.isarChatModels.clear();
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
}
