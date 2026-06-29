import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../skills/skill_service.dart';
import './system_prompts.dart';

/// 系统提示词构建 — 所有 provider 共用的系统提示词组装逻辑
class MessageBuilder {
  MessageBuilder._();

  /// 构建系统提示词字符串（所有系统消息合并）
  static String buildSystemPrompt({
    ChatModel? model,
    ChatSession? session,
    String providerPrompt = '',
  }) {
    return buildSystemMessages(
      model: model,
      session: session,
      providerPrompt: providerPrompt,
    ).map((m) => m['content'] as String).where((c) => c.isNotEmpty).join('\n\n');
  }

  /// 构建多条独立的 system 消息
  static List<Map<String, dynamic>> buildSystemMessages({
    ChatModel? model,
    ChatSession? session,
    String providerPrompt = '',
  }) {
    final systemMessages = <Map<String, dynamic>>[];

    // 1. 用户自定义系统提示词（取自模型配置）
    if (model?.chatSettings?.systemPrompt != null &&
        model!.chatSettings!.systemPrompt.isNotEmpty) {
      systemMessages.add({
        'role': 'system',
        'content': model.chatSettings!.systemPrompt,
      });
    }

    // 2. Provider 特有的提示词
    if (providerPrompt.isNotEmpty) {
      systemMessages.add({'role': 'system', 'content': providerPrompt});
    }

    // 3. 全局规则：禁止 Web 搜索
    systemMessages.add({
      'role': 'system',
      'content': CommonSystemPrompts.noWebSearch,
    });

    // 4. 技能提示词注入
    if (session?.skill != null) {
      final skillPrompt = SkillService.buildSkillPrompt(session!.skill);
      if (skillPrompt.isNotEmpty) {
        systemMessages.add({'role': 'system', 'content': skillPrompt});
      }
    }

    // 4.5. MCP 工具描述注入（添加/刷新时已生成 prompt，直接读取）
    if (session?.mcp?.prompt != null && session!.mcp!.prompt!.isNotEmpty) {
      systemMessages.add({'role': 'system', 'content': session.mcp!.prompt!});
    }

    // 4.6. 连接器与技能关系描述提示词
    if (session?.connectPrompt != null &&
        session!.connectPrompt!.isNotEmpty) {
      final mcpName = session.mcp?.name ?? '未选择连接器';
      final skillName = session.skill?.name ?? '未选择技能';
      systemMessages.add({
        'role': 'system',
        'content': '连接器【$mcpName】和技能[$skillName]的使用关系：${session.connectPrompt}',
      });
    }

    // 5. 深度思考模式：注入推理增强提示词
    if (session?.deepThink == true) {
      systemMessages.add({
        'role': 'system',
        'content': CommonSystemPrompts.deepThink,
      });
    }

    return systemMessages;
  }
}
