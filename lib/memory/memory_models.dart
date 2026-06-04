import 'package:isar/isar.dart';

part 'memory_models.g.dart';

/// L0: 原始对话记录
@Collection()
class L0Conversation {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionKey;

  @Index()
  late String sessionId;

  late DateTime timestamp;

  /// 用户消息
  late String userText;

  /// AI回复
  late String assistantText;

  /// 完整消息列表（JSON格式存储）
  late String messagesJson;

  /// 是否已处理为L1记忆
  @Index()
  bool processedToL1 = false;

  /// 处理时间
  DateTime? processedAt;
}

/// L1: 原子记忆（提取的关键事实）
@Collection()
class L1Memory {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionKey;

  /// 记忆内容
  late String content;

  /// 记忆类型
  @enumerated
  late MemoryType type;

  /// 来源对话ID列表
  List<int> sourceConversationIds = [];

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间（如果被更新）
  DateTime? updatedAt;

  /// 关联的场景ID
  @Index()
  int? sceneId;

  /// 向量嵌入（JSON格式）
  String? embeddingJson;

  /// 置信度分数 (0.0 - 1.0)
  double confidence = 1.0;

  /// 关键词（用于快速检索）
  List<String> keywords = [];
}

/// L2: 场景/情景块
@Collection()
class L2Scene {
  Id id = Isar.autoIncrement;

  @Index()
  late String sessionKey;

  /// 场景标题
  late String title;

  /// 场景描述
  late String description;

  /// 包含的记忆ID列表
  List<int> memoryIds = [];

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  DateTime? updatedAt;

  /// 场景向量（用于相似度检索）
  String? embeddingJson;

  /// 时间范围
  DateTime? startTime;
  DateTime? endTime;

  /// 关键词标签
  List<String> tags = [];
}

/// L3: 用户画像
@Collection()
class L3Persona {
  Id id = Isar.autoIncrement;

  /// 用户ID
  @Index(unique: true)
  late String userId;

  /// 画像版本
  int version = 1;

  /// 偏好总结
  late String preferences;

  /// 技能和经验
  String? skills;

  /// 常用工具和框架
  List<String> preferredTools = [];

  /// 沟通风格
  String? communicationStyle;

  /// 项目背景
  String? projectContext;

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 关联的场景ID列表（可追溯）
  List<int> sourceSceneIds = [];
}

/// 记忆类型枚举
enum MemoryType {
  /// 事实信息
  fact,

  /// 用户偏好
  preference,

  /// 任务目标
  goal,

  /// 项目信息
  project,

  /// 工具使用
  tool,

  /// 代码相关
  code,

  /// 学习记录
  learning,

  /// 其他
  other,
}

/// 记忆检索结果
class MemoryRecallResult {
  /// 动态检索到的L1记忆（追加到用户消息前）
  final List<L1Memory> relevantMemories;

  /// 系统提示词追加内容（稳定记忆）
  final String? systemContextAppend;

  /// L3人物画像内容
  final L3Persona? persona;

  /// 检索策略
  final String recallStrategy;

  const MemoryRecallResult({
    this.relevantMemories = const [],
    this.systemContextAppend,
    this.persona,
    this.recallStrategy = 'hybrid',
  });

  /// 获取格式化的记忆上下文
  String get formattedMemoryContext {
    if (relevantMemories.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## 相关历史记忆');
    buffer.writeln();

    for (var i = 0; i < relevantMemories.length; i++) {
      final memory = relevantMemories[i];
      buffer.writeln('${i + 1}. ${memory.content}');
    }

    return buffer.toString();
  }
}

/// 记忆统计信息
class MemoryStats {
  final int l0Count;
  final int l1Count;
  final int l2Count;
  final bool hasL3;
  final DateTime? lastL1Extraction;
  final DateTime? lastL2Aggregation;
  final DateTime? lastL3Update;

  const MemoryStats({
    required this.l0Count,
    required this.l1Count,
    required this.l2Count,
    required this.hasL3,
    this.lastL1Extraction,
    this.lastL2Aggregation,
    this.lastL3Update,
  });
}

/// 记忆配置
class MemoryConfig {
  /// 是否启用记忆系统
  final bool enabled;

  /// 存储后端
  final String storeBackend;

  /// 召回策略: keyword, embedding, hybrid
  final String recallStrategy;

  /// 每次召回的最大记忆数
  final int maxRecallResults;

  /// 每N轮对话触发L1提取
  final int extractionInterval;

  /// 触发L2聚合的最小L1记忆数
  final int l2TriggerThreshold;

  /// 触发L3更新的最小L2场景数
  final int l3TriggerThreshold;

  /// 空闲多久后触发L1提取（秒）
  final int l1IdleTimeoutSeconds;

  /// 最大记忆字符数限制
  final int maxMemoryChars;

  /// 是否启用去重
  final bool enableDeduplication;

  const MemoryConfig({
    this.enabled = true,
    this.storeBackend = 'sqlite',
    this.recallStrategy = 'hybrid',
    this.maxRecallResults = 5,
    this.extractionInterval = 5,
    this.l2TriggerThreshold = 10,
    this.l3TriggerThreshold = 5,
    this.l1IdleTimeoutSeconds = 600,
    this.maxMemoryChars = 0,
    this.enableDeduplication = true,
  });

  factory MemoryConfig.fromJson(Map<String, dynamic> json) {
    return MemoryConfig(
      enabled: json['enabled'] ?? true,
      storeBackend: json['storeBackend'] ?? 'sqlite',
      recallStrategy: json['recallStrategy'] ?? 'hybrid',
      maxRecallResults: json['maxRecallResults'] ?? 5,
      extractionInterval: json['extractionInterval'] ?? 5,
      l2TriggerThreshold: json['l2TriggerThreshold'] ?? 10,
      l3TriggerThreshold: json['l3TriggerThreshold'] ?? 5,
      l1IdleTimeoutSeconds: json['l1IdleTimeoutSeconds'] ?? 600,
      maxMemoryChars: json['maxMemoryChars'] ?? 0,
      enableDeduplication: json['enableDeduplication'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'storeBackend': storeBackend,
    'recallStrategy': recallStrategy,
    'maxRecallResults': maxRecallResults,
    'extractionInterval': extractionInterval,
    'l2TriggerThreshold': l2TriggerThreshold,
    'l3TriggerThreshold': l3TriggerThreshold,
    'l1IdleTimeoutSeconds': l1IdleTimeoutSeconds,
    'maxMemoryChars': maxMemoryChars,
    'enableDeduplication': enableDeduplication,
  };
}
