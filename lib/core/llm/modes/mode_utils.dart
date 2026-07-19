import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../models/model.dart';
import '../../../models/chat/session.dart';
import '../../../models/chat/message.dart';
import '../../../models/chat/mcp.dart';
import '../../../controllers/mcp_controller.dart';

import '../../../services/storage_paths.dart';
import '../common/system_prompts.dart';

/// 安全函数名 → 原始函数名 映射（用于还原 MCP 工具名中的非法字符）
final Map<String, String> _safeNameToOriginal = {};

/// 根据安全名称还原原始工具名；若未映射则原样返回
String resolveOriginalToolName(String safeName) {
  return _safeNameToOriginal[safeName] ?? safeName;
}

/// 加载聊天室模式的所有角色上下文
Future<List<String>> loadRoleContexts(String sessionId, {String? workDirectory}) async {
  final rolesDirPath = StoragePaths.rolesDir(
    sessionId: sessionId,
    workDirectory: workDirectory,
  );
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

/// 获取有效的工作目录（使用会话目录）
String getEffectiveWorkDir(ChatSession session) {
  return StoragePaths.sessionDir(session.sessionId);
}

/// 查找模式文件：先查工作目录，再查会话目录
///
/// 返回找到的文件路径，如果都没找到返回 null
Future<String?> findModeFile({
  required String sessionId,
  required String workMode,
  required String fileName,
  String? workDirectory,
}) async {
  // 1. 先查工作目录
  if (workDirectory != null && workDirectory.isNotEmpty) {
    final workPath = '${StoragePaths.modeDir(sessionId: sessionId, workMode: workMode, workDirectory: workDirectory)}/$fileName';
    debugPrint('🔍 查找工作目录文件: $workPath');
    if (await File(workPath).exists()) {
      debugPrint('✅ 找到文件: $workPath');
      return workPath;
    }
    debugPrint('❌ 工作目录文件不存在: $workPath');
  }

  // 2. 再查会话目录
  final sessionPath = '${StoragePaths.modeDir(sessionId: sessionId, workMode: workMode)}/$fileName';
  debugPrint('🔍 查格會话目录文件: $sessionPath');
  if (await File(sessionPath).exists()) {
    debugPrint('✅ 找到文件: $sessionPath');
    return sessionPath;
  }
  debugPrint('❌ 会话目录文件不存在: $sessionPath');

  return null;
}

/// 查找模式目录下的文件列表
///
/// 先查工作目录，再查会话目录
Future<List<FileSystemEntity>> findModeFiles({
  required String sessionId,
  required String workMode,
  String? workDirectory,
}) async {
  // 1. 先查工作目录
  if (workDirectory != null && workDirectory.isNotEmpty) {
    final workDir = StoragePaths.modeDir(sessionId: sessionId, workMode: workMode, workDirectory: workDirectory);
    if (await Directory(workDir).exists()) {
      final files = await Directory(workDir).list(recursive: true).toList();
      if (files.any((e) => e is File)) {
        return files;
      }
    }
  }

  // 2. 再查会话目录
  final sessionDir = StoragePaths.modeDir(sessionId: sessionId, workMode: workMode);
  if (await Directory(sessionDir).exists()) {
    return await Directory(sessionDir).list(recursive: true).toList();
  }

  return [];
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

  for (final msg in historyMessages) {
    if (msg.content.isEmpty) continue;
    final apiRole = _toOpenAIRole(msg.role);
    if (apiRole == null) continue;

    if (msg.role == MessageRole.user) {
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
  return userMessage.content;
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
}

/// 构建 MCP 服务工具列表（合并 session MCP + model MCP，去重）
List<Map<String, dynamic>> buildMcpTools(ChatSession? session) {
  final tools = <Map<String, dynamic>>[];
  if (session == null) return tools;

  final allTools = McpController.instance.getMergedTools(session);
  if (allTools.isEmpty) return tools;

  for (final tool in allTools) {
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

/// 构建通用系统提示词（所有模式共享部分）
List<Map<String, dynamic>> buildBaseSystemMessages({
  ChatModel? model,
  ChatSession? session,
  bool thinkEnabled = false,
}) {
  final messages = <Map<String, dynamic>>[];

  if (model?.systemPrompt != null && model!.systemPrompt!.isNotEmpty) {
    messages.add({
      'role': 'system',
      'name': 'model_system_prompt',
      'content':
          '[MODEL SYSTEM PROMPT] This is the highest-priority instruction. In any conflict with other instructions (including the session system prompt), this prompt takes precedence.\n\n${model.systemPrompt}',
    });
  }

  // 会话级系统提示词（若设置，作为会话级指令注入；与模型提示词冲突时以模型为准）
  if (session?.systemPrompt != null && session!.systemPrompt!.isNotEmpty) {
    messages.add({
      'role': 'system',
      'name': 'session_system_prompt',
      'content':
          '[SESSION SYSTEM PROMPT] This is a session-level instruction. If it conflicts with the model system prompt, the model system prompt takes precedence.\n\n${session.systemPrompt}',
    });
  }

  if (thinkEnabled) {
    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.deepThink,
    });
  }

  return messages;
}
