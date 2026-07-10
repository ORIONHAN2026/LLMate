import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/mcp_config.dart';
import '../models/bigmodel/chat_model.dart';
import '../core/llm/openai_provider.dart';
import '../features/mcp/storage/mcp_storage_manager.dart';
import '../features/models/controllers/model_controller.dart';

// MCP 工具结果
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
    if (s.mcp == null || s.mcp!.isEmpty) return [];
    final cfg = getMcp(s.mcp!);
    return cfg != null ? [cfg] : [];
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

  Future<Client?> getOrInitClient(ChatSession s) async {
    final svc = s.mcp;
    if (svc == null || svc.isEmpty) return null;
    Client? mc = getMCPClient(svc);
    if (mc == null) {
      try {
        await ensureLoaded();
        final inited = await initializeSessionMcpServices(s);
        if (inited == null) return null;
        mc = getMCPClient(svc);
      } on TimeoutException {
        debugPrint('⏱ getOrInitClient 超时: $svc');
        return null;
      } catch (e) {
        debugPrint('❌ getOrInitClient 失败: $svc, $e');
        return null;
      }
    }
    return mc;
  }

  void initForSession(ChatSession s) {
    if (s.mcp == null || s.mcp!.isEmpty) return;
    final svc = s.mcp!;
    if (_clients.containsKey(svc)) {
      debugPrint('📡 MCP 已存在: $svc');
      return;
    }
    debugPrint('🚀 预初始化 MCP: $svc');
    Future.microtask(() async {
      try {
        await ensureLoaded();
        await initializeSessionMcpServices(s);
      } on TimeoutException {
        debugPrint('⏱ 预初始化超时: $svc');
      } catch (e) {
        debugPrint('❌ 预初始化失败: $svc, $e');
      }
    });
  }

  Future<Mcp?> initForSessionSync(ChatSession s) async {
    if (s.mcp == null || s.mcp!.isEmpty) return null;
    final svc = s.mcp!;
    if (_clients.containsKey(svc) && _availableTools.containsKey(svc)) {
      debugPrint('📡 MCP 已就绪: $svc');
      return null;
    }
    debugPrint('🚀 同步初始化 MCP: $svc');
    try {
      await ensureLoaded();
      return await initializeSessionMcpServices(s);
    } on TimeoutException {
      debugPrint('⏱ 同步初始化超时: $svc');
      return null;
    } catch (e) {
      debugPrint('❌ 同步初始化失败: $svc, $e');
      return null;
    }
  }

  bool hasAvailableTools(ChatSession s) {
    if (s.mcp == null || !hasGlobalMcpServices) return false;
    return getSessionAvailableTools(s).isNotEmpty;
  }

  // ═══ 工具调用 ═══

  Future<McpToolResult> callTool({
    required String serviceName,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    try {
      debugPrint('🔨 调用 MCP 工具: $serviceName.$toolName');
      final client = _clients[serviceName];
      if (client == null) throw Exception('MCP 服务未初始化: $serviceName');
      final r = await client.callTool(toolName, arguments);
      final isErr = r.isError == true;
      final formatted = _formatResult(r);
      if (isErr)
        debugPrint('⚠️ MCP 工具返回错误: $serviceName.$toolName');
      else
        debugPrint('✅ MCP 工具调用成功: $serviceName.$toolName');
      return McpToolResult(
        toolName: toolName,
        arguments: arguments,
        result: formatted,
        isSuccess: !isErr,
        error: isErr ? formatted : null,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ MCP 工具调用失败: $serviceName.$toolName, $e');
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

  String _formatResult(CallToolResult r) {
    if (r.content.isEmpty) return '';
    final buf = StringBuffer();
    for (final c in r.content) {
      if (c is TextContent)
        buf.writeln(c.text);
      else if (c is ImageContent)
        buf.writeln('[图片: ${c.data}]');
      else
        buf.writeln('[内容: $c]');
    }
    return buf.toString().trim();
  }

  Future<List<McpToolResult>> executeSessionToolCalls({
    required ChatSession session,
    required List<Map<String, dynamic>> toolCalls,
  }) async {
    final results = <McpToolResult>[];
    final enabled = _getEnabledServices(session);
    if (enabled.isEmpty) {
      debugPrint('📝 无 MCP 服务，跳过工具调用');
      return results;
    }
    for (final tc in toolCalls) {
      try {
        final toolName = tc['name'] as String?;
        if (toolName == null || toolName.isEmpty) continue;
        final args = tc['arguments'] as Map<String, dynamic>? ?? {};
        String? target;
        final parts = toolName.split('.');
        if (parts.length >= 2) {
          final sn = parts[0];
          if (enabled.any((c) => c.name == sn)) {
            final t = _availableTools[sn];
            if (t != null && t.any((tool) => tool.name == toolName))
              target = sn;
          }
        }
        if (target == null) {
          for (final c in enabled) {
            final t = _availableTools[c.name];
            if (t != null && t.any((tool) => tool.name == toolName)) {
              target = c.name;
              break;
            }
          }
        }
        if (target != null) {
          results.add(
            await callTool(
              serviceName: target,
              toolName: toolName,
              arguments: args,
            ),
          );
        } else {
          results.add(
            McpToolResult(
              toolName: toolName,
              arguments: args,
              result: '',
              isSuccess: false,
              error: '未找到支持该工具的 MCP 服务',
              timestamp: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        results.add(
          McpToolResult(
            toolName: tc['name'] as String? ?? 'unknown',
            arguments: tc['arguments'] as Map<String, dynamic>? ?? {},
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

  String formatToolResultForDisplay(McpToolResult result) {
    final buf = StringBuffer();
    buf.writeln('🔧 工具: ${result.toolName}');
    if (result.arguments.isNotEmpty)
      buf.writeln('📝 参数: ${jsonEncode(result.arguments)}');
    buf.writeln(
      '${result.isSuccess ? '✅' : '❌'} 状态: ${result.isSuccess ? '成功' : '失败'}',
    );
    if (!result.isSuccess && result.error != null)
      buf.writeln('⚠️ 错误: ${result.error}');
    if (result.result.isNotEmpty) buf.writeln('📄 结果: ${result.result}');
    return buf.toString().trim();
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
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final e in this) return e;
    return null;
  }
}
