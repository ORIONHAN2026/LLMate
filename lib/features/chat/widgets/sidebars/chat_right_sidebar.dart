import 'dart:io';

import 'package:llmwork/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import '../../../../controllers/session_controller.dart';
import '../../../../models/chat/chat_message.dart';
import '../../../../core/llm/modes/mode_sidebars.dart';
import '../../../../core/llm/modes/work_mode_sidebar.dart';
import 'session_config_sidebar.dart';

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

  /// 缓存发送期间的构建结果
  Widget? _cachedTabChildren;

  /// 获取当前会话的工作模式
  String _getWorkMode() {
    return sessionController.currentSession.value?.workMode ?? 'conversation';
  }

  /// 获取当前模式的侧边栏策略
  WorkModeSidebar _getSidebar() {
    return getSidebarByMode(_getWorkMode());
  }

  /// 获取当前模式的 Tab 数量
  /// 获取当前模式的 Tab 数量（包含文件列表和会话配置）
  int _getTabCount() => _getSidebar().tabCount + 2; // +1 for file list, +1 for session config

  /// 获取当前模式的 Tab 标题（包含文件列表和会话配置）
  List<String> _getTabTitles() => ['文件列表', ..._getSidebar().tabTitles, '会话配置'];

  TabController _getTabController() {
    final count = _getTabCount();
    final currentMode = _getWorkMode();

    // 模式变化或数量不匹配时重建 TabController
    if (_tabController == null || _tabController!.length != count || _lastTabMode != currentMode) {
      _tabController?.dispose();
      _tabController = TabController(length: count, vsync: this);
      _lastTabMode = currentMode;
    }
    return _tabController!;
  }

  String _lastTabMode = '';

  String _lastWorkMode = 'conversation';
  String? _lastWorkDirectory;

  @override
  void initState() {
    super.initState();
    // 监听会话变化，当发送状态结束、模式变化或工作目录变化时清除缓存
    ever(sessionController.currentSession, (session) {
      if (session != null) {
        final currentMode = session.workMode ?? 'conversation';
        final currentWorkDir = session.workDirectory;
        final isSending = session.isSending ?? false;

        // 模式变化、工作目录变化或发送结束时清除缓存
        if (currentMode != _lastWorkMode ||
            currentWorkDir != _lastWorkDirectory ||
            !isSending) {
          _lastWorkMode = currentMode;
          _lastWorkDirectory = currentWorkDir;
          if (_cachedTabChildren != null) {
            setState(() {
              _cachedTabChildren = null;
            });
          }
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

      // 如果正在发送消息，使用缓存的数据，不重新构建
      if (isSending && _cachedTabChildren != null) {
        return _cachedTabChildren!;
      }

      final messages = session?.messages ?? const [];
      final sessionId = session?.sessionId ?? '';
      final workDirectory = session?.workDirectory;

      final tabChildren = <Widget>[
        // Tab 0: 文件列表
        _buildFilesContent(context, messages),
      ];

      // 从策略获取模式专属 Tab 内容（文件列表已单独添加）
      final sidebar = _getSidebar();
      for (int i = 0; i < sidebar.tabCount; i++) {
        tabChildren.add(sidebar.buildTabContent(context, i, sessionId, workDirectory: workDirectory));
      }
      
      // 添加会话配置 Tab
      tabChildren.add(SessionConfigSidebar.buildTabContent(context));

      final result = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部Tab栏
            _buildTabBar(context),
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

  Widget _buildTabBar(BuildContext context) {
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

  /// 记忆内容区域
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
      future: _listWorkDirFiles(_resolveDirPath(workDir)),
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
        final tree = _buildFileTree(files, _resolveDirPath(workDir));

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

  /// 获取实际的目录路径（如果是文件则返回父目录）
  String _resolveDirPath(String workDir) {
    if (FileSystemEntity.isFileSync(workDir)) {
      return p.dirname(workDir);
    }
    return workDir;
  }

  /// 列出工作目录下的文件（递归）
  Future<List<FileSystemEntity>> _listWorkDirFiles(String workDir) async {
    try {
      final dirPath = _resolveDirPath(workDir);
      final dir = Directory(dirPath);
      if (!await dir.exists()) return [];
      final list = await dir.list(recursive: true).toList();
      // 过滤掉隐藏文件和常见忽略目录
      final filtered = list.where((entity) {
        final relativePath = entity.path.substring(dirPath.length + 1);
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
}
