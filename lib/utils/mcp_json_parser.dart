import 'dart:convert';

/// MCP JSON 解析结果
class McpParseResult {
  final String name;
  final Map<String, dynamic> serverJson; // 完整的 server.json 内容
  final Map<String, dynamic> serverConfig; // 单个服务器配置
  final String? description;
  final String? command;
  final List<String>? args;
  final String? url;
  final Map<String, String>? headers;

  McpParseResult({
    required this.name,
    required this.serverJson,
    required this.serverConfig,
    this.description,
    this.command,
    this.args,
    this.url,
    this.headers,
  });
}

/// MCP JSON 解析器
///
/// 支持多种输入格式：
/// 1. 标准 mcpServers 格式
/// 2. 直接配置格式
/// 3. URL 格式
class McpJsonParser {
  /// 解析 JSON 字符串
  static McpParseResult? parse(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr.trim());
      if (json is! Map<String, dynamic>) return null;
      return _parseJson(json);
    } catch (e) {
      return null;
    }
  }

  /// 解析 JSON 对象
  static McpParseResult? _parseJson(Map<String, dynamic> json) {
    // 格式1: 标准 mcpServers 格式
    // { "mcpServers": { "name": { "command": "...", "args": [...] } } }
    if (json.containsKey('mcpServers')) {
      return _parseMcpServersFormat(json);
    }

    // 格式2: 直接配置格式
    // { "command": "...", "args": [...] }
    if (json.containsKey('command') || json.containsKey('url')) {
      return _parseDirectFormat(json);
    }

    // 格式3: 顶层有 name 字段
    // { "name": "...", "command": "...", "args": [...] }
    if (json.containsKey('name')) {
      return _parseNamedFormat(json);
    }

    return null;
  }

  /// 解析 mcpServers 格式
  static McpParseResult? _parseMcpServersFormat(Map<String, dynamic> json) {
    final mcpServers = json['mcpServers'] as Map<String, dynamic>?;
    if (mcpServers == null || mcpServers.isEmpty) return null;

    final serverName = mcpServers.keys.first;
    final serverConfig = mcpServers[serverName] as Map<String, dynamic>;

    return McpParseResult(
      name: serverName,
      serverJson: json,
      serverConfig: serverConfig,
      description: _extractDescription(serverConfig),
      command: serverConfig['command'] as String?,
      args: _extractArgs(serverConfig),
      url: serverConfig['url'] as String?,
      headers: _extractHeaders(serverConfig),
    );
  }

  /// 解析直接配置格式（无 mcpServers 包装）
  static McpParseResult? _parseDirectFormat(Map<String, dynamic> json) {
    // 尝试从 URL 或 command 生成名称
    final command = json['command'] as String?;
    final url = json['url'] as String?;
    final name = _generateName(command, url);

    // 包装为标准格式
    final wrappedJson = {
      'mcpServers': {
        name: json,
      },
    };

    return McpParseResult(
      name: name,
      serverJson: wrappedJson,
      serverConfig: json,
      description: _extractDescription(json),
      command: command,
      args: _extractArgs(json),
      url: url,
      headers: _extractHeaders(json),
    );
  }

  /// 解析带 name 字段的格式
  static McpParseResult? _parseNamedFormat(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final config = Map<String, dynamic>.from(json)..remove('name');

    final wrappedJson = {
      'mcpServers': {
        name: config,
      },
    };

    return McpParseResult(
      name: name,
      serverJson: wrappedJson,
      serverConfig: config,
      description: _extractDescription(config),
      command: config['command'] as String?,
      args: _extractArgs(config),
      url: config['url'] as String?,
      headers: _extractHeaders(config),
    );
  }

  /// 提取描述
  static String? _extractDescription(Map<String, dynamic> config) {
    return config['description'] as String? ??
        config['desc'] as String? ??
        config['instructions'] as String?;
  }

  /// 提取 args
  static List<String>? _extractArgs(Map<String, dynamic> config) {
    final args = config['args'] as List?;
    if (args == null) return null;
    return args.map((e) => e.toString()).toList();
  }

  /// 提取 headers
  static Map<String, String>? _extractHeaders(Map<String, dynamic> config) {
    final headers = config['headers'] as Map<String, dynamic>?;
    if (headers == null) return null;
    return headers.map((k, v) => MapEntry(k, v.toString()));
  }

  /// 根据 command/url 生成名称
  static String _generateName(String? command, String? url) {
    if (command != null && command.isNotEmpty) {
      // 从 command 提取包名
      // 例如: npx -y @negokaz/excel-mcp-server → @negokaz/excel-mcp-server
      if (command == 'npx' || command == 'npm' || command == 'node') {
        // 查找 args 中的包名
        return 'mcp_${DateTime.now().millisecondsSinceEpoch}';
      }
      return command.split('/').last.split(' ').first;
    }
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        return uri.host.replaceAll('.', '_');
      } catch (_) {}
    }
    return 'mcp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 验证配置是否有效
  static String? validate(String jsonStr) {
    if (jsonStr.trim().isEmpty) return '请输入 JSON 配置';

    final result = parse(jsonStr);
    if (result == null) return 'JSON 格式无效';

    // 检查是否有 command 或 url
    if (result.command == null && result.url == null) {
      return '缺少 command 或 url 字段';
    }

    return null; // 有效
  }
}
