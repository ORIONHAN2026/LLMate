import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../framework/llm_hub.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_message.dart';
import 'memory_models.dart';

/// 提取的记忆结果
class ExtractionResult {
  final List<ExtractedMemory> memories;
  final String rawResponse;
  final bool success;
  final String? error;

  const ExtractionResult({
    required this.memories,
    required this.rawResponse,
    this.success = true,
    this.error,
  });

  factory ExtractionResult.error(String error, String rawResponse) {
    return ExtractionResult(
      memories: [],
      rawResponse: rawResponse,
      success: false,
      error: error,
    );
  }
}

/// 提取的单个记忆
class ExtractedMemory {
  final String content;
  final MemoryType type;
  final double confidence;
  final List<String> keywords;

  const ExtractedMemory({
    required this.content,
    this.type = MemoryType.fact,
    this.confidence = 1.0,
    this.keywords = const [],
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'type': type.name,
    'confidence': confidence,
    'keywords': keywords,
  };
}

/// 场景聚合结果
class SceneAggregationResult {
  final String title;
  final String description;
  final List<int> memoryIds;
  final List<String> tags;

  const SceneAggregationResult({
    required this.title,
    required this.description,
    required this.memoryIds,
    required this.tags,
  });
}

/// 人物画像更新结果
class PersonaUpdateResult {
  final String preferences;
  final String? skills;
  final List<String> preferredTools;
  final String? communicationStyle;
  final String? projectContext;

  const PersonaUpdateResult({
    required this.preferences,
    this.skills,
    this.preferredTools = const [],
    this.communicationStyle,
    this.projectContext,
  });
}

/// 记忆提取服务
/// 
/// 使用LLM从对话中提取记忆（L1）、聚合场景（L2）、更新画像（L3）
class MemoryExtractor {
  final ChatModel extractionModel;
  
  MemoryExtractor({required this.extractionModel});

  /// L1: 从对话中提取原子记忆
  Future<ExtractionResult> extractL1Memories(List<L0Conversation> conversations) async {
    if (conversations.isEmpty) {
      return const ExtractionResult(memories: [], rawResponse: '');
    }

    final prompt = _buildL1ExtractionPrompt(conversations);
    
    try {
      final provider = LlmHub.createProvider(extractionModel);
      final response = await provider.sendMessage(
        userMessage: ChatMessage(
          msgId: 'extraction_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: prompt,
          timestamp: DateTime.now(),
        ),
      );

      if (response == null || response.isEmpty) {
        return ExtractionResult.error('LLM返回空响应', '');
      }

      final memories = _parseL1ExtractionResponse(response);
      
      return ExtractionResult(
        memories: memories,
        rawResponse: response,
      );
    } catch (e) {
      debugPrint('❌ L1记忆提取失败: $e');
      return ExtractionResult.error(e.toString(), '');
    }
  }

  /// L2: 将L1记忆聚合为场景
  Future<List<SceneAggregationResult>> aggregateL2Scenes(
    List<L1Memory> memories, {
    int minClusterSize = 3,
  }) async {
    if (memories.length < minClusterSize) {
      return [];
    }

    final prompt = _buildL2AggregationPrompt(memories);
    
    try {
      final provider = LlmHub.createProvider(extractionModel);
      final response = await provider.sendMessage(
        userMessage: ChatMessage(
          msgId: 'aggregation_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: prompt,
          timestamp: DateTime.now(),
        ),
      );

      if (response == null || response.isEmpty) {
        return [];
      }

      return _parseL2AggregationResponse(response, memories);
    } catch (e) {
      debugPrint('❌ L2场景聚合失败: $e');
      return [];
    }
  }

