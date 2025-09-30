import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 模型本地持久化存储服务
class ModelStorageService {
  static const String _modelsKey = 'ai_models';

  /// 保存所有模型数据
  static Future<void> saveModels(List<Map<String, dynamic>> models) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(models);
      final result = await prefs.setString(_modelsKey, jsonString);
      if (result != true) {
        print('保存模型失败: setString 返回 $result');
      }
    } catch (e) {
      print('保存模型失败: $e');
    }
  }

  /// 加载所有模型数据
  static Future<List<Map<String, dynamic>>> loadModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_modelsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('加载模型失败: $e');
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
      models.removeAt(index);
      await saveModels(models);
    }
  }

  /// 根据ID查找模型索引
  static int findModelIndexById(List<Map<String, dynamic>> models, String id) {
    return models.indexWhere((model) => model['id'] == id);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_modelsKey);
    } catch (e) {
      print('清除模型数据失败: $e');
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
          (excludeId == null || model['id'] != excludeId),
    );
  }

  /// 生成唯一的模型ID
  static String generateModelId() {
    return 'model_${DateTime.now().millisecondsSinceEpoch}';
  }
}
