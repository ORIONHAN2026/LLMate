import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_session.dart';
import 'file_tool_service.dart';
import 'mcp_service.dart';
import 'python_tool_service.dart';
import 'skill_storage_service.dart';

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
/// - `python_execute`: 执行 Python 脚本
/// - `file_read`: 读取文本文件
/// - `file_write`: 写入/创建文本文件
class SystemToolService {
  static const String pythonExecuteTool = 'python_execute';
  static const String fileReadTool = 'file_read';
  static const String fileWriteTool = 'file_write';

  static const List<SystemToolDefinition> _tools = [
    SystemToolDefinition(
      name: pythonExecuteTool,
      description:
          '执行 Python 脚本。支持内联代码和 .py 文件两种方式。可选安装 pip 依赖。'
          '适合数据分析、文件批处理、API 调用、爬虫、文档生成等任何场景。返回 stdout/stderr 输出。',
      parameters: {
        'type': 'object',
        'properties': {
          'script': {
            'type': 'string',
            'description':
                'Python 脚本内容（内联代码）。与 filePath 二选一，优先使用 script。',
          },
          'filePath': {
            'type': 'string',
            'description': '要执行的 .py 文件完整路径。与 script 二选一。',
          },
          'args': {
            'type': 'array',
            'description': '传递给脚本的命令行参数列表。',
            'items': {'type': 'string'},
          },
          'requirements': {
            'type': 'array',
            'description':
                '需要安装的 pip 包名列表（如 ["requests", "pandas"]），执行前自动 pip3 install。',
            'items': {'type': 'string'},
          },
        },
      },
    ),
    SystemToolDefinition(
      name: fileReadTool,
      description:
          '读取文本文件内容（代码、Markdown、配置、日志等）。'
          '支持 .dart .py .js .ts .json .yaml .md .txt 等常见文本格式。'
          '返回文件内容、行数、大小等信息。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的文件完整路径。必须是文本文件。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: fileWriteTool,
      description:
          '创建或覆盖写入文本文件。自动创建父目录。'
          '支持 .dart .py .js .ts .json .yaml .md .txt 等常见文本格式。'
          '返回文件路径、行数、是否覆盖等信息。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要写入的文件完整路径。',
          },
          'content': {
            'type': 'string',
            'description': '要写入的文件内容。',
          },
        },
        'required': ['filePath', 'content'],
      },
    ),
  ];

  static List<SystemToolDefinition> get tools => List.unmodifiable(_tools);

  static bool hasTool(String name) => _tools.any((tool) => tool.name == name);

  /// 构建 OpenAI tools 格式，用于向 LLM 声明可用工具
  static List<Map<String, dynamic>> buildOpenAIToolsFormat(
    ChatSession? session,
  ) {
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

  /// 构建系统工具说明文本，注入到 system prompt
  static String buildSystemToolsInfoForPrompt(ChatSession? session) {
    if (_tools.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## 系统内置工具');
    buffer.writeln();
    buffer.writeln(
      '你拥有以下客户端内置工具：',
    );
    buffer.writeln();
    buffer.writeln('- `$pythonExecuteTool`: 执行 Python 脚本（文件读写/数据分析/文档生成/爬虫等）');
    buffer.writeln('- `$fileReadTool`: 直接读取文本文件内容');
    buffer.writeln('- `$fileWriteTool`: 创建或覆盖写入文本文件');
    buffer.writeln();
    buffer.writeln('每个工具使用标准 function calling 格式调用（调用示例见下方）。');
    buffer.writeln();

    // 工作目录提示
    final workDir = session?.workDirectory;
    if (workDir != null && workDir.trim().isNotEmpty) {
      buffer.writeln('## 工作目录');
      buffer.writeln();
      buffer.writeln('当前会话已设置工作目录：`$workDir`');
      buffer.writeln();
      buffer.writeln('规则：');
      buffer.writeln(
        '- 生成文件时，如用户未指定保存路径，默认保存到工作目录。',
      );
      buffer.writeln(
        '- 脚本中涉及文件路径时，相对路径相对于工作目录解析。',
      );
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// 将每个系统内置工具生成独立的 system 消息列表（自然语言描述）
  static List<Map<String, dynamic>> buildSystemToolsInfoAsMessages(
    ChatSession? session,
  ) {
    if (_tools.isEmpty) return [];

    final messages = <Map<String, dynamic>>[];

    // 工具调用通用说明
    final toolNames = _tools.map((t) => '`${t.name}`').join('、');
    messages.add({
      'role': 'system',
      'content':
          '你拥有以下客户端内置工具：$toolNames。\n'
          '调用时请使用标准的 function calling 机制，不要用 Markdown 代码块或 XML 替代。',
    });

    // 每个工具独立一条 system 消息
    for (final tool in _tools) {
      final content = _buildToolNaturalDescription(tool);
      messages.add({'role': 'system', 'content': content});
    }

    // 工作目录提示
    final workDir = session?.workDirectory;
    if (workDir != null && workDir.trim().isNotEmpty) {
      messages.add({
        'role': 'system',
        'content':
            '当前会话工作目录：$workDir。'
            '脚本中涉及文件路径时，相对路径相对于工作目录解析。',
      });
    }

    // 技能目录提示
    messages.add({
      'role': 'system',
      'content':
          '技能文件存放在 ${SkillStorageService.skillsRootDir} 目录下，每个技能是一个文件夹，内含 SKILL.md 文件。\n'
          '你可以使用 python_execute 工具（调用 file_read / file_write 的 Python 脚本）直接读取、创建或修改技能文件。\n'
          '【重要约束】如果你正在调整某个技能（修改 SKILL.md 或为其添加配套脚本），'
          '所有与该技能相关的脚本文件（.py / .sh 等）必须放在该技能的文件夹内，不要放到其他位置。',
    });

    return messages;
  }

  /// 用自然语言构建单个工具的描述
  static String _buildToolNaturalDescription(SystemToolDefinition tool) {
    final buffer = StringBuffer();

    buffer.writeln('工具名称：${tool.name}');
    buffer.writeln();
    buffer.writeln(tool.description);
    buffer.writeln();

    final props = tool.parameters['properties'] as Map<String, dynamic>?;
    final required = tool.parameters['required'] as List<dynamic>? ?? [];

    if (props != null && props.isNotEmpty) {
      buffer.writeln('参数：');
      for (final entry in props.entries) {
        final paramName = entry.key;
        final paramDef = entry.value as Map<String, dynamic>;
        final isRequired = required.contains(paramName);
        final desc = paramDef['description'] as String? ?? '';
        final type = paramDef['type'] as String? ?? '';

        buffer.write('- $paramName');
        if (type.isNotEmpty) buffer.write('（$type）');
        if (isRequired) {
          buffer.write('，必填');
        } else {
          buffer.write('，可选');
        }
        if (desc.isNotEmpty) buffer.write('：$desc');
        buffer.writeln();
      }
    }

    buffer.writeln();
    buffer.writeln('调用示例：');
    buffer.writeln('');
    buffer.writeln('<invoke name="${tool.name}">');
    buffer.writeln('<arguments>');
    buffer.writeln(_exampleArguments(tool.name));
    buffer.writeln('</arguments>');
    buffer.writeln('</invoke>');
    buffer.writeln('</tool_calls>');

    return buffer.toString().trim();
  }

  /// 构建所有工具（系统 + MCP）的 OpenAI tools 格式
  static List<Map<String, dynamic>> buildAllOpenAIToolsFormat(
    ChatSession? session,
  ) {
    return [
      ...buildOpenAIToolsFormat(session),
      if (session != null) ...McpService.buildOpenAIToolsFormat(session),
    ];
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
      case pythonExecuteTool:
        return PythonToolService.execute(
          arguments: arguments,
          callId: callId,
        );
      case fileReadTool:
        return FileToolService.execute(
          action: 'read',
          arguments: arguments,
          callId: callId,
        );
      case fileWriteTool:
        return await FileToolService.execute(
          action: 'write',
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

  static String _exampleArguments(String toolName) {
    switch (toolName) {
      case pythonExecuteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'script': 'import pandas as pd\n\ndf = pd.read_csv("data.csv")\nprint(df.head())',
          'requirements': ['pandas'],
        });
      case fileReadTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/path/to/file.dart',
        });
      case fileWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/path/to/output.md',
          'content': '# Hello World',
        });
      default:
        return '{}';
    }
  }
}
