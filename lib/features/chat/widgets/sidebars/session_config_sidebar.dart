import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../models/chat/chat_session.dart';

/// 会话配置侧边栏内容
class SessionConfigSidebar {
  /// 构建会话配置 Tab 的内容
  static Widget buildTabContent(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    
    return Obx(() {
      final session = sessionController.currentSession.value;
      if (session == null) {
        return _buildEmptyState(context);
      }
      
      return _buildConfigContent(context, session);
    });
  }

  /// 构建空状态
  static Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.settings,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无会话配置',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '请先选择或创建一个会话',
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

  /// 构建配置内容
  static Widget _buildConfigContent(BuildContext context, ChatSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, '会话配置'),
          const SizedBox(height: 12),
          
          // 基础信息
          _buildConfigItem(
            context,
            icon: CupertinoIcons.chat_bubble,
            label: '会话名称',
            value: session.name,
          ),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.smiley,
            label: '会话图标',
            value: session.emoji,
          ),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.calendar,
            label: '创建时间',
            value: _formatDateTime(session.createdAt),
          ),
          const SizedBox(height: 12),
          
          // 模型配置
          _buildSectionTitle(context, '模型配置'),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.globe,
            label: '绑定模型',
            value: session.chatModel?.name ?? '未设置',
            valueColor: session.chatModel != null 
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.lightbulb,
            label: '深度思考',
            value: session.deepThink ? '已开启' : '已关闭',
            valueColor: session.deepThink 
                ? Colors.green 
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          
          // 工作配置
          _buildSectionTitle(context, '工作配置'),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.folder,
            label: '工作目录',
            value: session.workDirectory ?? '未设置',
            maxLines: 2,
            valueColor: session.workDirectory != null 
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(height: 8),
          
          _buildCopyableConfigItem(
            context,
            icon: CupertinoIcons.link,
            label: '服务地址',
            value: 'http://127.0.0.1:8899/${session.sessionId}/v1',
          ),
          const SizedBox(height: 12),
          
          // 功能配置
          _buildSectionTitle(context, '功能配置'),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.link,
            label: 'MCP连接器',
            value: session.mcp?.name ?? '未绑定',
            valueColor: session.mcp != null 
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(height: 8),
          
          const SizedBox(height: 12),
          
          // 关联提示词
          if (session.connectPrompt != null && session.connectPrompt!.isNotEmpty) ...[
            _buildSectionTitle(context, '关联提示词'),
            const SizedBox(height: 8),
            _buildPromptCard(context, session.connectPrompt!),
          ],
          
          // 统计信息
          _buildSectionTitle(context, '统计信息'),
          const SizedBox(height: 8),
          _buildConfigItem(
            context,
            icon: CupertinoIcons.chat_bubble_2,
            label: '消息数量',
            value: '${session.messages.length}条',
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 12),
          
          // 计费信息
          _buildSectionTitle(context, '计费信息'),
          const SizedBox(height: 8),
          _buildConfigItem(
            context,
            icon: CupertinoIcons.arrow_down_circle,
            label: '累计输入Token',
            value: _formatTokenCount(session.totalInputTokens),
            valueColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildConfigItem(
            context,
            icon: CupertinoIcons.arrow_up_circle,
            label: '累计输出Token',
            value: _formatTokenCount(session.totalOutputTokens),
            valueColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildConfigItem(
            context,
            icon: CupertinoIcons.money_dollar_circle,
            label: '累计费用',
            value: '\$${session.totalCost.toStringAsFixed(6)}',
            valueColor: session.totalCost > 0 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface,
          ),
          if (session.chatModel?.inputPrice != null || session.chatModel?.outputPrice != null) ...[
            const SizedBox(height: 8),
            _buildPriceCard(
              context,
              inputPrice: session.chatModel?.inputPrice,
              outputPrice: session.chatModel?.outputPrice,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 构建配置项
  static Widget _buildConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可复制的配置项（点击复制到剪贴板）
  static Widget _buildCopyableConfigItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已复制到剪贴板'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.doc_on_doc,
              size: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建提示词卡片
  static Widget _buildPromptCard(BuildContext context, String prompt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 12,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '连接器和技能的关联描述',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prompt,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建区域标题
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

  /// 格式化日期时间
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化Token数量
  static String _formatTokenCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(2)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  /// 构建价格卡片
  static Widget _buildPriceCard(
    BuildContext context, {
    double? inputPrice,
    double? outputPrice,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle,
                size: 12,
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                '模型定价（美元/百万Token）',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (inputPrice != null)
            Text(
              '输入: \$${inputPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (inputPrice != null && outputPrice != null)
            const SizedBox(height: 4),
          if (outputPrice != null)
            Text(
              '输出: \$${outputPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}