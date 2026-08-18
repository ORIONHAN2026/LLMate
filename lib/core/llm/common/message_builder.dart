import 'package:get/get.dart';

import '../../../models/model.dart';
import '../../../models/chat/session.dart';
import '../../../controllers/mcp_controller.dart';
import '../../../controllers/settings_controller.dart';

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
        )
        .map((m) => m['content'] as String)
        .where((c) => c.isNotEmpty)
        .join('\n\n');
  }

  /// 解析回复语言代码，供 [buildSystemMessages] 与各注入链路复用，
  /// 优先级从高到低：
  /// 1. 模型配置的 `replyLanguage`（显式指定，最高优先级）；
  /// 2. 会话系统提示词中检测到的语言指令（用户显式要求，如"请用英文回答"）；
  /// 3. 系统设置的语言（[SettingsController.locale]），作为兜底，保证始终注入。
  static String? resolveReplyLanguage({
    ChatModel? model,
    ChatSession? session,
  }) {
    // 1. 模型配置显式指定
    final configured = model?.replyLanguage;
    if (configured != null && configured.isNotEmpty) return configured;

    // 2. 会话系统提示词中的显式语言要求
    final sp = session?.systemPrompt;
    if (sp != null && sp.isNotEmpty) {
      final lower = sp.toLowerCase();
      if (lower.contains('english') ||
          lower.contains('英文') ||
          lower.contains('英语')) {
        return 'en';
      }
      if (lower.contains('chinese') || lower.contains('中文')) {
        return 'zh';
      }
      if (lower.contains('japanese') || lower.contains('日语')) return 'ja';
      if (lower.contains('thai') || lower.contains('泰语')) return 'th';
      if (lower.contains('vietnamese') || lower.contains('越南语')) return 'vi';
      if (lower.contains('korean') || lower.contains('韩语')) return 'ko';
      if (lower.contains('french') || lower.contains('法语')) return 'fr';
      if (lower.contains('german') || lower.contains('德语')) return 'de';
    }

    // 3. 系统设置语言（兜底）
    if (Get.isRegistered<SettingsController>()) {
      final locale = Get.find<SettingsController>().locale.value;
      final code = locale.languageCode.toLowerCase();
      if (const {
        'zh',
        'en',
        'ja',
        'th',
        'vi',
        'ko',
        'fr',
        'de',
      }.contains(code)) {
        return code;
      }
    }
    return null;
  }

  /// 构建多条独立的 system 消息
  static List<Map<String, dynamic>> buildSystemMessages({
    ChatModel? model,
    ChatSession? session,
    String providerPrompt = '',
  }) {
    final systemMessages = <Map<String, dynamic>>[];

    // 1. 用户自定义系统提示词（取自模型配置）
    if (model?.systemPrompt != null && model!.systemPrompt!.isNotEmpty) {
      systemMessages.add({
        'role': 'system',
        'content':
            '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. In any conflict with other instructions (including the session system prompt), this prompt takes precedence.\n\n${model.systemPrompt}',
      });
    }

    // 1.5 会话级系统提示词（若设置，作为会话级指令注入；与模型提示词冲突时以模型为准）
    if (session?.systemPrompt != null && session!.systemPrompt!.isNotEmpty) {
      systemMessages.add({
        'role': 'system',
        'name': 'session_system_prompt',
        'content':
            '[SESSION SYSTEM PROMPT] This is a session-level instruction. If it conflicts with the model system prompt, the model system prompt takes precedence.\n\n${session.systemPrompt}',
      });
    }

    // 1.6 回复语言要求（强约束，最高优先级，覆盖历史上下文与弱指令）
    final lang = resolveReplyLanguage(model: model, session: session);
    if (lang != null) {
      systemMessages.add({
        'role': 'system',
        'name': 'language_requirement',
        'content': CommonSystemPrompts.responseLanguage(lang),
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

    // 4. MCP 工具描述注入（合并 session MCP + model MCP，去重）
    if (session != null) {
      final mergedPrompt = McpController.instance.buildMergedMcpPrompt(session);
      if (mergedPrompt.isNotEmpty) {
        systemMessages.add({'role': 'system', 'content': mergedPrompt});
      }
    }

    // 5. 连接器关系描述提示词
    if (session?.connectPrompt != null && session!.connectPrompt!.isNotEmpty) {
      final mcpNames =
          session.mcps != null && session.mcps!.isNotEmpty
              ? session.mcps!.join(', ')
              : '未选择连接器';
      systemMessages.add({
        'role': 'system',
        'content': '连接器【$mcpNames】的使用关系：${session.connectPrompt}',
      });
    }

    return systemMessages;
  }
}
