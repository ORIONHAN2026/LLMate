import 'dart:math';
import 'package:flutter/foundation.dart';
import 'memory_models.dart';
import 'memory_store.dart';
import 'memory_store_simple.dart';

/// 记忆召回服务
///
/// 负责在用户查询时检索相关记忆
/// 支持多种召回策略：关键词、语义、混合
class MemoryRecall {
  final MemoryStore? _store;
  final MemoryStoreSimple? _storeSimple;
  final MemoryConfig _config;
  final bool _useSimpleStore;

  MemoryRecall({
    MemoryStore? store,
    MemoryStoreSimple? storeSimple,
    MemoryConfig? config,
  }) : _store = store,
       _storeSimple = storeSimple,
       _useSimpleStore = store == null,
       _config = config ?? const MemoryConfig();

  /// 执行记忆召回
  /// 
  /// [userText]: 用户输入文本
  /// [sessionKey]: 会话标识
  /// [userId]: 用户标识
  Future<MemoryRecallResult> recall({
    required String userText,
    required String sessionKey,
    required String userId,
  }) async {
    if (!_config.enabled) {
      return const MemoryRecallResult();
    }

    try {
      // 1. 提取查询关键词
      final keywords = _extractKeywords(userText);
      
      // 2. 根据策略召回记忆
      List<L1Memory> memories;
      String strategy;
      
      switch (_config.recallStrategy) {
        case 'keyword':
          memories = await _keywordRecall(keywords, sessionKey);
          strategy = 'keyword';
          break;
        case 'embedding':
          memories = await _embeddingRecall(userText, sessionKey);
          strategy = 'embedding';
          break;
        case 'hybrid':
        default:
          memories = await _hybridRecall(userText, keywords, sessionKey);
          strategy = 'hybrid';
          break;
      }

      // 3. 去重和排序
      memories = _deduplicateAndRank(memories, userText);

      // 4. 限制数量
      if (memories.length > _config.maxRecallResults) {
        memories = memories.sublist(0, _config.maxRecallResults);
      }

      // 5. 获取L3人物画像
      L3Persona? persona;
      if (_useSimpleStore && _storeSimple != null) {
        persona = await _storeSimple.getL3Persona(userId);
      } else if (_store != null) {
        persona = await _store.getL3Persona(userId);
      }

      // 6. 构建系统上下文
      final systemContext = _buildSystemContext(persona, sessionKey);

      return MemoryRecallResult(
        relevantMemories: memories,
        systemContextAppend: systemContext,
        persona: persona,
        recallStrategy: strategy,
      );
    } catch (e) {
      debugPrint('❌ 记忆召回失败: $e');
      return const MemoryRecallResult();
    }
  }

  /// 关键词召回
  Future<List<L1Memory>> _keywordRecall(List<String> keywords, String sessionKey) async {
    if (keywords.isEmpty) return [];

    if (_useSimpleStore && _storeSimple != null) {
      return await _storeSimple.searchL1ByKeywords(
        keywords,
        sessionKey: sessionKey,
        limit: _config.maxRecallResults * 2,
      );
    } else if (_store != null) {
      return await _store.searchL1ByKeywords(
        keywords,
        sessionKey: sessionKey,
        limit: _config.maxRecallResults * 2,
      );
    }
    return [];
  }

  /// 语义召回（基于嵌入向量）
  Future<List<L1Memory>> _embeddingRecall(String query, String sessionKey) async {
    // 简化的实现：使用关键词召回作为fallback
    // 实际实现需要向量数据库支持
    final keywords = _extractKeywords(query);
    return await _keywordRecall(keywords, sessionKey);
  }

  /// 混合召回（关键词 + 语义）
  Future<List<L1Memory>> _hybridRecall(
    String query,
    List<String> keywords,
    String sessionKey,
  ) async {
    // 获取关键词召回结果
    final keywordResults = await _keywordRecall(keywords, sessionKey);

    // 获取语义召回结果（简化实现）
    final semanticResults = await _embeddingRecall(query, sessionKey);

    // RRF融合排序
    return _rrfFusion(keywordResults, semanticResults);
  }

