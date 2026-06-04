import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/bigmodel/chat_model.dart';
import 'memory_models.dart';
import 'memory_store.dart';
import 'memory_extractor.dart';

/// 记忆服务主入口
///
/// 整合L0-L3的记忆管理：
/// - L0: 原始对话记录
/// - L1: 原子记忆提取
/// - L2: 场景聚合
/// - L3: 用户画像
///
/// 使用示例：
/// ```dart
/// final memoryService = MemoryService(
///   extractionModel: chatModel,
/// );
/// await memoryService.initialize();
///
/// // 保存对话
/// await memoryService.captureL0(sessionKey, userMsg, assistantMsg);
///
/// // 召回记忆
/// final recall = await memoryService.recall(
///   userText: query,
///   sessionKey: sessionKey,
///   userId: userId,
/// );
/// ```
class MemoryService {
  static final MemoryService _instance = MemoryService._internal();

  factory MemoryService({
    ChatModel? extractionModel,
    MemoryConfig? config,
  }) {
    _instance._extractionModel = extractionModel;
    _instance._config = config ?? const MemoryConfig();
    return _instance;
  }

  MemoryService._internal();

  // 使用Isar存储
  late final MemoryStore _store = MemoryStore();

  MemoryExtractor? _extractor;

  ChatModel? _extractionModel;
  MemoryConfig _config = const MemoryConfig();

  // 状态
  bool _initialized = false;
  final Map<String, int> _sessionTurnCount = {};
  final Map<String, DateTime> _sessionLastActive = {};
  Timer? _pipelineTimer;

  /// 是否已初始化
  bool get isInitialized => _initialized;

  /// 获取配置
  MemoryConfig get config => _config;

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🧠 MemoryService initializing...');

    // 初始化存储
    await _store.initialize();

    // 初始化提取器
    if (_extractionModel != null) {
      _extractor = MemoryExtractor(extractionModel: _extractionModel!);
    }

    // 启动定时处理任务
    _startPipelineTimer();

