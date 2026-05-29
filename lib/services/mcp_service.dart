import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import '../models/bigmodel/mcp_config.dart';
import 'mcp_storage_service.dart';

/// MCP工具调用结果
class McpToolResult {
  final String toolName;
  final Map<String, dynamic> arguments;
  final String result;
  final bool isSuccess;
  final String? error;
  final DateTime timestamp;

  McpToolResult({
    required this.toolName,
    required this.arguments,
    required this.result,
    required this.isSuccess,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'toolName': toolName,
    'arguments': arguments,
    'result': result,
    'isSuccess': isSuccess,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// MCP 连接信息（初始化后获取的服务器信息 + 工具列表）
class McpConnectionInfo {
  final String serverName;
  final List<McpToolInfo> tools;

  const McpConnectionInfo({required this.serverName, required this.tools});
}

/// MCP服务管理类
class McpService {
  static final Map<String, Client> _clients = {};
  static final Map<String, List<Tool>> _availableTools = {};

  /// 更新配置中的工具信息
  static Future<void> _updateConfigWithToolInfo(
    McpServerConfig config,
    List<Tool> tools,
  ) async {
    try {
      // 将MCP工具转换为McpToolInfo
      final toolInfos =
          tools.map((tool) {
            return McpToolInfo(
              name: tool.name,
              description: tool.description,
              inputSchema: tool.inputSchema as Map<String, dynamic>? ?? {},
            );
          }).toList();

      // 创建带有工具信息的配置副本
      final updatedConfig = config.copyWith(
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );

      // 保存到缓存
      _cachedConfigs[config.name] = updatedConfig;

      debugPrint('✅ 已更新 ${config.name} 的工具信息: ${toolInfos.length} 个工具');
    } catch (e) {
      debugPrint('❌ 更新配置工具信息失败: ${config.name}, 错误: $e');
    }
  }

  /// 缓存的配置信息
  static final Map<String, McpServerConfig> _cachedConfigs = {};
  
  /// 全局 MCP 配置列表（从 McpStorageService 加载）
  static List<McpServerConfig> _globalMcpConfigs = [];
  static bool _globalConfigsLoaded = false;

  /// 确保全局 MCP 配置已加载到内存
  static Future<void> ensureGlobalConfigsLoaded() async {
    if (_globalConfigsLoaded) return;
    _globalMcpConfigs = await McpStorageService.loadMcpServices();
    _globalConfigsLoaded = true;
    debugPrint('📦 从存储加载了 ${_globalMcpConfigs.length} 个全局 MCP 服务配置');
  }

  /// 是否有全局 MCP 服务（同步，用于快速判断）
  static bool get hasGlobalMcpServices {
    // 如果已加载，用内存中的结果
    if (_globalConfigsLoaded) return _globalMcpConfigs.isNotEmpty;
    // 否则也检查缓存中是否有数据（通过 refresh/connect 等填入的）
    return _cachedConfigs.isNotEmpty;
  }

  /// 刷新单个 MCP 服务的工具列表（支持 stdio 和 SSE 两种传输方式）
  /// 返回获取到的工具信息列表，失败时抛出异常
  static Future<List<McpToolInfo>> refreshServiceTools(
    McpServerConfig config,
  ) async {
    debugPrint('🔄 ====== 开始刷新 MCP 服务工具: ${config.name} ======');
    debugPrint('   配置详情: name=${config.name}, url=${config.url}, command=${config.command}');
    debugPrint('   args=${config.args}, headers=${config.headers}');
    debugPrint('   timeout=${config.timeout}');

    // 清理旧连接
    debugPrint('   🧹 清理旧连接...');
    await _cleanupClient(config.name);

    // 创建客户端
    final client = Client(
      name: 'aidock-client-${config.name}',
      version: '1.0.0',
    );
    debugPrint('   📦 创建 Client: aidock-client-${config.name} v1.0.0');

    // 根据配置类型选择传输方式
    ClientTransport transport;
    if (config.url != null && config.url!.isNotEmpty) {
      // SSE (URL-based) 传输
      debugPrint('🔗 使用 SSE 传输: ${config.url}');
      final startTime = DateTime.now();
      transport = await SseClientTransport.create(
        serverUrl: config.url!,
        headers: config.headers,
      );
      debugPrint('   ⏱ SSE Transport 创建耗时: ${DateTime.now().difference(startTime).inMilliseconds}ms');
    } else {
      // stdio 传输
      debugPrint('🔗 使用 stdio 传输: ${config.command} ${config.args.join(' ')}');
      transport = await StdioClientTransport.create(
        command: config.command,
        arguments: config.args,
        environment: config.env,
        workingDirectory: config.workingDirectory,
      );
    }

    try {
      // 连接（connect 内部会自动调用 initialize）
      debugPrint('🔌 调用 client.connect(transport)...');
      final connectStart = DateTime.now();
      await client.connect(transport);
      debugPrint('   ⏱ connect 耗时: ${DateTime.now().difference(connectStart).inMilliseconds}ms');

      // 获取工具列表
      debugPrint('📋 调用 client.listTools()...');
      final listStart = DateTime.now();
      final tools = await client.listTools();
      debugPrint('   ⏱ listTools 耗时: ${DateTime.now().difference(listStart).inMilliseconds}ms');
      debugPrint('   📊 获取到 ${tools.length} 个工具');

      for (var i = 0; i < tools.length; i++) {
        final t = tools[i];
        debugPrint('      [${i + 1}] ${t.name}: ${t.description}');
      }

      // 转为 McpToolInfo 列表
      final toolInfos = tools.map((tool) {
        return McpToolInfo(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema as Map<String, dynamic>? ?? {},
        );
      }).toList();

      // 缓存
      _clients[config.name] = client;
      _availableTools[config.name] = tools;
      _cachedConfigs[config.name] = config.copyWith(
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ ====== 刷新成功: ${config.name}, 工具数: ${toolInfos.length} ======');
      return toolInfos;
    } catch (e, stack) {
      // 清理失败的连接
      try { _cleanupClient(config.name); } catch (_) {}
      debugPrint('❌ ====== 刷新失败: ${config.name} ======');
      debugPrint('   错误类型: ${e.runtimeType}');
      debugPrint('   错误信息: $e');
      debugPrint('   堆栈: $stack');
      rethrow;
    }
  }

  /// 连接 MCP 服务器并获取服务器名称和工具列表
  /// 用于首次添加服务时，从远程获取服务器信息
  static Future<McpConnectionInfo> connectAndGetInfo(
    McpServerConfig config,
  ) async {
    debugPrint('🔗 ====== 连接 MCP 服务器并获取信息 ======');
    debugPrint('   配置: url=${config.url}, command=${config.command}');
    debugPrint('   args=${config.args}, headers=${config.headers}');

    // 清理旧连接
    await _cleanupClient(config.name);

    final client = Client(
      name: 'aidock-client-${config.name}',
      version: '1.0.0',
    );

    ClientTransport transport;
    if (config.url != null && config.url!.isNotEmpty) {
      debugPrint('🔗 使用 SSE 传输: ${config.url}');
      transport = await SseClientTransport.create(
        serverUrl: config.url!,
        headers: config.headers,
      );
    } else {
      debugPrint('🔗 使用 stdio 传输: ${config.command} ${config.args.join(' ')}');
      transport = await StdioClientTransport.create(
        command: config.command,
        arguments: config.args,
        environment: config.env,
        workingDirectory: config.workingDirectory,
      );
    }

    try {
      await client.connect(transport);

      // 从 initialize 响应中获取服务器名称
      final serverInfo = client.serverInfo;
      final serverName = serverInfo != null
          ? (serverInfo['name'] as String? ?? config.name)
          : config.name;
      debugPrint('📋 服务器名称: $serverName');

      // 获取工具列表
      final tools = await client.listTools();
      debugPrint('📊 获取到 ${tools.length} 个工具');

      final toolInfos = tools.map((tool) {
        return McpToolInfo(
          name: tool.name,
          description: tool.description,
          inputSchema: tool.inputSchema as Map<String, dynamic>? ?? {},
        );
      }).toList();

      // 缓存
      _clients[serverName] = client;
      _availableTools[serverName] = tools;
      _cachedConfigs[serverName] = config.copyWith(
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ ====== 连接成功: $serverName ======');
      return McpConnectionInfo(serverName: serverName, tools: toolInfos);
    } catch (e, stack) {
      try { _cleanupClient(config.name); } catch (_) {}
      debugPrint('❌ ====== 连接失败: ${config.name} ======');
      debugPrint('   错误: $e');
      debugPrint('   堆栈: $stack');
      rethrow;
    }
  }

  /// 初始化MCP客户端
  static Future<bool> initializeClient(McpServerConfig config) async {
    try {
      debugPrint('🔧 初始化MCP客户端: ${config.name}');

      // 检查是否已经初始化
      if (_clients.containsKey(config.name)) {
        final client = _clients[config.name]!;
        // 检查客户端是否仍然连接
        try {
          // 尝试获取工具列表来验证连接状态
          final tools = await client.listTools();
          _availableTools[config.name] = tools;
          debugPrint('✓ MCP客户端已存在且连接正常: ${config.name}, 工具数量: ${tools.length}');
          return true;
        } catch (e) {
          debugPrint('⚠️ 现有客户端连接异常，重新初始化: ${config.name}, 错误: $e');
          // 清理旧客户端
          await _cleanupClient(config.name);
        }
      }

      // 创建客户端
      final client = Client(
        name: 'aidock-client-${config.name}',
        version: '1.0.0',
      );

      // 创建并连接传输层 - 根据配置选择传输方式
      ClientTransport transport;
      if (config.url != null && config.url!.isNotEmpty) {
        // SSE (URL-based) 传输
        debugPrint('🔗 使用 SSE 传输: ${config.url}');
        transport = await SseClientTransport.create(
          serverUrl: config.url!,
          headers: config.headers,
        );
      } else {
        // stdio 传输
        debugPrint('🔗 使用 stdio 传输: ${config.command} ${config.args.join(' ')}');
        transport = await StdioClientTransport.create(
          command: config.command,
          arguments: config.args,
          environment: config.env,
          workingDirectory: config.workingDirectory,
        );
      }

      // 连接客户端到传输层
      await client.connect(transport);

      // 初始化客户端
      try {
        await client.initialize();
      } catch (e) {
        // 如果初始化失败，可能是因为客户端已经初始化过
        if (e.toString().contains('already initialized')) {
          debugPrint('⚠️ 客户端已经初始化，继续使用: ${config.name}');
        } else {
          // 其他错误，重新抛出
          rethrow;
        }
      }

      // 获取可用工具
      final tools = await client.listTools();

      // 存储客户端和工具列表
      _clients[config.name] = client;
      _availableTools[config.name] = tools;

      debugPrint('✅ MCP客户端初始化成功: ${config.name}, 工具数量: ${tools.length}');

      // 更新配置中的工具信息
      await _updateConfigWithToolInfo(config, tools);

      return true;
    } catch (e) {
      debugPrint('❌ MCP客户端初始化失败: ${config.name}, 错误: $e');
      return false;
    }
  }

  /// 清理客户端连接
  static Future<void> _cleanupClient(String serviceName) async {
    try {
      final client = _clients[serviceName];
      if (client != null) {
        try {
          client.disconnect();
        } catch (e) {
          debugPrint('⚠️ 断开客户端连接时出错: $serviceName, 错误: $e');
        }
        _clients.remove(serviceName);
        _availableTools.remove(serviceName);
        debugPrint('🧹 已清理客户端: $serviceName');
      }
    } catch (e) {
      debugPrint('❌ 清理客户端失败: $serviceName, 错误: $e');
    }
  }

  /// 关闭MCP客户端连接
  static Future<void> closeClient(String serviceName) async {
    await _cleanupClient(serviceName);
  }

  /// 关闭所有MCP客户端连接
  static Future<void> closeAllClients() async {
    final serviceNames = List<String>.from(_clients.keys);
    for (final serviceName in serviceNames) {
      await closeClient(serviceName);
    }
  }

  /// 获取会话中实际启用的MCP服务列表（直接从 session 获取）
  static List<McpServerConfig> _getEnabledServices(ChatSession session) {
    return session.mcpServer != null ? [session.mcpServer!] : [];
  }

  /// 初始化会话的MCP服务
  static Future<List<String>> initializeSessionMcpServices(
    ChatSession session,
  ) async {
    // 确保全局配置已从存储中加载
    await ensureGlobalConfigsLoaded();

    final enabledServices = _getEnabledServices(session);
    if (enabledServices.isEmpty) {
      debugPrint('📝 会话 ${session.name} 未配置MCP服务');
      return [];
    }

    final initializedServices = <String>[];

    for (final config in enabledServices) {
      final success = await initializeClient(config);
      if (success) {
        initializedServices.add(config.name);
      }
    }

    debugPrint(
      '🚀 会话 ${session.name} 初始化了 ${initializedServices.length} 个MCP服务',
    );
    return initializedServices;
  }

  /// 获取会话可用的MCP工具列表
  static List<Tool> getSessionAvailableTools(ChatSession session) {
    final enabledServices = _getEnabledServices(session);
    if (enabledServices.isEmpty) {
      return [];
    }

    final allTools = <Tool>[];
    for (final config in enabledServices) {
      final tools = _availableTools[config.name];
      if (tools != null) {
        allTools.addAll(tools);
      }
    }

    return allTools;
  }

  /// 调用MCP工具
  static Future<McpToolResult> callTool({
    required String serviceName,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      debugPrint('🔨 调用MCP工具: $serviceName.$toolName');
      debugPrint('🔨 参数: ${jsonEncode(arguments)}');

      final client = _clients[serviceName];
      if (client == null) {
        throw Exception('MCP服务未初始化: $serviceName');
      }

      // 调用工具
      final result = await client.callTool(toolName, arguments);

      // 检查服务端是否返回了错误标志
      final isError = result.isError == true;
      final formattedResult = _formatToolResult(result);

      if (isError) {
        debugPrint('⚠️ MCP工具调用返回错误: $serviceName.$toolName, 内容: $formattedResult');
        return McpToolResult(
          toolName: toolName,
          arguments: arguments,
          result: formattedResult,
          isSuccess: false,
          error: formattedResult,
          timestamp: DateTime.now(),
        );
      }

      debugPrint('✅ MCP工具调用成功: $serviceName.$toolName');

      return McpToolResult(
        toolName: toolName,
        arguments: arguments,
        result: formattedResult,
        isSuccess: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ MCP工具调用失败: $serviceName.$toolName, 错误: $e');

      return McpToolResult(
        toolName: toolName,
        arguments: arguments,
        result: '',
        isSuccess: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// 格式化工具调用结果
  static String _formatToolResult(CallToolResult result) {
    if (result.content.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final content in result.content) {
      if (content is TextContent) {
        buffer.writeln(content.text);
      } else if (content is ImageContent) {
        buffer.writeln('[图片: ${content.data}]');
      } else {
        buffer.writeln('[内容: ${content.toString()}]');
      }
    }
    return buffer.toString().trim();
  }

  /// 执行会话的多个MCP工具调用
  static Future<List<McpToolResult>> executeSessionToolCalls({
    required ChatSession session,
    required List<Map<String, dynamic>> toolCalls,
  }) async {
    final results = <McpToolResult>[];
    final enabledServices = _getEnabledServices(session);

    if (enabledServices.isEmpty) {
      debugPrint('📝 会话模型未配置MCP服务，跳过工具调用');
      return results;
    }

    for (final toolCall in toolCalls) {
      try {
        final toolName = toolCall['tool'] as String?;
        final args = toolCall['args'] as Map<String, dynamic>? ?? {};

        if (toolName == null || toolName.isEmpty) {
          debugPrint('❌ 工具调用缺少工具名称');
          continue;
        }

        // 查找支持该工具的MCP服务
        String? targetService;

        // 首先尝试从工具名称中提取服务名称
        final toolParts = toolName.split('.');
        if (toolParts.length >= 2) {
          final serviceName = toolParts[0];
          final serviceConfig =
              enabledServices
                  .where((config) => config.name == serviceName)
                  .firstOrNull;

          if (serviceConfig != null) {
            final tools = _availableTools[serviceName];
            if (tools != null && tools.any((tool) => tool.name == toolName)) {
              targetService = serviceName;
            }
          }
        }

        // 如果通过服务名称没有找到，在所有服务中搜索工具
        if (targetService == null) {
          for (final config in enabledServices) {
            final tools = _availableTools[config.name];
            if (tools != null && tools.any((tool) => tool.name == toolName)) {
              targetService = config.name;
              break;
            }
          }
        }

        if (targetService != null) {
          final result = await callTool(
            serviceName: targetService,
            toolName: toolName,
            arguments: args,
          );
          results.add(result);
        } else {
          debugPrint('❌ 未找到支持工具 $toolName 的MCP服务');
          results.add(
            McpToolResult(
              toolName: toolName,
              arguments: args,
              result: '',
              isSuccess: false,
              error: '未找到支持该工具的MCP服务',
              timestamp: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ 执行工具调用失败: $e');
        final toolName = toolCall['tool'] as String? ?? 'unknown';
        final args = toolCall['args'] as Map<String, dynamic>? ?? {};
        results.add(
          McpToolResult(
            toolName: toolName,
            arguments: args,
            result: '',
            isSuccess: false,
            error: e.toString(),
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    return results;
  }

  /// 格式化工具结果用于显示
  static String formatToolResultForDisplay(McpToolResult result) {
    final buffer = StringBuffer();
    buffer.writeln('🔧 工具: ${result.toolName}');

    if (result.arguments.isNotEmpty) {
      buffer.writeln('📝 参数: ${jsonEncode(result.arguments)}');
    }

    buffer.writeln(
      '${result.isSuccess ? '✅' : '❌'} 状态: ${result.isSuccess ? '成功' : '失败'}',
    );

    if (!result.isSuccess && result.error != null) {
      buffer.writeln('⚠️ 错误: ${result.error}');
    }

    if (result.result.isNotEmpty) {
      buffer.writeln('📄 结果: ${result.result}');
    }

    return buffer.toString().trim();
  }

  /// 解析AI响应中的工具调用请求
  static List<Map<String, dynamic>> parseToolCallsFromResponse(
    String response,
  ) {
    final toolCalls = <Map<String, dynamic>>[];

    debugPrint('🔍 开始解析AI响应中的工具调用...');
    debugPrint('🔍 响应内容长度: ${response.length}');

    // 格式1: XML标签格式 <tool_call><tool_name>工具名</tool_name><arguments>{...}</arguments></tool_call>
    final xmlNewRegex = RegExp(
      r'<tool_call>\s*<tool_name>([^<]+)</tool_name>\s*<arguments>\s*({.*?})\s*</arguments>\s*</tool_call>',
      dotAll: true,
    );
    final xmlNewMatches = xmlNewRegex.allMatches(response);

    for (final match in xmlNewMatches) {
      try {
        final toolName = match.group(1)?.trim();
        final argsJson = match.group(2)?.trim();
        if (toolName != null && argsJson != null) {
          final args = jsonDecode(argsJson) as Map<String, dynamic>;
          toolCalls.add({'tool': toolName, 'args': args});
          debugPrint('✅ 解析新XML格式工具调用: $toolName, 参数: $args');
        }
      } catch (e) {
        debugPrint('❌ 解析新XML格式工具调用失败: ${match.group(0)}, 错误: $e');
      }
    }

    // 格式2: 方括号格式 [TOOL_CALL: 工具名称] {json} [/TOOL_CALL]
    final bracketNewRegex = RegExp(
      r'\[TOOL_CALL:\s*([^\]]+)\]\s*({.*?})\s*\[/TOOL_CALL\]',
      dotAll: true,
    );
    final bracketNewMatches = bracketNewRegex.allMatches(response);

    for (final match in bracketNewMatches) {
      try {
        final toolName = match.group(1)?.trim();
        final argsJson = match.group(2)?.trim();
        if (toolName != null && argsJson != null) {
          final args = jsonDecode(argsJson) as Map<String, dynamic>;
          toolCalls.add({'tool': toolName, 'args': args});
          debugPrint('✅ 解析新方括号格式工具调用: $toolName, 参数: $args');
        }
      } catch (e) {
        debugPrint('❌ 解析新方括号格式工具调用失败: ${match.group(0)}, 错误: $e');
      }
    }

    // 格式3: 花括号格式 {"tool_name": "工具名", "arguments": {...}}
    final braceNewRegex = RegExp(
      r'{\s*"tool_name"\s*:\s*"([^"]+)"\s*,\s*"arguments"\s*:\s*({.*?})\s*}',
      dotAll: true,
    );
    final braceNewMatches = braceNewRegex.allMatches(response);

    for (final match in braceNewMatches) {
      try {
        final toolName = match.group(1)?.trim();
        final argsJson = match.group(2)?.trim();
        if (toolName != null && argsJson != null) {
          final args = jsonDecode(argsJson) as Map<String, dynamic>;
          toolCalls.add({'tool': toolName, 'args': args});
          debugPrint('✅ 解析新花括号格式工具调用: $toolName, 参数: $args');
        }
      } catch (e) {
        debugPrint('❌ 解析新花括号格式工具调用失败: ${match.group(0)}, 错误: $e');
      }
    }

    // 兼容性支持 - 原有的XML格式: <tool_call>{"tool": "get_weather", "args": {"city": "北京"}}</tool_call>
    if (toolCalls.isEmpty) {
      final xmlOldRegex = RegExp(r'<tool_call>(.*?)</tool_call>', dotAll: true);
      final xmlOldMatches = xmlOldRegex.allMatches(response);

      for (final match in xmlOldMatches) {
        try {
          final jsonStr = match.group(1)?.trim();
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final toolCall = jsonDecode(jsonStr) as Map<String, dynamic>;
            // 转换为统一格式
            if (toolCall.containsKey('tool') && toolCall.containsKey('args')) {
              toolCalls.add({
                'tool': toolCall['tool'],
                'args': toolCall['args'] as Map<String, dynamic>,
              });
              debugPrint(
                '✅ 解析旧XML格式工具调用: ${toolCall['tool']}, 参数: ${toolCall['args']}',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ 解析旧XML格式工具调用失败: ${match.group(1)}, 错误: $e');
        }
      }
    }

    // 兼容性支持 - 旧的方括号格式: [TOOL_CALL: toolname.method(args)]
    if (toolCalls.isEmpty) {
      final bracketOldRegex = RegExp(
        r'\[TOOL_CALL:\s*([^.]+)\.([^(]+)\(([^)]*)\)\]',
      );
      final bracketOldMatches = bracketOldRegex.allMatches(response);

      for (final match in bracketOldMatches) {
        try {
          final service = match.group(1)?.trim();
          final method = match.group(2)?.trim();
          final argsStr = match.group(3)?.trim() ?? '';

          if (service != null && method != null) {
            final toolName = '$service.$method';
            final args = <String, dynamic>{};

            // 解析参数字符串
            if (argsStr.isNotEmpty) {
              _parseArgumentString(argsStr, args);
            }

            toolCalls.add({'tool': toolName, 'args': args});
            debugPrint('✅ 解析旧方括号格式工具调用: $toolName, 参数: $args');
          }
        } catch (e) {
          debugPrint('❌ 解析旧方括号格式工具调用失败: ${match.group(0)}, 错误: $e');
        }
      }
    }

    // 兼容性支持 - 旧的花括号格式: {tool_call: toolname(args)}
    if (toolCalls.isEmpty) {
      final braceOldRegex = RegExp(
        r'\{tool_call:\s*([^(]+)\(([^)]*)\)\}',
        caseSensitive: false,
      );
      final braceOldMatches = braceOldRegex.allMatches(response);

      for (final match in braceOldMatches) {
        try {
          final toolName = match.group(1)?.trim();
          final argsStr = match.group(2)?.trim() ?? '';

          if (toolName != null && toolName.isNotEmpty) {
            final args = <String, dynamic>{};

            if (argsStr.isNotEmpty) {
              _parseArgumentString(argsStr, args);
            }

            toolCalls.add({'tool': toolName, 'args': args});
            debugPrint('✅ 解析旧花括号格式工具调用: $toolName, 参数: $args');
          }
        } catch (e) {
          debugPrint('❌ 解析旧花括号格式工具调用失败: ${match.group(0)}, 错误: $e');
        }
      }
    }

    debugPrint('🔍 工具调用解析完成，找到 ${toolCalls.length} 个工具调用');

    // 如果没有找到任何工具调用，输出调试信息
    if (toolCalls.isEmpty) {
      debugPrint('⚠️ 没有找到任何工具调用，响应内容前200字符：');
      debugPrint(
        response.length > 200 ? '${response.substring(0, 200)}...' : response,
      );
    }

    return toolCalls;
  }

  /// 解析参数字符串的辅助方法
  static void _parseArgumentString(String argsStr, Map<String, dynamic> args) {
    // 先尝试JSON格式
    try {
      if (argsStr.startsWith('{') && argsStr.endsWith('}')) {
        final jsonArgs = jsonDecode(argsStr) as Map<String, dynamic>;
        args.addAll(jsonArgs);
        return;
      }
    } catch (e) {
      debugPrint('🔍 非JSON格式参数，尝试键值对解析');
    }

    // 尝试key="value"格式
    final argRegex = RegExp(r'(\w+)="([^"]*)"');
    final argMatches = argRegex.allMatches(argsStr);

    for (final argMatch in argMatches) {
      final key = argMatch.group(1);
      final value = argMatch.group(2);
      if (key != null && value != null) {
        args[key] = value;
      }
    }

    // 如果没有匹配到，尝试key='value'格式
    if (args.isEmpty) {
      final argRegex2 = RegExp(r"(\w+)='([^']*)'");
      final argMatches2 = argRegex2.allMatches(argsStr);

      for (final argMatch in argMatches2) {
        final key = argMatch.group(1);
        final value = argMatch.group(2);
        if (key != null && value != null) {
          args[key] = value;
        }
      }
    }

    // 如果还是没有匹配到，尝试key:value格式
    if (args.isEmpty) {
      final argRegex3 = RegExp(r'(\w+):\s*"([^"]*)"');
      final argMatches3 = argRegex3.allMatches(argsStr);

      for (final argMatch in argMatches3) {
        final key = argMatch.group(1);
        final value = argMatch.group(2);
        if (key != null && value != null) {
          args[key] = value;
        }
      }
    }
  }

  /// 获取会话的真实MCP工具信息用于API调用
  static String buildMcpToolsInfoForApi(ChatSession session) {
    final enabledServices = _getEnabledServices(session);
    if (enabledServices.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('## 可用的MCP工具');
    buffer.writeln();

    // 更严格的格式要求说明
    buffer.writeln('### 🚨 工具调用格式要求 - 必须严格遵守');
    buffer.writeln();
    buffer.writeln('**支持的调用格式（任选其一）：**');
    buffer.writeln();

    buffer.writeln('1. **XML标签格式（推荐）**：');
    buffer.writeln('```');
    buffer.writeln('<tool_call>');
    buffer.writeln('<tool_name>工具名称</tool_name>');
    buffer.writeln('<arguments>');
    buffer.writeln('{"参数名1": "参数值1", "参数名2": "参数值2"}');
    buffer.writeln('</arguments>');
    buffer.writeln('</tool_call>');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('2. **方括号格式**：');
    buffer.writeln('```');
    buffer.writeln('[TOOL_CALL: 工具名称]');
    buffer.writeln('{"参数名1": "参数值1", "参数名2": "参数值2"}');
    buffer.writeln('[/TOOL_CALL]');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('3. **花括号格式**：');
    buffer.writeln('```');
    buffer.writeln('{');
    buffer.writeln('  "tool_name": "工具名称",');
    buffer.writeln('  "arguments": {');
    buffer.writeln('    "参数名1": "参数值1",');
    buffer.writeln('    "参数名2": "参数值2"');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('**关键要求：**');
    buffer.writeln('- ✅ 工具名称必须与下方列出的工具名**完全匹配**（区分大小写）');
    buffer.writeln('- ✅ 参数必须是**有效的JSON格式**，字符串值用双引号包围');
    buffer.writeln('- ✅ 必须提供所有**必需参数**，可选参数可以省略');
    buffer.writeln('- ✅ 参数类型必须正确（字符串、数字、布尔值、数组、对象）');
    buffer.writeln('- ✅ 每次只能调用**一个工具**，等待结果后再调用下一个');
    buffer.writeln('- ❌ 不要混合使用不同格式');
    buffer.writeln('- ❌ 不要在工具调用前后添加额外的标记或说明');
    buffer.writeln();

    for (final config in enabledServices) {
      // 首先尝试从缓存中获取最新的配置信息
      final cachedConfig = _cachedConfigs[config.name];
      final toolInfos = cachedConfig?.tools ?? config.tools;

      if (toolInfos != null && toolInfos.isNotEmpty) {
        buffer.writeln('### 📋 ${config.name} 服务工具');
        buffer.writeln();

        for (int i = 0; i < toolInfos.length; i++) {
          final tool = toolInfos[i];
          buffer.writeln('#### ${i + 1}. **${tool.name}**');
          buffer.writeln('**功能描述**: ${tool.description}');
          buffer.writeln();

          // 详细的参数信息
          if (tool.inputSchema.isNotEmpty) {
            final schema = tool.inputSchema;
            final properties =
                schema['properties'] as Map<String, dynamic>? ?? {};
            final required = (schema['required'] as List<dynamic>?) ?? [];

            if (properties.isNotEmpty) {
              buffer.writeln('**参数详情**:');
              for (final entry in properties.entries) {
                final propName = entry.key;
                final propInfo = entry.value as Map<String, dynamic>? ?? {};
                final type = propInfo['type'] ?? 'string';
                final description = propInfo['description'] ?? '无描述';
                final isRequired = required.contains(propName);
                final mark = isRequired ? '🔴 必需' : '⚪ 可选';

                buffer.writeln('- **$propName** ($type) - $mark');
                buffer.writeln('  说明: $description');

                // 显示枚举值
                if (propInfo.containsKey('enum')) {
                  final enumValues = propInfo['enum'] as List<dynamic>? ?? [];
                  if (enumValues.isNotEmpty) {
                    buffer.writeln('  可选值: ${enumValues.join(', ')}');
                  }
                }

                // 显示默认值
                if (propInfo.containsKey('default')) {
                  buffer.writeln('  默认值: ${propInfo['default']}');
                }
                buffer.writeln();
              }
            } else {
              buffer.writeln('**参数**: 无需参数');
              buffer.writeln();
            }

            // 生成准确的调用示例
            buffer.writeln('**📋 标准调用示例**:');

            // 构建示例参数
            final exampleArgs = <String, dynamic>{};
            for (final entry in properties.entries) {
              final propName = entry.key;
              final propInfo = entry.value as Map<String, dynamic>? ?? {};
              final type = propInfo['type'] ?? 'string';
              final isRequired = required.contains(propName);

              // 为必需参数生成示例值
              if (isRequired) {
                switch (type) {
                  case 'string':
                    if (propInfo.containsKey('enum')) {
                      final enumValues =
                          propInfo['enum'] as List<dynamic>? ?? [];
                      exampleArgs[propName] =
                          enumValues.isNotEmpty
                              ? enumValues.first.toString()
                              : 'example_string';
                    } else if (propName.toLowerCase().contains('path')) {
                      exampleArgs[propName] = '/path/to/file';
                    } else if (propName.toLowerCase().contains('query')) {
                      exampleArgs[propName] = '搜索关键词';
                    } else {
                      exampleArgs[propName] = 'example_string';
                    }
                    break;
                  case 'number':
                  case 'integer':
                    exampleArgs[propName] = 42;
                    break;
                  case 'boolean':
                    exampleArgs[propName] = true;
                    break;
                  case 'array':
                    exampleArgs[propName] = ['item1', 'item2'];
                    break;
                  case 'object':
                    exampleArgs[propName] = {'key': 'value'};
                    break;
                  default:
                    exampleArgs[propName] = 'example_value';
                }
              }
            }

            // 生成三种格式的示例
            buffer.writeln('```xml');
            buffer.writeln('<tool_call>');
            buffer.writeln('<tool_name>${tool.name}</tool_name>');
            buffer.writeln('<arguments>');
            try {
              const encoder = JsonEncoder.withIndent('  ');
              final jsonString = encoder.convert(exampleArgs);
              buffer.writeln(jsonString);
            } catch (e) {
              buffer.writeln('{}');
            }
            buffer.writeln('</arguments>');
            buffer.writeln('</tool_call>');
            buffer.writeln('```');
            buffer.writeln();
          } else {
            buffer.writeln('**参数**: 无需参数');
            buffer.writeln();
            buffer.writeln('**调用示例**:');
            buffer.writeln('```xml');
            buffer.writeln('<tool_call>');
            buffer.writeln('<tool_name>${tool.name}</tool_name>');
            buffer.writeln('<arguments>');
            buffer.writeln('{}');
            buffer.writeln('</arguments>');
            buffer.writeln('</tool_call>');
            buffer.writeln('```');
            buffer.writeln();
          }

          buffer.writeln('---');
          buffer.writeln();
        }
      } else {
        // 如果没有工具信息，使用通用描述
        buffer.writeln('### ${config.name} 服务');
        buffer.writeln('⏳ 服务正在初始化中，工具信息将在连接后更新。');
        buffer.writeln();
      }
    }

    // 添加最终的重要提醒
    buffer.writeln('### ⚠️ 重要提醒');
    buffer.writeln('1. **严格按照上述格式调用工具**，任何格式错误都会导致工具调用失败');
    buffer.writeln('2. **工具名称必须完全匹配**，区分大小写');
    buffer.writeln('3. **JSON格式必须有效**，字符串值用双引号，数字不用引号');
    buffer.writeln('4. **每次只调用一个工具**，等待结果返回后再决定下一步');
    buffer.writeln('5. **先理解用户需求，选择合适的工具，然后准确调用**');
    buffer.writeln();
    buffer.writeln('💡 **调用流程建议**: 说明意图 → 工具调用 → 等待结果 → 解释结果 → 必要时继续调用其他工具');

    return buffer.toString();
  }

  /// 构建OpenAI兼容的tools格式
  static List<Map<String, dynamic>> buildOpenAIToolsFormat(
    ChatSession session,
  ) {
    final tools = getSessionAvailableTools(session);
    if (tools.isEmpty) {
      return [];
    }

    final openAITools = <Map<String, dynamic>>[];

    for (final tool in tools) {
      try {
        // 构建OpenAI function格式
        final functionDef = <String, dynamic>{
          'type': 'function',
          'function': {'name': tool.name, 'description': tool.description},
        };

        // 处理参数schema
        if (tool.inputSchema.isNotEmpty) {
          final schema = Map<String, dynamic>.from(tool.inputSchema);

          // 确保schema符合OpenAI格式要求
          if (!schema.containsKey('type')) {
            schema['type'] = 'object';
          }
          if (!schema.containsKey('properties')) {
            schema['properties'] = <String, dynamic>{};
          }

          // 添加参数schema
          functionDef['function']['parameters'] = schema;
        } else {
          // 无参数的工具
          functionDef['function']['parameters'] = {
            'type': 'object',
            'properties': <String, dynamic>{},
            'required': <String>[],
          };
        }

        openAITools.add(functionDef);
        debugPrint('✅ 转换MCP工具为OpenAI格式: ${tool.name}');
      } catch (e) {
        debugPrint('❌ 转换MCP工具失败: ${tool.name}, 错误: $e');
      }
    }

    debugPrint('🔧 生成OpenAI tools数量: ${openAITools.length}');
    return openAITools;
  }

  /// 检查会话是否有可用的MCP工具
  static bool hasAvailableTools(ChatSession session) {
    if (session.mcpServer == null) return false;
    if (!hasGlobalMcpServices) return false;

    final tools = getSessionAvailableTools(session);
    return tools.isNotEmpty;
  }
}
