import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_session.dart';
import 'node_tool_service.dart';

class SystemToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const SystemToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

/// 内置系统工具注册中心。
///
/// 提供以下内置工具：
/// - `node_execute`: 执行 Node.js 脚本
class SystemToolService {
  static const String nodeExecuteTool = 'node_execute';

  static const List<SystemToolDefinition> _tools = [
    SystemToolDefinition(
      name: nodeExecuteTool,
      description:
          '执行 Node.js 脚本。支持内联代码和 .js/.ts 文件两种方式。可选安装 npm 依赖。'
          '适合数据分析、文件批处理、API 调用、爬虫、文档生成等任何场景。返回 stdout/stderr 输出。',
      parameters: {
        'type': 'object',
        'properties': {
          'script': {
            'type': 'string',
            'description':
                'Node.js 脚本内容（内联代码）。与 filePath 二选一，优先使用 script。',
          },
          'filePath': {
            'type': 'string',
            'description': '要执行的 .js 或 .ts 文件完整路径。与 script 二选一。',
          },
          'args': {
            'type': 'array',
            'description': '传递给脚本的命令行参数列表。',
            'items': {'type': 'string'},
          },
          'requirements': {
            'type': 'array',
            'description':
                '需要安装的 npm 包名列表（如 ["axios", "lodash"]），执行前自动 npm install。',
            'items': {'type': 'string'},
          },
        },
      },
    ),
  ];

  static List<SystemToolDefinition> get tools => List.unmodifiable(_tools);

  static bool hasTool(String name) => _tools.any((tool) => tool.name == name);

  /// 构建 OpenAI tools 格式，用于向 LLM 声明可用工具
  static List<Map<String, dynamic>> buildOpenAIToolsFormat() {
    return _tools.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.parameters,
        },
      };
    }).toList();
  }

  /// 执行系统工具
  static Future<Map<String, dynamic>> execute({
    required ChatSession session,
    required String toolName,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    if (kDebugMode) {
      debugPrint('🧰 SystemToolService 执行: $toolName ${jsonEncode(arguments)}');
    }

    switch (toolName) {
      case nodeExecuteTool:
        return NodeToolService.execute(
          arguments: arguments,
          callId: callId,
        );
      default:
        return {
          'id': callId,
          'name': toolName,
          'args': arguments,
          'result': '系统工具 "$toolName" 不存在。',
          'isError': true,
        };
    }
  }
}
