import 'package:isar/isar.dart';

part 'isar_models.g.dart';

/// Isar 集合：模型配置
@collection
class IsarChatModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String modelId;

  late String name;
  late String model;
  late String status;

  @Index()
  late String? type;

  @Index()
  late String? provider;

  late String? platform;

  late String? apiKey;
  late String? apiUrl;
  late DateTime? createdAt;
  late DateTime? updatedAt;
  late String? description;

  // JSON blobs for complex nested objects
  late String? chatSettingsJson;
  late String? mcpServicesJson;
  late String? chatCommandsJson;
  late String? skillsJson;
}

/// Isar 集合：聊天会话
@collection
class IsarChatSession {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String sessionId;

  late String name;
  late DateTime createdAt;
  late bool isFavorite;
  late bool isSending;
  late bool shouldStopResponse;
  late double scrollPosition;
  late String inputContent;
  late String? lastSelectedDirectory;

  /// 工作目录（会话绑定的文件操作目录）
  late String? workDirectory;

  // JSON blobs for complex nested data
  late String? messagesJson;
  @ignore late String? chatModelJson;
  @ignore late String? mcpServerJson;
  @ignore late String? skillJson;
  late String? attachmentsJson;
  late String? sessionQuickCommandsJson;
  late String? scheduledTasksJson;

  /// 记忆轮数（0 = 无记忆）
  late int memoryRounds;

  /// 深度思考模式
  late bool deepThink;

  /// 标记是否为当前活动会话
  @Index()
  late bool isCurrent;

  /// 绑定的模型ID（用于动态解析 ChatModel，放在末尾避免破坏旧数据字段索引）
  late String? modelId;

  /// 绑定的 MCP 服务名称
  late String? mcpId;

  /// 绑定的技能ID
  late String? skillId;
}

/// Isar 集合：MCP 服务配置（mcpId + 完整 JSON content）
@collection
class IsarMcpService {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String mcpId;

  /// 完整配置 JSON（标准 MCP 服务配置格式）
  late String content;
}

/// Isar 集合：通用键值设置（如主题偏好）
@collection
class IsarSettings {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
}

/// Isar 集合：MCP 供应商 API 密钥
@collection
class IsarVendorKey {
  Id id = Isar.autoIncrement;

  /// 供应商唯一标识（如 aliyun, modelscope, tencent）
  @Index(unique: true)
  late String vendorId;

  /// API 密钥（加密存储建议）
  late String apiKey;

  /// 最后更新时间
  late DateTime updatedAt;
}

