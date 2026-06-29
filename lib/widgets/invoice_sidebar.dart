import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../storage/storage_paths.dart';
import '../storage/file_storage.dart';
import '../framework/modes/mode_utils.dart';

/// 发票模式右侧边栏内容
class InvoiceSidebar {
  /// 获取发票模式的 Tab 标题列表
  static List<String> getTabTitles() {
    return ['文件列表', '发票汇总', '发票明细', '报销记录', '备忘录'];
  }

  /// 获取 Tab 数量
  static int get tabCount => 5;

  /// 构建指定 Tab 的内容
  static Widget buildTabContent(BuildContext context, int index, String sessionId, {String? workDirectory}) {
    switch (index) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return _buildInvoiceSummaryTab(context, sessionId, workDirectory: workDirectory);
      case 2:
        return _buildInvoiceDetailTab(context, sessionId, workDirectory: workDirectory);
      case 3:
        return _buildReimbursementTab(context, sessionId, workDirectory: workDirectory);
      case 4:
        return _buildNoteTab(context, sessionId, workDirectory: workDirectory);
      default:
        return const SizedBox.shrink();
    }
  }

  /// 发票汇总 Tab
  static Widget _buildInvoiceSummaryTab(BuildContext context, String sessionId, {String? workDirectory}) {
    return _buildFileTab(context, sessionId, 'invoice_summary.md', '发票汇总', workDirectory: workDirectory);
  }

  /// 发票明细 Tab
  static Widget _buildInvoiceDetailTab(BuildContext context, String sessionId, {String? workDirectory}) {
    return _buildFileTab(context, sessionId, 'invoice_detail.md', '发票明细', workDirectory: workDirectory);
  }

  /// 报销记录 Tab
  static Widget _buildReimbursementTab(BuildContext context, String sessionId, {String? workDirectory}) {
    return _buildFileTab(context, sessionId, 'reimbursement.md', '报销记录', workDirectory: workDirectory);
  }

  /// 备忘录 Tab
  static Widget _buildNoteTab(BuildContext context, String sessionId, {String? workDirectory}) {
    return _buildFileTab(context, sessionId, 'note.md', '备忘录', workDirectory: workDirectory);
  }

  /// 通用文件 Tab
  static Widget _buildFileTab(
    BuildContext context,
    String sessionId,
    String fileName,
    String title, {
    String? workDirectory,
  }) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无$title', '在对话中提及相关信息时会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, fileName, workDirectory: workDirectory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final content = snapshot.data;
        if (content == null || content.trim().isEmpty) {
          return _buildEmptyState(context, '暂无$title', '在对话中提及相关信息时会自动记录');
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

  /// 加载文件内容：先查工作目录，再查会话目录
  static Future<String?> _loadFile(String sessionId, String fileName, {String? workDirectory}) async {
    final filePath = await findModeFile(
      sessionId: sessionId,
      workMode: 'invoice',
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
              Icons.receipt_long_outlined,
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
