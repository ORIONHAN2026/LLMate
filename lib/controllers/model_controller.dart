import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../../../models/bigmodel/chat_model.dart';
import '../../../data/file_storage.dart';
import '../../../data/storage_paths.dart';

class ModelController extends GetxController {
  var models = <ChatModel>[].obs;
  var selectedModel = ''.obs;
  var apiUrl = ''.obs;

  /// 模型数据库路径：~/.llmate/models.db
  static String get _dbPath => p.join(StoragePaths.root, 'models.db');

  /// sembast store 名称（每个 record 的 key 为 modelId）
  static const String _storeName = 'models';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;
  static bool _migrated = false;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    await _maybeMigrate(_db!);
    return _db!;
  }

  /// 一次性将旧版 models.json 中的模型迁移进 models.db
  ///
  /// 仅当数据库中尚不存在同名记录时写入，避免覆盖；旧文件保留作备份。
  Future<void> _maybeMigrate(Database db) async {
    if (_migrated) return;
    _migrated = true;
    try {
      final list = await FileStorage.readJsonList(StoragePaths.modelsFile);
      if (list == null || list.isEmpty) return;
      int migrated = 0;
      for (final m in list) {
        final map = m as Map<String, dynamic>;
        final id = map['modelId'] as String? ?? '';
        if (id.isEmpty) continue;
        final existing = await _store.record(id).get(db);
        if (existing == null) {
          await _store.record(id).put(db, map);
          migrated++;
        }
      }
      if (migrated > 0) {
        debugPrint('📦 [Model] 已迁移 $migrated 个旧模型至 models.db');
      }
    } catch (e) {
      debugPrint('⚠️ [Model] 迁移旧模型失败: $e');
    }
  }

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

  /// 保存所有模型数据（整体替换：写入当前列表，并清理 db 中已不在列表的旧模型）
  Future<void> saveModels() async {
    try {
      final db = await _database;
      final currentIds = models.map((m) => m.modelId).toSet();
      for (final m in models) {
        await _store.record(m.modelId).put(db, m.toMap());
      }
      // 清理已从列表中移除的旧模型，保持与旧 ModelStore.putAll（整体替换）一致
      final existing = await _store.find(db);
      for (final rec in existing) {
        final mid = (rec.value as Map<String, dynamic>)['modelId'] as String? ?? rec.key;
        if (!currentIds.contains(mid)) {
          await _store.record(mid).delete(db);
        }
      }
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 加载所有模型数据（从 models.db 读取）
  Future<List<Map<String, dynamic>>> loadModels() async {
    try {
      final db = await _database;
      final records = await _store.find(db);
      return records
          .map((r) => r.value as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      return [];
    }
  }

  /// 保存指定的模型列表数据（仅写入 models.db）
  Future<void> saveModelsData(List<Map<String, dynamic>> modelsData) async {
    try {
      final db = await _database;
      for (final m in modelsData) {
        final id = m['modelId'] as String? ?? '';
        if (id.isNotEmpty) {
          await _store.record(id).put(db, m);
        }
      }
    } catch (e) {
      debugPrint('保存模型失败: $e');
    }
  }

  /// 根据 modelId 删除单个模型
  Future<void> deleteModelById(String modelId) async {
    try {
      final db = await _database;
      await _store.record(modelId).delete(db);
    } catch (e) {
      debugPrint('从存储删除模型失败: $e');
    }
  }

  /// 清除所有模型数据
  Future<void> clearAllModels() async {
    try {
      final db = await _database;
      await _store.delete(db);
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

/// 模型图标工具
///
/// 根据平台名称、协议、模型名称等信息解析图标路径。
/// 优先级：platform > protocol > modelName
class ModelIconUtils {
  static String? resolveIconPath({
    String? platform,
    String? protocol,
    String? modelName,
  }) {
    if (platform != null) {
      final p = platform.toLowerCase();
      if (p.contains('deepseek')) {
        return 'assets/icons/deepseek-color.webp';
      }
      if (p.contains('openai') || p.contains('chatgpt')) {
        return 'assets/icons/openai.webp';
      }
      if (p.contains('gemini') || p.contains('google')) {
        return 'assets/icons/gemini-color.webp';
      }
      if (p.contains('claude') || p.contains('anthropic')) {
        return 'assets/icons/claude-color.webp';
      }
      if (p.contains('qwen') || p.contains('通义') || p.contains('百炼') || p.contains('阿里')) {
        return 'assets/icons/qwen-color.webp';
      }
      if (p.contains('hunyuan') || p.contains('混元') || p.contains('腾讯')) {
        return 'assets/icons/tencent-color.webp';
      }
      if (p.contains('glm') || p.contains('智谱') || p.contains('zhipu')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('kimi') || p.contains('moonshot')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('minimax')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (p.contains('xiaomi') || p.contains('小米') || p.contains('milm') || p.contains('mimo')) {
        return 'assets/icons/xiaomi.webp';
      }
    }

    if (protocol != null) {
      final proto = protocol.toLowerCase();
      if (proto == 'gemini') {
        return 'assets/icons/gemini-color.webp';
      }
      if (proto == 'anthropic') {
        return 'assets/icons/claude-color.webp';
      }
    }

    if (modelName != null) {
      final name = modelName.toLowerCase();
      if (name.contains('deepseek') || name.contains('r1')) {
        return 'assets/icons/deepseek-color.webp';
      }
      if (name.contains('gpt') || name.contains('openai')) {
        return 'assets/icons/openai.webp';
      }
      if (name.contains('claude') || name.contains('anthropic')) {
        return 'assets/icons/claude-color.webp';
      }
      if (name.contains('gemini') || name.contains('bard') || name.contains('google')) {
        return 'assets/icons/gemini-color.webp';
      }
      if (name.contains('qwen') || name.contains('tongyi')) {
        return 'assets/icons/qwen-color.webp';
      }
      if (name.contains('hunyuan') || name.contains('混元')) {
        return 'assets/icons/tencent-color.webp';
      }
      if (name.contains('glm') || name.contains('zhipu') || name.contains('智谱')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('kimi') || name.contains('moonshot')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('minimax')) {
        return 'assets/icons/yuanbao-color.webp';
      }
      if (name.contains('milm') || name.contains('mi-llm')) {
        return 'assets/icons/yuanbao-color.webp';
      }
    }

    return null;
  }

  static Widget buildModelIconWidget(
    String modelName,
    bool isSelected, {
    String? platform,
    String? protocol,
  }) {
    final iconPath = resolveIconPath(
      platform: platform,
      protocol: protocol,
      modelName: modelName,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: iconPath != null
            ? _buildAssetIcon(
                iconPath,
                isSelected ? Colors.white : Colors.grey[600],
              )
            : Icon(
                Icons.desktop_windows,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 16,
              ),
      ),
    );
  }

  static Widget _buildAssetIcon(String assetPath, Color? fallbackColor) {
    return Image.asset(
      assetPath,
      width: 16,
      height: 16,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.desktop_windows, color: fallbackColor, size: 16);
      },
    );
  }
}
