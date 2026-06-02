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
  late String? chatModelJson;
  late String? mcpServerJson;
  late String? skillJson;
  late String? attachmentsJson;
  late String? sessionQuickCommandsJson;

  /// 记忆轮数（0 = 无记忆）
  late int memoryRounds;

  /// 深度思考模式
  late bool deepThink;

  /// 标记是否为当前活动会话
  @Index()
  late bool isCurrent;
}

/// Isar 集合：MCP 服务配置
@collection
class IsarMcpService {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  /// 完整的 McpServerConfig JSON
  late String configJson;
}

/// Isar 集合：通用键值设置（如主题偏好）
@collection
class IsarSettings {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String key;

  late String value;
}

