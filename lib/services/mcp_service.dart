import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import '../models/bigmodel/mcp_config.dart';
import 'mcp_storage_service.dart';

/// MCP 工具执行结果（统一返回）
class McpExecutionResult {
  /// 已剥离工具调用 XML 的干净文本
  final String cleanContent;
  /// 用于 OpenAI 兼容 follow-up 消息构建的工具调用列表
  final List<Map<String, dynamic>> toolCallList;
  /// 每个工具的调用执行结果
  final List<Map<String, dynamic>> executionResults;

  const McpExecutionResult({
    required this.cleanContent,
    required this.toolCallList,
    required this.executionResults,
  });
}

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

  /// 获取已连接的 MCP Client 实例（标准 mcp_client API）
  static Client? getMCPClient(String serviceName) => _clients[serviceName];

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
        final toolName = toolCall['name'] as String?;
        final args = toolCall['arguments'] as Map<String, dynamic>? ?? {};

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
        final toolName = toolCall['name'] as String? ?? 'unknown';
        final args = toolCall['arguments'] as Map<String, dynamic>? ?? {};
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

  // ── 解析器注册：按标签类型分发 ──

  /// 解析 AI 响应中的工具调用（组合所有解析器，保持向后兼容）
  static List<Map<String, dynamic>> parseToolCallsFromResponse(
    String response,
  ) {
    var calls = parseToolCallsXml(response);
    if (calls.isEmpty) {
      calls = parseDSMLXml(response);
    }
    return calls;
  }

  /// 解析 `<tool_calls>` 标签格式
  /// `<tool_calls><invoke name="工具名"><parameter name="x" string="true">value</parameter></invoke></tool_calls>`
  static List<Map<String, dynamic>> parseToolCallsXml(String response) {
    final toolCalls = <Map<String, dynamic>>[];

    final blockRegex = RegExp(
      r'<tool_calls>\s*(.*?)\s*</tool_calls>',
      dotAll: true,
    );
    final blockMatch = blockRegex.firstMatch(response);
    if (blockMatch == null) {
      debugPrint('⚠️ parseToolCallsXml: 没有找到 <tool_calls> 标签');
      return toolCalls;
    }

    final inner = blockMatch.group(1);
    if (inner == null) return toolCalls;

    _parseInvokeBlocks(inner, toolCalls);
    debugPrint('🔍 parseToolCallsXml: 找到 ${toolCalls.length} 个工具调用');
    return toolCalls;
  }

  /// 解析 DSML 标签格式（占位，待补充具体正则）
  static List<Map<String, dynamic>> parseDSMLXml(String response) {
    final toolCalls = <Map<String, dynamic>>[];

    // TODO: 补充 DSML 标签正则
    debugPrint('⚠️ parseDSMLXml: DSML 解析器待实现');

    return toolCalls;
  }

  // ── 内部：invoke 块解析（<invoke name="x"><parameter .../></invoke>） ──

  static void _parseInvokeBlocks(
    String inner,
    List<Map<String, dynamic>> toolCalls,
  ) {
    final invokeRegex = RegExp(
      r'<invoke\s+name="([^"]+)"[^>]*>(.*?)</invoke>',
      dotAll: true,
    );

    for (final im in invokeRegex.allMatches(inner)) {
      try {
        final toolName = im.group(1)?.trim();
        final invokeBody = im.group(2);
        if (toolName == null || invokeBody == null) continue;

        final args = <String, dynamic>{};

        // <parameter name="x" string="true">value</parameter>
        // <parameter name="y" number="true">42</parameter>
        // <parameter name="z" boolean="true">true</parameter>
        final paramRegex = RegExp(
          r'<parameter\s+name="([^"]+)"\s+(\w+)="[^"]*"[^>]*>([^<]*)</parameter>',
        );
        for (final pm in paramRegex.allMatches(invokeBody)) {
          final name = pm.group(1)?.trim();
          final type = pm.group(2)?.trim();
          final rawValue = pm.group(3)?.trim() ?? '';
          if (name != null && name.isNotEmpty) {
            args[name] = _parseParamValue(rawValue, type);
          }
        }

        toolCalls.add({'name': toolName, 'arguments': args});
        debugPrint('✅ 解析工具调用: $toolName, 参数: $args');
      } catch (e) {
        debugPrint('❌ 解析工具调用失败: ${im.group(0)}, 错误: $e');
      }
    }
  }

  /// 根据类型属性解析参数值
  static dynamic _parseParamValue(String rawValue, String? type) {
    switch (type) {
      case 'number':
        final n = num.tryParse(rawValue);
        return n ?? rawValue;
      case 'boolean':
        return rawValue.toLowerCase() == 'true';
      default: // string or unknown
        return rawValue;
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

    // 工具调用格式要求
    buffer.writeln('### 🚨 工具调用格式要求 - 必须严格遵守');
    buffer.writeln();
    buffer.writeln('**工具调用必须使用以下 `<tool_calls>` 格式：**');
    buffer.writeln();
    buffer.writeln('```xml');
    buffer.writeln('<tool_calls>');
    buffer.writeln('<invoke name="工具名称">');
    buffer.writeln('<arguments>');
    buffer.writeln('{"参数名1": "参数值1", "参数名2": "参数值2"}');
    buffer.writeln('</arguments>');
    buffer.writeln('</invoke>');
    buffer.writeln('</tool_calls>');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('**无参数的工具调用：**');
    buffer.writeln('```xml');
    buffer.writeln('<tool_calls>');
    buffer.writeln('<invoke name="工具名称">');
    buffer.writeln('</invoke>');
    buffer.writeln('</tool_calls>');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('**关键要求：**');
    buffer.writeln('- ✅ 工具名称必须与下方列出的工具名**完全匹配**（区分大小写）');
    buffer.writeln('- ✅ 参数必须是**有效的JSON格式**，字符串值用双引号包围');
    buffer.writeln('- ✅ 必须提供所有**必需参数**，可选参数可以省略');
    buffer.writeln('- ✅ 参数类型必须正确（字符串、数字、布尔值、数组、对象）');
    buffer.writeln('- ✅ 每次只能调用**一个工具**，等待结果后再调用下一个');
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

            // 生成示例
            buffer.writeln('```xml');
            buffer.writeln('<tool_calls>');
            buffer.writeln('<invoke name="${tool.name}">');
            if (exampleArgs.isNotEmpty) {
              buffer.writeln('<arguments>');
              try {
                const encoder = JsonEncoder.withIndent('  ');
                final jsonString = encoder.convert(exampleArgs);
                buffer.writeln(jsonString);
              } catch (e) {
                buffer.writeln('{}');
              }
              buffer.writeln('</arguments>');
            }
            buffer.writeln('</invoke>');
            buffer.writeln('</tool_calls>');
            buffer.writeln('```');
            buffer.writeln();
          } else {
            buffer.writeln('**参数**: 无需参数');
            buffer.writeln();
            buffer.writeln('**调用示例**:');
            buffer.writeln('```xml');
            buffer.writeln('<tool_calls>');
            buffer.writeln('<invoke name="${tool.name}">');
            buffer.writeln('</invoke>');
            buffer.writeln('</tool_calls>');
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

  // ──────────────────────────────────────────────
  // 工具调用 XML 剥离（从模型输出中移除 <tool_calls> 块）
  // ──────────────────────────────────────────────

  static final RegExp _stripToolCallsBlockRegex = RegExp(
    r'<tool_calls>.*?</tool_calls>',
    dotAll: true,
  );

  /// 从文本中移除 `<tool_calls>` 标签块，返回干净的可显示文本
  static String stripToolCallXml(String text) {
    return text
        .replaceAll(_stripToolCallsBlockRegex, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// 检查会话是否有可用的MCP工具
  static bool hasAvailableTools(ChatSession session) {
    if (session.mcpServer == null) return false;
    if (!hasGlobalMcpServices) return false;

    final tools = getSessionAvailableTools(session);
    return tools.isNotEmpty;
  }

  // ──────────────────────────────────────────────
  // 统一工具调用处理入口
  // ──────────────────────────────────────────────

  /// 处理模型响应中的工具调用：解析 → 获取 MCP 客户端 → 执行 → 返回
  ///
  /// [nativeToolCallsJson] 不为空时走原生 JSON tool_calls 解析；
  /// 否则从 [accumulatedContent] 中解析文本格式的工具调用。
  ///
  /// 返回 null 表示没有工具调用或 MCP 未配置。
  static Future<McpExecutionResult?> processAndExecuteToolCalls({
    required ChatSession session,
    required String accumulatedContent,
    String? nativeToolCallsJson,
  }) async {
    if (session.mcpServer == null) return null;

    // 1. 获取或初始化 MCP 客户端
    final mc = await _getOrInitClient(session);
    if (mc == null) return null;

    // 2. 解析工具调用
    List<Map<String, dynamic>> toolCalls;
    String cleanContent = accumulatedContent;

    if (nativeToolCallsJson != null && nativeToolCallsJson.isNotEmpty) {
      // JSON tool_calls（统一使用 name/arguments 格式）
      try {
        final List<dynamic> list = jsonDecode(nativeToolCallsJson);
        toolCalls =
            list
                .map((raw) {
                  final m = raw as Map<String, dynamic>;
                  return {
                    'name': (m['name'] ?? '') as String,
                    'arguments': (m['arguments'] ?? <String, dynamic>{}) as Map<String, dynamic>,
                    'id': m['id'],
                    'index': m['index'],
                  };
                })
                .where((tc) => (tc['name'] as String).isNotEmpty)
                .toList();
      } catch (_) {
        return null;
      }
    } else {
      // 文本格式 tool_calls
      toolCalls = parseToolCallsFromResponse(accumulatedContent);
      if (toolCalls.isEmpty) return null;
      cleanContent = stripToolCallXml(accumulatedContent);
    }

    if (toolCalls.isEmpty) return null;

    // 3. 逐个执行工具
    final executionResults = <Map<String, dynamic>>[];
    final toolCallList = <Map<String, dynamic>>[];

    for (int i = 0; i < toolCalls.length; i++) {
      final tc = toolCalls[i];
      final name = tc['name'] as String;
      final args = tc['arguments'] as Map<String, dynamic>;
      final callId = (tc['id'] as String?) ?? 'call_$i';

      toolCallList.add({
        'id': callId,
        'name': name,
        'arguments': args,
        'index': i,
      });

      try {
        final r = await mc.callTool(name, args);
        final ok = r.isError != true;
        final buf = StringBuffer();
        for (final c in r.content) {
          if (c is TextContent) {
            buf.writeln(c.text);
          } else if (c is ImageContent) {
            buf.writeln('[图片: ${c.data ?? c.url}]');
          }
        }
        final text = buf.toString().trim();
        executionResults.add({
          'id': callId,
          'name': name,
          'args': args,
          'result': text,
          'isError': !ok,
        });
      } catch (e) {
        executionResults.add({
          'id': callId,
          'name': name,
          'args': args,
          'result': '$e',
          'isError': true,
        });
      }
    }

    return McpExecutionResult(
      cleanContent: cleanContent,
      toolCallList: toolCallList,
      executionResults: executionResults,
    );
  }

  /// 获取或初始化会话的 MCP 客户端（带 session 级缓存）
  static Future<Client?> _getOrInitClient(ChatSession session) async {
    Client? mc = session.mcpClient;
    if (mc != null) return mc;

    final svc = session.mcpServer?.name;
    if (svc == null) return null;

    mc = getMCPClient(svc);
    if (mc == null) {
      await ensureGlobalConfigsLoaded();
      final inited = await initializeSessionMcpServices(session);
      if (inited.isEmpty) return null;
      mc = getMCPClient(svc);
    }

    if (mc != null) {
      session.mcpClient = mc;
    }
    return mc;
  }
}
