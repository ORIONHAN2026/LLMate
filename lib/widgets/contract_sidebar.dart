import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as p;
import '../models/chat/contract_info.dart';
import '../storage/storage_paths.dart';
import '../storage/file_storage.dart';

/// 合同模式右侧边栏内容
class ContractSidebar {
  /// 获取合同模式的 Tab 标题列表
  static List<String> getTabTitles() {
    return ['文件列表', '合约要点', '合同履约', '合同争议', '备忘录'];
  }

  /// 获取 Tab 数量
  static int get tabCount => 5;

  /// 构建指定 Tab 的内容
  static Widget buildTabContent(BuildContext context, int index, String sessionId) {
    switch (index) {
      case 0:
        return _buildFilesTab(context);
      case 1:
        return _buildContractPointsTab(context, sessionId);
      case 2:
        return _buildContractFileTab(context, sessionId, 'contract_process.md', '合同履约');
      case 3:
        return _buildContractFileTab(context, sessionId, 'contract_disguss.md', '合同争议');
      case 4:
        return _buildContractFileTab(context, sessionId, 'note.md', '备忘录');
      default:
        return _buildFilesTab(context);
    }
  }

  /// 文件列表 Tab（由主侧边栏提供，这里返回空占位）
  static Widget _buildFilesTab(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// 合约要点 Tab（从文件读取）
  static Widget _buildContractPointsTab(BuildContext context, String sessionId) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无合约要点', '在对话中解析合同后会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, 'contract_content.md'),
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
    String title,
  ) {
    if (sessionId.isEmpty) {
      return _buildEmptyState(context, '暂无$title记录', '在对话中提及相关信息时会自动记录');
    }

    return FutureBuilder<String?>(
      future: _loadFile(sessionId, fileName),
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
  static Future<String?> _loadFile(String sessionId, String fileName) async {
    final path = '${StoragePaths.sessionDir(sessionId)}/$fileName';
    return FileStorage.readText(path);
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

  /// 单个合同卡片
  static Widget _buildContractCard(BuildContext context, ContractInfo contract) {
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
            _buildField(context, '合同类型', contract.contractType!),
            const SizedBox(height: 6),
          ],

          // 签署方
          if (hasParties) ...[
            _buildSectionLabel(context, '签署方'),
            const SizedBox(height: 4),
            ...contract.parties.map((p) => _buildPartyItem(context, p)),
            const SizedBox(height: 6),
          ],

          // 收支条款
          if (contract.paymentClause != null) ...[
            _buildField(context, '收支条款', contract.paymentClause!),
            const SizedBox(height: 6),
          ],

          // 支付计划
          if (contract.paymentSchedule != null) ...[
            _buildField(context, '支付计划', contract.paymentSchedule!),
            const SizedBox(height: 6),
          ],

          // 违约条款
          if (contract.breachClause != null) ...[
            _buildField(context, '违约条款', contract.breachClause!),
            const SizedBox(height: 6),
          ],

          // 违约责任
          if (contract.liabilityClause != null) ...[
            _buildField(context, '违约责任', contract.liabilityClause!),
            const SizedBox(height: 6),
          ],

          // 合同期限 & 签订日期
          if (hasDates) ...[
            _buildSectionLabel(context, '合同期限'),
            const SizedBox(height: 4),
            if (contract.startDate != null)
              _buildDateRow(context, '起始', contract.startDate!),
            if (contract.endDate != null) ...[
              const SizedBox(height: 2),
              _buildDateRow(context, '→', contract.endDate!),
            ],
            if (contract.signingDate != null) ...[
              const SizedBox(height: 2),
              _buildDateRow(context, '签订日期', contract.signingDate!),
            ],
          ],
        ],
      ),
    );
  }

  /// 字段标签+值
  static Widget _buildField(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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

  /// 小节标签
  static Widget _buildSectionLabel(BuildContext context, String label) {
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
  static Widget _buildPartyItem(BuildContext context, ContractParty party) {
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
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
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
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日期行
  static Widget _buildDateRow(BuildContext context, String label, String date) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
}