  /// RRF (Reciprocal Rank Fusion) 融合排序
  List<L1Memory> _rrfFusion(List<L1Memory> list1, List<L1Memory> list2) {
    final k = 60; // RRF常数
    final scores = <int, double>{};
    final memories = <int, L1Memory>{};
    
    // 处理list1
    for (var i = 0; i < list1.length; i++) {
      final id = list1[i].id;
      scores[id] = (scores[id] ?? 0) + 1.0 / (k + i + 1);
      memories[id] = list1[i];
    }
    
    // 处理list2
    for (var i = 0; i < list2.length; i++) {
      final id = list2[i].id;
      scores[id] = (scores[id] ?? 0) + 1.0 / (k + i + 1);
      memories[id] = list2[i];
    }
    
    // 按分数排序
    final sortedIds = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    
    return sortedIds.map((id) => memories[id]!).toList();
  }

  /// 提取关键词
  List<String> _extractKeywords(String text) {
    // 简单的中文分词实现
    // 实际生产环境可以使用jieba或其他分词库
    final stopWords = {
      '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '那', '什么', '怎么', '为什么',
      'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'and', 'but', 'or', 'yet', 'so', 'if', 'because', 'although', 'though', 'while', 'where', 'when', 'that', 'which', 'who', 'whom', 'whose', 'what', 'this', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our', 'their', 'mine', 'yours', 'hers', 'ours', 'theirs', 'a', 'an',
    };
    
    // 预处理：移除标点，转换为小写
    final cleaned = text
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff]'), ' ')
        .toLowerCase();
    
    // 分词并过滤停用词
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !stopWords.contains(w) && w.length > 1)
        .toList();
    
    // 统计词频并返回高频词
    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }
    
    final sortedWords = wordFreq.keys.toList()
      ..sort((a, b) => wordFreq[b]!.compareTo(wordFreq[a]!));
    
    // 返回前10个关键词
    return sortedWords.take(10).toList();
  }

  /// 去重和重排序
  List<L1Memory> _deduplicateAndRank(List<L1Memory> memories, String query) {
    // 去重
    final seen = <String>{};
    final unique = <L1Memory>[];
    
    for (final memory in memories) {
      final normalized = memory.content.trim().toLowerCase();
      if (!seen.contains(normalized)) {
        seen.add(normalized);
        unique.add(memory);
      }
    }
    
    // 简单的相关性重排序
    // 基于关键词匹配度
    final queryLower = query.toLowerCase();
    final queryWords = queryLower.split(RegExp(r'\s+'));
    
    final scored = unique.map((m) {
      var score = 0.0;
      final contentLower = m.content.toLowerCase();
      
      // 完整匹配加分
      if (contentLower.contains(queryLower)) score += 10;
      
      // 关键词匹配
      for (final word in queryWords) {
        if (contentLower.contains(word)) score += 1;
      }
      
      // 记忆关键词匹配
      for (final keyword in m.keywords) {
        if (queryLower.contains(keyword.toLowerCase())) score += 2;
      }
      
      // 时间衰减（较新的记忆稍微优先）
      final daysOld = DateTime.now().difference(m.createdAt).inDays;
      score += max(0, 5 - daysOld * 0.1);
      
      return MapEntry(m, score);
    }).toList();
    
    scored.sort((a, b) => b.value.compareTo(a.value));
    
    return scored.map((e) => e.key).toList();
  }

  /// 构建系统上下文
  String? _buildSystemContext(L3Persona? persona, String sessionKey) {
    final parts = <String>[];
    
    if (persona != null && persona.preferences.isNotEmpty) {
      parts.add('## 用户画像\n${persona.preferences}');
    }
    
    if (parts.isEmpty) return null;
    
    return parts.join('\n\n');
  }

  /// 快速召回（用于实时场景）
  Future<List<L1Memory>> quickRecall({
    required String query,
    required String sessionKey,
    int limit = 3,
  }) async {
    final keywords = _extractKeywords(query);
    List<L1Memory> memories;
    if (_useSimpleStore && _storeSimple != null) {
      memories = await _storeSimple.searchL1ByKeywords(
        keywords,
        sessionKey: sessionKey,
        limit: limit * 2,
      );
    } else if (_store != null) {
      memories = await _store.searchL1ByKeywords(
        keywords,
        sessionKey: sessionKey,
        limit: limit * 2,
      );
    } else {
      return [];
    }
    return memories.take(limit).toList();
  }
}
