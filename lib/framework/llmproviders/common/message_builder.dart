import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../../models/chat/chat_message.dart';
import '../../../models/chat/chat_attachment.dart';
import '../../../services/mcp_service.dart';
import '../../../services/skill_service.dart';
import '../../../services/system_tool_service.dart';
import 'system_prompts.dart';

/// 消息构建工具类 — 所有 provider 共用的消息组装逻辑
///
/// 包含：
/// - 系统提示词拼接（模型设定 + provider 提示 + 公共规则 + skill + deepThink + 工具信息 + MCP）
/// - 历史消息追加（滑动窗口）
/// - 附件内容构建
class MessageBuilder {
  MessageBuilder._();

  // ──────────────────────────────────────────────
  // 系统提示词构建
  // ──────────────────────────────────────────────

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
        if (kDebugMode) {
          debugPrint(
            '🔧 [Skill] 注入技能 "${session.skill!.name}", prompt 长度: ${session.skill!.prompt.length} 字符',
          );
        }
        systemMessages.add({'role': 'system', 'content': skillPrompt});
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [Skill] 技能 "${session.skill!.name}" 的 prompt 为空，跳过注入');
        }
      }
    }

    // 5. 深度思考模式：注入推理增强提示词
    if (session?.deepThink == true) {
      systemMessages.add({
        'role': 'system',
        'content': CommonSystemPrompts.deepThink,
      });
    }

    // 6. 系统内置工具信息
    if (session != null) {
      final toolMessages =
          SystemToolService.buildSystemToolsInfoAsMessages(session);
      systemMessages.addAll(toolMessages);
    }

    // 7. MCP 工具信息
    if (session != null && session.mcpServer != null) {
      final mcpToolsInfo = McpService.buildMcpToolsInfoForApi(session);
      if (mcpToolsInfo.isNotEmpty) {
        systemMessages.add({'role': 'system', 'content': mcpToolsInfo});
      }
    }

    return systemMessages;
  }

  // ──────────────────────────────────────────────
  // 消息列表构建（含历史记忆）
  // ──────────────────────────────────────────────

  /// 构建完整的消息列表：系统提示词 + 历史 + 当前用户消息
  static List<Map<String, dynamic>> buildMessages({
    required ChatMessage userMessage,
    required ChatModel model,
    ChatSession? session,
    String providerPrompt = '',
  }) {
    final messages = <Map<String, dynamic>>[];

    // 添加系统提示词
    final systemMsgs = buildSystemMessages(
      model: model,
      session: session,
      providerPrompt: providerPrompt,
    );
    messages.addAll(systemMsgs);

    // 添加会话历史
    if (session != null && session.messages.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '🧠 [buildMessages] session.messages 共 ${session.messages.length} 条, 当前用户消息: ${userMessage.msgId}',
        );
      }
      _appendHistoryMessages(messages, session, userMessage);
    } else if (kDebugMode) {
      debugPrint('🧠 [buildMessages] session 为空或无历史消息');
    }

    // 构建包含附件信息的用户消息内容
    final userContent = buildUserContentWithAttachments(userMessage);
    messages.add({'role': 'user', 'content': userContent});

    return messages;
  }

  // ──────────────────────────────────────────────
  // 历史消息追加
  // ──────────────────────────────────────────────

  /// 将当前消息之前的会话历史追加到消息列表中（滑动窗口）
  static void _appendHistoryMessages(
    List<Map<String, dynamic>> messages,
    ChatSession session,
    ChatMessage currentUserMessage,
  ) {
    int userMsgIndex = session.messages.length;
    for (int i = session.messages.length - 1; i >= 0; i--) {
      if (session.messages[i].msgId == currentUserMessage.msgId) {
        userMsgIndex = i;
        break;
      }
    }

    if (userMsgIndex <= 0) {
      if (kDebugMode) {
        debugPrint(
          '🧠 [_appendHistoryMessages] 无历史: userMsgIndex=$userMsgIndex, session消息数=${session.messages.length}',
        );
      }
      return;
    }

    final historyMessages = session.messages.sublist(0, userMsgIndex);

    final int maxRounds = session.memoryRounds;
    if (maxRounds <= 0) {
      if (kDebugMode) {
        debugPrint('🧠 [_appendHistoryMessages] 记忆轮数=0，跳过历史注入');
      }
      return;
    }

    int roundCount = 0;
    int historyStart = 0;

    for (int i = historyMessages.length - 1; i >= 0; i--) {
      if (historyMessages[i].role == MessageRole.user) {
        roundCount++;
        if (roundCount >= maxRounds) {
          historyStart = i;
          break;
        }
      }
    }

    final included = historyMessages.sublist(historyStart);

    if (kDebugMode) {
      debugPrint(
        '🧠 [_appendHistoryMessages] 注入 ${included.length} 条历史消息 (总共 ${historyMessages.length} 条, 最近 $maxRounds 轮)',
      );
    }

    for (final msg in included) {
      if (msg.content.isEmpty && msg.attachments.isEmpty) continue;
      final apiRole = _toOpenAIRole(msg.role);
      if (apiRole == null) continue;

      if (msg.role == MessageRole.user && msg.attachments.isNotEmpty) {
        final msgContent = buildUserContentWithAttachments(msg);
        messages.add({'role': apiRole, 'content': msgContent});
      } else {
        final msgData = <String, dynamic>{
          'role': apiRole,
          'content': msg.content,
        };

        if (msg.role == MessageRole.tool && msg.toolName != null) {
          msgData['tool_call_id'] = msg.toolName;
        }

        messages.add(msgData);
      }
    }
  }

  /// 将内部角色映射为 OpenAI 兼容的 API 角色
  static String? _toOpenAIRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.bot:
        return 'assistant';
      case MessageRole.tool:
        return 'tool';
    }
  }

  // ──────────────────────────────────────────────
  // 用户消息 + 附件内容构建
  // ──────────────────────────────────────────────

  /// 构建包含附件信息的用户消息内容
  static dynamic buildUserContentWithAttachments(ChatMessage userMessage) {
    if (userMessage.attachments.isEmpty) {
      return userMessage.content;
    }

    final hasImageAttachment = userMessage.attachments.any(
      (a) => a.type == 'image' && a.base64Data != null && a.base64Data!.isNotEmpty,
    );

    if (hasImageAttachment) {
      final contentParts = <Map<String, dynamic>>[];

      for (final attachment in userMessage.attachments) {
        if (attachment.type == 'image' &&
            attachment.base64Data != null &&
            attachment.base64Data!.isNotEmpty) {
          final dataUri =
              'data:${attachment.mimeType ?? "image/png"};base64,${attachment.base64Data}';
          contentParts.add({
            'type': 'image_url',
            'image_url': {'url': dataUri},
          });
          if (attachment.content != null && attachment.content!.isNotEmpty) {
            final imagePath =
                (attachment.filePath != null && attachment.filePath!.isNotEmpty)
                    ? attachment.filePath!
                    : attachment.name;
            contentParts.add({
              'type': 'text',
              'text': '[图片: $imagePath] ${attachment.content}',
            });
          }
        } else {
          final text = _buildSingleAttachmentInfo(attachment);
          contentParts.add({'type': 'text', 'text': text});
        }
      }

      contentParts.add({'type': 'text', 'text': userMessage.content});
      return contentParts;
    }

    final attachmentInfos =
        userMessage.attachments.map(_buildSingleAttachmentInfo).toList();

    return '${attachmentInfos.join('\n\n')}\n\n ${userMessage.content}';
  }

  /// 构建单个附件信息
  static String _buildSingleAttachmentInfo(ChatAttachment attachment) {
    final buffer = StringBuffer();
    _addAttachmentHeader(buffer, attachment);
    _addAttachmentSize(buffer, attachment);
    buffer.write(']\n');
    _addAttachmentContent(buffer, attachment);
    return buffer.toString();
  }

  static void _addAttachmentHeader(StringBuffer buffer, ChatAttachment attachment) {
    const typeLabels = {
      'image': '图片文件',
      'document': '文档文件',
      'text': '文档文件',
      'code': '代码文件',
      'web': '网页链接',
      'folder': '文件夹',
    };

    final label = typeLabels[attachment.type] ?? '文件';
    final fileIdentity =
        (attachment.filePath != null && attachment.filePath!.isNotEmpty)
            ? attachment.filePath!
            : attachment.name;
    buffer.write('[$label: $fileIdentity');
  }

  static void _addAttachmentSize(StringBuffer buffer, ChatAttachment attachment) {
    if (attachment.size != null && attachment.size! > 0) {
      buffer.write(', 大小: ${_formatFileSize(attachment.size!)}');
    }
  }

  static void _addAttachmentContent(StringBuffer buffer, ChatAttachment attachment) {
    if (attachment.content == null || attachment.content!.isEmpty) {
      buffer.write('[文件处理中...]');
    } else if (attachment.content == 'ERROR_PROCESSING') {
      buffer.write('[文件处理失败]');
    } else {
      buffer.write(attachment.content!);
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // ──────────────────────────────────────────────
  // 工具调用 XML 解析辅助
  // ──────────────────────────────────────────────

  /// 从 invoke 体内解析 `<arguments>` JSON 块
  static Map<String, dynamic>? parseArgumentsJson(String invokeBody) {
    final match = RegExp(
      r'<arguments>\s*(.*?)\s*</arguments>',
      dotAll: true,
      caseSensitive: false,
    ).firstMatch(invokeBody);
    final raw = match?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }
}
