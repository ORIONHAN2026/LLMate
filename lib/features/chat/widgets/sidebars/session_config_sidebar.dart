import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
            icon: CupertinoIcons.settings,
            label: '工作模式',
            value: _getWorkModeName(session.workMode),
          ),
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
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.wand_stars,
            label: '技能',
            value: session.skill?.name ?? '未绑定',
            valueColor: session.skill != null 
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(height: 8),
          
          _buildConfigItem(
            context,
            icon: CupertinoIcons.square_list,
            label: '记忆压缩轮数',
            value: session.memoryRounds == 0 ? '已禁用' : '${session.memoryRounds}轮',
          ),
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
          _buildConfigItem(
            context,
            icon: CupertinoIcons.memories,
            label: '记忆轮数',
            value: '${session.memory.length}轮',
          ),
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

  /// 获取工作模式中文名
  static String _getWorkModeName(String workMode) {
    switch (workMode) {
      case 'conversation':
        return '对话模式';
      case 'contract':
        return '合同模式';
      case 'invoice':
        return '发票模式';
      case 'chatroom':
        return '聊天室模式';
      case 'creative':
        return '创意模式';
      case 'task':
        return '任务模式';
      default:
        return '对话模式';
    }
  }
}