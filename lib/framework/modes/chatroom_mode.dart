import 'package:get/get.dart';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../services/system_tool_service.dart';
import '../../storage/storage_paths.dart';
import '../common/system_prompts.dart';
import 'work_mode_strategy.dart';
import 'mode_utils.dart';

/// 聊天室模式
///
/// 系统提示词：通用提示词 + 聊天室专用提示词（含角色加载）
/// 工具：角色管理工具 + 基础系统工具 + MCP + Skill
class ChatroomMode extends WorkModeStrategy {
  @override
  String get modeName => 'chatroom';

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

    final roleContexts = await loadRoleContexts(session.sessionId);
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.chatroomMode(
        effectiveWorkDir,
        sessionDir,
        roleContexts,
      ),
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

    // 聊天室模式专属工具
    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'role_create',
          'description': '创建新角色。角色描述以 .md 文件形式保存，包含角色名称、性格、背景、说话风格等信息。在聊天室模式下，AI可以根据对话场景选择合适的角色进行回复。',
          'parameters': {
            'type': 'object',
            'properties': {
              'roleName': {'type': 'string', 'description': '角色名称（英文，用于文件名）。'},
              'displayName': {'type': 'string', 'description': '角色显示名称（中文，用于界面显示）。'},
              'content': {'type': 'string', 'description': '角色描述内容（Markdown 格式），包含：性格、背景、说话风格、知识领域等。'},
            },
            'required': ['roleName', 'displayName', 'content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'role_update',
          'description': '更新已有角色的描述内容。',
          'parameters': {
            'type': 'object',
            'properties': {
              'roleName': {'type': 'string', 'description': '要更新的角色名称（英文，文件名）。'},
              'content': {'type': 'string', 'description': '更新后的角色描述内容。'},
            },
            'required': ['roleName', 'content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'role_delete',
          'description': '删除指定角色。',
          'parameters': {
            'type': 'object',
            'properties': {
              'roleName': {'type': 'string', 'description': '要删除的角色名称（英文，文件名）。'},
            },
            'required': ['roleName'],
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
