import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/mcp_config.dart';
import '../models/bigmodel/chat_model.dart';
import '../core/llm/openai_provider.dart';
import '../core/llm/modes/mode_utils.dart' show resolveOriginalToolName;
import '../features/mcp/storage/mcp_storage_manager.dart';
import './model_controller.dart';

// MCP 连接信息
class McpConnectionInfo {
  final String serverName;
  final String? description;
  final String? serverVersion;
  final List<McpTool> tools;
  final String prompt;

  const McpConnectionInfo({
    required this.serverName,
    this.description,
    this.serverVersion,
    required this.tools,
    required this.prompt,
  });
}

// 工具调用执行结果（统一返回）
class ToolExecutionResult {
  final String cleanContent;
  final List<Map<String, dynamic>> toolCallList;
  final List<Map<String, dynamic>> executionResults;

  const ToolExecutionResult({
    required this.cleanContent,
    required this.toolCallList,
    required this.executionResults,
  });
}

// 统一 MCP Controller — 配置管理 + 连接/工具调用
class McpController extends GetxController {
  static McpController get instance => Get.find<McpController>();

  var configs = <Mcp>[].obs;
  bool _loaded = false;

  final Map<String, Client> _clients = {};
  final Map<String, List<Tool>> _availableTools = {};
  static const int _defaultTimeout = 50;

