import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import '../../models/bigmodel/chat_model.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/mindmap_node.dart';
import '../../widgets/mindmap_widget.dart';
import '../../services/system_tool_service.dart';
import '../../storage/storage_paths.dart';
import '../../storage/file_storage.dart';
import '../common/system_prompts.dart';
import 'work_mode_strategy.dart';
import 'work_mode_sidebar.dart';
import 'mode_utils.dart';

/// 创意模式
///
/// 系统提示词：通用提示词 + 创意专用流程提示词
/// 工具：脑图工具 + 灵感笔记 + 文件写入 + MCP + Skill
/// 侧边栏：灵感、脑图、草稿
class CreativeMode extends WorkModeStrategy {
  @override
  String get modeName => 'creative';

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
      workMode: 'creative',
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
      'content': CommonSystemPrompts.creativeMode(effectiveWorkDir, modeDirPath),
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

    // 创意模式专属工具
    allTools.addAll([
      {
        'type': 'function',
        'function': {
          'name': 'mindmap_update',
          'description': '更新脑图文件（mindmap.md）。使用 JSON 格式存储脑图数据，支持多层嵌套节点。直接写入完整的脑图 JSON 内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '脑图 JSON 数据。格式：{"title":"主题","children":[{"title":"分支","children":[{"title":"子节点"}]}]}'},
            },
            'required': ['content'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'note_update',
          'description': '更新灵感笔记文件（note.md）。直接写入完整的灵感笔记内容，无需指定文件路径。文件会自动保存到当前会话的工作目录下。',
          'parameters': {
            'type': 'object',
            'properties': {
              'content': {'type': 'string', 'description': '要写入的灵感笔记完整内容（Markdown 格式）。'},
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

/// 创意模式侧边栏
class CreativeModeSidebar extends WorkModeSidebar {
  @override
  int get tabCount => 3;

  @override
  List<String> get tabTitles => ['灵感', '脑图', '草稿'];

  @override
  Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    switch (index) {
      case 0:
        return _buildInspirationTab(context, sessionId, workDirectory: workDirectory);
      case 1:
        return _buildMindmapTab(context, sessionId, workDirectory: workDirectory);
      case 2:
        return _buildDraftsTab(context, sessionId, workDirectory: workDirectory);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 灵感笔记 Tab
  Widget _buildInspirationTab(BuildContext context, String sessionId, {String? workDirectory}) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无灵感', '在对话中记录灵感后会自动保存');
    }

    return FutureBuilder<String?>(
      key: ValueKey('inspiration_${sessionId}_'),
      future: _loadFile(sessionId, 'note.md', workDirectory: workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无灵感', '在对话中记录灵感后会自动保存');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '灵感笔记'),
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

  /// 脑图 Tab
  Widget _buildMindmapTab(BuildContext context, String sessionId, {String? workDirectory}) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无脑图', '在对话中创建脑图后会自动显示');
    }

    return FutureBuilder<String?>(
      key: ValueKey('mindmap_${sessionId}_'),
      future: _loadFile(sessionId, 'mindmap.md', workDirectory: workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无脑图', '在对话中创建脑图后会自动显示');
        }

        try {
          final json = jsonDecode(content.trim()) as Map<String, dynamic>;
          final root = MindMapNode.fromJson(json);
          return MindMapWidget(root: root);
        } catch (e) {
          return _buildEmptyState(context, '脑图格式错误', 'JSON 解析失败: $e');
        }
      },
    );
  }

  /// 草稿列表 Tab
  Widget _buildDraftsTab(BuildContext context, String sessionId, {String? workDirectory}) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无草稿', '在对话中创作后会自动保存');
    }

    final draftsDirPath = StoragePaths.draftsDir(
      sessionId: sessionId,
      workDirectory: workDirectory,
    );

    return FutureBuilder<List<_DraftInfo>>(
      key: ValueKey('drafts_${sessionId}_'),
      future: _loadDrafts(draftsDirPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final drafts = snapshot.data ?? [];
        if (drafts.isEmpty) {
          return _buildEmptyState(context, '暂无草稿', '在对话中创作后会自动保存');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '草稿列表 (${drafts.length})'),
              const SizedBox(height: 8),
              ...drafts.map((draft) => _buildDraftCard(context, draft)),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _loadFile(String sessionId, String fileName, {String? workDirectory}) async {
    final path = '${StoragePaths.modeDir(sessionId: sessionId, workMode: 'creative', workDirectory: workDirectory)}/$fileName';
    return FileStorage.readText(path);
  }

  Future<List<_DraftInfo>> _loadDrafts(String draftsDir) async {
    final dir = Directory(draftsDir);
    if (!await dir.exists()) return [];

    final drafts = <_DraftInfo>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final fileName = p.basenameWithoutExtension(entity.path);
        final content = await FileStorage.readText(entity.path);
        if (content != null && content.trim().isNotEmpty) {
          // 从文件头提取标题
          final titleMatch = RegExp(r'^# (.+)$', multiLine: true).firstMatch(content);
          final title = titleMatch?.group(1) ?? fileName;
          drafts.add(_DraftInfo(
            name: fileName,
            title: title,
            content: content,
            path: entity.path,
          ));
        }
      }
    }

    drafts.sort((a, b) => b.path.compareTo(a.path));
    return drafts;
  }

  Widget _buildDraftCard(BuildContext context, _DraftInfo draft) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  draft.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            draft.content
                .replaceAll(RegExp(r'^# .+$', multiLine: true), '')
                .trim()
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .take(5)
                .join('\n'),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
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

class _DraftInfo {
  final String name;
  final String title;
  final String content;
  final String path;

  _DraftInfo({
    required this.name,
    required this.title,
    required this.content,
    required this.path,
  });
}
