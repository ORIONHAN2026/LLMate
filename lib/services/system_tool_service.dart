import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/chat/chat_session.dart';
import 'excel_tool_service.dart';
import 'file_tool_service.dart';
import 'pdf_tool_service.dart';
import 'ppt_tool_service.dart';
import 'python_tool_service.dart';
import 'url_fetch_tool_service.dart';
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
/// 提供以下内置工具：
/// - `python_execute`: 执行 Python 脚本
/// - `file_read`: 读取文本文件
/// - `file_write`: 写入/创建文本文件
class SystemToolService {
  // ── 基础工具 ──
  static const String pythonExecuteTool = 'python_execute';
  static const String fileReadTool = 'file_read';
  static const String fileWriteTool = 'file_write';

  // ── 文档工具 ──
  static const String wordCreateTool = 'word_create';
  static const String wordReadTool = 'word_read';
  static const String excelWriteTool = 'excel_write';
  static const String excelReadTool = 'excel_read';
  static const String pdfWriteTool = 'pdf_write';
  static const String pdfReadTool = 'pdf_read';
  static const String pptWriteTool = 'ppt_write';
  static const String pptReadTool = 'ppt_read';

  // ── 网络工具 ──
  static const String urlFetchTool = 'url_fetch';

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

    // ── Word 文档 ──
    SystemToolDefinition(
      name: wordCreateTool,
      description:
          '创建 .docx Word 文档。支持标题、章节（heading + paragraphs）、'
          '表格（headers + rows）、项目符号/编号列表、文字对齐与加粗。'
          '如果不指定 fileName，自动根据 title 生成。返回生成文件路径。',
      parameters: {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': '文档标题（可选，自动回退）。'},
          'fileName': {
            'type': 'string',
            'description': '文件名（如 report.docx），可选。',
          },
          'outputDirectory': {
            'type': 'string',
            'description': '输出目录完整路径，默认 GeneratedDocuments。',
          },
          'paragraphs': {
            'type': 'array',
            'description': '顶层段落列表。每个元素可以是纯字符串或 {text, align, bold, listType} 对象。',
          },
          'sections': {
            'type': 'array',
            'description': '章节列表。每个元素为 {heading, level(1-3), paragraphs} 对象。',
          },
          'tables': {
            'type': 'array',
            'description': '表格列表。每个元素为 {headers:[], rows:[[]]} 对象。',
          },
        },
      },
    ),
    SystemToolDefinition(
      name: wordReadTool,
      description:
          '读取 .docx Word 文档内容，返回结构化 JSON（段落、表格、章节、元数据）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的 .docx 文件完整路径。',
          },
        },
        'required': ['filePath'],
      },
    ),

    // ── Excel 表格 ──
    SystemToolDefinition(
      name: excelWriteTool,
      description:
          '创建 .xlsx Excel 文件。支持多 Sheet、表头、数据行、'
          '自动识别数字/文本/布尔值类型。返回文件路径。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': 'Excel 文件完整路径（如 /path/to/data.xlsx）。',
          },
          'sheets': {
            'type': 'array',
            'description': 'Sheet 列表，每个元素为 {name, headers:[], rows:[[]]}。',
          },
        },
        'required': ['filePath', 'sheets'],
      },
    ),
    SystemToolDefinition(
      name: excelReadTool,
      description:
          '读取 .xlsx Excel 文件，返回所有 Sheet 的名称、行数据、行列数。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的 .xlsx 文件完整路径。',
          },
        },
        'required': ['filePath'],
      },
    ),

    // ── PDF 文档 ──
    SystemToolDefinition(
      name: pdfWriteTool,
      description:
          '创建或处理 PDF 文件。'
          '支持两种模式：create（新建带标题、章节、段落的 PDF）'
          '和 watermark（给已有 PDF 添加文字水印）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '输出 PDF 完整路径。',
          },
          'action': {
            'type': 'string',
            'description': '操作类型：create 或 watermark，默认 create。',
          },
          'title': {'type': 'string', 'description': 'PDF 标题（create 模式）。'},
          'author': {'type': 'string', 'description': '作者（create 模式）。'},
          'sections': {
            'type': 'array',
            'description': '章节列表 [{heading, level, paragraphs:[{text, bold, align}]}]。',
          },
          'sourcePath': {
            'type': 'string',
            'description': '源 PDF 文件路径（watermark 模式必填）。',
          },
          'watermarkText': {
            'type': 'string',
            'description': '水印文字（watermark 模式必填）。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: pdfReadTool,
      description:
          '读取 PDF 文件，提取每页文本内容、页数、元数据（标题/作者/主题）。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的 PDF 文件完整路径。',
          },
        },
        'required': ['filePath'],
      },
    ),

    // ── PPT 演示文稿 ──
    SystemToolDefinition(
      name: pptWriteTool,
      description:
          '创建 .pptx 演示文稿。支持多页幻灯片，每页含标题、正文内容、项目列表（items）。'
          '自动应用 Office 主题样式。返回文件路径。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': 'PPT 文件完整路径（如 /path/to/presentation.pptx）。',
          },
          'slides': {
            'type': 'array',
            'description': '幻灯片列表。每页为 {title, content, items:[]}。items 为项目符号列表。',
          },
        },
        'required': ['filePath', 'slides'],
      },
    ),
    SystemToolDefinition(
      name: pptReadTool,
      description:
          '读取 .pptx 演示文稿，提取每页幻灯片的文本元素和内容。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的 .pptx 文件完整路径。',
          },
        },
        'required': ['filePath'],
      },
    ),

    // ── 网络工具 ──
    SystemToolDefinition(
      name: urlFetchTool,
      description:
          '抓取指定 URL 的网页内容并提取纯文本。支持 HTTP/HTTPS。'
          '自动识别 HTML 页面（提取文本）、JSON 接口（格式化输出）、纯文本等。'
          '最大内容 5MB，文本截断至 20000 字符。适用于阅读文档、获取 API 数据等场景。',
      parameters: {
        'type': 'object',
        'properties': {
          'url': {
            'type': 'string',
            'description': '要抓取的完整 URL（必须包含 http:// 或 https://）。',
          },
        },
        'required': ['url'],
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
      case wordCreateTool:
        return await WordToolService.createDocument(
          arguments: arguments,
          callId: callId,
        );
      case wordReadTool:
        return await WordToolService.readDocument(
          arguments: arguments,
          callId: callId,
        );
      case excelWriteTool:
        return await ExcelToolService.execute(
          action: 'write',
          arguments: arguments,
          callId: callId,
        );
      case excelReadTool:
        return ExcelToolService.execute(
          action: 'read',
          arguments: arguments,
          callId: callId,
        );
      case pdfWriteTool:
        return await PdfToolService.execute(
          action: 'write',
          arguments: arguments,
          callId: callId,
        );
      case pdfReadTool:
        return PdfToolService.execute(
          action: 'read',
          arguments: arguments,
          callId: callId,
        );
      case pptWriteTool:
        return await PptToolService.execute(
          action: 'write',
          arguments: arguments,
          callId: callId,
        );
      case pptReadTool:
        return PptToolService.execute(
          action: 'read',
          arguments: arguments,
          callId: callId,
        );
      case urlFetchTool:
        return UrlFetchToolService.execute(
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
