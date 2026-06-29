import 'package:get/get.dart';
import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../../models/chat/chat_message.dart';
import '../../tools/tool_registry.dart';
import '../common/system_prompts.dart';
import './work_mode_strategy.dart';
import './mode_utils.dart';

/// 对话模式（默认）
///
/// 系统提示词：模型自定义 prompt + 技能 prompt + 深度思考 + 工作目录 + 核心规则 + 语言
/// 工具：基础系统工具 + MCP + Skill
class ConversationMode extends WorkModeStrategy {
  @override
  String get modeName => 'conversation';

  @override
  Future<List<Map<String, dynamic>>> buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    final workDir = getEffectiveWorkDir(session);

    // 1. 通用系统提示词
    messages.addAll(buildBaseSystemMessages(
      model: model,
      session: session,
      thinkEnabled: session.deepThink,
      workDir: workDir,
    ));

    // 2. 记忆上下文
    final memoryCtx = buildMemoryContext(session);
    if (memoryCtx.isNotEmpty) {
      messages.add({'role': 'system', 'content': memoryCtx});
    }

    // 3. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }

    // 4. 核心规则 + 语言（紧邻用户消息前）
    messages.add({'role': 'system', 'content': CommonSystemPrompts.coreRules});
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.responseLanguage(
        Get.locale?.languageCode ?? 'zh',
      ),
    });

    // 5. 用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});

    return messages;
  }

  @override
  List<Map<String, dynamic>> buildTools(ChatSession? session) {
    final allTools = <Map<String, dynamic>>[];
    // 基础工具
    allTools.addAll(SystemToolService.buildOpenAIToolsFormat());
    // MCP + Skill 工具
    allTools.addAll(buildMcpTools(session));
    allTools.addAll(buildSkillTools(session));
    return allTools;
  }
}
