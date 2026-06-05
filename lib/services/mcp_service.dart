import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mcp_client/mcp_client.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/mcp_config.dart';
import '../models/bigmodel/chat_model.dart';
import '../controllers/mcp_controller.dart';
import '../controllers/model_controller.dart';
import '../framework/llm_hub.dart';

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

/// MCP 连接信息（初始化后获取的服务器信息 + 工具列表 + 生成的 prompt）
class McpConnectionInfo {
  final String serverName;
  final String? description; // 服务器描述（来自 instructions）
  final List<McpToolInfo> tools;
  final String prompt; // LLM 用的工具介绍文本

  const McpConnectionInfo({
    required this.serverName,
    this.description,
    required this.tools,
    required this.prompt,
  });
}

/// MCP服务管理类
class McpService {
  static final Map<String, Client> _clients = {};
  static final Map<String, List<Tool>> _availableTools = {};

  /// 更新配置中的工具信息
  static Future<void> _updateConfigWithToolInfo(
    Mcp config,
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
      _cachedConfigs[config.mcpId] = updatedConfig;

      debugPrint('✅ 已更新 ${config.name} 的工具信息: ${toolInfos.length} 个工具');
    } catch (e) {
      debugPrint('❌ 更新配置工具信息失败: ${config.name}, 错误: $e');
    }
  }

  /// 缓存的配置信息（运行时工具信息，不持久化）
  static final Map<String, Mcp> _cachedConfigs = {};

  /// 通过 mcpId 获取缓存的配置（含运行时信息如 description、tools）
  static Mcp? getCachedConfig(String mcpId) => _cachedConfigs[mcpId];

  /// 获取 McpController 实例
  static McpController get _mcpController => Get.find<McpController>();

  /// 确保全局 MCP 配置已加载到内存
  static Future<void> ensureGlobalConfigsLoaded() async {
    await _mcpController.ensureLoaded();
  }

  /// 是否有全局 MCP 服务（同步，用于快速判断）
  static bool get hasGlobalMcpServices {
    try {
      return _mcpController.hasServices;
    } catch (_) {
      return _cachedConfigs.isNotEmpty;
    }
  }

  /// 按名称查找 MCP 服务配置
  static Mcp? getMcpServerByName(String name) {
    // 优先从缓存中查找（含运行时工具信息）
    if (_cachedConfigs.containsKey(name)) {
      return _cachedConfigs[name];
    }
    return _mcpController.getMcpByName(name);
  }

  /// 根据配置创建对应的 Transport（支持 stdio / SSE / StreamableHTTP）
  /// 当 type 未指定时，先尝试 SSE，若 SSE 返回 405 则自动回退到 Streamable HTTP。
  static Future<ClientTransport> _createTransport(
    Mcp config, {
    Duration? timeout,
  }) async {
    if (config.url != null && config.url!.isNotEmpty) {
      final transportType = config.type;
      if (transportType == McpTransportType.streamableHttp ||
          transportType == McpTransportType.http) {
        debugPrint('🔗 使用 Streamable HTTP 传输: ${config.url}');
        return StreamableHttpClientTransport.create(
          baseUrl: config.url!,
          headers: config.headers,
          timeout: timeout,
        );
      } else if (transportType == McpTransportType.sse) {
        debugPrint('🔗 使用 SSE 传输: ${config.url}');
        try {
          return await SseClientTransport.create(
            serverUrl: config.url!,
            headers: config.headers,
          );
        } catch (e) {
          final es = e.toString();
          // SSE 端点不支持（405 Method Not Allowed），回退到 Streamable HTTP
          if (es.contains('405') || es.contains('Method not allowed')) {
            debugPrint('🔗 SSE 不支持 (405)，自动回退到 Streamable HTTP: ${config.url}');
            return StreamableHttpClientTransport.create(
              baseUrl: config.url!,
              headers: config.headers,
              timeout: timeout,
            );
          }
          rethrow;
        }
      } else {
        // type 未指定，先尝试 SSE，405 时自动回退 Streamable HTTP
        debugPrint('🔗 传输类型未指定，先尝试 SSE: ${config.url}');
        try {
          return SseClientTransport.create(
            serverUrl: config.url!,
            headers: config.headers,
          );
        } catch (e) {
          final es = e.toString();
          // SSE 端点不支持（405 Method Not Allowed），回退到 Streamable HTTP
          if (es.contains('405') || es.contains('Method not allowed')) {
            debugPrint('🔗 SSE 不支持 (405)，自动回退到 Streamable HTTP: ${config.url}');
            return StreamableHttpClientTransport.create(
              baseUrl: config.url!,
              headers: config.headers,
              timeout: timeout,
            );
          }
          rethrow;
        }
      }
    } else {
      final cmd = config.command;
      final args = config.args;
      if (cmd == null || cmd.isEmpty) {
        throw Exception('Stdio MCP 配置缺少 command: ${config.name}');
      }
      debugPrint('🔗 使用 stdio 传输: $cmd ${args?.join(' ') ?? ''}');
      return StdioClientTransport.create(
        command: cmd,
        arguments: args ?? [],
        environment: config.env,
        workingDirectory: config.workingDirectory,
      );
    }
  }

  /// 刷新单个 MCP 服务的工具列表（支持 stdio、SSE 和 Streamable HTTP 传输方式）
  /// 刷新单个 MCP 服务的工具列表（支持 stdio、SSE 和 Streamable HTTP 传输方式）
  /// 返回获取到的工具信息列表，失败时抛出异常。
  ///
  /// 使用 [config.timeout] 作为超时时间，未设置则默认 30 秒。
  /// 超时时抛出 [TimeoutException]。
  static Future<List<McpToolInfo>> refreshServiceTools(Mcp config) async {
    final timeoutSec = config.timeout ?? _defaultConnectionTimeoutSeconds;
    debugPrint('🔄 ====== 开始刷新 MCP 服务工具: ${config.name} ======');
    debugPrint(
      '   配置详情: name=${config.name}, url=${config.url}, command=${config.command}',
    );
    debugPrint('   args=${config.args}, headers=${config.headers}');
    debugPrint('   ⏱ 超时: ${timeoutSec}s');

    // 清理旧连接
    debugPrint('   🧹 清理旧连接...');
    await _cleanupClient(config.mcpId);

    // 创建客户端
    final client = Client(
      name: 'aidock-client-${config.name}',
      version: '1.0.0',
    );
    debugPrint('   📦 创建 Client: aidock-client-${config.name} v1.0.0');

    ClientTransport? transport;
    
    try {
      // 根据配置类型选择传输方式
      final startTime = DateTime.now();
      transport = await _createTransport(
        config,
        timeout: Duration(seconds: timeoutSec),
      ).timeout(
        Duration(seconds: timeoutSec),
        onTimeout:
            () =>
                throw TimeoutException(
                  '创建 Transport 超时 (${timeoutSec}s): ${config.name}',
                ),
      );
      debugPrint(
        '   ⏱ Transport 创建耗时: ${DateTime.now().difference(startTime).inMilliseconds}ms',
      );

      // 连接（connect 内部会自动调用 initialize）
      debugPrint('🔌 调用 client.connect(transport)...');
      final connectStart = DateTime.now();
      
      try {
        await client
            .connect(transport)
            .timeout(
              Duration(seconds: timeoutSec),
              onTimeout:
                  () =>
                      throw TimeoutException(
                        '连接 MCP 服务器超时 (${timeoutSec}s): ${config.name}',
                      ),
            );
      } on McpError catch (e) {
        final errorStr = e.toString();
        // 检测 SSE 405 错误，回退到 Streamable HTTP
        if ((errorStr.contains('405') || 
            errorStr.contains('Method not allowed') ||
            errorStr.contains('Method Not Allowed')) &&
            config.url != null && config.url!.isNotEmpty) {
          debugPrint('   ⚠️ SSE 连接失败 (405)，尝试回退到 Streamable HTTP...');
          
          // 重新创建 Streamable HTTP 传输
          transport = await StreamableHttpClientTransport.create(
            baseUrl: config.url!,
            headers: config.headers,
            timeout: Duration(seconds: timeoutSec),
          );
          
          // 使用新 transport 重新连接
          debugPrint('🔌 使用 Streamable HTTP 重新连接...');
          final reconnectStart = DateTime.now();
          await client.connect(transport).timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException(
              'Streamable HTTP 连接超时 (${timeoutSec}s): ${config.name}',
            ),
          );
          debugPrint(
            '   ⏱ Streamable HTTP 连接耗时: ${DateTime.now().difference(reconnectStart).inMilliseconds}ms',
          );
        } else {
          rethrow;
        }
      }
      
      debugPrint(
        '   ⏱ connect 耗时: ${DateTime.now().difference(connectStart).inMilliseconds}ms',
      );

      // 获取工具列表
      debugPrint('📋 调用 client.listTools()...');
      final listStart = DateTime.now();
      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout:
            () =>
                throw TimeoutException(
                  '获取工具列表超时 (${timeoutSec}s): ${config.name}',
                ),
      );
      debugPrint(
        '   ⏱ listTools 耗时: ${DateTime.now().difference(listStart).inMilliseconds}ms',
      );
      debugPrint('   📊 获取到 ${tools.length} 个工具');

      for (var i = 0; i < tools.length; i++) {
        final t = tools[i];
        debugPrint('      [${i + 1}] ${t.name}: ${t.description}');
      }

      // 转为 McpToolInfo 列表 + 缓存
      final toolInfos =
          tools.map((tool) {
            return McpToolInfo(
              name: tool.name,
              description: tool.description,
              inputSchema: tool.inputSchema as Map<String, dynamic>? ?? {},
            );
          }).toList();

      final description = config.description ?? client.instructions;
      debugPrint('   📝 服务器描述: $description');
      _cachedConfigs[config.mcpId] = config.copyWith(
        description: description,
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );

      debugPrint(
        '✅ ====== 刷新成功: ${config.name}, 工具数: ${toolInfos.length} ======',
      );

      // 断开连接
      return toolInfos;
    } catch (e, stack) {
      final isTimeout = e is TimeoutException;
      debugPrint('${isTimeout ? '⏱' : '❌'} ====== 刷新失败: ${config.name} ======');
      debugPrint('   错误类型: ${e.runtimeType}');
      debugPrint('   错误信息: $e');
      debugPrint('   堆栈: $stack');
      rethrow;
    } finally {
      // 无论成功失败，断开连接
      try {
        client.disconnect();
      } catch (_) {}
      _clients.remove(config.mcpId);
      _availableTools.remove(config.mcpId);
      debugPrint('🧹 已断开刷新连接: ${config.name}');
    }
  }

  // ── LLM 总结 MCP 服务信息 ──

  /// 用 LLM 总结 MCP 服务，生成精简的名称和中文描述
  ///
  /// 使用 ModelController 中最后添加的模型来调用 LLM，
  /// 根据原始服务器名称和工具列表生成一个友好的名称和描述。
  ///
  /// 返回 `{name, description}`，失败时返回 null。
  static Future<Map<String, String>?> _summarizeMcpWithLLM({
    required String serverName,
    required List<McpToolInfo> tools,
  }) async {
    try {
      final modelController = Get.find<ModelController>();
      if (modelController.models.isEmpty) {
        debugPrint('⚠️ [MCP-Summarize] 没有可用的模型，跳过总结');
        return null;
      }

      // 使用最后添加的模型
      final ChatModel model = modelController.models.last;
      final provider = LlmHub.createProvider(model);

      // 构建工具信息摘要
      final toolSummary = StringBuffer();
      for (final tool in tools) {
        toolSummary.writeln('- ${tool.name}: ${tool.description}');
      }

      final prompt = '''
你是一个技术工具命名专家。请根据以下 MCP (Model Context Protocol) 服务的信息，生成一个精简的中文名称和一段简洁的中文描述。

要求：
1. 名称：简洁易读，中文优先（可以包含英文关键词），不超过15个字
2. 描述：一句话说明这个服务能做什么，不超过50个字
3. 仅输出JSON格式，不要包含其他文字

原始服务器名称：$serverName

工具列表：
${toolSummary.toString()}

请按以下JSON格式输出：
{"name": "生成的名称", "description": "生成的描述"}''';

      debugPrint('🤖 [MCP-Summarize] 调用 LLM 总结服务: $serverName');
      debugPrint('   模型: ${model.name} (${model.provider})');

      final messages = [
        {'role': 'user', 'content': prompt},
      ];

      final buffer = StringBuffer();
      final stream = provider.sendMessageStreamWithMessages(messages);

      await for (final chunk in stream) {
        final content = chunk['content'] ?? '';
        if (content.isNotEmpty) {
          buffer.write(content);
        }
      }

      final responseText = buffer.toString().trim();
      debugPrint('🤖 [MCP-Summarize] LLM 响应: $responseText');

      // 提取 JSON（可能包含 markdown 代码块）
      String jsonStr = responseText;
      final codeBlockMatch = RegExp(
        r'```(?:json)?\s*([\s\S]*?)\s*```',
      ).firstMatch(responseText);
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      }

      final result = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = result['name'] as String?;
      final description = result['description'] as String?;

      if (name != null && name.isNotEmpty) {
        debugPrint('✅ [MCP-Summarize] 总结完成: name=$name, desc=$description');
        return {
          'name': name,
          'description': description ?? '',
        };
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [MCP-Summarize] 总结失败: $e');
      return null;
    }
  }

  /// 默认连接超时（秒）
  static const int _defaultConnectionTimeoutSeconds = 10;

  /// 连接 MCP 服务器并获取服务器名称和工具列表。
  /// 用于首次添加服务时，从远程获取服务器信息。**完成后断开连接**。
  ///
  /// 使用 [config.timeout] 作为超时时间，未设置则默认 30 秒。
  /// 超时时抛出 [TimeoutException]。
  ///
  /// [preDefinedName] 和 [preDefinedDescription]：当已明确知道名称和描述时，
  /// 传入后可跳过 LLM 总结步骤，直接使用预定义值。
  static Future<McpConnectionInfo> connectAndGetInfo(
    Mcp config, {
    String? preDefinedName,
    String? preDefinedDescription,
  }) async {
    final timeoutSec = config.timeout ?? _defaultConnectionTimeoutSeconds;
    debugPrint('🔗 ====== 连接 MCP 服务器并获取信息 ======');
    debugPrint('   配置: url=${config.url}, command=${config.command}');
    debugPrint('   args=${config.args}, headers=${config.headers}');
    debugPrint('   ⏱ 超时: ${timeoutSec}s');

    // 清理旧连接
    await _cleanupClient(config.mcpId);

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
        onTimeout:
            () =>
                throw TimeoutException(
                  '创建 Transport 超时 (${timeoutSec}s): ${config.name}',
                ),
      );

      await client
          .connect(transport)
          .timeout(
            Duration(seconds: timeoutSec),
            onTimeout:
                () =>
                    throw TimeoutException(
                      '连接 MCP 服务器超时 (${timeoutSec}s): ${config.name}',
                    ),
          );

      final serverInfo = client.serverInfo;
      final serverName =
          serverInfo != null
              ? (serverInfo['name'] as String? ?? config.name)
              : config.name;
      final serverDescription = client.instructions;
      debugPrint('📋 服务器名称: $serverName, 描述: $serverDescription');

      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout:
            () =>
                throw TimeoutException(
                  '获取工具列表超时 (${timeoutSec}s): $serverName',
                ),
      );
      debugPrint('📊 获取到 ${tools.length} 个工具');

      final toolInfos =
          tools.map((tool) {
            return McpToolInfo(
              name: tool.name,
              description: tool.description,
              inputSchema: tool.inputSchema as Map<String, dynamic>? ?? {},
            );
          }).toList();

      // 用 LLM 总结生成更好的名称和描述（如果没有预定义值）
      String finalName = preDefinedName ?? serverName;
      String? finalDescription = preDefinedDescription ?? serverDescription;
      if (preDefinedName == null && toolInfos.isNotEmpty) {
        final summary = await _summarizeMcpWithLLM(
          serverName: serverName,
          tools: toolInfos,
        );
        if (summary != null) {
          finalName = summary['name'] ?? serverName;
          finalDescription = summary['description'] ?? serverDescription;
        }
      }

      // 缓存工具信息
      _cachedConfigs[serverName] = config.copyWith(
        description: finalDescription,
        tools: toolInfos,
        lastUpdated: DateTime.now(),
      );

      // 生成 LLM 用的工具介绍文本
      final tempMcp = config.copyWith(
        name: finalName,
        description: finalDescription,
        tools: toolInfos,
      );
      final prompt = buildMcpPrompt(tempMcp);

      debugPrint('✅ ====== 获取信息成功: $finalName，断开连接 ======');

      // 立即断开，工具信息已保存到本地缓存
      return McpConnectionInfo(
        serverName: finalName,
        description: finalDescription,
        tools: toolInfos,
        prompt: prompt,
      );
    } catch (e, stack) {
      final isTimeout = e is TimeoutException;
      debugPrint('${isTimeout ? '⏱' : '❌'} ====== 连接失败: ${config.name} ======');
      debugPrint('   错误类型: ${e.runtimeType}');
      debugPrint('   错误信息: $e');
      debugPrint('   堆栈: $stack');
      rethrow;
    } finally {
      // 无论成功失败，断开连接
      try {
        client.disconnect();
      } catch (_) {}
      _clients.remove(config.mcpId);
      _availableTools.remove(config.mcpId);
      debugPrint('🧹 已断开探测连接: ${config.name}');
    }
  }

  /// 初始化MCP客户端
  static Future<bool> initializeClient(Mcp config) async {
    final timeoutSec = config.timeout ?? _defaultConnectionTimeoutSeconds;
    try {
      debugPrint('🔧 初始化MCP客户端: ${config.name}');

      // 检查是否已经初始化
      if (_clients.containsKey(config.mcpId)) {
        final client = _clients[config.mcpId]!;
        // 检查客户端是否仍然连接
        try {
          // 尝试获取工具列表来验证连接状态
          final tools = await client.listTools().timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException(
              '验证连接超时 (${timeoutSec}s): ${config.name}',
            ),
          );
          _availableTools[config.mcpId] = tools;
          debugPrint('✓ MCP客户端已存在且连接正常: ${config.name}, 工具数量: ${tools.length}');
          return true;
        } on TimeoutException {
          debugPrint('⏱ 验证现有连接超时: ${config.name}，重新初始化');
          await _cleanupClient(config.mcpId);
        } catch (e) {
          debugPrint('⚠️ 现有客户端连接异常，重新初始化: ${config.name}, 错误: $e');
          // 清理旧客户端
          await _cleanupClient(config.mcpId);
        }
      }

      // 创建客户端
      final client = Client(
        name: 'aidock-client-${config.name}',
        version: '1.0.0',
      );

      // 创建并连接传输层 - 根据配置选择传输方式
      ClientTransport? transport;
      
      try {
        transport = await _createTransport(
          config,
          timeout: Duration(seconds: timeoutSec),
        ).timeout(
          Duration(seconds: timeoutSec),
          onTimeout: () => throw TimeoutException(
            '创建 Transport 超时 (${timeoutSec}s): ${config.name}',
          ),
        );
        
        // 连接客户端到传输层
        await client.connect(transport).timeout(
          Duration(seconds: timeoutSec),
          onTimeout: () => throw TimeoutException(
            '连接 MCP 服务器超时 (${timeoutSec}s): ${config.name}',
          ),
        );
      } on McpError catch (e) {
        final errorStr = e.toString();
        // 检测 SSE 405 错误，回退到 Streamable HTTP
        if ((errorStr.contains('405') || 
            errorStr.contains('Method not allowed') ||
            errorStr.contains('Method Not Allowed')) &&
            config.url != null && config.url!.isNotEmpty) {
          debugPrint('   ⚠️ SSE 连接失败 (405)，尝试回退到 Streamable HTTP: ${config.name}');
          
          // 断开失败的连接
          try {
            client.disconnect();
          } catch (_) {}
          
          // 重新创建 Streamable HTTP 传输
          transport = await StreamableHttpClientTransport.create(
            baseUrl: config.url!,
            headers: config.headers,
            timeout: Duration(seconds: timeoutSec),
          ).timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException(
              '创建 Streamable HTTP Transport 超时 (${timeoutSec}s): ${config.name}',
            ),
          );
          
          // 使用新 transport 重新连接
          debugPrint('🔌 使用 Streamable HTTP 重新连接: ${config.name}');
          await client.connect(transport).timeout(
            Duration(seconds: timeoutSec),
            onTimeout: () => throw TimeoutException(
              'Streamable HTTP 连接超时 (${timeoutSec}s): ${config.name}',
            ),
          );
        } else {
          rethrow;
        }
      }

      // 初始化客户端
      try {
        await client.initialize().timeout(
          Duration(seconds: timeoutSec),
          onTimeout: () => throw TimeoutException(
            '初始化客户端超时 (${timeoutSec}s): ${config.name}',
          ),
        );
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
      final tools = await client.listTools().timeout(
        Duration(seconds: timeoutSec),
        onTimeout: () => throw TimeoutException(
          '获取工具列表超时 (${timeoutSec}s): ${config.name}',
        ),
      );

      // 存储客户端和工具列表
      _clients[config.mcpId] = client;
      _availableTools[config.mcpId] = tools;

      debugPrint('✅ MCP客户端初始化成功: ${config.name}, 工具数量: ${tools.length}');

      // 更新配置中的工具信息
      await _updateConfigWithToolInfo(config, tools);

      return true;
    } on TimeoutException catch (e) {
      debugPrint('⏱ MCP客户端初始化超时: ${config.name}, ${e.message}');
      return false;
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
  static List<Mcp> _getEnabledServices(ChatSession session) {
    return session.mcp != null ? [session.mcp!] : [];
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
        initializedServices.add(config.mcpId);
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
      final tools = _availableTools[config.mcpId];
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
        debugPrint(
          '⚠️ MCP工具调用返回错误: $serviceName.$toolName, 内容: $formattedResult',
        );
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
                  .where((config) => config.mcpId == serviceName)
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
            final tools = _availableTools[config.mcpId];
            if (tools != null && tools.any((tool) => tool.name == toolName)) {
              targetService = config.mcpId;
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

  /// 生成 MCP 工具介绍文本（添加/刷新时调用，存入 Mcp.prompt）
  static String buildMcpPrompt(Mcp mcp) {
    final toolInfos = mcp.tools;
    if (toolInfos == null || toolInfos.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('## 可用的MCP工具');
    buffer.writeln();

    // 工具调用格式要求

    buffer.writeln('### 📋 ${mcp.name} 服务工具');
    buffer.writeln();

    for (int i = 0; i < toolInfos.length; i++) {
      final tool = toolInfos[i];
      buffer.writeln('#### ${i + 1}. **${tool.name}**');
      buffer.writeln('**功能描述**: ${tool.description}');
      buffer.writeln();

      // 详细的参数信息
      if (tool.inputSchema.isNotEmpty) {
        final schema = tool.inputSchema;
        final properties = schema['properties'] as Map<String, dynamic>? ?? {};
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
                  final enumValues = propInfo['enum'] as List<dynamic>? ?? [];
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

    // 添加最终的重要提醒

    buffer.writeln();

    return buffer.toString();
  }

  /// 构建OpenAI兼容的tools格式
  static List<Map<String, dynamic>> buildOpenAIToolsFormat(
    ChatSession session,
  ) {
    final mcp = session.mcp;
    if (mcp == null) {
      return [];
    }

    final toolInfos = mcp.tools;
    if (toolInfos == null || toolInfos.isEmpty) {
      debugPrint('📝 session.mcp (${mcp.name}) 没有工具信息');
      return [];
    }

    final openAITools = <Map<String, dynamic>>[];
    for (final tool in toolInfos) {
      try {
        openAITools.add(
          _toolToOpenAiFormat(tool.name, tool.description, tool.inputSchema),
        );
        debugPrint('✅ 转换MCP工具为OpenAI格式: ${tool.name}');
      } catch (e) {
        debugPrint('❌ 转换MCP工具失败: ${tool.name}, 错误: $e');
      }
    }

    debugPrint('🔧 生成OpenAI tools数量: ${openAITools.length}');
    return openAITools;
  }

  static Map<String, dynamic> _toolToOpenAiFormat(
    String name,
    String description,
    Map<String, dynamic> inputSchema,
  ) {
    final functionDef = <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{'name': name, 'description': description},
    };

    if (inputSchema.isNotEmpty) {
      final schema = Map<String, dynamic>.from(inputSchema);
      if (!schema.containsKey('type')) {
        schema['type'] = 'object';
      }
      if (!schema.containsKey('properties')) {
        schema['properties'] = <String, dynamic>{};
      }
      functionDef['function']['parameters'] = schema;
    } else {
      functionDef['function']['parameters'] = {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      };
    }

    return functionDef;
  }

  // ──────────────────────────────────────────────
  // 工具调用解析 / 剥离 已迁移到 BaseLlmProvider.parseToolCalls()
  // ──────────────────────────────────────────────

  /// 检查会话是否有可用的MCP工具
  static bool hasAvailableTools(ChatSession session) {
    if (session.mcp == null) return false;
    if (!hasGlobalMcpServices) return false;

    final tools = getSessionAvailableTools(session);
    return tools.isNotEmpty;
  }

  /// 按需获取 MCP 客户端（懒连接 - 仅作兜底）
  ///
  /// 正常流程中，MCP 在会话打开时就已通过 [initForSession] 预连接，
  /// 此方法仅在未预连接的异常情况下按需初始化。
  static Future<Client?> getOrInitClient(ChatSession session) async {
    final svc = session.mcp?.mcpId;
    if (svc == null) return null;

    Client? mc = getMCPClient(svc);
    if (mc == null) {
      try {
        await ensureGlobalConfigsLoaded();
        final inited = await initializeSessionMcpServices(session);
        if (inited.isEmpty) return null;
        mc = getMCPClient(svc);
      } on TimeoutException catch (e) {
        debugPrint('⏱ getOrInitClient 超时: $svc, ${e.message}');
        return null;
      } catch (e) {
        debugPrint('❌ getOrInitClient 失败: $svc, 错误: $e');
        return null;
      }
    }

    return mc;
  }

  /// 会话打开时预初始化 MCP 连接
  ///
  /// 在 [SessionController.switchToSession] 和 [SessionController.setCurrentSession]
  /// 中调用，确保切换到会话时 MCP 已连接，后续工具调用无需等待。
  static void initForSession(ChatSession session) {
    if (session.mcp == null) return;
    final svc = session.mcp!.name;

    // 避免重复初始化
    if (_clients.containsKey(svc)) {
      debugPrint('📡 MCP 客户端已存在: $svc，跳过重复初始化');
      return;
    }

    debugPrint('🚀 会话打开，预初始化 MCP: $svc');
    // 放到微任务中，不阻塞 UI
    Future.microtask(() async {
      try {
        await ensureGlobalConfigsLoaded();
        await initializeSessionMcpServices(session);
      } on TimeoutException catch (e) {
        debugPrint('⏱ MCP 预初始化超时: $svc, ${e.message}');
      } catch (e) {
        debugPrint('❌ MCP 预初始化失败: $svc, 错误: $e');
      }
    });
  }
}
