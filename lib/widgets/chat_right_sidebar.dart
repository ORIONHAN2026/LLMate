import 'dart:convert';
import 'package:chathub/controllers/session_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/chat_attachment.dart';

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
    required this.onClose,
    required this.chatSessions,
    required this.onSessionUpdated,
    this.width = 420,
  });

  @override
  State<ChatRightSidebar> createState() => _ChatRightSidebarState();
}

class _ChatRightSidebarState extends State<ChatRightSidebar> {
  final sessionController = Get.find<SessionController>();
  int _activeTabIndex = 0; // 0 工作区 1 附件

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChatRightSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换会话时强制刷新以展示新的 workspace/附件
    if (oldWidget.chatSession.sessionId != widget.chatSession.sessionId) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _resolveWorkspacePlain() {
    // 优先使用已保存的 plain text
    final plain = widget.chatSession.workspacePlainText;
    if (plain != null && plain.trim().isNotEmpty) return plain;
    // 如果只有 delta, 做一次简单提取（只拼接 insert 字符串）
    final deltaJson = widget.chatSession.workspaceDelta;
    if (deltaJson == null || deltaJson.isEmpty) return '';
    try {
      final decoded = jsonDecode(deltaJson);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op['insert'] is String) buffer.write(op['insert']);
        }
        return buffer.toString();
      }
    } catch (_) {}
    return '';
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
      child: Column(
        children: [
          _buildHeader(context),
          // 已移除富文本编辑工具栏
          Expanded(
            child: _activeTabIndex == 0
                ? _buildWorkspaceReadOnly(context)
                : _buildAttachmentsArea(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final tabs = [
      _TabInfo(icon: CupertinoIcons.doc_text, label: '工作区'),
      _TabInfo(icon: CupertinoIcons.paperclip, label: '附件 (${widget.chatSession.attachments.length})'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, i) {
                  final selected = i == _activeTabIndex;
                  final t = tabs[i];
                  return GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 14, color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemCount: tabs.length,
              ),
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: widget.onClose,
            icon: const Icon(CupertinoIcons.xmark, size: 16),
          ),
        ],
      ),
    );
  }
  Widget _buildWorkspaceReadOnly(BuildContext context) {
    final text = _resolveWorkspacePlain();
    if (text.isEmpty) {
      return Center(
        child: Text(
          '暂无工作区内容',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        text,
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
    );
  }

  Widget _buildAttachmentsArea(BuildContext context) {
    final attachments = widget.chatSession.attachments;
    if (attachments.isEmpty) {
      return Center(
        child: Text(
          '暂无附件',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (c, i) => _buildAttachmentTile(context, attachments[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: attachments.length,
    );
  }

  Widget _buildAttachmentTile(BuildContext context, ChatAttachment a) {
    final icon = _pickAttachmentIcon(a.type);
    final snippet = _buildSnippet(a.content);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          dense: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(icon, size: 18),
          title: Text(
            a.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: snippet != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : null,
          children: [
            if (a.content != null && a.content!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: _buildFullContent(context, a),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '无内容',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _buildSnippet(String? content) {
    if (content == null || content.trim().isEmpty) return null;
    final cleaned = content.replaceAll('\n', ' ').trim();
    if (cleaned.length <= 60) return cleaned;
    return '${cleaned.substring(0, 60)}...';
  }

  Widget _buildFullContent(BuildContext context, ChatAttachment a) {
    final content = a.content ?? '';
    final isCode = ['code', 'dart', 'js', 'ts', 'py', 'go', 'rs'].contains(a.type) || a.name.endsWith('.dart');
    return SelectableText(
      content,
      style: TextStyle(
        fontSize: 12,
        fontFamily: isCode ? 'monospace' : null,
      ),
    );
  }

  IconData _pickAttachmentIcon(String type) {
    switch (type) {
      case 'image':
        return CupertinoIcons.photo;
      case 'code':
        return CupertinoIcons.chevron_left_slash_chevron_right;
      case 'web':
        return CupertinoIcons.globe;
      case 'folder':
        return CupertinoIcons.folder;
      case 'document':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.paperclip;
    }
  }
}

class _TabInfo {
  final IconData icon;
  final String label;
  const _TabInfo({required this.icon, required this.label});
}