  // ═══ 配置 CRUD ═══

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await loadAll();
  }

  Future<void> loadAll() async {
    configs.value = await McpStorageManager.loadAll();
    _loaded = true;
    debugPrint('📦 McpController: 已加载 \${configs.length} 个 MCP 服务');
  }

  /// 根据会话绑定的 MCP 文件夹名获取连接配置
  Mcp? getMcp(String mcp) {
    for (final c in configs) {
      if (c.name == mcp) return c;
    }
    return null;
  }

  bool isBuiltin(String mcp) {
    return ['filesystem', 'git', 'shell', 'fetch', 'sqlite'].contains(mcp);
  }

  bool get hasServices => configs.isNotEmpty;

  Future<void> addService(
    Mcp service, {
    Map<String, dynamic>? serverJson,
  }) async {
    await McpStorageManager.saveConfig(service, serverJson: serverJson);
    final existing = getMcp(service.name);
    if (existing != null) {
      final idx = configs.indexWhere((c) => c.name == service.name);
      if (idx != -1) configs[idx] = service;
    } else {
      configs.add(service);
    }
  }

  Future<void> removeService(String mcp) async {
    if (mcp.isEmpty) return;
    await McpStorageManager.delete(mcp);
    configs.removeWhere((c) => c.name == mcp);
  }

  Future<void> updateService(String mcp, Mcp newService) async {
    await McpStorageManager.save(newService);
    final idx = configs.indexWhere((c) => c.name == mcp);
    if (idx != -1) configs[idx] = newService;
  }

  Future<void> updateServerConfig(
    String mcp,
    Map<String, dynamic> serverJson,
  ) async {
    final existing = getMcp(mcp);
    final merged = <String, dynamic>{...serverJson};
    if (existing != null) {
      merged['name'] = existing.name;
      if (existing.description != null)
        merged['description'] = existing.description!;
      if (existing.tools != null) {
        merged['tools'] = existing.tools!.map((t) => t.toJson()).toList();
      }
      if (existing.version != null) merged['version'] = existing.version!;
      if (existing.prompt != null) merged['prompt'] = existing.prompt!;
      if (existing.lastUpdated != null) {
        merged['lastUpdated'] = existing.lastUpdated!.toIso8601String();
      }
    }
    final mcpObj = Mcp.fromJson(mcp, merged);
    await McpStorageManager.save(mcpObj);
    final idx = configs.indexWhere((c) => c.name == mcp);
    if (idx != -1) configs[idx] = mcpObj;
  }

  bool get hasGlobalMcpServices => configs.isNotEmpty;

  // ═══ Transport ═══

  Future<ClientTransport> _createTransport(
    Mcp config, {
    Duration? timeout,
  }) async {
    if (config.url != null && config.url!.isNotEmpty) {
      final t = config.type;
      if (t == McpTransportType.streamableHttp || t == McpTransportType.http) {
        debugPrint('🔗 使用 Streamable HTTP 传输: ${config.url}');
        return StreamableHttpClientTransport.create(
          baseUrl: config.url!,
          headers: config.headers,
          body: config.body,
          timeout: timeout,
        );
      } else if (t == McpTransportType.sse) {
        debugPrint('🔗 使用 SSE 传输: ${config.url}');
        try {
          return await SseClientTransport.create(
            serverUrl: config.url!,
            headers: config.headers,
          );
        } catch (e) {
          final es = e.toString();
          if (es.contains('405') || es.contains('Method not allowed')) {
            debugPrint('🔗 SSE 不支持 (405)，回退到 Streamable HTTP: ${config.url}');
            return StreamableHttpClientTransport.create(
              baseUrl: config.url!,
              headers: config.headers,
              body: config.body,
              timeout: timeout,
            );
          }
          rethrow;
        }
      } else {
        debugPrint('🔗 传输类型未指定，先尝试 Streamable HTTP: ${config.url}');
        try {
          return await StreamableHttpClientTransport.create(
            baseUrl: config.url!,
            headers: config.headers,
            body: config.body,
            timeout: timeout,
          );
        } catch (e) {
          final es = e.toString();
          if (es.contains('405') ||
              es.contains('Method not allowed') ||
              es.contains('404')) {
            debugPrint('🔗 Streamable HTTP 不支持，回退到 SSE: ${config.url}');
            return await SseClientTransport.create(
              serverUrl: config.url!,
              headers: config.headers,
            );
          }
          rethrow;
        }
      }
    }
    final cmd = config.command;
    if (cmd == null || cmd.isEmpty)
      throw Exception('Stdio MCP 配置缺少 command: ${config.name}');
    debugPrint('🔗 使用 stdio 传输: $cmd ${config.args?.join(' ') ?? ''}');
    return StdioClientTransport.create(
      command: cmd,
      arguments: config.args ?? [],
      environment: config.env,
      workingDirectory: config.workingDirectory,
    );
  }

  // ═══ 刷新服务工具 ═══

  Future<List<McpTool>> refreshServiceTools(Mcp config) async {
    final timeoutSec = config.timeout ?? _defaultTimeout;
    debugPrint('🔄 ====== 开始刷新 MCP 服务工具: ${config.name} ======');
    await _cleanupClient(config.name);
    final client = Client(
      name: 'aidock-client-${config.name}',
      version: '1.0.0',
    );
    ClientTransport? transport;
    try {
      transport = await _createTransport(
        config,
        timeout: Duration(seconds: timeoutSec),
      ).timeout(
        Duration(seconds: timeoutSec),
        onTimeout:
            () => throw TimeoutException('创建 Transport 超时: ${config.name}'),
      );
      try {
        await client
            .connect(transport)
            .timeout(
              Duration(seconds: timeoutSec),
              onTimeout: () => throw TimeoutException('连接超时: ${config.name}'),
            );
      } on McpError catch (e) {
        final err = e.toString();
        if ((err.contains('405') ||
                err.contains('Method not allowed') ||
                err.contains('Method Not Allowed')) &&
            config.url != null &&
            config.url!.isNotEmpty) {
          debugPrint('   ⚠️ SSE 连接失败 (405)，回退到 Streamable HTTP...');
          transport = await StreamableHttpClientTransport.create(
            baseUrl: config.url!,
            headers: config.headers,
            timeout: Duration(seconds: timeoutSec),
          );
          await client
              .connect(transport)
              .timeout(
                Duration(seconds: timeoutSec),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'Streamable HTTP 连接超时: ${config.name}',
                        ),
              );
        } else {
          rethrow;
        }
      }
      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException('获取工具列表超时: ${config.name}'),
      );
      final toolInfos =
          tools
              .map(
                (t) => McpTool(
                  name: t.name,
                  description: t.description,
                  inputSchema: t.inputSchema as Map<String, dynamic>? ?? {},
                ),
              )
              .toList();
      debugPrint(
        '✅ ====== 刷新成功: ${config.name}, 工具数: ${toolInfos.length} ======',
      );
      return toolInfos;
    } catch (e, stack) {
      debugPrint(
        '${e is TimeoutException ? '⏱' : '❌'} ====== 刷新失败: ${config.name} ======',
      );
      debugPrint('   错误: $e\n   堆栈: $stack');
      rethrow;
    } finally {
      try {
        client.disconnect();
      } catch (_) {}
      _clients.remove(config.name);
      _availableTools.remove(config.name);
    }
  }

  // ═══ 连接并获取信息 ═══

  Future<McpConnectionInfo> connectAndGetInfo(
    Mcp config, {
    String? preDefinedName,
    String? preDefinedDescription,
  }) async {
    final timeoutSec = config.timeout ?? _defaultTimeout;
    debugPrint('🔗 ====== 连接 MCP 服务器并获取信息 ======');
    await _cleanupClient(config.name);
    final client = Client(
      name: 'aidock-client-${config.name}',
      version: '1.0.0',
    );
    try {
      final transport = await _createTransport(
        config,
        timeout: Duration(seconds: timeoutSec),
      ).timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException('Transport 超时: ${config.name}'),
      );
      await client
          .connect(transport)
          .timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException('连接超时: ${config.name}'),
          );
      final info = client.serverInfo;
      final serverName =
          info != null ? (info['name'] as String? ?? config.name) : config.name;
      final serverVersion =
          info != null ? (info['version'] as String? ?? '') : '';
      final serverDesc = client.instructions;
      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException('listTools 超时: $serverName'),
      );
      final toolInfos =
          tools
              .map(
                (t) => McpTool(
                  name: t.name,
                  description: t.description,
                  inputSchema: t.inputSchema as Map<String, dynamic>? ?? {},
                ),
              )
              .toList();
      final finalName = preDefinedName ?? serverName;
      String? finalDesc = preDefinedDescription;
      if (finalDesc == null) {
        final llm = await summarizeWithLLM(
          serverName: serverName,
          tools: toolInfos,
        );
        finalDesc = llm?['description'] ?? serverDesc;
      }
      final server = Mcp(
        name: finalName,
        description: finalDesc,
        version: serverVersion.isNotEmpty ? serverVersion : null,
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );
      final prompt = buildMcpPrompt(server);
      debugPrint('✅ ====== 获取信息成功: $finalName ======');
      return McpConnectionInfo(
        serverName: finalName,
        description: finalDesc,
        serverVersion: serverVersion.isNotEmpty ? serverVersion : null,
        tools: toolInfos,
        prompt: prompt,
      );
    } catch (e, stack) {
      debugPrint(
        '${e is TimeoutException ? '⏱' : '❌'} ====== 连接失败: ${config.name} ======',
      );
      debugPrint('   错误: $e\n   堆栈: $stack');
      rethrow;
    } finally {
      try {
        client.disconnect();
      } catch (_) {}
      _clients.remove(config.name);
      _availableTools.remove(config.name);
    }
  }

  // ═══ LLM 总结 ═══

  Future<Map<String, String>?> summarizeWithLLM({
    required String serverName,
    required List<McpTool> tools,
  }) async {
    try {
      final modelController = Get.find<ModelController>();
      if (modelController.models.isEmpty) {
        debugPrint('⚠️ [MCP-Summarize] 没有可用模型');
        return null;
      }
      final ChatModel model = modelController.models.last;
      final provider = OpenAiProvider();
      provider.configure(model);
      final toolSummary = StringBuffer();
      for (final t in tools) {
        toolSummary.writeln('- ${t.name}: ${t.description}');
      }

      final prompt =
          r"""你是一个技术工具命名专家。请根据以下 MCP 服务信息生成精简的中文名称和描述。

要求：1.名称简洁中文优先(可含英文关键词)不超过15字 2.描述一句话不超过50字 3.仅输出JSON

原始名称：""" +
          serverName +
          r"""

工具列表：
""" +
          toolSummary.toString() +
          r"""
输出格式：{"name": "名称", "description": "描述"}""";

      debugPrint('🤖 [MCP-Summarize] 调用 LLM 总结: $serverName');
      final tempSession = ChatSession(
        sessionId: 'mcp_summarize',
        name: 'MCP Summarize',
        createdAt: DateTime.now(),
        messages: [],
        chatModel: model,
      );
      final buffer = StringBuffer();
      await for (final chunk in provider.sendMessageStream(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        session: tempSession,
      )) {
        final c = chunk['content'] ?? '';
        if (c.isNotEmpty) buffer.write(c);
      }
      final text = buffer.toString().trim();
      String jsonStr = text;
      final m = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(text);
      if (m != null) jsonStr = m.group(1)!.trim();
      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = result['name'] as String?;
      final desc = result['description'] as String?;
      if (name != null && name.isNotEmpty) {
        debugPrint('✅ [MCP-Summarize] name=$name, desc=$desc');
        return {'name': name, 'description': desc ?? ''};
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [MCP-Summarize] 失败: $e');
      return null;
    }
  }

  // ═══ 客户端生命周期 ═══

  Future<Mcp?> initializeClient(Mcp config) async {
    final timeoutSec = config.timeout ?? _defaultTimeout;
    try {
      debugPrint('🔧 初始化 MCP 客户端: ${config.name}');
      if (_clients.containsKey(config.name)) {
        final c = _clients[config.name]!;
        try {
          final tools = await c.listTools().timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException('验证超时: ${config.name}'),
          );
          _availableTools[config.name] = tools;
          debugPrint('✓ MCP 客户端已连接: ${config.name}, 工具: ${tools.length}');
          return _buildServer(config, tools);
        } on TimeoutException {
          await _cleanupClient(config.name);
        } catch (e) {
          debugPrint('⚠️ 连接异常，重新初始化: ${config.name}');
          await _cleanupClient(config.name);
        }
      }
      final client = Client(
        name: 'aidock-client-${config.name}',
        version: '1.0.0',
      );
      ClientTransport? transport;
      try {
        transport = await _createTransport(
          config,
          timeout: Duration(seconds: timeoutSec),
        ).timeout(
          Duration(seconds: timeoutSec),
          onTimeout:
              () => throw TimeoutException('Transport 超时: ${config.name}'),
        );
        await client
            .connect(transport)
            .timeout(
              Duration(seconds: timeoutSec),
              onTimeout: () => throw TimeoutException('连接超时: ${config.name}'),
            );
      } on McpError catch (e) {
        final err = e.toString();
        if ((err.contains('405') ||
                err.contains('Method not allowed') ||
                err.contains('Method Not Allowed')) &&
            config.url != null &&
            config.url!.isNotEmpty) {
          try {
            client.disconnect();
          } catch (_) {}
          transport = await StreamableHttpClientTransport.create(
            baseUrl: config.url!,
            headers: config.headers,
            timeout: Duration(seconds: timeoutSec),
          );
          await client
              .connect(transport)
              .timeout(
                Duration(seconds: timeoutSec),
                onTimeout:
                    () =>
                        throw TimeoutException(
                          'Streamable HTTP 连接超时: ${config.name}',
                        ),
              );
        } else {
          rethrow;
        }
      }
      try {
        await client.initialize().timeout(
          Duration(seconds: timeoutSec),
          onTimeout: () => throw TimeoutException('初始化超时: ${config.name}'),
        );
      } catch (e) {
        if (!e.toString().contains('already initialized')) rethrow;
      }
      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException('listTools 超时: ${config.name}'),
      );
      _clients[config.name] = client;
      _availableTools[config.name] = tools;
      debugPrint('✅ MCP 客户端初始化成功: ${config.name}, 工具: ${tools.length}');
      return _buildServer(config, tools);
    } on TimeoutException {
      debugPrint('⏱ 初始化超时: ${config.name}');
      return null;
    } catch (e) {
      debugPrint('❌ 初始化失败: ${config.name}, $e');
      return null;
    }
  }

  Mcp _buildServer(Mcp config, List<Tool> tools) {
    return Mcp(
      name: config.name,
      description: config.description,
      tools:
          tools
              .map(
                (t) => McpTool(
                  name: t.name,
                  description: t.description,
                  inputSchema: t.inputSchema as Map<String, dynamic>? ?? {},
                ),
              )
              .toList(),
      lastUpdated: DateTime.now(),
    );
  }

  Future<void> _cleanupClient(String name) async {
    final c = _clients[name];
    if (c != null) {
      try {
        c.disconnect();
      } catch (_) {}
    }
    _clients.remove(name);
    _availableTools.remove(name);
  }

  Client? getMCPClient(String name) => _clients[name];
  Future<void> closeClient(String name) async => await _cleanupClient(name);

  Future<void> closeAllClients() async {
    for (final name in List<String>.from(_clients.keys)) {
      await closeClient(name);
    }
  }

  // ═══ 会话级管理 ═══

  List<Mcp> _getEnabledServices(ChatSession s) {
    final services = <Mcp>[];
    final sessionMcpNames = <String>{};
    // session-level MCPs
    if (s.mcps != null && s.mcps!.isNotEmpty) {
      for (final name in s.mcps!) {
        if (name.isEmpty) continue;
        sessionMcpNames.add(name);
        final cfg = getMcp(name);
        if (cfg != null) services.add(cfg);
      }
    }
    // model-level MCPs (dedup)
    final modelMcps = s.chatModel?.mcps;
    if (modelMcps != null && modelMcps.isNotEmpty) {
      for (final name in modelMcps) {
        if (name.isEmpty || sessionMcpNames.contains(name)) continue;
        final cfg = getMcp(name);
        if (cfg != null) services.add(cfg);
      }
    }
    return services;
  }

  Future<Mcp?> initializeSessionMcpServices(ChatSession s) async {
    await ensureLoaded();
    final svcs = _getEnabledServices(s);
    if (svcs.isEmpty) {
      debugPrint('📝 会话 ${s.name} 未配置MCP服务');
      return null;
    }
    Mcp? server;
    for (final c in svcs) {
      server = await initializeClient(c);
    }
    debugPrint('🚀 会话 ${s.name} 初始化 ${svcs.length} 个 MCP 服务');
    return server;
  }

  List<Tool> getSessionAvailableTools(ChatSession s) {
    final all = <Tool>[];
    for (final c in _getEnabledServices(s)) {
      final t = _availableTools[c.name];
      if (t != null) all.addAll(t);
    }
    return all;
  }

  Future<Client?> getOrInitClient(ChatSession s, {String? toolName}) async {
    // Find the MCP that has the requested tool
    if (toolName != null && toolName.isNotEmpty) {
      for (final mcpName in _effectiveMcpNames(s)) {
        if (_hasTool(mcpName, toolName)) {
          final mc = await _getOrInitSingleClient(mcpName);
          if (mc != null) return mc;
        }
      }
      return null;
    }

    // No specific tool requested, return first available client
    for (final mcpName in _effectiveMcpNames(s)) {
      final mc = await _getOrInitSingleClient(mcpName);
      if (mc != null) return mc;
    }
    return null;
  }

  /// Find the MCP name that owns a specific tool
  String? findMcpOwner(ChatSession s, String toolName) {
    for (final mcpName in _effectiveMcpNames(s)) {
      if (_hasTool(mcpName, toolName)) return mcpName;
    }
    return null;
  }

  Future<Client?> _getOrInitSingleClient(String mcpName) async {
    Client? mc = getMCPClient(mcpName);
    if (mc == null) {
      try {
        await ensureLoaded();
        await _initSingleMcp(mcpName);
        mc = getMCPClient(mcpName);
      } on TimeoutException {
        debugPrint('⏱ _getOrInitSingleClient 超时: $mcpName');
      } catch (e) {
        debugPrint('❌ _getOrInitSingleClient 失败: $mcpName, $e');
      }
    }
    return mc;
  }

  bool _hasTool(String mcpName, String toolName) {
    final mcp = getMcp(mcpName);
    if (mcp?.tools == null) return false;
    return mcp!.tools!.any((t) => t.name == toolName);
  }

  /// Get all effective MCP names for a session (session MCPs + model MCPs, deduplicated)
  Iterable<String> _effectiveMcpNames(ChatSession s) sync* {
    if (s.mcps != null) {
      for (final name in s.mcps!) {
        if (name.isNotEmpty) yield name;
      }
    }
    final modelMcps = s.chatModel?.mcps;
    if (modelMcps != null) {
      for (final name in modelMcps) {
        if (name.isNotEmpty && !(s.mcps?.contains(name) == true)) yield name;
      }
    }
  }

  /// Initialize a single MCP by name
  Future<void> _initSingleMcp(String mcpName) async {
    if (_clients.containsKey(mcpName)) return;
    final cfg = getMcp(mcpName);
    if (cfg == null) return;
    await initializeClient(cfg);
  }

  /// Get merged tools from session MCP + model MCP, deduplicated by name
  List<McpTool> getMergedTools(ChatSession s) {
    final seen = <String>{};
    final merged = <McpTool>[];

    for (final mcpName in _effectiveMcpNames(s)) {
      final tools = getTools(mcpName);
      for (final t in tools) {
        if (seen.add(t.name)) merged.add(t);
      }
    }
    return merged;
  }

  /// Get merged MCP servers list (for prompt building)
  List<Mcp> getMergedMcpServers(ChatSession s) {
    final servers = <Mcp>[];
    for (final mcpName in _effectiveMcpNames(s)) {
      final mcp = getMcp(mcpName);
      if (mcp != null) servers.add(mcp);
    }
    return servers;
  }

  /// Build MCP prompt from merged tools (deduplicated across all MCPs)
  String buildMergedMcpPrompt(ChatSession s) {
    final mergedTools = getMergedTools(s);
    if (mergedTools.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('## 可用的MCP工具\n');
    for (int i = 0; i < mergedTools.length; i++) {
      final tool = mergedTools[i];
      buf.writeln('#### ${i + 1}. **${tool.name}**');
      buf.writeln('**功能描述**: ${tool.description}\n');
      if (tool.inputSchema.isNotEmpty) {
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>? ?? {};
        final required = (schema['required'] as List<dynamic>?) ?? [];
        if (properties.isNotEmpty) {
          buf.writeln('**参数详情**:');
          for (final entry in properties.entries) {
            final propName = entry.key;
            final propInfo = entry.value as Map<String, dynamic>? ?? {};
            final type = propInfo['type'] ?? 'string';
            final desc = propInfo['description'] ?? '无描述';
            final mark = required.contains(propName) ? '🔴 必需' : '⚪ 可选';
            buf.writeln('- **$propName** ($type) - $mark');
            buf.writeln('  说明: $desc');
            if (propInfo.containsKey('enum')) {
              final ev = propInfo['enum'] as List<dynamic>? ?? [];
              if (ev.isNotEmpty) buf.writeln('  可选值: ${ev.join(', ')}');
            }
            if (propInfo.containsKey('default'))
              buf.writeln('  默认值: ${propInfo['default']}');
            buf.writeln();
          }
        }
        buf.writeln('**📋 标准调用示例**:');
        final exampleArgs = <String, dynamic>{};
        for (final entry in properties.entries) {
          final propName = entry.key;
          final propInfo = entry.value as Map<String, dynamic>? ?? {};
          final type = propInfo['type'] ?? 'string';
          if (required.contains(propName)) {
            switch (type) {
              case 'string':
                if (propInfo.containsKey('enum')) {
                  final ev = propInfo['enum'] as List<dynamic>? ?? [];
                  exampleArgs[propName] =
                      ev.isNotEmpty ? ev.first.toString() : 'example_string';
                } else if (propName.toLowerCase().contains('path')) {
                  exampleArgs[propName] = '/path/to/file';
                } else if (propName.toLowerCase().contains('query')) {
                  exampleArgs[propName] = '搜索关键词';
                } else {
                  exampleArgs[propName] = 'example_string';
                }
              case 'number':
              case 'integer':
                exampleArgs[propName] = 42;
              case 'boolean':
                exampleArgs[propName] = true;
              case 'array':
                exampleArgs[propName] = ['item1', 'item2'];
              case 'object':
                exampleArgs[propName] = {'key': 'value'};
              default:
                exampleArgs[propName] = 'example_value';
            }
          }
        }
        buf.writeln('```xml');
        buf.writeln('<tool_calls>');
        buf.writeln('<invoke name="${tool.name}">');
        if (exampleArgs.isNotEmpty) {
          buf.writeln('<arguments>');
          try {
            buf.writeln(
              const JsonEncoder.withIndent('  ').convert(exampleArgs),
            );
          } catch (_) {
            buf.writeln('{}');
          }
          buf.writeln('</arguments>');
        }
        buf.writeln('</invoke>');
        buf.writeln('</tool_calls>');
        buf.writeln('```\n');
      }
      buf.writeln('---\n');
    }
    return buf.toString();
  }

  void initForSession(ChatSession s) {
    // init both session and model MCPs
    for (final mcpName in _effectiveMcpNames(s)) {
      if (_clients.containsKey(mcpName)) {
        debugPrint('📡 MCP 已存在: $mcpName');
        continue;
      }
      debugPrint('🚀 预初始化 MCP: $mcpName');
      Future.microtask(() async {
        try {
          await ensureLoaded();
          await _initSingleMcp(mcpName);
        } on TimeoutException {
          debugPrint('⏱ 预初始化超时: $mcpName');
        } catch (e) {
          debugPrint('❌ 预初始化失败: $mcpName, $e');
        }
      });
    }
  }

  Future<Mcp?> initForSessionSync(ChatSession s) async {
    // init all effective MCPs (session + model)
    Mcp? lastServer;
    for (final mcpName in _effectiveMcpNames(s)) {
      if (_clients.containsKey(mcpName) && _availableTools.containsKey(mcpName)) {
        debugPrint('📡 MCP 已就绪: $mcpName');
        continue;
      }
      debugPrint('🚀 同步初始化 MCP: $mcpName');
      try {
        await ensureLoaded();
        final cfg = getMcp(mcpName);
        if (cfg != null) {
          lastServer = await initializeClient(cfg);
        }
      } on TimeoutException {
        debugPrint('⏱ 同步初始化超时: $mcpName');
      } catch (e) {
        debugPrint('❌ 同步初始化失败: $mcpName, $e');
      }
    }
    return lastServer;
  }

  bool hasAvailableTools(ChatSession s) {
    if (!hasGlobalMcpServices) return false;
    // check if any MCP (session or model) has tools
    for (final mcpName in _effectiveMcpNames(s)) {
      if (_availableTools[mcpName]?.isNotEmpty == true) return true;
    }
    return false;
  }

  // ═══ Prompt 构建 ═══

  String buildMcpPrompt(Mcp mcp) {
    final toolInfos = mcp.tools;
    if (toolInfos == null || toolInfos.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('## 可用的MCP工具\n');
    buf.writeln('### 📋 ${mcp.name} 服务工具\n');
    for (int i = 0; i < toolInfos.length; i++) {
      final tool = toolInfos[i];
      buf.writeln('#### ${i + 1}. **${tool.name}**');
      buf.writeln('**功能描述**: ${tool.description}\n');
      if (tool.inputSchema.isNotEmpty) {
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>? ?? {};
        final required = (schema['required'] as List<dynamic>?) ?? [];
        if (properties.isNotEmpty) {
          buf.writeln('**参数详情**:');
          for (final entry in properties.entries) {
            final propName = entry.key;
            final propInfo = entry.value as Map<String, dynamic>? ?? {};
            final type = propInfo['type'] ?? 'string';
            final desc = propInfo['description'] ?? '无描述';
            final mark = required.contains(propName) ? '🔴 必需' : '⚪ 可选';
            buf.writeln('- **$propName** ($type) - $mark');
            buf.writeln('  说明: $desc');
            if (propInfo.containsKey('enum')) {
              final ev = propInfo['enum'] as List<dynamic>? ?? [];
              if (ev.isNotEmpty) buf.writeln('  可选值: ${ev.join(', ')}');
            }
            if (propInfo.containsKey('default'))
              buf.writeln('  默认值: ${propInfo['default']}');
            buf.writeln();
          }
        }
        buf.writeln('**📋 标准调用示例**:');
        final exampleArgs = <String, dynamic>{};
        for (final entry in properties.entries) {
          final propName = entry.key;
          final propInfo = entry.value as Map<String, dynamic>? ?? {};
          final type = propInfo['type'] ?? 'string';
          if (required.contains(propName)) {
            switch (type) {
              case 'string':
                if (propInfo.containsKey('enum')) {
                  final ev = propInfo['enum'] as List<dynamic>? ?? [];
                  exampleArgs[propName] =
                      ev.isNotEmpty ? ev.first.toString() : 'example_string';
                } else if (propName.toLowerCase().contains('path')) {
                  exampleArgs[propName] = '/path/to/file';
                } else if (propName.toLowerCase().contains('query')) {
                  exampleArgs[propName] = '搜索关键词';
                } else {
                  exampleArgs[propName] = 'example_string';
                }
              case 'number':
              case 'integer':
                exampleArgs[propName] = 42;
              case 'boolean':
                exampleArgs[propName] = true;
              case 'array':
                exampleArgs[propName] = ['item1', 'item2'];
              case 'object':
                exampleArgs[propName] = {'key': 'value'};
              default:
                exampleArgs[propName] = 'example_value';
            }
          }
        }
        buf.writeln('```xml');
        buf.writeln('<tool_calls>');
        buf.writeln('<invoke name="${tool.name}">');
        if (exampleArgs.isNotEmpty) {
          buf.writeln('<arguments>');
          try {
            buf.writeln(
              const JsonEncoder.withIndent('  ').convert(exampleArgs),
            );
          } catch (_) {
            buf.writeln('{}');
          }
          buf.writeln('</arguments>');
        }
        buf.writeln('</invoke>');
        buf.writeln('</tool_calls>');
        buf.writeln('```\n');
      }
      buf.writeln('---\n');
    }
    return buf.toString();
  }

  // ═══ OpenAI 工具格式 ═══

  /// 根据 Mcp 名称获取其结构体中存储的 OpenAI 格式工具列表（纯读取）。
  List<McpTool> getTools(String mcpName) {
    final mcp = getMcp(mcpName);
    if (mcp == null) return [];
    final tools = mcp.tools;
    if (tools == null || tools.isEmpty) return [];
    debugPrint('🔧 生成 OpenAI tools 数量: ${tools.length}');
    return tools;
  }

  // ═══ 工具执行（统一执行器）═══
  //
  // 与 MCP 完全解耦，独立调度所有类型工具的执行：
  // - MCP 工具：通过 MCP 客户端执行
  //
  // 注意：工具调用解析由 OpenAiProvider 负责，本服务只执行已解析的工具。

  /// 执行已解析的工具调用列表
  ///
  /// [toolCalls] 已解析的工具调用列表 (每个: {name, arguments, id?, index?})
  /// [cleanContent] 剥离工具调用 XML 后的干净文本
  Future<ToolExecutionResult?> executeToolCalls({
    required ChatSession session,
    required List<Map<String, dynamic>> toolCalls,
    required String cleanContent,
  }) async {
    if (toolCalls.isEmpty) return null;

    debugPrint('🔧 McpController: 准备执行 ${toolCalls.length} 个工具调用');

    // 逐个执行工具
    final executionResults = <Map<String, dynamic>>[];
    final toolCallList = <Map<String, dynamic>>[];

    for (int i = 0; i < toolCalls.length; i++) {
      final tc = toolCalls[i];
      final name = tc['name'] as String;
      final args = tc['arguments'] as Map<String, dynamic>;
      final callId = (tc['id'] as String?) ?? 'call_$i';

      // 标准化：补齐 id / index
      toolCallList.add({
        ...tc,
        'id': callId,
        if (!tc.containsKey('index')) 'index': i,
      });

      try {
        final result = await _routeAndExecute(
          session: session,
          toolName: name,
          arguments: args,
          callId: callId,
        );
        executionResults.add(result);
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

    return ToolExecutionResult(
      cleanContent: cleanContent,
      toolCallList: toolCallList,
      executionResults: executionResults,
    );
  }

  // ── 路由 → 执行 ──

  Future<Map<String, dynamic>> _routeAndExecute({
    required ChatSession session,
    required String toolName,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    // 还原被转义的工具名（OpenAI function calling 不允许函数名含点号等特殊字符）
    final resolvedName = resolveOriginalToolName(toolName);

    // ── MCP 工具：尝试 MCP 客户端（按工具名路由到正确的 MCP） ──
    final mc = await getOrInitClient(session, toolName: resolvedName);
    if (mc != null) {
      final result = await _callMCPTool(mc, resolvedName, arguments, callId);
      // 成功或非连接类错误 → 直接返回
      if (result != null) return result;

      // 连接失败（SSE 长连接可能因空闲超时被断开），
      // 清理旧客户端并重连重试一次
      debugPrint('🔄 MCP 工具 "$toolName" 连接失败，尝试重连重试...');
      final ownerMcpName = findMcpOwner(session, resolvedName);
      if (ownerMcpName != null) {
        await closeClient(ownerMcpName);
        final retryMc = await getOrInitClient(session, toolName: resolvedName);
        if (retryMc != null) {
          final retryResult = await _callMCPTool(
            retryMc,
            toolName,
            arguments,
            callId,
          );
          if (retryResult != null) return retryResult;
        }
      }
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': 'MCP 执行失败: 连接不可用，已尝试重连',
        'isError': true,
      };
    }

    // ── 无法识别 ──
    return {
      'id': callId,
      'name': toolName,
      'args': arguments,
      'result': '工具 "$toolName" 在当前环境中不可用。',
      'isError': true,
    };
  }

  // ── MCP 工具执行 ──

  Future<Map<String, dynamic>?> _callMCPTool(
    Client mc,
    String toolName,
    Map<String, dynamic> arguments,
    String callId,
  ) async {
    try {
      final r = await mc.callTool(toolName, arguments);
      final ok = r.isError != true;
      final buf = StringBuffer();
      for (final c in r.content) {
        if (c is TextContent) buf.writeln(c.text);
        if (c is ImageContent) buf.writeln('[图片: ${c.data ?? c.url}]');
      }
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': buf.toString().trim(),
        'isError': !ok,
      };
    } catch (e) {
      final errStr = e.toString();
      debugPrint('⚠️ MCP 工具 "$toolName" 执行失败: $errStr');
      // 连接类错误（transport 断开、超时等）→ 返回 null 触发重连
      if (errStr.contains('disconnected') ||
          errStr.contains('Connection') ||
          errStr.contains('timed out') ||
          errStr.contains('Timeout') ||
          errStr.contains('502') ||
          errStr.contains('503') ||
          errStr.contains('not connected') ||
          errStr.contains('SSE')) {
        debugPrint('🔄 检测到连接类错误，将尝试重连');
        return null;
      }
      // 非连接类错误（参数错误等）→ 直接返回错误
      return {
        'id': callId,
        'name': toolName,
        'args': arguments,
        'result': 'MCP 执行失败: $errStr',
        'isError': true,
      };
    }
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final e in this) return e;
    return null;
  }
}
