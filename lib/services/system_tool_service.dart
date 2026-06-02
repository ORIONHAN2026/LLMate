import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/chat/chat_session.dart';
import 'email_tool_service.dart';
import 'excel_tool_service.dart';
import 'file_tool_service.dart';
import 'image_tool_service.dart';
import 'mcp_service.dart';
import 'pdf_tool_service.dart';
import 'ppt_tool_service.dart';
import 'skill_storage_service.dart';
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
  static const String fileReadTool = 'file_read';
  static const String fileWriteTool = 'file_write';
  static const String excelReadTool = 'excel_read';
  static const String excelWriteTool = 'excel_write';
  static const String pdfReadTool = 'pdf_read';
  static const String pdfWriteTool = 'pdf_write';
  static const String imageReadTool = 'image_read';
  static const String imageWriteTool = 'image_write';
  static const String pptReadTool = 'ppt_read';
  static const String pptWriteTool = 'ppt_write';
  static const String emailReadTool = 'email_read';
  static const String emailWriteTool = 'email_write';

  static const List<SystemToolDefinition> _tools = [
    SystemToolDefinition(
      name: createWordDocumentTool,
      description:
          '创建一个 Word .docx 文档。支持段落富文本（对齐/加粗/列表）、多级标题(1-3)、表格。适合生成会议通知、纪要、公告、方案、报告等结构化文档，返回保存路径。',
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
                    'bold': {
                      'type': 'boolean',
                      'description': '是否加粗，默认 false。',
                    },
                    'listType': {
                      'type': 'string',
                      'enum': ['none', 'bullet', 'number'],
                      'description':
                          '列表类型：none=普通段落，bullet=无序列表，number=有序列表。默认 none。',
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
                'level': {'type': 'integer', 'description': '标题级别 1-3，默认 1。'},
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
      description:
          '读取一个 Word .docx 文档的结构信息，返回标题、段落（含对齐/加粗/列表属性）、表格、章节层级等结构化 JSON。适合分析模板格式后据此生成相同样式的文档。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '要读取的 .docx 文件的完整路径。'},
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: fileReadTool,
      description:
          '读取文本文件内容。支持代码文件(.dart/.py/.js/.ts/.java/.kt/.swift/.go/.rs/.c/.cpp/.html/.css/.sql等)、Markdown文件(.md)、配置文件(.json/.yaml/.toml/.xml等)、纯文本(.txt/.log/.csv等)。返回文件内容、行数、大小等信息。也可用于读取技能文件（skills/目录下的SKILL.md）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '要读取的文件完整路径。'},
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: fileWriteTool,
      description:
          '写入或创建文本文件。支持代码文件、Markdown文件、配置文件、纯文本等。如果文件已存在则覆盖，如果父目录不存在则自动创建。适合生成代码、Markdown文档、配置文件等。也可用于创建或更新技能文件（在skills/目录下创建文件夹并写入SKILL.md）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要写入的文件完整路径，包含文件名和扩展名。',
          },
          'content': {'type': 'string', 'description': '要写入的文件内容。'},
        },
        'required': ['filePath', 'content'],
      },
    ),
    SystemToolDefinition(
      name: excelReadTool,
      description:
          '读取 Excel .xlsx 文件内容。返回所有 Sheet 的名称、行数、列数以及每行每列的数据。适合分析表格数据、提取信息。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '要读取的 .xlsx 文件的完整路径。'},
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: excelWriteTool,
      description:
          '创建 Excel .xlsx 文件。支持多 Sheet、表头（自动加粗）、数据行。数字类型自动识别为数值单元格。适合生成数据报表、统计表格、清单等。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要写入的文件完整路径，包含文件名和 .xlsx 扩展名。',
          },
          'sheets': {
            'type': 'array',
            'description': 'Sheet 列表，每项包含 name、headers、rows。',
            'items': {
              'type': 'object',
              'properties': {
                'name': {
                  'type': 'string',
                  'description': 'Sheet 名称，默认 Sheet1。',
                },
                'headers': {
                  'type': 'array',
                  'description': '表头行，字符串数组。表头自动加粗。',
                  'items': {'type': 'string'},
                },
                'rows': {
                  'type': 'array',
                  'description': '数据行，每行是数组（支持字符串和数字）。',
                  'items': {'type': 'array', 'items': {}},
                },
              },
            },
          },
        },
        'required': ['filePath', 'sheets'],
      },
    ),
    // ── PDF 工具 ──────────────────────────────────────────────
    SystemToolDefinition(
      name: pdfReadTool,
      description: '读取 PDF 文件。提取每页文本内容、页数、元数据（标题/作者/主题/关键词）。适合分析 PDF 文档内容。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '要读取的 .pdf 文件完整路径。'},
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: pdfWriteTool,
      description:
          'PDF 写入工具。支持三种操作：create=创建新PDF（标题+章节+段落+表格），merge=合并多个PDF，watermark=添加文字水印。通过 action 参数选择操作。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '输出 .pdf 文件完整路径。'},
          'action': {
            'type': 'string',
            'enum': ['create', 'merge', 'watermark'],
            'description':
                '操作类型：create=创建PDF，merge=合并PDF，watermark=添加水印。默认 create。',
          },
          'title': {'type': 'string', 'description': '文档标题（create 时使用）。'},
          'author': {'type': 'string', 'description': '文档作者（create 时使用）。'},
          'sections': {
            'type': 'array',
            'description':
                '章节列表（create 时使用），每项含 heading、level、paragraphs、tables。',
            'items': {
              'type': 'object',
              'properties': {
                'heading': {'type': 'string', 'description': '章节标题。'},
                'level': {'type': 'integer', 'description': '标题级别 1-3，默认 1。'},
                'paragraphs': {
                  'type': 'array',
                  'description': '段落列表，同 word_create_document。',
                  'items': {},
                },
                'tables': {
                  'type': 'array',
                  'description': '表格列表。',
                  'items': {},
                },
              },
            },
          },
          'files': {
            'type': 'array',
            'description': '要合并的 PDF 文件路径列表（merge 时使用）。',
            'items': {'type': 'string'},
          },
          'sourcePath': {
            'type': 'string',
            'description': '源 PDF 路径（watermark 时使用）。',
          },
          'watermarkText': {
            'type': 'string',
            'description': '水印文字（watermark 时使用）。',
          },
        },
        'required': ['filePath'],
      },
    ),
    // ── 图片工具 ──────────────────────────────────────────────
    SystemToolDefinition(
      name: imageReadTool,
      description: '读取图片信息。返回尺寸（宽/高）、格式、文件大小、通道数、是否有透明通道。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '图片文件完整路径。支持 png/jpg/jpeg/gif/webp/bmp/tiff。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: imageWriteTool,
      description:
          '图片处理工具。支持六种操作：resize=缩放，crop=裁剪，rotate=旋转，convert=格式转换，compress=压缩，watermark=添加文字水印。通过 action 参数选择操作。',
      parameters: {
        'type': 'object',
        'properties': {
          'sourcePath': {'type': 'string', 'description': '源图片路径。'},
          'filePath': {
            'type': 'string',
            'description': '输出图片路径（含扩展名，扩展名决定输出格式）。',
          },
          'action': {
            'type': 'string',
            'enum': [
              'resize',
              'crop',
              'rotate',
              'convert',
              'compress',
              'watermark',
            ],
            'description': '操作类型，默认 resize。',
          },
          'width': {'type': 'integer', 'description': '目标宽度（resize 时使用）。'},
          'height': {'type': 'integer', 'description': '目标高度（resize 时使用）。'},
          'maintainAspectRatio': {
            'type': 'boolean',
            'description': '是否保持宽高比（resize 时），默认 true。',
          },
          'x': {'type': 'integer', 'description': '裁剪起始 X 坐标（crop 时使用）。'},
          'y': {'type': 'integer', 'description': '裁剪起始 Y 坐标（crop 时使用）。'},
          'cropWidth': {'type': 'integer', 'description': '裁剪宽度（crop 时使用）。'},
          'cropHeight': {'type': 'integer', 'description': '裁剪高度（crop 时使用）。'},
          'angle': {
            'type': 'integer',
            'description': '旋转角度，90的倍数（rotate 时使用），默认 90。',
          },
          'quality': {
            'type': 'integer',
            'description': '压缩质量 0-100（compress/convert 时使用），默认 85。',
          },
          'watermarkText': {
            'type': 'string',
            'description': '水印文字（watermark 时使用）。',
          },
          'fontSize': {
            'type': 'integer',
            'description': '水印字号（watermark 时使用），默认 24。',
          },
        },
        'required': ['sourcePath', 'filePath'],
      },
    ),
    // ── PPT 工具 ──────────────────────────────────────────────
    SystemToolDefinition(
      name: pptReadTool,
      description: '读取 PPT .pptx 文件。提取每页幻灯片的文本内容、幻灯片数量。适合分析演示文稿结构。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '要读取的 .pptx 文件完整路径。'},
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: pptWriteTool,
      description: '创建 PPT .pptx 演示文稿。支持多页幻灯片，每页可设置标题和内容（支持项目列表）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {'type': 'string', 'description': '输出 .pptx 文件完整路径。'},
          'title': {'type': 'string', 'description': '演示文稿标题。'},
          'slides': {
            'type': 'array',
            'description': '幻灯片列表，每项含 title、content 或 items。',
            'items': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': '幻灯片标题。'},
                'content': {
                  'type': 'string',
                  'description': '幻灯片正文内容，支持换行。以 "- " 或 "• " 开头的行自动变为项目列表。',
                },
                'items': {
                  'type': 'array',
                  'description': '项目列表，字符串数组。',
                  'items': {'type': 'string'},
                },
              },
            },
          },
        },
        'required': ['filePath', 'slides'],
      },
    ),
    // ── 邮件工具 ──────────────────────────────────────────────
    SystemToolDefinition(
      name: emailReadTool,
      description:
          '读取邮件。通过 IMAP 协议连接邮箱，支持三种操作：list=列出最近邮件，fetch=读取指定邮件完整内容，search=按主题搜索邮件。需要提供邮箱账号和IMAP服务器信息。',
      parameters: {
        'type': 'object',
        'properties': {
          'host': {
            'type': 'string',
            'description': 'IMAP 服务器地址，如 imap.qq.com。',
          },
          'port': {'type': 'integer', 'description': 'IMAP 端口，默认 993。'},
          'username': {'type': 'string', 'description': '邮箱账号。'},
          'password': {'type': 'string', 'description': '邮箱密码或授权码。'},
          'useSSL': {'type': 'boolean', 'description': '是否使用 SSL，默认 true。'},
          'action': {
            'type': 'string',
            'enum': ['list', 'fetch', 'search'],
            'description': '操作类型：list=列出邮件，fetch=读取邮件，search=搜索邮件。默认 list。',
          },
          'folder': {'type': 'string', 'description': '邮箱文件夹，默认 INBOX。'},
          'limit': {'type': 'integer', 'description': '返回邮件数量上限，默认 10。'},
          'emailId': {'type': 'string', 'description': '邮件 ID（fetch 时必填）。'},
          'query': {'type': 'string', 'description': '搜索关键词（search 时必填）。'},
        },
        'required': ['host', 'username', 'password'],
      },
    ),
    SystemToolDefinition(
      name: emailWriteTool,
      description:
          '发送邮件。通过 SMTP 协议发送，支持纯文本/HTML正文、抄送、密送、附件。需要提供邮箱账号和SMTP服务器信息。',
      parameters: {
        'type': 'object',
        'properties': {
          'host': {
            'type': 'string',
            'description': 'SMTP 服务器地址，如 smtp.qq.com。',
          },
          'port': {'type': 'integer', 'description': 'SMTP 端口，默认 465。'},
          'username': {'type': 'string', 'description': '发件邮箱账号。'},
          'password': {'type': 'string', 'description': '邮箱密码或授权码。'},
          'useSSL': {'type': 'boolean', 'description': '是否使用 SSL，默认 true。'},
          'to': {'type': 'string', 'description': '收件人邮箱（多人用数组）。'},
          'cc': {'type': 'string', 'description': '抄送邮箱。'},
          'bcc': {'type': 'string', 'description': '密送邮箱。'},
          'subject': {'type': 'string', 'description': '邮件主题。'},
          'body': {'type': 'string', 'description': '纯文本正文。'},
          'htmlBody': {'type': 'string', 'description': 'HTML 正文（与 body 二选一）。'},
          'attachments': {
            'type': 'array',
            'description': '附件文件路径列表。',
            'items': {'type': 'string'},
          },
        },
        'required': ['host', 'username', 'password', 'to', 'subject'],
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

    // 工作目录提示
    final workDir = session?.workDirectory;
    if (workDir != null && workDir.trim().isNotEmpty) {
      buffer.writeln('## 工作目录');
      buffer.writeln();
      buffer.writeln('当前会话已设置工作目录：`$workDir`');
      buffer.writeln();
      buffer.writeln('规则：');
      buffer.writeln('- 生成文件时，如用户未指定保存路径，默认保存到工作目录。');
      buffer.writeln(
        '- 使用 `word_create_document` 时不需指定 `outputDirectory`，系统会自动使用工作目录。',
      );
      buffer.writeln(
        '- 使用 `file_write`、`excel_write`、`pdf_write`、`ppt_write`、`image_write` 时若 `filePath` 为相对路径或仅文件名，系统会自动拼接工作目录。',
      );
      buffer.writeln();
    }

    // 技能目录提示
    buffer.writeln('## 技能目录');
    buffer.writeln();
    buffer.writeln('技能文件存放在 `${SkillStorageService.skillsRootDir}` 目录下，每个技能是一个文件夹，内含 SKILL.md 文件。');
    buffer.writeln('你可以使用 `file_read` 和 `file_write` 工具直接读取、创建或修改技能文件。');
    buffer.writeln('创建技能时，先在技能目录下创建子文件夹，再写入 SKILL.md 文件，文件格式为：');
    buffer.writeln('```markdown');
    buffer.writeln('---');
    buffer.writeln('name: 技能名称');
    buffer.writeln('description: 技能描述');
    buffer.writeln('agent_created: true');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('技能正文内容...');
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString().trim();
  }

  /// 将每个系统内置工具生成独立的 system 消息列表
  /// 使用自然语言描述，去除冗余的 JSON Schema 和代码块标记
  static List<Map<String, dynamic>> buildSystemToolsInfoAsMessages(
    ChatSession? session,
  ) {
    if (_tools.isEmpty) return [];

    final messages = <Map<String, dynamic>>[];

    // 工具调用通用说明（单独一条）
    messages.add({
      'role': 'system',
      'content':
          '你拥有以下客户端内置工具，可以直接调用来完成文件与文档操作。'
          '调用时必须使用 XML 格式，不要用 Markdown 代码块替代。'
          '格式如下：\n'
          '<tool_calls>\n'
          '<invoke name="工具名">\n'
          '<arguments>\n'
          'JSON 参数\n'
          '</arguments>\n'
          '</invoke>\n'
          '</tool_calls>',
    });

    // 每个工具独立一条 system 消息，使用自然语言描述
    for (final tool in _tools) {
      final content = _buildToolNaturalDescription(tool);
      messages.add({'role': 'system', 'content': content});
    }

    // 工作目录提示（独立一条）
    final workDir = session?.workDirectory;
    if (workDir != null && workDir.trim().isNotEmpty) {
      messages.add({
        'role': 'system',
        'content':
            '当前会话工作目录：$workDir。'
            '生成文件时如用户未指定路径，默认保存到该目录。',
      });
    }

    // 技能目录提示（独立一条）
    messages.add({
      'role': 'system',
      'content':
          '技能文件存放在 ${SkillStorageService.skillsRootDir} 目录下，每个技能是一个文件夹，内含 SKILL.md 文件。'
          '你可以使用 file_read 和 file_write 工具直接读取、创建或修改技能文件。'
          '创建技能时，先在技能目录下创建子文件夹，再写入 SKILL.md 文件，格式为：YAML front matter（name/description/agent_created）+ Markdown 正文。',
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

    // 参数说明
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
        final enumValues = paramDef['enum'] as List<dynamic>?;

        buffer.write('- $paramName');
        if (type.isNotEmpty) buffer.write('（$type');
        if (enumValues != null) buffer.write('，可选值：${enumValues.join('/')}');
        if (type.isNotEmpty) buffer.write('）');
        if (isRequired)
          buffer.write('，必填');
        else
          buffer.write('，可选');
        if (desc.isNotEmpty) buffer.write('：$desc');
        buffer.writeln();
      }
    }

    // 调用示例
    buffer.writeln();
    buffer.writeln('调用示例：');
    buffer.writeln('<tool_calls>');
    buffer.writeln('<invoke name="${tool.name}">');
    buffer.writeln('<arguments>');
    buffer.writeln(_exampleArguments(tool.name));
    buffer.writeln('</arguments>');
    buffer.writeln('</invoke>');
    buffer.writeln('</tool_calls>');

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

    // 注入会话工作目录到工具参数（当工具需要 outputDirectory 但未指定时）
    final enrichedArgs = _injectWorkDirectory(session, toolName, arguments);

    switch (toolName) {
      case createWordDocumentTool:
        return WordToolService.createDocument(
          arguments: enrichedArgs,
          callId: callId,
        );
      case readWordDocumentTool:
        return WordToolService.readDocument(
          arguments: enrichedArgs,
          callId: callId,
        );
      case fileReadTool:
        return FileToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case fileWriteTool:
        return FileToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      case excelReadTool:
        return ExcelToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case excelWriteTool:
        return ExcelToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      case pdfReadTool:
        return PdfToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case pdfWriteTool:
        return PdfToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      case imageReadTool:
        return ImageToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case imageWriteTool:
        return ImageToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      case pptReadTool:
        return PptToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case pptWriteTool:
        return PptToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      case emailReadTool:
        return EmailToolService.execute(
          action: 'read',
          arguments: enrichedArgs,
          callId: callId,
        );
      case emailWriteTool:
        return EmailToolService.execute(
          action: 'write',
          arguments: enrichedArgs,
          callId: callId,
        );
      default:
        return {
          'id': callId,
          'name': toolName,
          'args': enrichedArgs,
          'result': '系统工具 "$toolName" 不存在。',
          'isError': true,
        };
    }
  }

  /// 当会话设置了工作目录且工具未指定输出目录时，自动注入
  static Map<String, dynamic> _injectWorkDirectory(
    ChatSession session,
    String toolName,
    Map<String, dynamic> arguments,
  ) {
    final workDir = session.workDirectory;
    if (workDir == null || workDir.trim().isEmpty) return arguments;

    // word_create_document: 注入 outputDirectory
    if (toolName == createWordDocumentTool) {
      final current = (arguments['outputDirectory'] ?? '').toString().trim();
      if (current.isEmpty) {
        return {...arguments, 'outputDirectory': workDir};
      }
    }

    // file_write: 当 filePath 为相对路径或仅文件名时，拼接工作目录
    if (toolName == fileWriteTool) {
      final current = (arguments['filePath'] ?? '').toString().trim();
      if (current.isNotEmpty && !p.isAbsolute(current)) {
        return {...arguments, 'filePath': p.join(workDir, current)};
      }
    }

    // excel_write / pdf_write / ppt_write / image_write: 当 filePath 为相对路径时，拼接工作目录
    if (toolName == excelWriteTool ||
        toolName == pdfWriteTool ||
        toolName == pptWriteTool ||
        toolName == imageWriteTool) {
      final current = (arguments['filePath'] ?? '').toString().trim();
      if (current.isNotEmpty && !p.isAbsolute(current)) {
        return {...arguments, 'filePath': p.join(workDir, current)};
      }
    }

    return arguments;
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
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/Documents/模板.docx'});
      case fileReadTool:
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/project/README.md'});
      case fileWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/Users/example/project/notes.md',
          'content': '# 笔记\n\n这是一段示例内容。',
        });
      case excelReadTool:
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/Documents/数据报表.xlsx'});
      case excelWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/Users/example/Documents/成绩单.xlsx',
          'sheets': [
            {
              'name': '成绩表',
              'headers': ['姓名', '语文', '数学', '英语'],
              'rows': [
                ['张三', 92, 88, 95],
                ['李四', 85, 96, 78],
              ],
            },
          ],
        });
      case pdfReadTool:
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/Documents/报告.pdf'});
      case pdfWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/Users/example/Documents/报告.pdf',
          'action': 'create',
          'title': '项目报告',
          'sections': [
            {
              'heading': '项目概述',
              'level': 1,
              'paragraphs': ['本项目旨在提升系统性能。'],
            },
          ],
        });
      case imageReadTool:
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/Documents/photo.jpg'});
      case imageWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'sourcePath': '/Users/example/Documents/photo.jpg',
          'filePath': '/Users/example/Documents/photo_resized.jpg',
          'action': 'resize',
          'width': 800,
          'height': 600,
        });
      case pptReadTool:
        return const JsonEncoder.withIndent(
          '  ',
        ).convert({'filePath': '/Users/example/Documents/演示文稿.pptx'});
      case pptWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'filePath': '/Users/example/Documents/演示文稿.pptx',
          'slides': [
            {
              'title': '项目概述',
              'items': ['背景介绍', '项目目标', '团队构成'],
            },
            {'title': '技术方案', 'content': '- 前端架构\n- 后端服务\n- 数据库设计'},
          ],
        });
      case emailReadTool:
        return const JsonEncoder.withIndent('  ').convert({
          'host': 'imap.qq.com',
          'username': 'user@qq.com',
          'password': '授权码',
          'action': 'list',
          'limit': 5,
        });
      case emailWriteTool:
        return const JsonEncoder.withIndent('  ').convert({
          'host': 'smtp.qq.com',
          'username': 'user@qq.com',
          'password': '授权码',
          'to': 'recipient@example.com',
          'subject': '会议通知',
          'body': '请于周五下午参加项目评审会议。',
        });
      default:
        return '{}';
    }
  }
}