  /// L3: 更新用户画像
  Future<PersonaUpdateResult?> updateL3Persona(
    L3Persona? existingPersona,
    List<L2Scene> recentScenes,
  ) async {
    if (recentScenes.isEmpty) {
      return null;
    }

    final prompt = _buildL3PersonaPrompt(existingPersona, recentScenes);
    
    try {
      final provider = LlmHub.createProvider(extractionModel);
      final response = await provider.sendMessage(
        userMessage: ChatMessage(
          msgId: 'persona_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: prompt,
          timestamp: DateTime.now(),
        ),
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      return _parseL3PersonaResponse(response);
    } catch (e) {
      debugPrint('❌ L3画像更新失败: $e');
      return null;
    }
  }

  // ==================== Prompt构建 ====================

  String _buildL1ExtractionPrompt(List<L0Conversation> conversations) {
    final buffer = StringBuffer();
    buffer.writeln('## 任务');
    buffer.writeln('从以下对话中提取关键记忆信息。提取的事实应该是：');
    buffer.writeln('1. 具体且有意义的信息');
    buffer.writeln('2. 有助于未来理解用户上下文');
    buffer.writeln('3. 去重且简洁');
    buffer.writeln();
    buffer.writeln('## 可提取的记忆类型');
    buffer.writeln('- fact: 客观事实和信息');
    buffer.writeln('- preference: 用户偏好、习惯、风格');
    buffer.writeln('- goal: 目标、任务、计划');
    buffer.writeln('- project: 项目相关信息');
    buffer.writeln('- tool: 工具使用偏好和习惯');
    buffer.writeln('- code: 代码相关偏好（语言、框架等）');
    buffer.writeln('- learning: 学习记录和知识点');
    buffer.writeln('- other: 其他重要信息');
    buffer.writeln();
    buffer.writeln('## 对话记录');
    buffer.writeln();

    for (var i = 0; i < conversations.length; i++) {
      final c = conversations[i];
      buffer.writeln('--- 对话 ${i + 1} ---');
      buffer.writeln('用户: ${c.userText}');
      buffer.writeln('AI: ${c.assistantText}');
      buffer.writeln();
    }

    buffer.writeln('## 输出格式');
    buffer.writeln('请以JSON数组格式输出，每个记忆包含content、type、keywords字段：');
    buffer.writeln('```json');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "content": "用户偏好使用Flutter开发移动端应用",');
    buffer.writeln('    "type": "preference",');
    buffer.writeln('    "keywords": ["Flutter", "移动端", "开发偏好"]');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('如果对话中没有值得提取的信息，请返回空数组 []');

    return buffer.toString();
  }

  String _buildL2AggregationPrompt(List<L1Memory> memories) {
    final buffer = StringBuffer();
    buffer.writeln('## 任务');
    buffer.writeln('将以下原子记忆聚类为相关场景/主题。');
    buffer.writeln('每个场景应该是一组相关的记忆，代表一个完整的上下文或任务。');
    buffer.writeln();
    buffer.writeln('## 记忆列表');
    buffer.writeln();

    for (var i = 0; i < memories.length; i++) {
      final m = memories[i];
      buffer.writeln('${i + 1}. [${m.type.name}] ${m.content}');
      if (m.keywords.isNotEmpty) {
        buffer.writeln('   关键词: ${m.keywords.join(', ')}');
      }
      buffer.writeln();
    }

    buffer.writeln('## 输出格式');
    buffer.writeln('请以JSON数组格式输出，每个场景包含：');
    buffer.writeln('- title: 场景标题（简洁，3-10字）');
    buffer.writeln('- description: 场景描述（一段话总结）');
    buffer.writeln('- memoryIndices: 包含的记忆序号列表（从1开始）');
    buffer.writeln('- tags: 场景标签列表（3-5个关键词）');
    buffer.writeln();
    buffer.writeln('```json');
    buffer.writeln('[');
    buffer.writeln('  {');
    buffer.writeln('    "title": "Flutter项目开发",');
    buffer.writeln('    "description": "用户正在开发Flutter应用，涉及UI组件、状态管理等",');
    buffer.writeln('    "memoryIndices": [1, 3, 5],');
    buffer.writeln('    "tags": ["Flutter", "Dart", "移动开发", "UI"]');
    buffer.writeln('  }');
    buffer.writeln(']');
    buffer.writeln('```');

    return buffer.toString();
  }

  String _buildL3PersonaPrompt(L3Persona? existing, List<L2Scene> scenes) {
    final buffer = StringBuffer();
    buffer.writeln('## 任务');
    buffer.writeln('基于用户最近的场景活动，更新用户画像总结。');
    buffer.writeln('画像应该反映用户的长期偏好、技能和习惯。');
    buffer.writeln();

    if (existing != null && existing.preferences.isNotEmpty) {
      buffer.writeln('## 现有画像');
      buffer.writeln('偏好: ${existing.preferences}');
      if (existing.skills != null) {
        buffer.writeln('技能: ${existing.skills}');
      }
      if (existing.preferredTools.isNotEmpty) {
        buffer.writeln('常用工具: ${existing.preferredTools.join(', ')}');
      }
      if (existing.communicationStyle != null) {
        buffer.writeln('沟通风格: ${existing.communicationStyle}');
      }
      if (existing.projectContext != null) {
        buffer.writeln('项目背景: ${existing.projectContext}');
      }
      buffer.writeln();
    }

    buffer.writeln('## 最近场景活动');
    buffer.writeln();

    for (var i = 0; i < scenes.length && i < 10; i++) {
      final s = scenes[i];
      buffer.writeln('${i + 1}. ${s.title}');
      buffer.writeln('   ${s.description}');
      buffer.writeln('   标签: ${s.tags.join(', ')}');
      buffer.writeln();
    }

    buffer.writeln('## 输出格式');
    buffer.writeln('请以JSON格式输出更新后的画像：');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "preferences": "用户偏好...（总结性描述）",');
    buffer.writeln('  "skills": "技能描述...",');
    buffer.writeln('  "preferredTools": ["工具1", "工具2"],');
    buffer.writeln('  "communicationStyle": "沟通风格描述...",');
    buffer.writeln('  "projectContext": "当前项目背景..."');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln('注意：如果某项信息没有变化或无法确定，可以省略该字段。');

    return buffer.toString();
  }

  // ==================== 响应解析 ====================

  List<ExtractedMemory> _parseL1ExtractionResponse(String response) {
    final memories = <ExtractedMemory>[];
    
    try {
      // 提取JSON部分
      final jsonMatch = RegExp(r'\[\s*\{.*?\}\s*\]', dotAll: true).firstMatch(response);
      if (jsonMatch == null) {
        // 尝试整个响应作为JSON
        final parsed = jsonDecode(response);
        if (parsed is List) {
          for (final item in parsed) {
            final memory = _parseExtractedMemory(item);
            if (memory != null) memories.add(memory);
          }
        }
        return memories;
      }
      
      final jsonStr = jsonMatch.group(0);
      if (jsonStr == null) return memories;
      
      final parsed = jsonDecode(jsonStr);
      if (parsed is! List) return memories;
      
      for (final item in parsed) {
        final memory = _parseExtractedMemory(item);
        if (memory != null) memories.add(memory);
      }
    } catch (e) {
      debugPrint('解析L1提取结果失败: $e');
      debugPrint('原始响应: $response');
    }
    
    return memories;
  }

  ExtractedMemory? _parseExtractedMemory(dynamic item) {
    if (item is! Map) return null;
    
    final content = item['content'] as String?;
    if (content == null || content.isEmpty) return null;
    
    final typeStr = item['type'] as String? ?? 'fact';
    final type = MemoryType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => MemoryType.fact,
    );
    
    final keywords = (item['keywords'] as List<dynamic>?)
        ?.map((k) => k.toString())
        .toList() ?? [];
    
    return ExtractedMemory(
      content: content,
      type: type,
      keywords: keywords,
    );
  }

