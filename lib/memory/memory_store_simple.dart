import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'memory_models.dart';

/// 简化版记忆存储（基于JSON文件）
/// 
/// 在Isar代码生成完成前可作为备选方案
/// 生产环境建议使用Isar版本 (memory_store.dart)
class MemoryStoreSimple {
  static MemoryStoreSimple? _instance;
  late String _basePath;
  bool _initialized = false;

  static MemoryStoreSimple get instance {
    _instance ??= MemoryStoreSimple._internal();
    return _instance!;
  }

  MemoryStoreSimple._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _basePath = '${dir.path}/memory';

    // 创建目录
    await Directory(_basePath).create(recursive: true);
    await Directory('$_basePath/l0').create(recursive: true);
    await Directory('$_basePath/l1').create(recursive: true);
    await Directory('$_basePath/l2').create(recursive: true);
    await Directory('$_basePath/l3').create(recursive: true);

    _initialized = true;
    debugPrint('✅ MemoryStoreSimple initialized: $_basePath');
  }

  // ==================== L0: 原始对话操作 ====================

  Future<void> saveL0Conversation(L0Conversation conversation) async {
    final file = File('$_basePath/l0/${conversation.sessionKey}.jsonl');
    final line = jsonEncode({
      'id': conversation.id,
      'timestamp': conversation.timestamp.toIso8601String(),
      'userText': conversation.userText,
      'assistantText': conversation.assistantText,
      'messagesJson': conversation.messagesJson,
      'processedToL1': conversation.processedToL1,
      'processedAt': conversation.processedAt?.toIso8601String(),
    });
    await file.writeAsString('$line\n', mode: FileMode.append);
  }

  Future<List<L0Conversation>> getUnprocessedL0Conversations(String sessionKey) async {
    final conversations = await _readL0Conversations(sessionKey);
    return conversations.where((c) => !c.processedToL1).toList();
  }

  Future<List<L0Conversation>> _readL0Conversations(String sessionKey) async {
    final file = File('$_basePath/l0/$sessionKey.jsonl');
    if (!await file.exists()) return [];

    final lines = await file.readAsLines();
    final conversations = <L0Conversation>[];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line);
        conversations.add(L0Conversation()
          ..id = json['id'] ?? 0
          ..sessionKey = sessionKey
          ..timestamp = DateTime.parse(json['timestamp'])
          ..userText = json['userText']
          ..assistantText = json['assistantText']
          ..messagesJson = json['messagesJson']
          ..processedToL1 = json['processedToL1'] ?? false
          ..processedAt = json['processedAt'] != null 
              ? DateTime.parse(json['processedAt']) 
              : null);
      } catch (e) {
        debugPrint('Error parsing L0 conversation: $e');
      }
    }

    return conversations;
  }

  Future<void> markL0AsProcessed(List<int> ids) async {
    // 简化实现：重新写入所有数据
    // 生产环境建议使用数据库
  }

  Future<List<L0Conversation>> getL0History(String sessionKey, {int? limit}) async {
    var conversations = await _readL0Conversations(sessionKey);
    conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null && conversations.length > limit) {
      conversations = conversations.sublist(0, limit);
    }
    return conversations;
  }

  // ==================== L1: 原子记忆操作 ====================

  Future<int> saveL1Memory(L1Memory memory) async {
    final memories = await _readL1Memories(memory.sessionKey);
    final newId = memories.isEmpty ? 1 : memories.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    memory.id = newId;
    memories.add(memory);
    await _writeL1Memories(memory.sessionKey, memories);
    return newId;
  }

  Future<List<int>> saveL1Memories(List<L1Memory> memories) async {
    final ids = <int>[];
    for (final memory in memories) {
      final id = await saveL1Memory(memory);
      ids.add(id);
    }
    return ids;
  }

  Future<List<L1Memory>> getL1Memories(String sessionKey) async {
    return await _readL1Memories(sessionKey);
  }

  Future<List<L1Memory>> getUnsceneMemories(String sessionKey) async {
    final memories = await _readL1Memories(sessionKey);
    return memories.where((m) => m.sceneId == null).toList();
  }

  Future<List<L1Memory>> _readL1Memories(String sessionKey) async {
    final file = File('$_basePath/l1/$sessionKey.json');
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((json) => _l1FromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeL1Memories(String sessionKey, List<L1Memory> memories) async {
    final file = File('$_basePath/l1/$sessionKey.json');
    final list = memories.map((m) => _l1ToJson(m)).toList();
    await file.writeAsString(jsonEncode(list));
  }

  L1Memory _l1FromJson(Map<String, dynamic> json) {
    return L1Memory()
      ..id = json['id'] ?? 0
      ..sessionKey = json['sessionKey']
      ..content = json['content']
      ..type = MemoryType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => MemoryType.fact)
      ..sourceConversationIds = List<int>.from(json['sourceConversationIds'] ?? [])
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null
      ..sceneId = json['sceneId']
      ..embeddingJson = json['embeddingJson']
      ..confidence = json['confidence']?.toDouble() ?? 1.0
      ..keywords = List<String>.from(json['keywords'] ?? []);
  }

  Map<String, dynamic> _l1ToJson(L1Memory memory) {
    return {
      'id': memory.id,
      'sessionKey': memory.sessionKey,
      'content': memory.content,
      'type': memory.type.name,
      'sourceConversationIds': memory.sourceConversationIds,
      'createdAt': memory.createdAt.toIso8601String(),
      'updatedAt': memory.updatedAt?.toIso8601String(),
      'sceneId': memory.sceneId,
      'embeddingJson': memory.embeddingJson,
      'confidence': memory.confidence,
      'keywords': memory.keywords,
    };
  }

  Future<List<L1Memory>> searchL1ByKeyword(String keyword, {String? sessionKey, int limit = 10}) async {
    final allMemories = sessionKey != null 
        ? await _readL1Memories(sessionKey)
        : await _searchAllL1Memories();
    
    final lowerKeyword = keyword.toLowerCase();
    return allMemories
        .where((m) => m.content.toLowerCase().contains(lowerKeyword))
        .take(limit)
        .toList();
  }

  Future<List<L1Memory>> searchL1ByKeywords(List<String> keywords, {String? sessionKey, int limit = 10}) async {
    final allMemories = sessionKey != null 
        ? await _readL1Memories(sessionKey)
        : await _searchAllL1Memories();
    
    final results = <L1Memory>[];
    final seenIds = <int>{};
    
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      final lowerKeyword = keyword.toLowerCase();
      
      for (final memory in allMemories) {
        if (memory.content.toLowerCase().contains(lowerKeyword) && !seenIds.contains(memory.id)) {
          seenIds.add(memory.id);
          results.add(memory);
        }
      }
      
      if (results.length >= limit) break;
    }
    
    return results.take(limit).toList();
  }

  Future<List<L1Memory>> _searchAllL1Memories() async {
    final dir = Directory('$_basePath/l1');
    if (!await dir.exists()) return [];
    
    final memories = <L1Memory>[];
    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        memories.addAll(list.map((json) => _l1FromJson(json)));
      }
    }
    return memories;
  }

  Future<void> updateMemoryScene(int memoryId, int sceneId) async {
    // 简化实现：需要遍历所有文件
  }

  Future<int> deduplicateMemories(String sessionKey) async {
    final memories = await _readL1Memories(sessionKey);
    final unique = <String, L1Memory>{};
    final toRemove = <int>[];
    
    for (final memory in memories) {
      final normalized = memory.content.trim().toLowerCase();
      if (unique.containsKey(normalized)) {
        // 保留较新的
        if (memory.createdAt.isAfter(unique[normalized]!.createdAt)) {
          toRemove.add(unique[normalized]!.id);
          unique[normalized] = memory;
        } else {
          toRemove.add(memory.id);
        }
      } else {
        unique[normalized] = memory;
      }
    }
    
    if (toRemove.isNotEmpty) {
      memories.removeWhere((m) => toRemove.contains(m.id));
      await _writeL1Memories(sessionKey, memories);
    }
    
    return toRemove.length;
  }

  // ==================== L2: 场景操作 ====================

  Future<int> saveL2Scene(L2Scene scene) async {
    final scenes = await _readL2Scenes(scene.sessionKey);
    final newId = scenes.isEmpty ? 1 : scenes.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    scene.id = newId;
    scenes.add(scene);
    await _writeL2Scenes(scene.sessionKey, scenes);
    return newId;
  }

  Future<List<L2Scene>> getL2Scenes(String sessionKey) async {
    return await _readL2Scenes(sessionKey);
  }

  Future<List<L2Scene>> _readL2Scenes(String sessionKey) async {
    final file = File('$_basePath/l2/$sessionKey.json');
    if (!await file.exists()) return [];

    try {
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list.map((json) => _l2FromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _writeL2Scenes(String sessionKey, List<L2Scene> scenes) async {
    final file = File('$_basePath/l2/$sessionKey.json');
    final list = scenes.map((s) => _l2ToJson(s)).toList();
    await file.writeAsString(jsonEncode(list));
  }

  L2Scene _l2FromJson(Map<String, dynamic> json) {
    return L2Scene()
      ..id = json['id'] ?? 0
      ..sessionKey = json['sessionKey']
      ..title = json['title']
      ..description = json['description']
      ..memoryIds = List<int>.from(json['memoryIds'] ?? [])
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null
      ..tags = List<String>.from(json['tags'] ?? []);
  }

  Map<String, dynamic> _l2ToJson(L2Scene scene) {
    return {
      'id': scene.id,
      'sessionKey': scene.sessionKey,
      'title': scene.title,
      'description': scene.description,
      'memoryIds': scene.memoryIds,
      'createdAt': scene.createdAt.toIso8601String(),
      'updatedAt': scene.updatedAt?.toIso8601String(),
      'tags': scene.tags,
    };
  }

  // ==================== L3: 人物画像操作 ====================

  Future<int> saveL3Persona(L3Persona persona) async {
    final file = File('$_basePath/l3/${persona.userId}.json');
    await file.writeAsString(jsonEncode(_l3ToJson(persona)));
    return persona.id;
  }

  Future<L3Persona?> getL3Persona(String userId) async {
    final file = File('$_basePath/l3/$userId.json');
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      return _l3FromJson(jsonDecode(content));
    } catch (e) {
      return null;
    }
  }

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

  L3Persona _l3FromJson(Map<String, dynamic> json) {
    return L3Persona()
      ..id = json['id'] ?? 0
      ..userId = json['userId']
      ..version = json['version'] ?? 1
      ..preferences = json['preferences']
      ..skills = json['skills']
      ..preferredTools = List<String>.from(json['preferredTools'] ?? [])
      ..communicationStyle = json['communicationStyle']
      ..projectContext = json['projectContext']
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt'])
      ..sourceSceneIds = List<int>.from(json['sourceSceneIds'] ?? []);
  }

  Map<String, dynamic> _l3ToJson(L3Persona persona) {
    return {
      'id': persona.id,
      'userId': persona.userId,
      'version': persona.version,
      'preferences': persona.preferences,
      'skills': persona.skills,
      'preferredTools': persona.preferredTools,
      'communicationStyle': persona.communicationStyle,
      'projectContext': persona.projectContext,
      'createdAt': persona.createdAt.toIso8601String(),
      'updatedAt': persona.updatedAt.toIso8601String(),
      'sourceSceneIds': persona.sourceSceneIds,
    };
  }

  // ==================== 统计信息 ====================

  Future<MemoryStats> getStats(String sessionKey, String userId) async {
    final l0Conversations = await _readL0Conversations(sessionKey);
    final l1Memories = await _readL1Memories(sessionKey);
    final l2Scenes = await _readL2Scenes(sessionKey);
    final persona = await getL3Persona(userId);

    return MemoryStats(
      l0Count: l0Conversations.length,
      l1Count: l1Memories.length,
      l2Count: l2Scenes.length,
      hasL3: persona != null,
    );
  }

  // ==================== 导出 ====================

  Future<Map<String, dynamic>> exportSessionMemories(String sessionKey) async {
    return {
      'sessionKey': sessionKey,
      'exportedAt': DateTime.now().toIso8601String(),
      'l0Conversations': (await _readL0Conversations(sessionKey)).map((c) => {
        'id': c.id,
        'timestamp': c.timestamp.toIso8601String(),
        'userText': c.userText,
        'assistantText': c.assistantText,
      }).toList(),
      'l1Memories': (await _readL1Memories(sessionKey)).map((m) => {
        'id': m.id,
        'content': m.content,
        'type': m.type.name,
        'createdAt': m.createdAt.toIso8601String(),
      }).toList(),
      'l2Scenes': (await _readL2Scenes(sessionKey)).map((s) => {
        'id': s.id,
        'title': s.title,
        'description': s.description,
        'tags': s.tags,
      }).toList(),
    };
  }

  Future<void> close() async {
    // JSON文件无需关闭
    _initialized = false;
  }
}
