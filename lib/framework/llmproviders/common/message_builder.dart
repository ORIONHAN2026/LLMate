import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../../services/skill_service.dart';
import 'system_prompts.dart';

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
