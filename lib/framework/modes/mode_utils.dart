import 'dart:io';
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_attachment.dart';
import '../../services/skill_service.dart';
import '../../storage/storage_paths.dart';
import '../common/system_prompts.dart';

/// 安全函数名 → 原始函数名 映射（用于还原 MCP/Skill 工具名中的非法字符）
final Map<String, String> _safeNameToOriginal = {};

/// 根据安全名称还原原始工具名；若未映射则原样返回
String resolveOriginalToolName(String safeName) {
  return _safeNameToOriginal[safeName] ?? safeName;
}

/// 构建记忆上下文，合并压缩记忆和最近记忆
String buildMemoryContext(ChatSession session) {
  final buf = StringBuffer();
  var hasContent = false;

  if (session.compressedMemory != null &&
      session.compressedMemory!.isNotEmpty) {
    buf.writeln('## 📝 对话历史记忆（压缩摘要）');
    buf.writeln(session.compressedMemory);
    hasContent = true;
  }

  if (session.memory.isNotEmpty) {
    if (hasContent) buf.writeln();
    buf.writeln('## 💬 最近对话记录');
    for (final turn in session.memory) {
      final label = turn.role == 'user' ? '👤 用户' : '🤖 助手';
      buf.writeln('$label: ${turn.content}');
    }
  }

  return buf.toString();
}

/// 加载聊天室模式的所有角色上下文
Future<List<String>> loadRoleContexts(String sessionId) async {
  final rolesDirPath = StoragePaths.rolesDir(sessionId);
  final dir = Directory(rolesDirPath);

  if (!await dir.exists()) return [];

  final contexts = <String>[];
  await for (final entity in dir.list(recursive: false)) {
    if (entity is File && entity.path.endsWith('.md')) {
      try {
        final content = await File(entity.path).readAsString();
        if (content.trim().isNotEmpty) {
          contexts.add(content.trim());
        }
      } catch (_) {}
    }
  }

  return contexts;
}

/// 获取有效的工作目录（优先使用用户选择的，否则使用会话目录）
String getEffectiveWorkDir(ChatSession session) {
  if (session.workDirectory != null && session.workDirectory!.isNotEmpty) {
    return session.workDirectory!;
  }
  return StoragePaths.sessionDir(session.sessionId);
}

/// 将当前消息之前的会话历史追加到消息列表中（滑动窗口）
void appendHistoryMessages(
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

  if (userMsgIndex <= 0) return;

  final historyMessages = session.messages.sublist(0, userMsgIndex);
  final int maxRounds = session.memoryRounds;
  if (maxRounds <= 0) return;

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
  for (final msg in included) {
    if (msg.content.isEmpty && msg.attachments.isEmpty) continue;
    final apiRole = _toOpenAIRole(msg.role);
    if (apiRole == null) continue;

    if (msg.role == MessageRole.user && msg.attachments.isNotEmpty) {
      final msgContent = buildUserContent(msg);
      messages.add({'role': apiRole, 'content': msgContent});
    } else if (msg.role == MessageRole.tool) {
      messages.add({
        'role': 'tool',
        'tool_call_id': msg.toolCallId ?? msg.msgId,
        'content': msg.content,
      });
    } else {
      messages.add({'role': apiRole, 'content': msg.content});
    }
  }
}

String? _toOpenAIRole(MessageRole role) {
  switch (role) {
    case MessageRole.user:
      return 'user';
    case MessageRole.bot:
      return 'assistant';
    case MessageRole.tool:
      return 'tool';
  }
}

/// 构建包含附件信息的用户消息内容
dynamic buildUserContent(ChatMessage userMessage) {
  if (userMessage.attachments.isEmpty) {
    return userMessage.content;
  }

  final hasImageAttachment = userMessage.attachments.any(
    (a) =>
        a.type == 'image' && a.base64Data != null && a.base64Data!.isNotEmpty,
  );

  if (hasImageAttachment) {
    final parts = <Map<String, dynamic>>[];
    for (final a in userMessage.attachments) {
      if (a.type == 'image' &&
          a.base64Data != null &&
          a.base64Data!.isNotEmpty) {
        final dataUri =
            'data:${a.mimeType ?? "image/png"};base64,${a.base64Data}';
        parts.add({
          'type': 'image_url',
          'image_url': {'url': dataUri},
        });
        if (a.content != null && a.content!.isNotEmpty) {
          final path =
              (a.filePath != null && a.filePath!.isNotEmpty)
                  ? a.filePath!
                  : a.name;
          parts.add({'type': 'text', 'text': '[图片: $path] ${a.content}'});
        }
      } else {
        parts.add({'type': 'text', 'text': _buildAttachmentInfo(a)});
      }
    }
    parts.add({'type': 'text', 'text': userMessage.content});
    return parts;
  }

  final infos = userMessage.attachments.map(_buildAttachmentInfo).toList();
  return '${infos.join('\n\n')}\n\n ${userMessage.content}';
}

