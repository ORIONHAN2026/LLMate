import 'package:get/get.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/system_tool_service.dart';
import '../../storage/storage_paths.dart';
import '../common/system_prompts.dart';
import 'work_mode_strategy.dart';
import 'mode_utils.dart';

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

    // 1. 通用系统提示词
    messages.addAll(buildBaseSystemMessages(
      model: model,
      session: session,
      thinkEnabled: session.deepThink,
      workDir: effectiveWorkDir,
    ));

    // 2. 合同模式专用提示词
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.contractMode(effectiveWorkDir, sessionDir),
    });

    // 3. 记忆上下文
    final memoryCtx = buildMemoryContext(session);
    if (memoryCtx.isNotEmpty) {
      messages.add({'role': 'system', 'content': memoryCtx});
    }

    // 4. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }

    // 5. 核心规则 + 语言
    messages.add({'role': 'system', 'content': CommonSystemPrompts.coreRules});
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(
        Get.locale?.languageCode ?? 'zh',
      ),
    });

    // 6. 用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});

    return messages;
  }

  @override
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    final allTools = <Map<String, dynamic>>[];
    allTools.addAll(
      SystemToolService.buildOpenAIToolsFormat(workMode: modeName),
    );
    allTools.addAll(buildMcpTools(session));
    allTools.addAll(buildSkillTools(session));
    return allTools;
  }
}