  List<SceneAggregationResult> _parseL2AggregationResponse(
    String response,
    List<L1Memory> sourceMemories,
  ) {
    final scenes = <SceneAggregationResult>[];
    
    try {
      final jsonMatch = RegExp(r'\[\s*\{.*?\}\s*\]', dotAll: true).firstMatch(response);
      if (jsonMatch == null) return scenes;
      
      final parsed = jsonDecode(jsonMatch.group(0)!);
      if (parsed is! List) return scenes;
      
      for (final item in parsed) {
        if (item is! Map) continue;
        
        final title = item['title'] as String?;
        final description = item['description'] as String?;
        final indices = item['memoryIndices'] as List<dynamic>?;
        final tags = item['tags'] as List<dynamic>?;
        
        if (title == null || description == null || indices == null) continue;
        
        // 将序号转换为实际ID
        final memoryIds = indices
            .map((i) => (i as num).toInt() - 1)
            .where((i) => i >= 0 && i < sourceMemories.length)
            .map((i) => sourceMemories[i].id)
            .toList();
        
        if (memoryIds.isEmpty) continue;
        
        scenes.add(SceneAggregationResult(
          title: title,
          description: description,
          memoryIds: memoryIds,
          tags: tags?.map((t) => t.toString()).toList() ?? [],
        ));
      }
    } catch (e) {
      debugPrint('解析L2聚合结果失败: $e');
    }
    
    return scenes;
  }

  PersonaUpdateResult? _parseL3PersonaResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[^{}]*"preferences"[^}]*\}', dotAll: true).firstMatch(response);
      if (jsonMatch == null) return null;
      
      final parsed = jsonDecode(jsonMatch.group(0)!);
      if (parsed is! Map) return null;
      
      return PersonaUpdateResult(
        preferences: parsed['preferences'] as String? ?? '',
        skills: parsed['skills'] as String?,
        preferredTools: (parsed['preferredTools'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .toList() ?? [],
        communicationStyle: parsed['communicationStyle'] as String?,
        projectContext: parsed['projectContext'] as String?,
      );
    } catch (e) {
      debugPrint('解析L3画像结果失败: $e');
      return null;
    }
  }
}
