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
class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  factory McpTool.fromJson(Map<String, dynamic> json) {
    return McpTool(
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

  /// 转为 OpenAI function calling 格式
  Map<String, dynamic> toOpenAIFunction() {
    final func = <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{
        'name': name,
        'description': description,
      },
    };
    if (inputSchema.isNotEmpty) {
      final schema = Map<String, dynamic>.from(inputSchema);
      schema.putIfAbsent('type', () => 'object');
      schema.putIfAbsent('properties', () => <String, dynamic>{});
      func['function']['parameters'] = schema;
    } else {
      func['function']['parameters'] = {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      };
    }
    return func;
  }

  @override
  String toString() {
    return 'McpTool(name: $name, description: $description)';
  }
}

/// MCP 服务模型
///
/// 与磁盘上的 `server.json` 完全对应，合并了原 `config.json`（工具/描述等元信息）
/// 与原 `server.json`（连接配置：command/args/env/url 等）的内容。
///
/// 字段说明：
/// - 连接配置：command / args / env / workingDirectory（Stdio 型）、
///   url / type / headers / body（URL 型）、timeout（通用）
/// - 元信息：description / version / prompt / tools / lastUpdated
class Mcp {
  final String name; // 唯一标识（与文件夹名一致）
  final String? description; // 描述

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

  // ── 元信息（原 config.json）──
  final String? version; // MCP 服务器版本号
  final String? prompt; // LLM 用的工具介绍文本
  final List<McpTool>? tools; // 工具信息列表
  final DateTime? lastUpdated; // 最后更新时间

  const Mcp({
    required this.name,
    this.description,
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
    this.prompt,
    this.tools,
    this.lastUpdated,
  });

  /// 从包含 name 字段的 Map 反序列化
  factory Mcp.fromMap(Map<String, dynamic> json) {
    return Mcp.fromJson(
      json['name'] as String? ?? (json['mcpId'] as String? ?? ''),
      json,
    );
  }

  factory Mcp.fromJson(String name, Map<String, dynamic> json) {
    // 兼容 mcpServers 包装格式：{ "mcpServers": { "name": {...} } }
    Map<String, dynamic> data = json;
    if (json.containsKey('mcpServers')) {
      final mcpServers = json['mcpServers'] as Map<String, dynamic>? ?? {};
      if (mcpServers.isNotEmpty) {
        final first = mcpServers.values.first as Map<String, dynamic>;
        data = <String, dynamic>{...first, ...json}..remove('mcpServers');
      }
    }

    // 兜底：确保 name 有有效值
    final rawName = name.isNotEmpty ? name : (data['name'] as String? ?? '');
    final fallback = rawName.isNotEmpty
        ? rawName
        : 'mcp_${jsonEncode(json).hashCode}';
    final effectiveName = rawName.isNotEmpty ? rawName : fallback;

    final toolsList = data['tools'] as List<dynamic>?;
    final tools = toolsList
        ?.map((tool) => McpTool.fromJson(tool as Map<String, dynamic>))
        .toList();

    final lastUpdatedStr = data['lastUpdated'] as String?;
    final lastUpdated =
        lastUpdatedStr != null ? DateTime.tryParse(lastUpdatedStr) : null;

    return Mcp(
      name: effectiveName,
      description: data['description'] as String?,
      command: data['command'] as String?,
      args: data['args'] != null ? List<String>.from(data['args']) : null,
      env: data['env'] != null ? Map<String, String>.from(data['env']) : null,
      workingDirectory: data['workingDirectory'] as String?,
      timeout: data['timeout'] as int?,
      url: data['url'] as String?,
      headers: data['headers'] != null
          ? Map<String, String>.from(data['headers'])
          : null,
      body: data['body'] != null
          ? Map<String, dynamic>.from(data['body'] as Map)
          : null,
      type: McpTransportTypeExt.fromString(data['type'] as String?),
      version: data['version'] as String?,
      prompt: data['prompt'] as String?,
      tools: tools,
      lastUpdated: lastUpdated,
    );
  }

  /// 序列化为 server.json（与本对象内容完全对应）
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
    };
    if (description != null) data['description'] = description;

    // Stdio 类型配置
    if (command != null && command!.isNotEmpty) data['command'] = command;
    if (args != null && args!.isNotEmpty) data['args'] = args;
    if (env != null && env!.isNotEmpty) data['env'] = env;
    if (workingDirectory != null && workingDirectory!.isNotEmpty) {
      data['workingDirectory'] = workingDirectory;
    }

    // URL 类型配置
    if (url != null && url!.isNotEmpty) data['url'] = url;
    if (type != null) data['type'] = type!.value;
    if (headers != null && headers!.isNotEmpty) data['headers'] = headers;
    if (body != null && body!.isNotEmpty) data['body'] = body;

    // 通用
    if (timeout != null) data['timeout'] = timeout;

    // 元信息（原 config.json）
    if (version != null) data['version'] = version;
    if (prompt != null && prompt!.isNotEmpty) data['prompt'] = prompt;
    if (tools != null && tools!.isNotEmpty) {
      data['tools'] = tools!.map((tool) => tool.toJson()).toList();
    }
    if (lastUpdated != null) {
      data['lastUpdated'] = lastUpdated!.toIso8601String();
    }

    return data;
  }

  /// 序列化为完整 JSON（用于展示/导出，与 toJson 一致）
  Map<String, dynamic> toFullJson() => toJson();

  /// 创建副本
  Mcp copyWith({
    String? name,
    String? description,
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
    String? prompt,
    List<McpTool>? tools,
    DateTime? lastUpdated,
  }) {
    return Mcp(
      name: name ?? this.name,
      description: description ?? this.description,
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
      prompt: prompt ?? this.prompt,
      tools: tools ?? this.tools,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Mcp(name: $name, command: $command, url: $url, tools: ${tools?.length ?? 0})';
  }
}
