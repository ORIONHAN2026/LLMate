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
import 'paddle_ocr_service.dart';
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
  static const String noteUpdateTool = 'note_update';
  static const String invoiceSummaryUpdateTool = 'invoice_summary_update';
  static const String invoiceDetailUpdateTool = 'invoice_detail_update';
  static const String reimbursementUpdateTool = 'reimbursement_update';
  static const String paddleOcrTool = 'paddle_ocr';
  static const String roleCreateTool = 'role_create';
  static const String roleUpdateTool = 'role_update';
  static const String roleDeleteTool = 'role_delete';
  static const String mindmapUpdateTool = 'mindmap_update';

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
      name: noteUpdateTool,
      description:
          '更新备忘录文件（note.md）。直接写入完整的备忘录内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的备忘录完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: wordModifyTool,
      description:
          '修改 Word 文档内容。支持修改文档中的文本、表格等内容。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要修改的 Word 文档完整路径。',
          },
          'content': {
            'type': 'string',
            'description': '修改后的内容（Markdown 格式）。',
          },
        },
        'required': ['filePath', 'content'],
      },
    ),
    SystemToolDefinition(
      name: paddleOcrTool,
      description:
          '使用 PaddleOCR 对图片执行文字识别，提取图片中的文字内容。支持中英文混合识别。',
      parameters: {
        'type': 'object',
        'properties': {
          'filePath': {
            'type': 'string',
            'description': '要识别的图片文件完整路径（支持 PNG/JPEG/BMP/TIFF 等格式）。',
          },
        },
        'required': ['filePath'],
      },
    ),
    SystemToolDefinition(
      name: invoiceSummaryUpdateTool,
      description:
          '更新发票汇总文件（invoice_summary.md）。直接写入完整的发票汇总内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的发票汇总完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: invoiceDetailUpdateTool,
      description:
          '更新发票明细文件（invoice_detail.md）。直接写入完整的发票明细内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的发票明细完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: reimbursementUpdateTool,
      description:
          '更新报销记录文件（reimbursement.md）。直接写入完整的报销记录内容，无需指定文件路径。'
          '文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '要写入的报销记录完整内容（Markdown 格式）。',
          },
        },
        'required': ['content'],
      },
    ),
    SystemToolDefinition(
      name: roleCreateTool,
      description:
          '创建新角色。角色描述以 .md 文件形式保存，包含角色名称、性格、背景、说话风格等信息。'
          '在聊天室模式下，AI可以根据对话场景选择合适的角色进行回复。displayName 必须以一个合适的 emoji 开头。',
      parameters: {
        'type': 'object',
        'properties': {
          'roleName': {
            'type': 'string',
            'description': '角色名称（英文，用于文件名）。',
          },
          'displayName': {
            'type': 'string',
            'description': '角色显示名称，必须以 emoji 开头（如：🧙 邓布利多、🧑‍💻 小明）。',
          },
          'content': {
            'type': 'string',
            'description': '角色描述内容（Markdown 格式），包含：性格、背景、说话风格、知识领域等。',
          },
        },
        'required': ['roleName', 'displayName', 'content'],
      },
    ),
    SystemToolDefinition(
      name: roleUpdateTool,
      description:
          '更新已有角色的描述内容。',
      parameters: {
        'type': 'object',
        'properties': {
          'roleName': {
            'type': 'string',
            'description': '要更新的角色名称（英文，文件名）。',
          },
          'content': {
            'type': 'string',
            'description': '更新后的角色描述内容。',
          },
        },
        'required': ['roleName', 'content'],
      },
    ),
    SystemToolDefinition(
      name: roleDeleteTool,
      description:
          '删除指定角色。',
      parameters: {
        'type': 'object',
        'properties': {
          'roleName': {
            'type': 'string',
            'description': '要删除的角色名称（英文，文件名）。',
          },
        },
        'required': ['roleName'],
      },
    ),
    SystemToolDefinition(
      name: mindmapUpdateTool,
      description:
          '更新脑图文件（mindmap.md）。使用 JSON 格式存储脑图数据，支持多层嵌套节点。'
          '直接写入完整的脑图 JSON 内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
      parameters: {
        'type': 'object',
        'properties': {
          'content': {
            'type': 'string',
            'description': '脑图 JSON 数据。格式：{"title":"主题","children":[{"title":"分支","children":[{"title":"子节点"}]}]}',
          },
        },
        'required': ['content'],
      },
    ),
  ];

  static List<SystemToolDefinition> get tools => List.unmodifiable(_tools);

  static bool hasTool(String name) => _tools.any((tool) => tool.name == name);

  /// 基础工具（所有模式都可用）
  static const _baseToolNames = {
    nodeExecuteTool, pythonExecuteTool, ocrExtractTool,
    fileReadTool, fileWriteTool, wordModifyTool, paddleOcrTool,
  };

  /// 构建基础工具的 OpenAI tools 格式
  static List<Map<String, dynamic>> buildOpenAIToolsFormat() {
    final baseTools = _tools.where((tool) => _baseToolNames.contains(tool.name)).toList();
    return baseTools.map((tool) {
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
      case noteUpdateTool:
        return _executeNoteUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case invoiceSummaryUpdateTool:
        return _executeInvoiceSummaryUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case invoiceDetailUpdateTool:
        return _executeInvoiceDetailUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case reimbursementUpdateTool:
        return _executeReimbursementUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case roleCreateTool:
        return _executeRoleCreate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case roleUpdateTool:
        return _executeRoleUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case roleDeleteTool:
        return _executeRoleDelete(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case mindmapUpdateTool:
        return _executeMindmapUpdate(
          session: session,
          arguments: arguments,
          callId: callId,
        );
      case paddleOcrTool:
        return PaddleOcrService.execute(
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

      final filePath = StoragePaths.contractContentFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'contract',
        workDirectory: session.workDirectory,
      );
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

      final filePath = StoragePaths.contractProcessFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'contract',
        workDirectory: session.workDirectory,
      );
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

      final filePath = StoragePaths.contractDisgussFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'contract',
        workDirectory: session.workDirectory,
      );
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

  /// 执行备忘录更新
  static Future<Map<String, dynamic>> _executeNoteUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.noteFile(
        sessionId: session.sessionId,
        workMode: session.workMode,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: session.workMode,
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(content);

      debugPrint('📝 备忘录已更新: $filePath');

      return {
        'id': callId,
        'name': noteUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '备忘录已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '备忘录更新失败: $e');
    }
  }

  /// 执行发票汇总更新
  static Future<Map<String, dynamic>> _executeInvoiceSummaryUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.invoiceSummaryFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'invoice',
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(content);

      debugPrint('🧾 发票汇总已更新: $filePath');

      return {
        'id': callId,
        'name': invoiceSummaryUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '发票汇总已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '发票汇总更新失败: $e');
    }
  }

  /// 执行发票明细更新
  static Future<Map<String, dynamic>> _executeInvoiceDetailUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.invoiceDetailFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'invoice',
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(content);

      debugPrint('🧾 发票明细已更新: $filePath');

      return {
        'id': callId,
        'name': invoiceDetailUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '发票明细已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '发票明细更新失败: $e');
    }
  }

  /// 执行角色创建
  static Future<Map<String, dynamic>> _executeRoleCreate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final roleName = arguments['roleName'] as String? ?? '';
      final displayName = arguments['displayName'] as String? ?? '';
      final content = arguments['content'] as String? ?? '';
      
      if (roleName.isEmpty) {
        return _errorResult(callId, arguments, 'roleName 参数不能为空');
      }
      if (displayName.isEmpty) {
        return _errorResult(callId, arguments, 'displayName 参数不能为空');
      }
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final rolesDirPath = StoragePaths.rolesDir(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'chatroom',
        workDirectory: session.workDirectory,
      );
      await Directory(rolesDirPath).create(recursive: true);

      // 写入角色文件，文件头包含显示名称
      final fileContent = '# $displayName\n\n$content';
      final filePath = StoragePaths.roleFile(
        sessionId: session.sessionId,
        roleName: roleName,
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(fileContent);

      debugPrint('🎭 角色已创建: $filePath');

      return {
        'id': callId,
        'name': roleCreateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'roleName': roleName,
          'displayName': displayName,
          'message': '角色 "$displayName" 已创建',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '角色创建失败: $e');
    }
  }

  /// 执行角色更新
  static Future<Map<String, dynamic>> _executeRoleUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final roleName = arguments['roleName'] as String? ?? '';
      final content = arguments['content'] as String? ?? '';
      
      if (roleName.isEmpty) {
        return _errorResult(callId, arguments, 'roleName 参数不能为空');
      }
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.roleFile(
        sessionId: session.sessionId,
        roleName: roleName,
        workDirectory: session.workDirectory,
      );
      if (!await File(filePath).exists()) {
        return _errorResult(callId, arguments, '角色 "$roleName" 不存在');
      }

      // 读取原文件获取显示名称
      final existingContent = await File(filePath).readAsString();
      final displayNameMatch = RegExp(r'^# (.+)$', multiLine: true).firstMatch(existingContent);
      final displayName = displayNameMatch?.group(1) ?? roleName;

      final fileContent = '# $displayName\n\n$content';
      await File(filePath).writeAsString(fileContent);

      debugPrint('🎭 角色已更新: $filePath');

      return {
        'id': callId,
        'name': roleUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '角色 "$displayName" 已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '角色更新失败: $e');
    }
  }

  /// 执行角色删除
  static Future<Map<String, dynamic>> _executeRoleDelete({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final roleName = arguments['roleName'] as String? ?? '';
      
      if (roleName.isEmpty) {
        return _errorResult(callId, arguments, 'roleName 参数不能为空');
      }

      final filePath = StoragePaths.roleFile(
        sessionId: session.sessionId,
        roleName: roleName,
        workDirectory: session.workDirectory,
      );
      if (!await File(filePath).exists()) {
        return _errorResult(callId, arguments, '角色 "$roleName" 不存在');
      }

      await File(filePath).delete();

      debugPrint('🎭 角色已删除: $filePath');

      return {
        'id': callId,
        'name': roleDeleteTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'message': '角色 "$roleName" 已删除',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '角色删除失败: $e');
    }
  }

  /// 执行报销记录更新
  static Future<Map<String, dynamic>> _executeReimbursementUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      final filePath = StoragePaths.reimbursementFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'invoice',
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(content);

      debugPrint('🧾 报销记录已更新: $filePath');

      return {
        'id': callId,
        'name': reimbursementUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '报销记录已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '报销记录更新失败: $e');
    }
  }

  /// 执行脑图更新
  static Future<Map<String, dynamic>> _executeMindmapUpdate({
    required ChatSession session,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final content = arguments['content'] as String? ?? '';
      if (content.isEmpty) {
        return _errorResult(callId, arguments, 'content 参数不能为空');
      }

      // 验证 JSON 格式
      try {
        final decoded = jsonDecode(content);
        if (decoded is! Map) {
          return _errorResult(callId, arguments, 'content 必须是 JSON 对象格式');
        }
      } catch (e) {
        return _errorResult(callId, arguments, 'content 不是有效的 JSON: $e');
      }

      final filePath = StoragePaths.mindmapFile(
        sessionId: session.sessionId,
        workDirectory: session.workDirectory,
      );
      await StoragePaths.ensureModeDir(
        sessionId: session.sessionId,
        workMode: 'creative',
        workDirectory: session.workDirectory,
      );
      await File(filePath).writeAsString(content);

      debugPrint('🧠 脑图已更新: $filePath');

      return {
        'id': callId,
        'name': mindmapUpdateTool,
        'args': arguments,
        'result': jsonEncode({
          'ok': true,
          'filePath': filePath,
          'message': '脑图已更新',
        }),
        'isError': false,
      };
    } catch (e) {
      return _errorResult(callId, arguments, '脑图更新失败: $e');
    }
  }

}
