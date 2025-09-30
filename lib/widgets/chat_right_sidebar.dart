import 'package:flutter/material.dart';
import '../models/chat/chat_session.dart';

class ChatRightSidebar extends StatefulWidget {
  final bool isCollapsed;
  final ChatSession chatSession;
  final VoidCallback onClose;
  final List<ChatSession> chatSessions;
  final Function(ChatSession) onSessionUpdated;
  final double width;

  const ChatRightSidebar({
    super.key,
    required this.isCollapsed,
    required this.chatSession,
    required this.onClose, // 仍保留参数以兼容现有调用，但不再在UI中展示关闭按钮
    required this.chatSessions,
    required this.onSessionUpdated,
    this.width = 420,
  });

  @override
  State<ChatRightSidebar> createState() => _ChatRightSidebarState();
}

class _ChatRightSidebarState extends State<ChatRightSidebar> {
  // 需求：移除工作区与附件的概念，清空显示，仅保留一个占位空面板供后续功能使用

  @override
  void didUpdateWidget(covariant ChatRightSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatSession.sessionId != widget.chatSession.sessionId) {
      // 不再根据会话内容展示任何数据，仅触发重建
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) return const SizedBox.shrink();
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Center(
        child: Text(
          '（侧边区域已清空，等待新功能接入）',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
      ),
    );
  }
}
 
