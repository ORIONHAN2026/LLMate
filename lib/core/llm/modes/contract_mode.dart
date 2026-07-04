import 'package:get/get.dart';
import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../../models/chat/chat_message.dart';
import '../../../data/storage_paths.dart';
import '../common/system_prompts.dart';
import './work_mode_strategy.dart';
import './mode_utils.dart';

/// 合同模式
///
/// 系统提示词：通用提示词 + 合同专用流程提示词
/// 工具：合同专用工具 + 基础系统工具 + MCP + Skill
class ContractMode extends WorkModeStrategy {
  @override
  String get modeName => 'contract';

  @override
  Future<List<Map<String, dynamic>>> buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    final effectiveWorkDir = getEffectiveWorkDir(session);
    final sessionDir = StoragePaths.sessionDir(session.sessionId);

    messages.addAll(buildBaseSystemMessages(
      model: model,
      session: session,
      thinkEnabled: session.deepThink,
      workDir: effectiveWorkDir,
    ));

    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.contractMode(effectiveWorkDir, sessionDir),
    });

    final memoryCtx = buildMemoryContext(session);
    if (memoryCtx.isNotEmpty) {
      messages.add({'role': 'system', 'content': memoryCtx});
    }

    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }

    messages.add({'role': 'system', 'content': CommonSystemPrompts.coreRules});
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(
        Get.locale?.languageCode ?? 'zh',
      ),
    });

    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});

    return messages;
  }

  @override
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    final allTools = <Map<String, dynamic>>[];

    // 基础工具

    // 合同模式专属工具
    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'contract_inspect',
          'description': '将合同解析结果写入当前会话的合同列表。支持三种操作：add（新增一份合同）、update（更新已有合同的字段）、addParty（向已有合同添加签署方）。每次调用只能操作一份合同。合同信息会在右侧边栏"合约要点"Tab中展示。',
          'parameters': {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'description': '操作类型：add（新增合同）、update（更新已有合同）、addParty（添加签署方）',
                'enum': ['add', 'update', 'addParty'],
              },
              'contractName': {'type': 'string', 'description': '合同名称（add 操作必填，update 操作用来定位目标合同）'},
              'contractType': {'type': 'string', 'description': '合同类型，如：采购合同、服务合同、租赁合同等'},
              'startDate': {'type': 'string', 'description': '合同起始日期，格式如 2024-01-01'},
              'endDate': {'type': 'string', 'description': '合同结束日期，格式如 2025-12-31'},
              'signingDate': {'type': 'string', 'description': '合同签订日期'},
              'paymentClause': {'type': 'string', 'description': '收支条款详细内容'},
              'paymentSchedule': {'type': 'string', 'description': '收支计划/付款计划详细内容'},
              'breachClause': {'type': 'string', 'description': '违约条款详细内容'},
              'liabilityClause': {'type': 'string', 'description': '违约责任详细内容'},
              'partyRole': {'type': 'string', 'description': '签署方角色，如：甲方、乙方'},
              'partyName': {'type': 'string', 'description': '签署方名称/公司名'},
              'partyContact': {'type': 'string', 'description': '签署方联系方式'},
              'partyAddress': {'type': 'string', 'description': '签署方地址'},
            },
            'required': ['action', 'contractName'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'contract_content_update',
          'description': '更新合同要点文件（contract_content.md）。直接写入完整的合同要点内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的合同要点完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'contract_process_update',
          'description': '更新合同履约跟踪文件（contract_process.md）。直接写入完整的履约跟踪内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的合同履约跟踪完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'contract_disguss_update',
          'description': '更新合同争议记录文件（contract_disguss.md）。直接写入完整的争议记录内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的合同争议记录完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'note_update',
          'description': '更新备忘录文件（note.md）。直接写入完整的备忘录内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的备忘录完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
    ]);

    // MCP + Skill 工具
    allTools.addAll(buildMcpTools(session));
    allTools.addAll([]);
    return allTools;
  }
}