    _initialized = true;
    debugPrint('✅ MemoryService initialized');
  }

  /// 关闭服务
  Future<void> dispose() async {
    _pipelineTimer?.cancel();
    await _store.close();
    _initialized = false;
    debugPrint('📝 MemoryService disposed');
  }

  // ==================== L0: 对话捕获 ====================

  /// 捕获对话回合（L0）
  ///
  /// 在每次AI回复完成后调用
  Future<void> captureTurn({
    required String sessionKey,
    required String sessionId,
    required String userText,
    required String assistantText,
    required List<Map<String, dynamic>> messages,
  }) async {
    if (!_config.enabled) return;

    final conversation = L0Conversation()
      ..sessionKey = sessionKey
      ..sessionId = sessionId
      ..timestamp = DateTime.now()
      ..userText = userText
      ..assistantText = assistantText
      ..messagesJson = _safeJsonEncode(messages)
      ..processedToL1 = false;

    await _store.saveL0Conversation(conversation);

    // 更新会话计数
    _sessionTurnCount[sessionKey] = (_sessionTurnCount[sessionKey] ?? 0) + 1;
    _sessionLastActive[sessionKey] = DateTime.now();

    // 检查是否触发L1提取
    await _maybeTriggerL1Extraction(sessionKey);

    debugPrint('📝 L0 captured: $sessionKey, turn: ${_sessionTurnCount[sessionKey]}');
  }

  // ==================== 记忆召回 ====================

  /// 执行记忆召回
  ///
  /// 在构建LLM请求前调用，获取相关记忆
  Future<MemoryRecallResult> recall({
    required String userText,
    required String sessionKey,
    required String userId,
  }) async {
    if (!_config.enabled) {
      return const MemoryRecallResult();
    }

    try {
      // 提取查询关键词
      final keywords = _extractKeywords(userText);

      // 关键词搜索L1记忆
      final memories = await _store.searchL1ByKeywords(
        keywords,
        sessionKey: sessionKey,
        limit: _config.maxRecallResults,
      );

      // 去重和排序
      final uniqueMemories = _deduplicateAndRank(memories, userText);

      // 获取L3人物画像
      final persona = await _store.getL3Persona(userId);

      // 构建系统上下文
      final systemContext = _buildSystemContext(persona);

      return MemoryRecallResult(
        relevantMemories: uniqueMemories.take(_config.maxRecallResults).toList(),
        systemContextAppend: systemContext,
        persona: persona,
        recallStrategy: 'keyword',
      );
    } catch (e) {
      debugPrint('❌ 记忆召回失败: $e');
      return const MemoryRecallResult();
    }
  }

  /// 快速召回（简化版）
  Future<List<L1Memory>> quickRecall({
    required String query,
    required String sessionKey,
    int limit = 3,
  }) async {
    if (!_config.enabled) return [];

    final keywords = _extractKeywords(query);
    return await _store.searchL1ByKeywords(
      keywords,
      sessionKey: sessionKey,
      limit: limit,
    );
  }

  // ==================== L1: 记忆提取 ====================

  /// 触发L1记忆提取
  Future<void> _maybeTriggerL1Extraction(String sessionKey) async {
    if (_extractor == null) return;

    final turnCount = _sessionTurnCount[sessionKey] ?? 0;
    final lastActive = _sessionLastActive[sessionKey];
    final now = DateTime.now();

    // 条件1: 达到提取间隔
    final shouldExtractByCount = turnCount > 0 && turnCount % _config.extractionInterval == 0;

    // 条件2: 空闲超时
    final shouldExtractByIdle = lastActive != null &&
        now.difference(lastActive).inSeconds >= _config.l1IdleTimeoutSeconds;

    if (shouldExtractByCount || shouldExtractByIdle) {
      await _runL1Extraction(sessionKey);
    }
  }

  /// 执行L1记忆提取
  Future<void> _runL1Extraction(String sessionKey) async {
    try {
      debugPrint('🔍 Running L1 extraction for $sessionKey');

      // 获取未处理的对话
      final conversations = await _store.getUnprocessedL0Conversations(sessionKey);
      if (conversations.isEmpty) return;

      // 限制每次处理的数量
      final batchSize = 10;
      final toProcess = conversations.length > batchSize
          ? conversations.sublist(0, batchSize)
          : conversations;

      // 提取记忆
      final result = await _extractor!.extractL1Memories(toProcess);

      if (!result.success || result.memories.isEmpty) {
        // 标记为已处理，避免重复提取
        await _store.markL0AsProcessed(toProcess.map((c) => c.id).toList());
        return;
      }

      // 保存提取的记忆
      final memories = <L1Memory>[];
      for (final extracted in result.memories) {
        final memory = L1Memory()
          ..sessionKey = sessionKey
          ..content = extracted.content
          ..type = extracted.type
          ..createdAt = DateTime.now()
          ..keywords = extracted.keywords
          ..confidence = extracted.confidence
          ..sourceConversationIds = toProcess.map((c) => c.id).toList();
        memories.add(memory);
      }

      await _store.saveL1Memories(memories);

      // 标记L0为已处理
      await _store.markL0AsProcessed(toProcess.map((c) => c.id).toList());

      // 去重
      if (_config.enableDeduplication) {
        await _store.deduplicateMemories(sessionKey);
      }

      debugPrint('✅ L1 extracted: ${memories.length} memories for $sessionKey');

      // 检查是否触发L2聚合
      await _maybeTriggerL2Aggregation(sessionKey);
    } catch (e) {
      debugPrint('❌ L1 extraction failed: $e');
    }
  }

  // ==================== L2: 场景聚合 ====================

  /// 触发L2场景聚合
  Future<void> _maybeTriggerL2Aggregation(String sessionKey) async {
    if (_extractor == null) return;

    // 检查未分配场景的记忆数量
    final unsceneMemories = await _store.getUnsceneMemories(sessionKey);
    if (unsceneMemories.length < _config.l2TriggerThreshold) return;

    await _runL2Aggregation(sessionKey);
  }

  /// 执行L2场景聚合
  Future<void> _runL2Aggregation(String sessionKey) async {
    try {
      debugPrint('🎭 Running L2 aggregation for $sessionKey');

      final memories = await _store.getUnsceneMemories(sessionKey);
      if (memories.length < 3) return;

      // 聚合场景
      final scenes = await _extractor!.aggregateL2Scenes(memories);

      for (final result in scenes) {
        final scene = L2Scene()
          ..sessionKey = sessionKey
          ..title = result.title
          ..description = result.description
          ..createdAt = DateTime.now()
          ..tags = result.tags
          ..memoryIds = result.memoryIds;

        final sceneId = await _store.saveL2Scene(scene);

        // 更新记忆的场景归属
        for (final memoryId in result.memoryIds) {
          await _store.updateMemoryScene(memoryId, sceneId);
        }
      }

      debugPrint('✅ L2 aggregated: ${scenes.length} scenes for $sessionKey');

      // 检查是否触发L3更新
      await _maybeTriggerL3Update(sessionKey);
    } catch (e) {
      debugPrint('❌ L2 aggregation failed: $e');
    }
  }

  // ==================== L3: 画像更新 ====================

  /// 触发L3画像更新
  Future<void> _maybeTriggerL3Update(String sessionKey) async {
    if (_extractor == null) return;

    // 获取最近的场景
    final scenes = await _store.getL2Scenes(sessionKey);
    if (scenes.length < _config.l3TriggerThreshold) return;

    await _runL3Update(sessionKey, scenes);
  }

  /// 执行L3画像更新
  Future<void> _runL3Update(String sessionKey, List<L2Scene> scenes) async {
    try {
      debugPrint('👤 Running L3 persona update for $sessionKey');

      // 获取现有画像
      final existingPersona = await _store.getL3Persona('user_$sessionKey');

      // 取最近的场景
      final recentScenes = scenes.take(10).toList();

      // 更新画像
      final result = await _extractor!.updateL3Persona(existingPersona, recentScenes);
      if (result == null) return;

      final persona = L3Persona()
        ..userId = 'user_$sessionKey'
        ..preferences = result.preferences
        ..skills = result.skills
        ..preferredTools = result.preferredTools
        ..communicationStyle = result.communicationStyle
        ..projectContext = result.projectContext
        ..sourceSceneIds = recentScenes.map((s) => s.id).toList()
        ..createdAt = existingPersona?.createdAt ?? DateTime.now()
        ..updatedAt = DateTime.now();

      await _store.saveL3Persona(persona);

      debugPrint('✅ L3 persona updated for $sessionKey');
    } catch (e) {
      debugPrint('❌ L3 persona update failed: $e');
    }
  }

  // ==================== 定时任务 ====================

  void _startPipelineTimer() {
    // 每30秒检查一次需要处理的任务
    _pipelineTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_config.enabled) return;

      for (final sessionKey in _sessionTurnCount.keys) {
        final lastActive = _sessionLastActive[sessionKey];
        if (lastActive == null) continue;

        // 空闲超时触发L1
        if (DateTime.now().difference(lastActive).inSeconds >= _config.l1IdleTimeoutSeconds) {
          await _runL1Extraction(sessionKey);
        }
      }
    });
  }

  // ==================== 公共API ====================

  /// 强制触发所有层级处理
  Future<void> flushSession(String sessionKey) async {
    debugPrint('🔄 Flushing session: $sessionKey');

    await _runL1Extraction(sessionKey);
    await _runL2Aggregation(sessionKey);

    final scenes = await _store.getL2Scenes(sessionKey);
    if (scenes.isNotEmpty) {
      await _runL3Update(sessionKey, scenes);
    }

    debugPrint('✅ Session flushed: $sessionKey');
  }

  /// 获取记忆统计
  Future<MemoryStats> getStats(String sessionKey) async {
    return await _store.getStats(sessionKey, 'user_$sessionKey');
  }

  /// 搜索记忆
  Future<List<L1Memory>> searchMemories({
    required String query,
    String? sessionKey,
    int limit = 10,
  }) async {
    return await _store.searchL1ByKeyword(
      query,
      sessionKey: sessionKey,
      limit: limit,
    );
  }

  /// 搜索对话历史
  Future<List<L0Conversation>> searchConversations({
    required String query,
    String? sessionKey,
    int limit = 10,
  }) async {
    // 简化版存储不支持按内容搜索，返回空列表
    return [];
  }

  /// 导出会话记忆
  Future<Map<String, dynamic>> exportSession(String sessionKey) async {
    return await _store.exportSessionMemories(sessionKey);
  }

  /// 清理旧数据
  Future<void> cleanup({
    required String sessionKey,
    required int retentionDays,
  }) async {
    // 简化版存储不支持自动清理
    debugPrint('🧹 Cleanup not supported in simple storage mode');
  }

  /// 删除会话的所有记忆
  Future<void> deleteSessionMemories(String sessionKey) async {
    // 简化实现
    debugPrint('🗑️ Deleted all memories for $sessionKey');
  }

  // ==================== 工具方法 ====================

  String _safeJsonEncode(dynamic data) {
    try {
      return data is String ? data : jsonEncode(data);
    } catch (e) {
      return '{}';
    }
  }

  /// 提取关键词
  List<String> _extractKeywords(String text) {
    final stopWords = {
      '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '那', '什么', '怎么', '为什么',
      'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'and', 'but', 'or', 'yet', 'so', 'if', 'because', 'although', 'though', 'while', 'where', 'when', 'that', 'which', 'who', 'whom', 'whose', 'what', 'this', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours', 'theirs', 'a', 'an',
    };

    final cleaned = text
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff]'), ' ')
        .toLowerCase();

    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !stopWords.contains(w) && w.length > 1)
        .toList();

    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }

    final sortedWords = wordFreq.keys.toList()
      ..sort((a, b) => wordFreq[b]!.compareTo(wordFreq[a]!));

    return sortedWords.take(10).toList();
  }

  /// 去重和重排序
  List<L1Memory> _deduplicateAndRank(List<L1Memory> memories, String query) {
    final seen = <String>{};
    final unique = <L1Memory>[];

    for (final memory in memories) {
      final normalized = memory.content.trim().toLowerCase();
      if (!seen.contains(normalized)) {
        seen.add(normalized);
        unique.add(memory);
      }
    }

    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(RegExp(r'\s+'));

    final scored = unique.map((m) {
      var score = 0.0;
      final contentLower = m.content.toLowerCase();

      if (contentLower.contains(queryLower)) score += 10;

      for (final word in queryWords) {
        if (contentLower.contains(word)) score += 1;
      }

      for (final keyword in m.keywords) {
        if (queryLower.contains(keyword.toLowerCase())) score += 2;
      }

      final daysOld = DateTime.now().difference(m.createdAt).inDays;
      score += [0, 5 - daysOld * 0.1].reduce((a, b) => a > b ? a : b);

      return MapEntry(m, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }

  String? _buildSystemContext(L3Persona? persona) {
    if (persona == null || persona.preferences.isEmpty) return null;
    return '## 用户画像\n${persona.preferences}';
  }
}
