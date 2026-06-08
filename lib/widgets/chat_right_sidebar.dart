import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';

/// 右侧边栏 — 显示当前会话的记忆内容
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

class _ChatRightSidebarState extends State<ChatRightSidebar> {
  final sessionController = Get.find<SessionController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = sessionController.currentSession.value;
      final compressedMemory = session?.compressedMemory;
      final memory = session?.memory ?? [];

      return Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题栏
            _buildHeader(context),
            // 分隔线
            Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            // 内容区域
            Expanded(
              child:
                  compressedMemory == null && memory.isEmpty
                      ? _buildEmptyState(context)
                      : _buildMemoryContent(context, compressedMemory, memory),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '会话记忆',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // 折叠按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggleCollapse,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  CupertinoIcons.sidebar_right,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
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
              '暂无记忆',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '随着对话进行，AI 会自动\n记录和压缩对话记忆',
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
            _buildSectionTitle(context, '记忆摘要'),
            const SizedBox(height: 6),
            _buildCompressedMemoryCard(context, compressedMemory),
            const SizedBox(height: 16),
          ],
          // 最近记忆轮次
          if (memory.isNotEmpty) ...[
            _buildSectionTitle(context, '最近对话 (${memory.length} 条)'),
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
                      ? Theme.of(context).colorScheme.primary.withValues(
                        alpha: 0.1,
                      )
                      : Theme.of(context).colorScheme.tertiary.withValues(
                        alpha: 0.1,
                      ),
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
                  isUser ? '用户' : '助手',
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
}
