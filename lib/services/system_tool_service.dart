import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../controllers/session_controller.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/contract_info.dart';
import '../storage/storage_paths.dart';
import 'node_tool_service.dart';
import 'ocr_tool_service.dart';
import 'python_tool_service.dart';
import 'file_tool_service.dart';

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
/// - `python_execute`: 执行 Python 脚本
/// - `ocr_extract`: 对图片执行 OCR 文字识别
class SystemToolService {
  static const String nodeExecuteTool = 'node_execute';
  static const String pythonExecuteTool = 'python_execute';
  static const String ocrExtractTool = 'ocr_extract';
  static const String contractInspectTool = 'contract_inspect';
  static const String fileReadTool = 'file_read';
  static const String fileWriteTool = 'file_write';
  static const String contractContentUpdateTool = 'contract_content_update';
  static const String contractProcessUpdateTool = 'contract_process_update';
  static const String contractDisgussUpdateTool = 'contract_disguss_update';
  static const String wordModifyTool = 'word_modify';

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
    SystemToolDefinition(
      name: pythonExecuteTool,
      description:
          '执行 Python 脚本。支持内联代码和 .py 文件两种方式。可选 pip install 安装依赖。'
          '适合数据分析、文件处理、API 调用、爬虫、图像处理、自动化脚本等任何场景。返回 stdout/stderr 输出。',
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
                '需要安装的 pip 包名列表（如 ["requests", "beautifulsoup4"]），执行前自动 pip install。',
            'items': {'type': 'string'},
          },
        },
      },
    ),
    SystemToolDefinition(
      name: ocrExtractTool,
      description:
          '对图片执行 OCR 文字识别，提取图片中的文字内容。使用 RapidOCR（基于 ONNXRuntime），'
          '纯 pip 安装无需额外系统依赖，速度比 Tesseract 更快。自动安装 rapidocr_onnxruntime。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要识别的图片文件完整路径（支持 PNG/JPEG/BMP/TIFF 等格式）。',
          },
          'lang': {
            'type': 'string',
            'description':
                'OCR 语言代码。默认 "ch"（中文，自动包含英文）。'
                '常用值: "ch"（中英混合）、"en"（英文）、"ja"（日语）、"ko"（韩语）。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: contractInspectTool,
      description:
          '将合同解析结果写入当前会话的合同列表。'
          '支持三种操作：add（新增一份合同）、update（更新已有合同的字段）、addParty（向已有合同添加签署方）。'
          '每次调用只能操作一份合同。合同信息会在右侧边栏"合约要点"Tab中展示。',
      parameters: {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'description': '操作类型：add（新增合同）、update（更新已有合同）、addParty（添加签署方）',
            'enum': ['add', 'update', 'addParty'],
          },
          'contractName': {
            'type': 'string',
            'description': '合同名称（add 操作必填，update 操作用来定位目标合同）',
          },
          'contractType': {
            'type': 'string',
            'description': '合同类型，如：采购合同、服务合同、租赁合同等',
          },
          'startDate': {
            'type': 'string',
            'description': '合同起始日期，格式如 2024-01-01',
          },
          'endDate': {
            'type': 'string',
            'description': '合同结束日期，格式如 2025-12-31',
          },
          'signingDate': {
            'type': 'string',
            'description': '合同签订日期',
          },
          'paymentClause': {
            'type': 'string',
            'description': '收支条款详细内容',
          },
          'paymentSchedule': {
            'type': 'string',
            'description': '收支计划/付款计划详细内容',
          },
          'breachClause': {
            'type': 'string',
            'description': '违约条款详细内容',
          },
          'liabilityClause': {
            'type': 'string',
            'description': '违约责任详细内容',
          },
          'partyRole': {
            'type': 'string',
            'description': '签署方角色，如：甲方、乙方',
          },
          'partyName': {
            'type': 'string',
            'description': '签署方名称/公司名',
          },
          'partyContact': {
            'type': 'string',
            'description': '签署方联系方式',
          },
          'partyAddress': {
            'type': 'string',
            'description': '签署方地址',
          },
        },
        'required': ['action', 'contractName'],
      },
    ),
    SystemToolDefinition(
      name: fileReadTool,
      description:
          '读取文本文件内容（代码、Markdown、配置等）。支持常见编程语言和配置文件格式。'
          '返回文件内容、行数、大小等信息。仅限读取工作目录下的文件。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要读取的文件完整路径。必须是工作目录下的文件。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: fileWriteTool,
      description:
          '写入/创建文本文件。支持常见编程语言和配置文件格式。'
          '会保留文件原有格式（包括字体、缩进等）。仅限操作工作目录下的文件。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要写入的文件完整路径。必须是工作目录下的文件。',
          },
          'content': {
            'type': 'string',
            'description': '要写入的文件内容。保留原始格式，不要添加额外的格式化。',
          },
        },
        'required': ['filePath', 'content'],
      },
    ),
    SystemToolDefinition(
      name: contractContentUpdateTool,
      description:
          '更新合同要点文件（contract_content.md）。直接写入完整的合同要点内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的合同要点完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: contractProcessUpdateTool,
      description:
          '更新合同履约跟踪文件（contract_process.md）。直接写入完整的履约跟踪内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的合同履约跟踪完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: contractDisgussUpdateTool,
      description:
          '更新合同争议记录文件（contract_disguss.md）。直接写入完整的争议记录内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的合同争议记录完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: wordModifyTool,
      description:
          '修改 Word 文档（.docx）。使用 Python 脚本修改文档内容，保留原有格式（字体、样式、表格等）。'
          '支持替换文本、修改段落、更新表格等操作。文件路径必须是工作目录下的文件。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要修改的 Word 文档完整路径（.docx 格式）。',
          },
          'script': {
            'type': 'string',
            'description': 'Python 脚本内容，用于修改文档。脚本中使用 docx 库操作文档。',
          },
        },
        'required': ['filePath', 'script'],
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
      case pythonExecuteTool:
        return PythonToolService.execute(
          arguments: arguments,
          callId: callId,
        );
      case ocrExtractTool:
        return OcrToolService.execute(
          arguments: arguments,
          callId: callId,
        );
      case contractInspectTool:
        return _executeContractInspect(
          session: session,
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
        return FileToolService.execute(
          action: 'write',
          arguments: arguments,
          callId: callId,
        );
      case contractContentUpdateTool:
        return _executeContractContentUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case contractProcessUpdateTool:
        return _executeContractProcessUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case contractDisgussUpdateTool:
        return _executeContractDisgussUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case wordModifyTool:
        return _executeWordModify(
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

  /// 执行 contract_inspect 工具：向会话写入合同信息
  static Future<Map<String, dynamic>> _executeContractInspect({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final action = arguments['action'] as String? ?? 'add';
      final contractName = arguments['contractName'] as String? ?? '';

      if (contractName.isEmpty) {
        return _errorResult(callId, arguments, 'contractName 不能为空');
      }

      final currentContracts = List<ContractInfo>.from(session.contracts ?? []);

      switch (action) {
        case 'add':
          // 新增合同
          final newContract = ContractInfo(
            name: contractName,
            contractType: arguments['contractType'] as String?,
            startDate: arguments['startDate'] as String?,
            endDate: arguments['endDate'] as String?,
            signingDate: arguments['signingDate'] as String?,
            paymentClause: arguments['paymentClause'] as String?,
            paymentSchedule: arguments['paymentSchedule'] as String?,
            breachClause: arguments['breachClause'] as String?,
            liabilityClause: arguments['liabilityClause'] as String?,
          );
          currentContracts.add(newContract);
          break;

        case 'update':
          // 按名称查找已有合同并更新字段
          final idx = currentContracts.indexWhere(
            (c) => c.name == contractName,
          );
          if (idx == -1) {
            return _errorResult(
              callId,
              arguments,
              '未找到名称为 "$contractName" 的合同',
            );
          }
          final existing = currentContracts[idx];
          currentContracts[idx] = existing.copyWith(
            contractType:
                arguments['contractType'] as String? ?? existing.contractType,
            clearContractType: arguments.containsKey('contractType') && arguments['contractType'] == null,
            startDate:
                arguments['startDate'] as String? ?? existing.startDate,
            clearStartDate: arguments.containsKey('startDate') && arguments['startDate'] == null,
            endDate: arguments['endDate'] as String? ?? existing.endDate,
            clearEndDate: arguments.containsKey('endDate') && arguments['endDate'] == null,
            signingDate:
                arguments['signingDate'] as String? ?? existing.signingDate,
            clearSigningDate: arguments.containsKey('signingDate') && arguments['signingDate'] == null,
            paymentClause:
                arguments['paymentClause'] as String? ?? existing.paymentClause,
            clearPaymentClause: arguments.containsKey('paymentClause') && arguments['paymentClause'] == null,
            paymentSchedule:
                arguments['paymentSchedule'] as String? ?? existing.paymentSchedule,
            clearPaymentSchedule: arguments.containsKey('paymentSchedule') && arguments['paymentSchedule'] == null,
            breachClause:
                arguments['breachClause'] as String? ?? existing.breachClause,
            clearBreachClause: arguments.containsKey('breachClause') && arguments['breachClause'] == null,
            liabilityClause:
                arguments['liabilityClause'] as String? ?? existing.liabilityClause,
            clearLiabilityClause: arguments.containsKey('liabilityClause') && arguments['liabilityClause'] == null,
          );
          break;

        case 'addParty':
          final partyRole = arguments['partyRole'] as String?;
          final partyName = arguments['partyName'] as String?;
          if (partyRole == null || partyRole.isEmpty || partyName == null || partyName.isEmpty) {
            return _errorResult(callId, arguments, 'addParty 操作需要 partyRole 和 partyName');
          }
          final idx2 = currentContracts.indexWhere(
            (c) => c.name == contractName,
          );
          if (idx2 == -1) {
            return _errorResult(
              callId,
              arguments,
              '未找到名称为 "$contractName" 的合同',
            );
          }
          final existing2 = currentContracts[idx2];
          final newParty = ContractParty(
            role: partyRole,
            name: partyName,
            contact: arguments['partyContact'] as String?,
            address: arguments['partyAddress'] as String?,
          );
          currentContracts[idx2] = existing2.copyWith(
            parties: [...existing2.parties, newParty],
          );
          break;

        default:
          return _errorResult(callId, arguments, '未知操作类型: $action');
      }

      // 通过全局 controller 更新 session
      try {
        final sessionController = Get.find<SessionController>();
        final updatedSession = session.copyWith(contracts: currentContracts);
        await sessionController.updateSession(updatedSession);
      } catch (e) {
        debugPrint('contract_inspect: 更新 session 失败: $e');
      }

      return {
        'id': callId,
        'name': contractInspectTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'action': action,
          'contractName': contractName,
          'totalContracts': currentContracts.length,
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '合同信息写入失败: $e');
    }
  }

  static Map<String, dynamic> _errorResult(
    String callId,
    Map<String, dynamic> arguments,
    String message,
  ) {
    return {
      'id': callId,
      'name': contractInspectTool,
      'args': arguments,
      'result': message,
      'isError': true,
    };
  }

  /// 执行合同要点更新
  static Future<Map<String, dynamic>> _executeContractContentUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.contractContentFile(session.sessionId);
      await StoragePaths.ensureSessionDir(session.sessionId);
      await File(filePath).writeAsString(content);

      debugPrint('📄 合同要点已更新: $filePath');

      return {
        'id': callId,
        'name': contractContentUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '合同要点已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '合同要点更新失败: $e');
    }
  }

  /// 执行合同履约跟踪更新
  static Future<Map<String, dynamic>> _executeContractProcessUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.contractProcessFile(session.sessionId);
      await StoragePaths.ensureSessionDir(session.sessionId);
      await File(filePath).writeAsString(content);

      debugPrint('📄 合同履约跟踪已更新: $filePath');

      return {
        'id': callId,
        'name': contractProcessUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '合同履约跟踪已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '合同履约跟踪更新失败: $e');
    }
  }

  /// 执行合同争议记录更新
  static Future<Map<String, dynamic>> _executeContractDisgussUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.contractDisgussFile(session.sessionId);
      await StoragePaths.ensureSessionDir(session.sessionId);
      await File(filePath).writeAsString(content);

      debugPrint('📄 合同争议记录已更新: $filePath');

      return {
        'id': callId,
        'name': contractDisgussUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '合同争议记录已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '合同争议记录更新失败: $e');
    }
  }

  /// 执行 Word 文档修改
  static Future<Map<String, dynamic>> _executeWordModify({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final filePath = arguments['filePath'] as String? ?? '';
      final script = arguments['script'] as String? ?? '';

      if (filePath.isEmpty) {
        return _errorResult(callId, arguments, 'filePath 参数不能为空');
      }
      if (script.isEmpty) {
        return _errorResult(callId, arguments, 'script 参数不能为空');
      }

      // 构建 Python 脚本，使用 python-docx 库修改文档
      final fullScript = '''
import sys
sys.path.insert(0, '.')

try:
    from docx import Document
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'python-docx'])
    from docx import Document

# 加载文档
doc = Document("$filePath")

# 用户脚本
$script

# 保存文档
doc.save("$filePath")
print("文档修改成功: $filePath")
''';

      // 使用 PythonToolService 执行脚本
      final result = await PythonToolService.execute(
        arguments: {
          'script': fullScript,
          'requirements': ['python-docx'],
        },
        callId: callId,
      );

      return result;
    } catch (e) {
      return _errorResult(callId, arguments, 'Word 文档修改失败: $e');
    }
  }

}
