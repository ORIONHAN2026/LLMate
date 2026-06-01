import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_session.dart';
import 'mcp_service.dart';
import 'word_tool_service.dart';

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
/// MCP 工具来自外部服务，系统工具由客户端自身实现。两类工具最终都走
/// LlmClient 的同一套 tool_call 调度循环。
class SystemToolService {
  static const String createWordDocumentTool = 'word_create_document';
  static const String readWordDocumentTool = 'word_read_document';

  static const List<SystemToolDefinition> _tools = [
    SystemToolDefinition(
      name: createWordDocumentTool,
      description: '创建一个 Word .docx 文档。支持段落富文本（对齐/加粗/列表）、多级标题(1-3)、表格。适合生成会议通知、纪要、公告、方案、报告等结构化文档，返回保存路径。',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': '文档标题，例如"会议通知"。'},
          'fileName': {
            'type': 'string',
            'description': '可选文件名，不需要扩展名也可以；系统会自动保存为 .docx。',
          },
          'paragraphs': {
            'type': 'array',
            'description': '正文段落列表。每项可以是纯字符串或对象 {text,align,bold,listType}。',
            'items': {
              'oneOf': [
                {'type': 'string'},
                {
                  'type': 'object',
                  'properties': {
                    'text': {'type': 'string', 'description': '段落文本。'},
                    'align': {
                      'type': 'string',
                      'enum': ['left', 'center', 'right'],
                      'description': '对齐方式，默认 left。',
                    },
                    'bold': {'type': 'boolean', 'description': '是否加粗，默认 false。'},
                    'listType': {
                      'type': 'string',
                      'enum': ['none', 'bullet', 'number'],
                      'description': '列表类型：none=普通段落，bullet=无序列表，number=有序列表。默认 none。',
                    },
                  },
                  'required': ['text'],
                },
              ],
            },
          },
          'tables': {
            'type': 'array',
            'description': '表格列表。每项包含 headers 和 rows。',
            'items': {
              'type': 'object',
              'properties': {
                'headers': {
                  'type': 'array',
                  'description': '表头列名。',
                  'items': {'type': 'string'},
                },
                'rows': {
                  'type': 'array',
                  'description': '数据行，每行是字符串数组。',
                  'items': {
                    'type': 'array',
                    'items': {'type': 'string'},
                  },
                },
              },
            },
          },
          'sections': {
            'type': 'array',
            'description': '章节列表，每项包含 heading、level(1-3) 和 paragraphs。',
            'items': {
              'type': 'object',
              'properties': {
                'heading': {'type': 'string', 'description': '章节标题。'},
                'level': {
                  'type': 'integer',
                  'description': '标题级别 1-3，默认 1。',
                },
                'paragraphs': {
                  'type': 'array',
                  'description': '章节段落，同顶层 paragraphs 格式。',
                  'items': {
                    'oneOf': [
                      {'type': 'string'},
                      {
                        'type': 'object',
                        'properties': {
                          'text': {'type': 'string', 'description': '段落文本。'},
                          'align': {
                            'type': 'string',
                            'enum': ['left', 'center', 'right'],
                            'description': '对齐方式。',
                          },
                          'bold': {'type': 'boolean', 'description': '是否加粗。'},
                          'listType': {
                            'type': 'string',
                            'enum': ['none', 'bullet', 'number'],
                            'description': '列表类型。',
                          },
                        },
                        'required': ['text'],
                      },
                    ],
                  },
                },
              },
            },
          },
          'outputDirectory': {
            'type': 'string',
            'description': '可选保存目录。为空时保存到应用文档目录下的 GeneratedDocuments。',
          },
        },
        'required': ['title'],
      },
    ),
    SystemToolDefinition(
      name: readWordDocumentTool,
      description: '读取一个 Word .docx 文档的结构信息，返回标题、段落（含对齐/加粗/列表属性）、表格、章节层级等结构化 JSON。适合分析模板格式后据此生成相同样式的文档。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的 .docx 文件的完整路径。',
          },
        },
        'required': ['filePath'],
      },
    ),
  ];

  static List<SystemToolDefinition> get tools => List.unmodifiable(_tools);

  static bool hasTool(String name) => _tools.any((tool) => tool.name == name);

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

  static String buildSystemToolsInfoForPrompt(ChatSession? session) {
    if (_tools.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('## 系统内置工具');
    buffer.writeln();
    buffer.writeln('你可以调用以下客户端内置工具完成文件与文档操作。');
    buffer.writeln('调用方式必须使用 XML 工具调用格式，不要用 Markdown 代码块替代工具调用。');
    buffer.writeln();

    for (final tool in _tools) {
      buffer.writeln('### ${tool.name}');
      buffer.writeln(tool.description);
      buffer.writeln();
      buffer.writeln('参数 Schema:');
      buffer.writeln('```json');
      buffer.writeln(
        const JsonEncoder.withIndent('  ').convert(tool.parameters),
      );
      buffer.writeln('```');
      buffer.writeln();
      buffer.writeln('调用示例:');
      buffer.writeln('```xml');
      buffer.writeln('<tool_calls>');
      buffer.writeln('<invoke name="${tool.name}">');
      buffer.writeln('<arguments>');
      buffer.writeln(_exampleArguments(tool.name));
      buffer.writeln('</arguments>');
      buffer.writeln('</invoke>');
      buffer.writeln('</tool_calls>');
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

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
      case createWordDocumentTool:
        return WordToolService.createDocument(
          arguments: arguments,
          callId: callId,
        );
      case readWordDocumentTool:
        return WordToolService.readDocument(
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

  static List<Map<String, dynamic>> buildAllOpenAIToolsFormat(
    ChatSession? session,
  ) {
    return [
      ...buildOpenAIToolsFormat(session),
      if (session != null) ...McpService.buildOpenAIToolsFormat(session),
    ];
  }

  static String _exampleArguments(String toolName) {
    switch (toolName) {
      case createWordDocumentTool:
        return const JsonEncoder.withIndent('  ').convert({
          'title': '项目周例会通知',
          'fileName': '项目周例会通知',
          'paragraphs': [
            {'text': '各位同事：', 'bold': true},
            '请准时参加本周项目例会，会议议程如下。',
          ],
          'tables': [
            {
              'headers': ['时间', '内容', '负责人'],
              'rows': [
                ['10:00-10:15', '上周进展汇报', '张三'],
                ['10:15-10:30', '本周计划讨论', '李四'],
              ],
            },
          ],
          'sections': [
            {
              'heading': '会议信息',
              'level': 1,
              'paragraphs': [
                {'text': '时间：周五上午 10:00', 'listType': 'bullet'},
                {'text': '地点：第一会议室', 'listType': 'bullet'},
              ],
            },
            {
              'heading': '注意事项',
              'level': 2,
              'paragraphs': [
                {'text': '请提前准备汇报材料', 'listType': 'number'},
                {'text': '如有议题请提前提交', 'listType': 'number'},
              ],
            },
          ],
        });
      case readWordDocumentTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/Users/example/Documents/模板.docx',
        });
      default:
        return '{}';
    }
  }
}
