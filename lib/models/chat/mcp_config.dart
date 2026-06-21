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
        return McpTransportType.http;
      case 'streamableHttp':
        return McpTransportType.streamableHttp;
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
  final String mcpId; // 唯一标识 ID
  final String name;
  final String? description; // 从 MCP 服务器 instructions 获取的描述
  final String code; // MCP 配置脚本（原始 JSON 配置，必定保存）

  // ── Stdio 类型配置 ──
  final String? command; // Stdio 命令（URL 型为 null）
  final List<String>? args; // Stdio 参数（URL 型为 null）
  final Map<String, String>? env;
  final String? workingDirectory;

  // ── URL 类型配置 ──
  final int? timeout;
  final String? url; // URL 型 MCP（HTTP/SSE/StreamableHTTP 传输）
  final Map<String, String>? headers; // URL 型请求头
  final Map<String, dynamic>? body; // 请求体额外参数（非标准 MCP 扩展，如 appid/secret）
  final McpTransportType? type; // 传输协议枚举

  // ── 运行时数据 ──
  final String? version; // MCP 服务器版本号（来自 serverInfo.version）
  final List<McpToolInfo>? tools; // 工具信息列表
  final DateTime? lastUpdated; // 最后更新时间
  final String? prompt; // LLM 用的工具介绍文本（添加/刷新时生成）

  const Mcp({
    required this.mcpId,
    required this.name,
    this.description,
    required this.code,
    this.command,
    this.args,
    this.env,
    this.workingDirectory,
    this.timeout,
    this.url,
    this.headers,
    this.body,
    this.type,
    this.version,
    this.tools,
    this.lastUpdated,
    this.prompt,
  });

  /// 从包含 name 字段的 Map 反序列化
  factory Mcp.fromMap(Map<String, dynamic> json) {
    return Mcp.fromJson(
      json['name'] as String? ?? '',
      json,
    );
  }

  factory Mcp.fromJson(String name, Map<String, dynamic> json) {
    final toolsList = json['tools'] as List<dynamic>?;
    final tools =
        toolsList
            ?.map((tool) => McpToolInfo.fromJson(tool as Map<String, dynamic>))
            .toList();

    final lastUpdatedStr = json['lastUpdated'] as String?;
    final lastUpdated =
        lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

    // 兜底：确保 name 和 mcpId 至少有一个有效值
    final rawName = name.isNotEmpty ? name : (json['mcpId'] as String? ?? '');
    final rawMcpId = (json['mcpId'] as String? ?? '').isNotEmpty
        ? json['mcpId'] as String
        : rawName;
    final fallback = rawName.isNotEmpty
        ? rawName
        : 'mcp_${jsonEncode(json).hashCode}';
    final effectiveName = rawName.isNotEmpty ? rawName : fallback;
    final effectiveMcpId = rawMcpId.isNotEmpty ? rawMcpId : fallback;

    return Mcp(
      mcpId: effectiveMcpId,
      name: effectiveName,
      description: json['description'] as String?,
      code: json['code'] as String? ?? jsonEncode(json),
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
      body: json['body'] != null
          ? Map<String, dynamic>.from(json['body'] as Map)
          : null,
      type: McpTransportTypeExt.fromString(json['type'] as String?),
      version: json['version'] as String?,
      tools: tools,
      lastUpdated: lastUpdated,
      prompt: json['prompt'] as String?,
    );
  }

  /// 序列化为标准 MCP 服务配置 JSON（不含内部字段，用于导出/展示）
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
    if (body != null && body!.isNotEmpty) data['body'] = body;

    // 通用
    if (timeout != null) data['timeout'] = timeout;

    return data;
  }

  /// 序列化为包含所有字段的完整 JSON（用于展示/导出）
  Map<String, dynamic> toFullJson() {
    final data = toJson();
    data['mcpId'] = mcpId;
    data['name'] = name;
    if (description != null) data['description'] = description;
    data['code'] = code;
    if (version != null) data['version'] = version;
    if (workingDirectory != null) data['workingDirectory'] = workingDirectory;
    if (prompt != null && prompt!.isNotEmpty) data['prompt'] = prompt;
    if (tools != null && tools!.isNotEmpty) {
      data['tools'] = tools!.map((tool) => tool.toJson()).toList();
    }
    if (lastUpdated != null) {
      data['lastUpdated'] = lastUpdated!.toIso8601String();
    }
    return data;
  }

  /// 创建带有工具信息的副本
  Mcp copyWith({
    String? mcpId,
    String? name,
    String? description,
    String? code, // 允许为空以支持 copyWith(code: null) 不覆盖场景，但实际创建时必填
    String? command,
    List<String>? args,
    Map<String, String>? env,
    String? workingDirectory,
    int? timeout,
    String? url,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    McpTransportType? type,
    String? version,
    List<McpToolInfo>? tools,
    DateTime? lastUpdated,
    String? prompt,
  }) {
    return Mcp(
      mcpId: mcpId ?? this.mcpId,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      command: command ?? this.command,
      args: args ?? this.args,
      env: env ?? this.env,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      timeout: timeout ?? this.timeout,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      type: type ?? this.type,
      version: version ?? this.version,
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
          code: '{"command":"npx","args":["-y","12306-mcp"]}',
          command: 'npx',
          args: ['-y', '12306-mcp'],
        ),
        'filesystem': Mcp(
          mcpId: 'filesystem',
          name: 'filesystem',
          code: '{"command":"npx","args":["-y","@modelcontextprotocol/server-filesystem","/path/to/allowed/files"]}',
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
          code: '{"command":"npx","args":["-y","@modelcontextprotocol/server-sqlite","/path/to/database.db"]}',
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
