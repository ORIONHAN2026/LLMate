import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../data/file_storage.dart';
import '../../../../core/llm/modes/mode_utils.dart';

/// 合同模式右侧边栏内容
class ContractSidebar {
  /// 获取合同模式的 Tab 标题列表
  static List<String> getTabTitles() {
    return ['文件列表', '合约要点', '合同履约', '合同争议', '备忘录'];
  }

  /// 获取 Tab 数量
  static int get tabCount => 5;

  /// 构建指定 Tab 的内容
  static Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    switch (index) {
      case 0:
        return _buildFilesTab(context);
      case 1:
        return _buildContractPointsTab(context, sessionId, workDirectory: workDirectory);
      case 2:
        return _buildContractFileTab(context, sessionId, 'contract_process.md', '合同履约', workDirectory: workDirectory);
      case 3:
        return _buildContractFileTab(context, sessionId, 'contract_disguss.md', '合同争议', workDirectory: workDirectory);
      case 4:
        return _buildContractFileTab(context, sessionId, 'note.md', '备忘录', workDirectory: workDirectory);
      default:
        return _buildFilesTab(context);
    }
  }

  /// 文件列表 Tab（由主侧边栏提供，这里返回空占位）
  static Widget _buildFilesTab(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// 合约要点 Tab（从文件读取）
  static Widget _buildContractPointsTab(BuildContext context, String sessionId, {String? workDirectory}) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无合约要点', '在对话中解析合同后会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, 'contract_content.md', workDirectory: workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无合约要点', '在对话中解析合同后会自动记录');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '合约要点'),
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
                  tableBody: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tableHead: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 合同文件 Tab（履约/争议/备忘录）
  static Widget _buildContractFileTab(
    BuildContext context,
    String sessionId,
    String fileName,
    String title, {
    String? workDirectory,
  }) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无$title记录', '在对话中提及相关信息时会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, fileName, workDirectory: workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无$title记录', '在对话中提及相关信息时会自动记录');
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

  /// 加载文件内容
  /// 加载文件内容：先查工作目录，再查会话目录
  static Future<String?> _loadFile(String sessionId, String fileName, {String? workDirectory}) async {
    final filePath = await findModeFile(
      sessionId: sessionId,
      workMode: 'contract',
      fileName: fileName,
      workDirectory: workDirectory,
    );
    if (filePath == null) return null;
    return FileStorage.readText(filePath);
  }

  /// 空状态
  static Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
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

  /// 章节标题
  static Widget _buildSectionTitle(BuildContext context, String title) {
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
