import 'dart:convert';

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
class McpServerConfig {
  final String name;
  final String command;
  final List<String> args;
  final Map<String, String>? env;
  final String? workingDirectory;
  final int? timeout;
  final String? url; // URL 型 MCP（HTTP/SSE 传输）
  final Map<String, String>? headers; // URL 型请求头
  final List<McpToolInfo>? tools; // 新增：工具信息列表
  final DateTime? lastUpdated; // 新增：最后更新时间

  const McpServerConfig({
    required this.name,
    required this.command,
    required this.args,
    this.env,
    this.workingDirectory,
    this.timeout,
    this.url,
    this.headers,
    this.tools,
    this.lastUpdated,
  });

  factory McpServerConfig.fromJson(String name, Map<String, dynamic> json) {
    final toolsList = json['tools'] as List<dynamic>?;
    final tools =
        toolsList
            ?.map((tool) => McpToolInfo.fromJson(tool as Map<String, dynamic>))
            .toList();

    final lastUpdatedStr = json['lastUpdated'] as String?;
    final lastUpdated =
        lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

    return McpServerConfig(
      name: name,
      command: json['command'] as String? ?? '',
      args: List<String>.from(json['args'] ?? []),
      env: json['env'] != null ? Map<String, String>.from(json['env']) : null,
      workingDirectory: json['workingDirectory'] as String?,
      timeout: json['timeout'] as int?,
      url: json['url'] as String?,
      headers: json['headers'] != null ? Map<String, String>.from(json['headers']) : null,
      tools: tools,
      lastUpdated: lastUpdated,
    );
  }

  /// 从包含 name 字段的 Map 反序列化（用于独立存储）
  factory McpServerConfig.fromMap(Map<String, dynamic> json) {
    return McpServerConfig.fromJson(
      json['name'] as String? ?? '',
      json,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'name': name, 'command': command, 'args': args};

    if (env != null) data['env'] = env;
    if (workingDirectory != null) data['workingDirectory'] = workingDirectory;
    if (timeout != null) data['timeout'] = timeout;
    if (url != null) data['url'] = url;
    if (headers != null) data['headers'] = headers;
    if (tools != null) {
      data['tools'] = tools!.map((tool) => tool.toJson()).toList();
    }
    if (lastUpdated != null) {
      data['lastUpdated'] = lastUpdated!.toIso8601String();
    }

    return data;
  }

  /// 创建带有工具信息的副本
  McpServerConfig copyWith({
    String? name,
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? workingDirectory,
    int? timeout,
    String? url,
    Map<String, String>? headers,
    List<McpToolInfo>? tools,
    DateTime? lastUpdated,
  }) {
    return McpServerConfig(
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      timeout: timeout ?? this.timeout,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      tools: tools ?? this.tools,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'McpServerConfig(name: $name, command: $command, args: $args, tools: ${tools?.length ?? 0})';
  }
}

/// MCP配置文件模型
class McpConfig {
  final Map<String, McpServerConfig> mcpServers;
  final String? version;

  const McpConfig({required this.mcpServers, this.version});

  factory McpConfig.fromJson(Map<String, dynamic> json) {
    final servers = <String, McpServerConfig>{};
    final mcpServersJson = json['mcpServers'] as Map<String, dynamic>? ?? {};

    for (final entry in mcpServersJson.entries) {
      servers[entry.key] = McpServerConfig.fromJson(
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
        '12306-mcp': McpServerConfig(
          name: '12306-mcp',
          command: 'npx',
          args: ['-y', '12306-mcp'],
        ),
        'filesystem': McpServerConfig(
          name: 'filesystem',
          command: 'npx',
          args: [
            '-y',
            '@modelcontextprotocol/server-filesystem',
            '/path/to/allowed/files',
          ],
        ),
        'sqlite': McpServerConfig(
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
