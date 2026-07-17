import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../../../models/bigmodel/chat_model.dart';
import '../../../data/storage_paths.dart';

class ModelController extends GetxController {
  /// 模型数据库路径：~/.llmate/models.db
  static String get _dbPath => p.join(StoragePaths.root, 'models.db');

  /// sembast store 名称（每个 record 的 key 为 modelId）
  static const String _storeName = 'models';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    return _db!;
  }

  // ========== 模型持久化存储操作 ==========

  /// 加载所有模型数据（从 models.db 读取）
  Future<List<ChatModel>> loadModels() async {
    try {
      final db = await _database;
      final records = await _store.find(db);
      return records
          .map((r) => ChatModel.fromMap(r.value as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('加载模型失败: $e');
      return [];
    }
  }

  /// 新增单个模型（按 modelId 写入 models.db）
  Future<void> addModel(ChatModel model) async {
    if (model.modelId.isEmpty) return;
    try {
      final db = await _database;
      await _store.record(model.modelId).put(db, model.toMap());
    } catch (e) {
      debugPrint('新增模型失败: $e');
    }
  }

  /// 更新单个模型（按 modelId 覆盖 models.db 中对应记录）
  Future<void> updateModel(ChatModel model) async {
    if (model.modelId.isEmpty) return;
    try {
      final db = await _database;
      await _store.record(model.modelId).put(db, model.toMap());
    } catch (e) {
      debugPrint('更新模型失败: $e');
    }
  }

  /// 删除单个模型（按 modelId 从 models.db 中移除）
  Future<void> deleteModel(String modelId) async {
    if (modelId.isEmpty) return;
    try {
      final db = await _database;
      await _store.record(modelId).delete(db);
    } catch (e) {
      debugPrint('删除模型失败: $e');
    }
  }

  /// 根据 modelId 查询单个模型（不存在返回 null）
  Future<ChatModel?> getModel(String modelId) async {
    if (modelId.isEmpty) return null;
    try {
      final db = await _database;
      final record = await _store.record(modelId).get(db);
      if (record == null) return null;
      return ChatModel.fromMap(record as Map<String, dynamic>);
    } catch (e) {
      debugPrint('查询模型失败: $e');
      return null;
    }
  }

  // ========== 模型图标工具 ==========

  /// 根据平台名称、协议、模型名称等信息解析图标路径。
  /// 优先级：platform > protocol > modelName
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
