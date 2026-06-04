import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'memory_models.dart';

/// 记忆存储服务
/// 
/// 管理L0-L3数据的持久化存储和检索
class MemoryStore {
  static Isar? _isar;
  static final MemoryStore _instance = MemoryStore._internal();
  
  factory MemoryStore() => _instance;
  MemoryStore._internal();

  /// 获取Isar实例
  Isar get isar {
    if (_isar == null) {
      throw StateError('MemoryStore未初始化，请先调用initialize()');
    }
    return _isar!;
  }

  /// 初始化存储
  Future<void> initialize() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final memoryDir = '${dir.path}/memory';

    _isar = await Isar.open(
      [L0ConversationSchema, L1MemorySchema, L2SceneSchema, L3PersonaSchema],
      directory: memoryDir,
    );

    debugPrint('✅ MemoryStore初始化完成: $memoryDir');
  }

  /// 关闭存储
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      debugPrint('📝 MemoryStore已关闭');
    }
  }

  // ==================== L0: 原始对话操作 ====================

  /// 保存L0对话记录
  Future<int> saveL0Conversation(L0Conversation conversation) async {
    return await isar.writeTxn(() async {
      return await isar.l0Conversations.put(conversation);
    });
  }

  /// 批量保存L0对话
  Future<List<int>> saveL0Conversations(List<L0Conversation> conversations) async {
    return await isar.writeTxn(() async {
      return await isar.l0Conversations.putAll(conversations);
    });
  }

  /// 获取未处理的L0对话
  Future<List<L0Conversation>> getUnprocessedL0Conversations(String sessionKey) async {
    return await isar.l0Conversations
        .where()
        .sessionKeyEqualTo(sessionKey)
        .filter()
        .processedToL1EqualTo(false)
        .sortByTimestampDesc()
        .findAll();
  }

  /// 标记L0对话为已处理
  Future<void> markL0AsProcessed(List<int> ids) async {
    await isar.writeTxn(() async {
      for (final id in ids) {
        final conversation = await isar.l0Conversations.get(id);
        if (conversation != null) {
          conversation.processedToL1 = true;
          conversation.processedAt = DateTime.now();
          await isar.l0Conversations.put(conversation);
        }
      }
    });
  }

  /// 获取会话的L0对话历史
  Future<List<L0Conversation>> getL0History(String sessionKey, {int? limit}) async {
    final query = isar.l0Conversations
        .where()
        .sessionKeyEqualTo(sessionKey)
        .sortByTimestampDesc()
        .limit(limit ?? 1000);
    
    return await query.findAll();
  }

  /// 搜索L0对话
  Future<List<L0Conversation>> searchL0(String queryText, {String? sessionKey, int limit = 10}) async {
    if (sessionKey != null) {
      return await isar.l0Conversations
          .where()
          .sessionKeyEqualTo(sessionKey)
          .filter()
          .userTextContains(queryText, caseSensitive: false)
          .or()
          .assistantTextContains(queryText, caseSensitive: false)
          .limit(limit)
          .findAll();
    }
    
    return await isar.l0Conversations
        .where()
        .filter()
        .userTextContains(queryText, caseSensitive: false)
        .or()
        .assistantTextContains(queryText, caseSensitive: false)
        .limit(limit)
        .findAll();
  }

  // ==================== L1: 原子记忆操作 ====================

  /// 保存L1记忆
  Future<int> saveL1Memory(L1Memory memory) async {
    return await isar.writeTxn(() async {
      return await isar.l1Memorys.put(memory);
    });
  }

  /// 批量保存L1记忆
  Future<List<int>> saveL1Memories(List<L1Memory> memories) async {
    return await isar.writeTxn(() async {
      return await isar.l1Memorys.putAll(memories);
    });
  }

  /// 获取会话的所有L1记忆
  Future<List<L1Memory>> getL1Memories(String sessionKey) async {
    return await isar.l1Memorys
        .where()
        .sessionKeyEqualTo(sessionKey)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取未分配场景的记忆
  Future<List<L1Memory>> getUnsceneMemories(String sessionKey) async {
    return await isar.l1Memorys
        .where()
        .sessionKeyEqualTo(sessionKey)
        .filter()
        .sceneIdIsNull()
        .findAll();
  }

  /// 关键词搜索L1记忆
  Future<List<L1Memory>> searchL1ByKeyword(String keyword, {String? sessionKey, int limit = 10}) async {
    if (sessionKey != null) {
      return await isar.l1Memorys
          .where()
          .sessionKeyEqualTo(sessionKey)
          .filter()
          .contentContains(keyword, caseSensitive: false)
          .limit(limit)
          .findAll();
    }
    
    return await isar.l1Memorys
        .where()
        .filter()
        .contentContains(keyword, caseSensitive: false)
        .limit(limit)
        .findAll();
  }

  /// 根据关键词列表检索相关记忆
  Future<List<L1Memory>> searchL1ByKeywords(List<String> keywords, {String? sessionKey, int limit = 10}) async {
    // 简单实现：查找包含任意关键词的记忆
    final results = <L1Memory>[];
    final seenIds = <int>{};
    
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      
      final memories = await searchL1ByKeyword(keyword, sessionKey: sessionKey, limit: limit);
      
      for (final memory in memories) {
        if (!seenIds.contains(memory.id)) {
          seenIds.add(memory.id);
          results.add(memory);
        }
      }
      
      if (results.length >= limit) break;
    }
    
    return results.take(limit).toList();
  }

  /// 更新记忆的场景归属
  Future<void> updateMemoryScene(int memoryId, int sceneId) async {
    await isar.writeTxn(() async {
      final memory = await isar.l1Memorys.get(memoryId);
      if (memory != null) {
        memory.sceneId = sceneId;
        memory.updatedAt = DateTime.now();
        await isar.l1Memorys.put(memory);
      }
    });
  }

  /// 删除重复的记忆
  Future<int> deduplicateMemories(String sessionKey) async {
    final memories = await getL1Memories(sessionKey);
    final toDelete = <int>[];
    final contentMap = <String, int>{};
    
    for (final memory in memories) {
      final normalized = memory.content.trim().toLowerCase();
      if (contentMap.containsKey(normalized)) {
        // 保留较新的
        if (memory.createdAt.isAfter(memories.firstWhere((m) => m.id == contentMap[normalized]).createdAt)) {
          toDelete.add(contentMap[normalized]!);
          contentMap[normalized] = memory.id;
        } else {
          toDelete.add(memory.id);
        }
      } else {
        contentMap[normalized] = memory.id;
      }
    }
    
    if (toDelete.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.l1Memorys.deleteAll(toDelete);
      });
    }
    
    return toDelete.length;
  }

  // ==================== L2: 场景操作 ====================

  /// 保存L2场景
  Future<int> saveL2Scene(L2Scene scene) async {
    return await isar.writeTxn(() async {
      return await isar.l2Scenes.put(scene);
    });
  }

  /// 获取会话的所有场景
  Future<List<L2Scene>> getL2Scenes(String sessionKey) async {
    return await isar.l2Scenes
        .where()
        .sessionKeyEqualTo(sessionKey)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 根据标签搜索场景
  Future<List<L2Scene>> searchL2ByTag(String tag, {String? sessionKey}) async {
    List<L2Scene> scenes;
    if (sessionKey != null) {
      scenes = await isar.l2Scenes
          .where()
          .sessionKeyEqualTo(sessionKey)
          .findAll();
    } else {
      scenes = await isar.l2Scenes.where().findAll();
    }
    return scenes.where((s) => s.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))).toList();
  }

  /// 更新场景的记忆列表
  Future<void> updateSceneMemories(int sceneId, List<int> memoryIds) async {
    await isar.writeTxn(() async {
      final scene = await isar.l2Scenes.get(sceneId);
      if (scene != null) {
        scene.memoryIds = memoryIds;
        scene.updatedAt = DateTime.now();
        await isar.l2Scenes.put(scene);
      }
    });
  }

  // ==================== L3: 人物画像操作 ====================

  /// 保存或更新L3人物画像
  Future<int> saveL3Persona(L3Persona persona) async {
    return await isar.writeTxn(() async {
      // 检查是否已存在
      final existing = await isar.l3Personas.where().userIdEqualTo(persona.userId).findFirst();
      if (existing != null) {
        persona.id = existing.id;
        persona.version = existing.version + 1;
      }
      persona.updatedAt = DateTime.now();
      return await isar.l3Personas.put(persona);
    });
  }

  /// 获取用户画像
  Future<L3Persona?> getL3Persona(String userId) async {
    return await isar.l3Personas.where().userIdEqualTo(userId).findFirst();
  }

  /// 获取或创建默认画像
  Future<L3Persona> getOrCreatePersona(String userId) async {
    var persona = await getL3Persona(userId);
    if (persona == null) {
      persona = L3Persona()
        ..userId = userId
        ..preferences = ''
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await saveL3Persona(persona);
    }
    return persona;
  }

  // ==================== 统计信息 ====================

  /// 获取记忆统计
  Future<MemoryStats> getStats(String sessionKey, String userId) async {
    final l0Count = await isar.l0Conversations.where().sessionKeyEqualTo(sessionKey).count();
    final l1Count = await isar.l1Memorys.where().sessionKeyEqualTo(sessionKey).count();
    final l2Count = await isar.l2Scenes.where().sessionKeyEqualTo(sessionKey).count();
    final persona = await getL3Persona(userId);

    return MemoryStats(
      l0Count: l0Count,
      l1Count: l1Count,
      l2Count: l2Count,
      hasL3: persona != null,
    );
  }

  /// 清理旧的L0对话
  Future<int> cleanupOldL0(String sessionKey, {required int retentionDays}) async {
    if (retentionDays <= 0) return 0;
    
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    
    final oldConversations = await isar.l0Conversations
        .where()
        .sessionKeyEqualTo(sessionKey)
        .filter()
        .processedToL1EqualTo(true)
        .timestampLessThan(cutoff)
        .findAll();
    
    if (oldConversations.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.l0Conversations.deleteAll(oldConversations.map((c) => c.id).toList());
      });
    }
    
    return oldConversations.length;
  }

  /// 导出会话的所有记忆
  Future<Map<String, dynamic>> exportSessionMemories(String sessionKey) async {
    final l0Conversations = await getL0History(sessionKey);
    final l1Memories = await getL1Memories(sessionKey);
    final l2Scenes = await getL2Scenes(sessionKey);
    
    return {
      'sessionKey': sessionKey,
      'exportedAt': DateTime.now().toIso8601String(),
      'l0Conversations': l0Conversations.map((c) => {
        'id': c.id,
        'timestamp': c.timestamp.toIso8601String(),
        'userText': c.userText,
        'assistantText': c.assistantText,
      }).toList(),
      'l1Memories': l1Memories.map((m) => {
        'id': m.id,
        'content': m.content,
        'type': m.type.name,
        'createdAt': m.createdAt.toIso8601String(),
      }).toList(),
      'l2Scenes': l2Scenes.map((s) => {
        'id': s.id,
        'title': s.title,
        'description': s.description,
        'tags': s.tags,
      }).toList(),
    };
  }
}
