import 'dart:convert';
import 'dart:io';

import 'package:llmwork/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/content_block.dart';
import '../models/chat/artifact_entry.dart';

/// 右侧边栏 — 显示当前会话的记忆内容和文件列表
class ChatRightSidebar extends StatefulWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const ChatRightSidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  State<ChatRightSidebar> createState() => _ChatRightSidebarState();
}

class _ChatRightSidebarState extends State<ChatRightSidebar>
    with SingleTickerProviderStateMixin {
  final sessionController = Get.find<SessionController>();
  late TabController _tabController;

  /// 记录展开的目录产物 ID
  final Set<String> _expandedDirs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = sessionController.currentSession.value;
      final compressedMemory = session?.compressedMemory;
      final memory = session?.memory ?? [];
      final messages = session?.messages ?? const [];

      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部Tab栏（下划线与聊天主窗口顶部栏对齐）
            _buildTabBar(context),
            // 内容区域
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 0: 文件列表
                  _buildFilesContent(context, messages),
                  // Tab 1: 会话记忆
                  compressedMemory == null && memory.isEmpty
                      ? _buildEmptyState(context)
                      : _buildMemoryContent(context, compressedMemory, memory),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        indicatorWeight: 2,
        labelColor: Theme.of(context).colorScheme.onSurface,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.35),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.files),
          Tab(text: AppLocalizations.of(context)!.memory),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 32,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.noMemory,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.asConversationContinues,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 记忆内容区域
  Widget _buildMemoryContent(
    BuildContext context,
    String? compressedMemory,
    List memory,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 压缩记忆摘要
          if (compressedMemory != null &&
              compressedMemory.trim().isNotEmpty) ...[
            _buildSectionTitle(
              context,
              AppLocalizations.of(context)!.memorySummary,
            ),
            const SizedBox(height: 6),
            _buildCompressedMemoryCard(context, compressedMemory),
            const SizedBox(height: 16),
          ],
          // 最近记忆轮次
          if (memory.isNotEmpty) ...[
            _buildSectionTitle(
              context,
              '${AppLocalizations.of(context)!.recentConversations} (${AppLocalizations.of(context)!.messageCount(memory.length.toString())})',
            ),
            const SizedBox(height: 6),
            ...memory.map((turn) => _buildMemoryTurnItem(context, turn)),
          ],
        ],
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

  /// 压缩记忆摘要卡片
  Widget _buildCompressedMemoryCard(
    BuildContext context,
    String compressedMemory,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        compressedMemory,
        style: TextStyle(
          fontSize: 11,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// 单条记忆轮次
  Widget _buildMemoryTurnItem(BuildContext context, dynamic turn) {
    final role = turn.role as String;
    final content = turn.content as String;
    final isUser = role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 角色图标
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(
                        context,
                      ).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isUser ? CupertinoIcons.person_fill : CupertinoIcons.sparkles,
              size: 11,
              color:
                  isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: 8),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUser
                      ? AppLocalizations.of(context)!.user
                      : AppLocalizations.of(context)!.assistant,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 文件 Tab 相关 ==========

  /// 文件列表内容 — 从消息中提取文件路径，智能分组为目录/单文件产物
  Widget _buildFilesContent(BuildContext context, List<ChatMessage> messages) {
    final artifacts = _extractArtifactsFromMessages(messages);

    if (artifacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc,
                size: 32,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.noFiles,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.whenAiCreatesFiles,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            context,
            '${AppLocalizations.of(context)!.sessionFiles} (${_totalFileCount(artifacts)})',
          ),
          const SizedBox(height: 8),
          ...artifacts.map((a) => _buildArtifactItem(context, a)),
        ],
      ),
    );
  }

  /// 从所有消息中提取文件路径，返回分组后的 ArtifactEntry 列表
  static List<ArtifactEntry> _extractArtifactsFromMessages(
    List<ChatMessage> messages,
  ) {
    final seen = <String>{};
    final allPaths = <String>[];

    for (final msg in messages) {
      // 1. 从 tool 类型 contentBlock 中提取（JSON 结果中的 path/filePath/outputPath）
      for (final block in msg.contentBlocks) {
        if (block.type != ContentBlockType.tool) continue;
        try {
          final decoded = jsonDecode(block.text);
          if (decoded is Map) {
            // 提取顶层路径字段
            for (final key in ['path', 'filePath', 'outputPath']) {
              final val = decoded[key];
              if (val is String && val.isNotEmpty && seen.add(val)) {
                allPaths.add(val);
              }
            }
            // 递归提取嵌套对象中的路径
            for (final entry in decoded.entries) {
              if (entry.value is Map) {
                for (final key in ['path', 'filePath', 'outputPath']) {
                  final v = (entry.value as Map)[key];
                  if (v is String && v.isNotEmpty && seen.add(v)) {
                    allPaths.add(v);
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      // 2. 从正文中提取绝对文件路径
      final allContent = msg.contentBlocks
          .where(
            (b) =>
                b.type == ContentBlockType.content ||
                b.type == ContentBlockType.tool,
          )
          .map((b) => b.text)
          .join('\n');
      for (final path in _extractFilePaths(allContent)) {
        if (seen.add(path)) {
          allPaths.add(path);
        }
      }

      // 3. 也从 msg.content / msg.think 中提取
      for (final path in _extractFilePaths(msg.content)) {
        if (seen.add(path)) {
          allPaths.add(path);
        }
      }
    }

    return ArtifactEntry.fromPaths(allPaths);
  }

  /// 从文本中提取本地绝对文件路径
  static List<String> _extractFilePaths(String text) {
    if (text.isEmpty) return [];
    final pathRegex = RegExp(
      r'(?<![(\[])(?<!file:\/{1,3})(\/(?:Users|home|tmp|var|etc|opt|srv)\/[\w./\-_\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]+\.(?:docx?|xlsx?|xls|csv|pdf|pptx?|png|jpe?g|gif|webp|bmp|tiff?|md|txt|json|html?|css|dart|py|js|ts|java|xml|yaml|yml|toml|sh|log|key|pem|crt|cer))',
      caseSensitive: false,
    );
    return pathRegex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  /// 统计总文件数
  int _totalFileCount(List<ArtifactEntry> artifacts) {
    return artifacts.fold(0, (sum, a) => sum + a.files.length);
  }

  /// 产物条目 — 支持目录和单文件两种展示
  Widget _buildArtifactItem(BuildContext context, ArtifactEntry artifact) {
    if (artifact.isDirectory) {
      return _buildDirectoryItem(context, artifact);
    }
    return _buildSingleFileItem(context, artifact.path, artifact.name);
  }

  /// 目录级产物 — 可展开查看文件列表
  Widget _buildDirectoryItem(BuildContext context, ArtifactEntry artifact) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isExpanded = _expandedDirs.contains(artifact.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 目录头
              InkWell(
                onTap: () {
                  setLocalState(() {
                    if (isExpanded) {
                      _expandedDirs.remove(artifact.id);
                    } else {
                      _expandedDirs.add(artifact.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? CupertinoIcons.folder_fill
                            : CupertinoIcons.folder,
                        size: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artifact.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (artifact.path.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                artifact.path,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 在 Finder 中打开目录
                      GestureDetector(
                        onTap: () => _openFile(artifact.path),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 展开的文件列表
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children:
                        artifact.files
                            .map(
                              (f) => _buildNestedFileItem(
                                context,
                                f,
                                f.contains('/')
                                    ? f.substring(f.lastIndexOf('/') + 1)
                                    : f,
                              ),
                            )
                            .toList(),
                  ),
                ),
                crossFadeState:
                    isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 目录内子文件条目
  Widget _buildNestedFileItem(
    BuildContext context,
    String path,
    String fileName,
  ) {
    return GestureDetector(
      onTap: () => _openFile(path),
      onDoubleTap: () => _openFileLocation(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(
              _iconForExtension(fileName),
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fileName,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 10,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ],
        ),
      ),
    );
  }

  /// 单文件产物条目
  Widget _buildSingleFileItem(
    BuildContext context,
    String path,
    String fileName,
  ) {
    return GestureDetector(
      onTap: () => _openFile(path),
      onDoubleTap: () => _openFileLocation(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconForExtension(fileName),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开本地文件
  Future<void> _openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.fileNotFound)),
          );
        }
        return;
      }
      final command =
          Platform.isWindows
              ? 'start'
              : Platform.isMacOS
              ? 'open'
              : 'xdg-open';
      final args = Platform.isWindows ? ['', filePath] : [filePath];
      await Process.run(command, args, runInShell: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.openFileFailed)),
        );
      }
    }
  }

  /// 在文件管理器中打开文件所在的文件夹
  Future<void> _openFileLocation(String path) async {
    try {
      final entity =
          FileSystemEntity.isDirectorySync(path) ? Directory(path) : File(path);

      if (!await entity.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.fileNotFound)),
          );
        }
        return;
      }

      if (Platform.isMacOS) {
        // macOS: 使用 open -R 在 Finder 中显示文件并选中
        if (entity is File) {
          await Process.run('open', ['-R', path], runInShell: true);
        } else {
          // 如果是目录，直接打开
          await Process.run('open', [path], runInShell: true);
        }
      } else if (Platform.isWindows) {
        // Windows: 使用 explorer /select, 选中文件
        if (entity is File) {
          await Process.run('explorer', ['/select,$path'], runInShell: true);
        } else {
          await Process.run('explorer', [path], runInShell: true);
        }
      } else {
        // Linux: 打开文件所在目录
        final dir = entity is File ? entity.parent.path : path;
        await Process.run('xdg-open', [dir], runInShell: true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.openFileFailed)),
        );
      }
    }
  }

  /// 根据文件扩展名返回对应图标
  IconData _iconForExtension(String fileName) {
    final ext =
        fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
            : '';
    switch (ext) {
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc_plaintext;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return CupertinoIcons.table;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
        return CupertinoIcons.photo;
      case 'pptx':
      case 'ppt':
        return CupertinoIcons.doc_richtext;
      case 'md':
      case 'txt':
        return CupertinoIcons.doc_text;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'toml':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.doc;
    }
  }
}
