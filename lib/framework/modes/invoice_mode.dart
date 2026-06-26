import 'package:get/get.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/system_tool_service.dart';
import '../../storage/storage_paths.dart';
import '../common/system_prompts.dart';
import 'work_mode_strategy.dart';
import 'mode_utils.dart';

/// 发票模式
///
/// 系统提示词：通用提示词 + 发票专用流程提示词
/// 工具：发票专用工具 + 基础系统工具 + MCP + Skill
class InvoiceMode extends WorkModeStrategy {
  @override
  String get modeName => 'invoice';

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
      'content': CommonSystemPrompts.invoiceMode(effectiveWorkDir, sessionDir),
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
    allTools.addAll(SystemToolService.buildOpenAIToolsFormat());

    // 发票模式专属工具
    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'invoice_summary_update',
          'description': '更新发票汇总文件（invoice_summary.md）。直接写入完整的发票汇总内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的发票汇总完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'invoice_detail_update',
          'description': '更新发票明细文件（invoice_detail.md）。直接写入完整的发票明细内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的发票明细完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'reimbursement_update',
          'description': '更新报销记录文件（reimbursement.md）。直接写入完整的报销记录内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的报销记录完整内容（Markdown 格式）。'},
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
    allTools.addAll(buildSkillTools(session));
    return allTools;
  }
}
