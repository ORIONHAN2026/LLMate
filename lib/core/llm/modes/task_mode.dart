import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/bigmodel/chat_model.dart';
import '../../../models/chat/chat_session.dart';
import '../../../models/chat/chat_message.dart';
import '../../tools/tool_registry.dart';
import '../../../data/storage_paths.dart';
import '../../../data/file_storage.dart';
import '../common/system_prompts.dart';
import './work_mode_strategy.dart';
import './work_mode_sidebar.dart';
import './mode_utils.dart';

/// 日程模式
///
/// 只记录日程安排，包含内容、时间、描述
class TaskMode extends WorkModeStrategy {
  @override
  String get modeName => 'task';

  @override
  Future<List<Map<String, dynamic>>> buildMessages({
    required ChatModel? model,
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    final effectiveWorkDir = getEffectiveWorkDir(session);
    final modeDirPath = StoragePaths.modeDir(
      sessionId: session.sessionId,
      workMode: 'task',
      workDirectory: session.workDirectory,
    );

    messages.addAll(buildBaseSystemMessages(
      model: model,
      session: session,
      thinkEnabled: session.deepThink,
      workDir: effectiveWorkDir,
    ));

    messages.add({
      'role': 'system',
      'content': CommonSystemPrompts.taskMode(effectiveWorkDir, modeDirPath),
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

    allTools.addAll(SystemToolService.buildOpenAIToolsFormat());

    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'task_update',
          'description': '更新日程安排文件（schedule.md）。直接写入完整的日程安排内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的日程安排完整内容（Markdown 格式）。'},
            },
            'required': ['content'],
          },
        },
      },
    ]);

    allTools.addAll(buildMcpTools(session));
    allTools.addAll(buildSkillTools(session));
    return allTools;
  }
}

/// 日程模式侧边栏
class TaskModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 1; // 只算模式专属 tab

  @override
  List<String> get tabTitles => ['日程安排'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    if (index == 0) {
      return _buildScheduleTab(context, sessionId, workDirectory: workDirectory);
    }
    return const SizedBox.shrink();
  }

  /// 日程安排 Tab
  Widget _buildScheduleTab(BuildContext context, String sessionId, {String? workDirectory}) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无日程', '在对话中添加日程后会自动记录');
    }

    return FutureBuilder<String?>(
      key: ValueKey('task_schedule_${sessionId}_${workDirectory ?? ''}_'),
      future: _loadScheduleFile(sessionId, workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无日程', '在对话中添加日程后会自动记录');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '日程安排'),
              const SizedBox(height: 8),
              SelectableText(
                content.trim(),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 加载日程文件：先查工作目录，再查会话目录
  Future<String?> _loadScheduleFile(String sessionId, String? workDirectory) async {
    final filePath = await findModeFile(
      sessionId: sessionId,
      workMode: 'task',
      fileName: 'schedule.md',
      workDirectory: workDirectory,
    );
    if (filePath == null) return null;
    return FileStorage.readText(filePath);
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        letterSpacing: 0.3,
      ),
    );
  }
}
