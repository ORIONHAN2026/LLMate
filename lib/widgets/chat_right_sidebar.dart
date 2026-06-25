import 'dart:convert';
import 'dart:io';

import 'package:llmwork/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/content_block.dart';
import '../models/chat/artifact_entry.dart';
import '../models/chat/contract_info.dart';
import '../storage/isar_service.dart';
import '../storage/file_storage.dart';
import 'contract_sidebar.dart';
import 'invoice_sidebar.dart';

/// 文件树节点
class _FileTreeNode {
  final String name;
  final String fullPath;
  final bool isDirectory;
  final List<_FileTreeNode> children = [];
  bool isExpanded;

  _FileTreeNode({
    required this.name,
    required this.fullPath,
    required this.isDirectory,
    this.isExpanded = false,
  });
}

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
    with TickerProviderStateMixin {
  final sessionController = Get.find<SessionController>();
  TabController? _tabController;

  /// 记录展开的目录产物 ID
  final Set<String> _expandedDirs = {};

  /// 缓存发送期间的构建结果
  Widget? _cachedTabChildren;

  /// 获取当前会话的工作模式
  String _getWorkMode() {
    return sessionController.currentSession.value?.workMode ?? 'conversation';
  }

  /// 获取当前模式的 Tab 数量
  int _getTabCount() {
    final mode = _getWorkMode();
    switch (mode) {
      case 'contract':
        return ContractSidebar.tabCount;
      case 'invoice':
        return InvoiceSidebar.tabCount;
      default:
        return 1;
    }
  }

  /// 获取当前模式的 Tab 标题
  List<String> _getTabTitles() {
    final mode = _getWorkMode();
    switch (mode) {
      case 'contract':
        return ContractSidebar.getTabTitles();
      case 'invoice':
        return InvoiceSidebar.getTabTitles();
      default:
        return ['文件列表'];
    }
  }

  TabController _getTabController() {
    final count = _getTabCount();
    if (_tabController == null || _tabController!.length != count) {
      _tabController?.dispose();
      _tabController = TabController(length: count, vsync: this);
    }
    return _tabController!;
  }

  @override
  void initState() {
    super.initState();
    // 监听会话变化，当发送状态结束时清除缓存
    ever(sessionController.currentSession, (session) {
      if (session != null && !(session.isSending ?? false)) {
        // 发送结束，清除缓存以便下次重建
        if (_cachedTabChildren != null) {
          setState(() {
            _cachedTabChildren = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = sessionController.currentSession.value;
      final isSending = session?.isSending ?? false;
      final workMode = session?.workMode ?? 'conversation';
      final isSpecialMode = workMode == 'contract' || workMode == 'invoice';

      // 如果正在发送消息，使用缓存的数据，不重新构建
      if (isSending && _cachedTabChildren != null) {
        return _cachedTabChildren!;
      }

      final messages = session?.messages ?? const [];
      final contracts = session?.contracts ?? [];
      final sessionId = session?.sessionId ?? '';

      // 动态调整 tab 数量
      final currentTabCount = _getTabCount();

      final tabChildren = <Widget>[
        // Tab 0: 文件列表
        _buildFilesContent(context, messages),
      ];

      // 根据模式添加对应的 Tab 内容
      if (workMode == 'contract') {
        for (int i = 1; i < ContractSidebar.tabCount; i++) {
          tabChildren.add(ContractSidebar.buildTabContent(context, i, sessionId, contracts));
        }
      } else if (workMode == 'invoice') {
        for (int i = 1; i < InvoiceSidebar.tabCount; i++) {
          tabChildren.add(InvoiceSidebar.buildTabContent(context, i, sessionId));
        }
      }

      final result = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部Tab栏
            _buildTabBar(context, isSpecialMode),
            // 内容区域
            Expanded(
              child: TabBarView(
                controller: _getTabController(),
                children: tabChildren,
              ),
            ),
          ],
        ),
      );

      // 缓存构建结果
      _cachedTabChildren = result;

      return result;
    });
  }

  Widget _buildTabBar(BuildContext context, bool isSpecialMode) {
    final tabTitles = _getTabTitles();
    final tabs = tabTitles.map((title) => Tab(text: title)).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _getTabController(),
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
        tabs: tabs,
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
    final session = sessionController.currentSession.value;
    final workDir = session?.workDirectory;

    if (workDir == null || workDir.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.folder,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                '未设置工作目录',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '请先在输入框中设置工作目录',
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

    return FutureBuilder<List<FileSystemEntity>>(
      future: _listWorkDirFiles(workDir),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.doc,
                    size: 32,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.noFiles,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 构建文件树
        final tree = _buildFileTree(files, workDir);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                context,
                '${AppLocalizations.of(context)!.sessionFiles} (${files.length})',
              ),
              const SizedBox(height: 4),
              Text(
                workDir,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ..._buildTreeWidgets(context, tree, workDir),
            ],
          ),
        );
      },
    );
  }

  /// 列出工作目录下的文件（递归）
  Future<List<FileSystemEntity>> _listWorkDirFiles(String workDir) async {
    try {
      final dir = Directory(workDir);
      if (!await dir.exists()) return [];
      final list = await dir.list(recursive: true).toList();
      // 过滤掉隐藏文件和常见忽略目录
      final filtered = list.where((entity) {
        final relativePath = entity.path.substring(workDir.length + 1);
        // 跳过隐藏文件和常见忽略目录
        if (relativePath.startsWith('.') || 
            relativePath.contains('/.') ||
            relativePath.contains('node_modules') ||
            relativePath.contains('.git') ||
            relativePath.contains('build') ||
            relativePath.contains('.dart_tool')) {
          return false;
        }
        return true;
      }).toList();
      // 按路径排序
      filtered.sort((a, b) => a.path.compareTo(b.path));
      return filtered;
    } catch (_) {
      return [];
    }
  }

  /// 构建文件树
  List<_FileTreeNode> _buildFileTree(List<FileSystemEntity> files, String workDir) {
    final Map<String, _FileTreeNode> dirMap = {};
    final List<_FileTreeNode> roots = [];

    for (final entity in files) {
      final relativePath = entity.path.substring(workDir.length + 1);
      final parts = relativePath.split('/');
      
      // 处理目录
      String currentPath = workDir;
      _FileTreeNode? parentDir;
      
      for (int i = 0; i < parts.length - 1; i++) {
        currentPath = '$currentPath/${parts[i]}';
        if (!dirMap.containsKey(currentPath)) {
          final dirNode = _FileTreeNode(
            name: parts[i],
            fullPath: currentPath,
            isDirectory: true,
            isExpanded: true, // 默认展开
          );
          dirMap[currentPath] = dirNode;
          
          if (parentDir == null) {
            roots.add(dirNode);
          } else {
            parentDir.children.add(dirNode);
          }
        }
        parentDir = dirMap[currentPath]!;
      }
      
      // 处理文件
      final fileName = parts.last;
      final fileNode = _FileTreeNode(
        name: fileName,
        fullPath: entity.path,
        isDirectory: false,
      );
      
      if (parentDir == null) {
        roots.add(fileNode);
      } else {
        parentDir.children.add(fileNode);
      }
    }

    return roots;
  }

  /// 构建树形 Widget 列表
  List<Widget> _buildTreeWidgets(BuildContext context, List<_FileTreeNode> nodes, String workDir, {int depth = 0}) {
    final widgets = <Widget>[];
    
    for (final node in nodes) {
      widgets.add(_buildTreeNodeWidget(context, node, workDir, depth));
      
      if (node.isDirectory && node.isExpanded && node.children.isNotEmpty) {
        widgets.addAll(_buildTreeWidgets(context, node.children, workDir, depth: depth + 1));
      }
    }
    
    return widgets;
  }

  /// 构建单个树节点 Widget
  Widget _buildTreeNodeWidget(BuildContext context, _FileTreeNode node, String workDir, int depth) {
    final isDir = node.isDirectory;
    final icon = isDir 
        ? (node.isExpanded ? CupertinoIcons.folder_open : CupertinoIcons.folder)
        : _getFileIcon(node.name);
    
    // 计算缩进
    final indent = depth * 16.0;

    return InkWell(
      onTap: () {
        if (isDir) {
          setState(() {
            node.isExpanded = !node.isExpanded;
          });
        } else {
          // 打开文件
          Process.run('open', [node.fullPath]);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: EdgeInsets.only(left: 8 + indent, right: 8, top: 6, bottom: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (isDir)
              Icon(
                node.isExpanded 
                    ? CupertinoIcons.chevron_down 
                    : CupertinoIcons.chevron_right,
                size: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            if (isDir) const SizedBox(width: 4),
            Icon(
              icon,
              size: 14,
              color: isDir 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDir ? FontWeight.w500 : FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据文件扩展名返回图标
  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'docx':
      case 'doc':
        return CupertinoIcons.doc_text;
      case 'xlsx':
      case 'xls':
      case 'csv':
        return CupertinoIcons.doc_text;
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'pptx':
      case 'ppt':
        return CupertinoIcons.doc_text;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return CupertinoIcons.photo;
      case 'md':
      case 'txt':
        return CupertinoIcons.doc_plaintext;
      case 'json':
      case 'yaml':
      case 'yml':
        return CupertinoIcons.doc;
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
        return CupertinoIcons.device_laptop;
      default:
        return CupertinoIcons.doc;
    }
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

  // ========== 合约要点 Tab 相关 ==========

  /// 合约要点内容
  Widget _buildContractPointsContent(
    BuildContext context,
    List<ContractInfo> contracts,
  ) {
    if (contracts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc_checkmark,
                size: 32,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.noContracts,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.contractParsing,
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
            '${AppLocalizations.of(context)!.contractPoints} (${contracts.length})',
          ),
          const SizedBox(height: 8),
          ...contracts.map((c) => _buildContractCard(context, c)),
        ],
      ),
    );
  }

  /// 合同履约/争议 — 从 markdown 文件读取内容展示
  Widget _buildContractFileContent(
    BuildContext context,
    String sessionId,
    String fileName,
    String title,
  ) {
    if (sessionId.isEmpty) {
      return _buildContractFileEmpty(context, title);
    }

    return FutureBuilder<String?>(
      future: _loadContractFile(sessionId, fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildContractFileEmpty(context, title);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, title),
              const SizedBox(height: 8),
              MarkdownBody(
                data: content.trim(),
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h1: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h2: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h3: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  listBullet: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  code: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  blockquote: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Colors.grey[400]!, width: 4)),
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _loadContractFile(String sessionId, String fileName) async {
    final path = '${StoragePaths.sessionDir(sessionId)}/$fileName';
    return FileStorage.readText(path);
  }

  Widget _buildContractFileEmpty(BuildContext context, String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无$title记录',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '在对话中提及相关信息时会自动记录',
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

  /// 单个合同卡片
  Widget _buildContractCard(BuildContext context, ContractInfo contract) {
    final loc = AppLocalizations.of(context)!;
    final hasParties = contract.parties.isNotEmpty;
    final hasDates =
        contract.startDate != null ||
        contract.endDate != null ||
        contract.signingDate != null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 合同名称
          Row(
            children: [
              Icon(
                CupertinoIcons.doc_plaintext,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  contract.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 合同类型
          if (contract.contractType != null) ...[
            _buildContractField(
              context,
              loc.contractTypeLabel,
              contract.contractType!,
            ),
            const SizedBox(height: 6),
          ],

          // 签署方
          if (hasParties) ...[
            _buildContractSectionLabel(context, loc.contractParty),
            const SizedBox(height: 4),
            ...contract.parties.map(
              (p) => _buildPartyItem(context, p),
            ),
            const SizedBox(height: 6),
          ],

          // 收支条款
          if (contract.paymentClause != null) ...[
            _buildContractField(
              context,
              loc.contractPaymentClause,
              contract.paymentClause!,
            ),
            const SizedBox(height: 6),
          ],

          // 收支计划
          if (contract.paymentSchedule != null) ...[
            _buildContractField(
              context,
              loc.contractPaymentSchedule,
              contract.paymentSchedule!,
            ),
            const SizedBox(height: 6),
          ],

          // 违约条款
          if (contract.breachClause != null) ...[
            _buildContractField(
              context,
              loc.contractBreachClause,
              contract.breachClause!,
            ),
            const SizedBox(height: 6),
          ],

          // 违约责任
          if (contract.liabilityClause != null) ...[
            _buildContractField(
              context,
              loc.contractLiability,
              contract.liabilityClause!,
            ),
            const SizedBox(height: 6),
          ],

          // 合同期限 & 签订日期
          if (hasDates) ...[
            _buildContractSectionLabel(context, loc.contractPeriod),
            const SizedBox(height: 4),
            if (contract.startDate != null)
              _buildDateRow(context, loc.contractPeriod, contract.startDate!),
            if (contract.endDate != null) ...[
              const SizedBox(height: 2),
              _buildDateRow(context, '→', contract.endDate!),
            ],
            if (contract.signingDate != null) ...[
              const SizedBox(height: 2),
              _buildDateRow(
                context,
                loc.contractSigningDate,
                contract.signingDate!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// 合约字段标签+值
  Widget _buildContractField(
    BuildContext context,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// 合约小节标签
  Widget _buildContractSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  /// 签署方条目
  Widget _buildPartyItem(BuildContext context, ContractParty party) {
    final detail = StringBuffer(party.name);
    if (party.contact != null && party.contact!.isNotEmpty) {
      detail.write(' · ${party.contact}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              party.role,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              detail.toString(),
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日期行
  Widget _buildDateRow(BuildContext context, String label, String date) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          date,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
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
