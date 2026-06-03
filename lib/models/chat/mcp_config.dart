import 'dart:convert';

/// MCP 传输协议枚举
enum McpTransportType { sse, http, streamableHttp }

extension McpTransportTypeExt on McpTransportType {
  String get value {
    switch (this) {
      case McpTransportType.sse:
        return 'sse';
      case McpTransportType.http:
        return 'http';
      case McpTransportType.streamableHttp:
        return 'streamableHttp';
    }
  }

  static McpTransportType? fromString(String? s) {
    switch (s) {
      case 'sse':
        return McpTransportType.sse;
      case 'http':
      case 'streamableHttp':
        return McpTransportType.http;
      default:
        return null;
    }
  }
}

/// MCP工具信息模型
class McpToolInfo {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpToolInfo({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  factory McpToolInfo.fromJson(Map<String, dynamic> json) {
    return McpToolInfo(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      inputSchema: json['inputSchema'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }

  @override
  String toString() {
    return 'McpToolInfo(name: $name, description: $description)';
  }
}

/// MCP服务器配置模型
class Mcp {
  /// 数据库原始 JSON 内容（从 content 字段读出，toFullJson 直接返回此内容）
  final String? content;

  /// 系统生成的唯一标识（添加时由调用方生成 UUID/时间戳）
  final String mcpId;

  final String name;

  // ── 以下字段运行时从 content 解析，不独立持久化 ──
  final String? command; // Stdio 命令（URL 型为 null）
  final List<String>? args; // Stdio 参数（URL 型为 null）
  final Map<String, String>? env;
  final String? workingDirectory;
  final int? timeout;
  final String? url; // URL 型 MCP（HTTP/SSE/StreamableHTTP 传输）
  final Map<String, String>? headers; // URL 型请求头
  final McpTransportType? type; // 传输协议枚举
  final List<McpToolInfo>? tools; // 工具信息列表
  final DateTime? lastUpdated; // 最后更新时间
  final String? prompt; // LLM 用的工具介绍文本（添加/刷新时生成）

  const Mcp({
    this.content,
    required this.mcpId,
    required this.name,
    this.command,
    this.args,
    this.env,
    this.workingDirectory,
    this.timeout,
    this.url,
    this.headers,
    this.type,
    this.tools,
    this.lastUpdated,
    this.prompt,
  });

  /// 从数据库 content JSON 反序列化（核心入口）
  factory Mcp.fromContent(String content) {
    final map = jsonDecode(content) as Map<String, dynamic>;
    return Mcp.fromMap(map, content: content);
  }

  factory Mcp.fromJson(String name, Map<String, dynamic> json, {String? content}) {
    final toolsList = json['tools'] as List<dynamic>?;
    final tools =
        toolsList
            ?.map((tool) => McpToolInfo.fromJson(tool as Map<String, dynamic>))
            .toList();

    final lastUpdatedStr = json['lastUpdated'] as String?;
    final lastUpdated =
        lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

    return Mcp(
      content: content,
      mcpId: json['mcpId'] as String? ?? name,
      name: name,
      command: json['command'] as String?,
      args: json['args'] != null ? List<String>.from(json['args']) : null,
      env: json['env'] != null ? Map<String, String>.from(json['env']) : null,
      workingDirectory: json['workingDirectory'] as String?,
      timeout: json['timeout'] as int?,
      url: json['url'] as String?,
      headers:
          json['headers'] != null
              ? Map<String, String>.from(json['headers'])
              : null,
      type: McpTransportTypeExt.fromString(json['type'] as String?),
      tools: tools,
      lastUpdated: lastUpdated,
      prompt: json['prompt'] as String?,
    );
  }

  /// 从包含 name 字段的 Map 反序列化（用于独立存储）
  factory Mcp.fromMap(Map<String, dynamic> json, {String? content}) {
    return Mcp.fromJson(
      json['name'] as String? ?? '',
      json,
      content: content ?? jsonEncode(json),
    );
  }

  /// 序列化为标准 MCP 服务配置 JSON（不含内部字段）
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Stdio 类型配置
    if (command != null && command!.isNotEmpty) data['command'] = command;
    if (args != null && args!.isNotEmpty) data['args'] = args;
    if (env != null && env!.isNotEmpty) data['env'] = env;

    // URL 类型配置
    if (url != null && url!.isNotEmpty) data['url'] = url;
    if (type != null) data['type'] = type!.value;
    if (headers != null && headers!.isNotEmpty) data['headers'] = headers;

    // 通用
    if (timeout != null) data['timeout'] = timeout;

    return data;
  }

  /// 序列化为包含内部字段的完整 JSON（content 基础上叠加 prompt 等）
  Map<String, dynamic> toFullJson() {
    Map<String, dynamic> data;
    if (content != null && content!.isNotEmpty) {
      data = Map<String, dynamic>.from(jsonDecode(content!) as Map<String, dynamic>);
    } else {
      data = toJson();
      data['mcpId'] = mcpId;
      data['name'] = name;
      if (workingDirectory != null) data['workingDirectory'] = workingDirectory;
      if (tools != null) {
        data['tools'] = tools!.map((tool) => tool.toJson()).toList();
      }
      if (lastUpdated != null) {
        data['lastUpdated'] = lastUpdated!.toIso8601String();
      }
    }
    if (prompt != null && prompt!.isNotEmpty) data['prompt'] = prompt;
    return data;
  }

  /// 创建带有工具信息的副本
  Mcp copyWith({
    String? content,
    String? mcpId,
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? workingDirectory,
    int? timeout,
    String? url,
    Map<String, String>? headers,
    McpTransportType? type,
    List<McpToolInfo>? tools,
    DateTime? lastUpdated,
    String? prompt,
  }) {
    return Mcp(
      content: content ?? this.content,
      mcpId: mcpId ?? this.mcpId,
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      timeout: timeout ?? this.timeout,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      type: type ?? this.type,
      tools: tools ?? this.tools,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      prompt: prompt ?? this.prompt,
    );
  }

  @override
  String toString() {
    return 'Mcp(mcpId: $mcpId, name: $name, command: $command, tools: ${tools?.length ?? 0})';
  }
}

/// MCP配置文件模型
class McpConfig {
  final Map<String, Mcp> mcpServers;
  final String? version;

  const McpConfig({required this.mcpServers, this.version});

  factory McpConfig.fromJson(Map<String, dynamic> json) {
    final servers = <String, Mcp>{};
    final mcpServersJson = json['mcpServers'] as Map<String, dynamic>? ?? {};

    for (final entry in mcpServersJson.entries) {
      servers[entry.key] = Mcp.fromJson(
        entry.key,
        entry.value as Map<String, dynamic>,
      );
    }

    return McpConfig(mcpServers: servers, version: json['version'] as String?);
  }

  factory McpConfig.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return McpConfig.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> servers = {};
    for (final entry in mcpServers.entries) {
      servers[entry.key] = entry.value.toJson();
    }

    final Map<String, dynamic> data = {'mcpServers': servers};

    if (version != null) data['version'] = version;

    return data;
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// 创建默认配置示例
  factory McpConfig.defaultConfig() {
    return McpConfig(
      mcpServers: {
        '12306-mcp': Mcp(
          mcpId: '12306-mcp',
          name: '12306-mcp',
          command: 'npx',
          args: ['-y', '12306-mcp'],
        ),
        'filesystem': Mcp(
          mcpId: 'filesystem',
          name: 'filesystem',
          command: 'npx',
          args: [
            '-y',
            '@modelcontextprotocol/server-filesystem',
            '/path/to/allowed/files',
          ],
        ),
        'sqlite': Mcp(
          mcpId: 'sqlite',
          name: 'sqlite',
          command: 'npx',
          args: [
            '-y',
            '@modelcontextprotocol/server-sqlite',
            '/path/to/database.db',
          ],
        ),
      },
      version: '1.0.0',
    );
  }

  @override
  String toString() {
    return 'McpConfig(servers: ${mcpServers.keys.toList()}, version: $version)';
  }
}
