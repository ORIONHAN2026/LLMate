import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../controllers/session_controller.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/contract_info.dart';
import 'node_tool_service.dart';
import 'ocr_tool_service.dart';
import 'python_tool_service.dart';

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

}
