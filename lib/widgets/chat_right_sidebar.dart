import 'package:flutter/material.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_message.dart';

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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

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
    String text = '';
    // 优先根据选中的 AI 消息 ID 获取其整理文档
    final selectedId = widget.chatSession.selectedOrganizedMessageId;
    if (selectedId != null) {
      final msg = widget.chatSession.messages.firstWhere(
        (m) => m.msgId == selectedId,
        orElse: () => ChatMessage(
          msgId: 'temp',
          role: MessageRole.bot,
          content: '',
          timestamp: DateTime.now(),
        ),
      );
      text = msg.organizedDocument?.trim() ?? '';
    }
    // 不再回退：如果当前选中消息没有整理文档，则保持空白
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: text.isEmpty
          ? Center(
              child: Text(
                '（暂无整理内容，生成含结构化输出的 AI 回答后会显示其整理文档）',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                child: SelectableText(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
            ),
    );
  }
}
 
