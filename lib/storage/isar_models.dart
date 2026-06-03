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

/// Isar 集合：MCP 服务配置（独立字段存储，不再使用 JSON 大对象）
@collection
class IsarMcpService {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String mcpId;

  late String name;
  late String command;
  late String argsJson;       // JSON for List<String>
  late String? envJson;       // JSON for Map<String,String>
  late String? workingDirectory;
  late int? timeout;
  late String? url;
  late String? headersJson;   // JSON for Map<String,String>
  late String? toolsJson;     // JSON for List<McpToolInfo>
  late DateTime? lastUpdated;
}

/// Isar 集合：通用键值设置（如主题偏好）
@collection
class IsarSettings {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
}