String _buildAttachmentInfo(ChatAttachment a) {
  final buf = StringBuffer();
  const labels = {
    'image': '图片文件',
    'document': '文档文件',
    'text': '文档文件',
    'code': '代码文件',
    'web': '网页链接',
    'folder': '文件夹',
  };
  final label = labels[a.type] ?? '文件';
  final path =
      (a.filePath != null && a.filePath!.isNotEmpty) ? a.filePath! : a.name;
  buf.write('[$label: $path');
  if (a.size != null && a.size! > 0) {
    buf.write(', 大小: ${_formatFileSize(a.size!)}');
  }
  buf.write(']\n');

  if (a.content == null || a.content!.isEmpty) {
    buf.write('[文件处理中...]');
  } else if (a.content == 'ERROR_PROCESSING') {
    buf.write('[文件处理失败]');
  } else {
    buf.write(a.content!);
  }
  return buf.toString();
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}

/// 构建 MCP 服务工具列表
List<Map<String, dynamic>> buildMcpTools(ChatSession? session) {
  final tools = <Map<String, dynamic>>[];
  final mcp = session?.mcp;
  if (mcp == null || mcp.tools == null || mcp.tools!.isEmpty) return tools;

  for (final tool in mcp.tools!) {
    final safeName = tool.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (safeName != tool.name) {
      _safeNameToOriginal[safeName] = tool.name;
    }
    final schema = <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{
        'name': safeName,
        'description': tool.description,
      },
    };
    if (tool.inputSchema.isNotEmpty) {
      final s = Map<String, dynamic>.from(tool.inputSchema);
      if (!s.containsKey('type')) s['type'] = 'object';
      if (!s.containsKey('properties')) {
        s['properties'] = <String, dynamic>{};
      }
      schema['function']['parameters'] = s;
    } else {
      schema['function']['parameters'] = {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      };
    }
    tools.add(schema);
  }
  return tools;
}

/// 构建技能工具列表
List<Map<String, dynamic>> buildSkillTools(ChatSession? session) {
  final tools = <Map<String, dynamic>>[];
  if (session?.skill == null || session!.skill!.tools == null) return tools;

  for (final tool in session.skill!.tools!) {
    final safeName = tool.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (safeName != tool.name) {
      _safeNameToOriginal[safeName] = tool.name;
    }
    final schema = <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{
        'name': safeName,
        'description': tool.description,
      },
    };
    if (tool.inputSchema.isNotEmpty) {
      final s = Map<String, dynamic>.from(tool.inputSchema);
      if (!s.containsKey('type')) s['type'] = 'object';
      if (!s.containsKey('properties')) s['properties'] = <String, dynamic>{};
      schema['function']['parameters'] = s;
    } else {
      schema['function']['parameters'] = {
        'type': 'object',
        'properties': <String, dynamic>{},
        'required': <String>[],
      };
    }
    tools.add(schema);
  }
  return tools;
}

/// 构建通用系统提示词（所有模式共享部分）
List<Map<String, dynamic>> buildBaseSystemMessages({
  ChatModel? model,
  ChatSession? session,
  bool thinkEnabled = false,
  String? workDir,
}) {
  final messages = <Map<String, dynamic>>[];

  if (model?.chatSettings?.systemPrompt != null &&
      model!.chatSettings!.systemPrompt.isNotEmpty) {
    messages.add({'role': 'system', 'content': model.chatSettings!.systemPrompt});
  }

  if (session?.skill != null) {
    final sp = SkillService.buildSkillPrompt(session!.skill);
    if (sp.isNotEmpty) {
      messages.add({'role': 'system', 'content': sp});
    }
  }

  if (thinkEnabled) {
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.deepThink,
    });
  }

  if (workDir != null) {
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.workDirectory(workDir),
    });
  }

  return messages;
}
