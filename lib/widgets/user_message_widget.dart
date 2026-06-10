import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:chathub/controllers/session_controller.dart';
import 'package:chathub/l10n/app_localizations.dart';
import 'package:chathub/models/bigmodel/models.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/utils/responsive_utils.dart';
import 'package:chathub/framework/llm_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'chat_message_widget.dart';

// 用户消息组件
class UserMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onUpdate;
  final Future<void> Function(ChatMessage)? onCaptureMessage;
  final Future<void> Function(ChatMessage)? onCaptureRound;
  final Future<void> Function()? onCaptureConversation;

  const UserMessageWidget({
    super.key,
    required this.message,
    this.onUpdate,
    this.onCaptureMessage,
    this.onCaptureRound,
    this.onCaptureConversation,
  });

  @override
  State<UserMessageWidget> createState() => _UserMessageWidgetState();
}

class _UserMessageWidgetState extends State<UserMessageWidget> {
  bool _isHovered = false;
  final sessionController = Get.find<SessionController>();

  // 根据消息ID同步查找包含该消息的会话（仅内存）
  ChatSession? _findSessionContainingMessage(String messageId) {
    for (final session in sessionController.sessions) {
      if (session.messages.any((msg) => msg.msgId == messageId)) {
        return session;
      }
    }
    return null;
  }

  // 根据消息ID异步查找包含该消息的会话（内存+Isar）
  Future<ChatSession?> _findSessionContainingMessageAsync(String messageId) async {
    // 先尝试内存查找
    final memorySession = _findSessionContainingMessage(messageId);
    if (memorySession != null) return memorySession;

    // 内存未找到，从Isar加载
    return await sessionController.findSessionByMessageId(messageId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: ValueKey(widget.message.msgId),
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户消息 - 右侧对齐
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onSecondaryTapDown: (details) {
                  _showUserMessageMenu(context, details.globalPosition);
                },
                behavior: HitTestBehavior.opaque, // 确保空白区域也能响应点击
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width *
                            ResponsiveUtils.getUserMessageMaxWidthRatio(
                              context,
                            ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 附件展示区域
                          if (widget.message.attachments.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  widget.message.attachments.map((attachment) {
                                    return _buildAttachmentChip(attachment);
                                  }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          // 消息文本内容
                          Text(
                            widget.message.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 用户消息操作按钮 - 悬停时显示，但保持布局高度
                    SizedBox(
                      height: 28, // 固定高度避免飘动
                      child: AnimatedOpacity(
                        opacity: _isHovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 编辑按钮
                            _buildActionButton(
                              icon: CupertinoIcons.pencil,
                              tooltip: l10n.edit,
                              onTap: () => _editMessage(widget.message),
                            ),
                            const SizedBox(width: 4),
                            // 重新生成按钮
                            _buildActionButton(
                              icon: CupertinoIcons.arrow_clockwise,
                              tooltip: l10n.regenerate,
                              onTap:
                                  () => _regenerateMessage(
                                    RegenerateActionType.regenerate,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            // 复制按钮
                            _buildActionButton(
                              icon: CupertinoIcons.doc_on_doc,
                              tooltip: l10n.copy,
                              onTap:
                                  () => _copyMessage(
                                    context,
                                    widget.message.content,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            // 更多操作按钮
                            Builder(
                              builder: (buttonContext) {
                                return _buildActionButton(
                                  icon: CupertinoIcons.ellipsis_vertical,
                                  tooltip: l10n.more,
                                  onTap: () {},
                                  onTapDown:
                                      (details) => _showUserMessageMenu(
                                        buttonContext,
                                        details.globalPosition,
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Function(TapDownDetails)? onTapDown,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        onTapDown: onTapDown,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  // 复制消息内容
  void _copyMessage(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.copiedToClipboard);
  }

  // 编辑消息
  void _editMessage(ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final TextEditingController controller = TextEditingController(
          text: message.content,
        );

        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            l10n.editMessageTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400, minHeight: 200),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                hintText: l10n.messageHint,
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final newContent = controller.text.trim();
                if (newContent.isNotEmpty) {
                  if (newContent.trim().isEmpty) {
                    SnackBarUtils.showError(context, l10n.messageContentCannotBeEmpty);
                    return;
                  }

                  setState(() {
                    widget.message.content = newContent.trim();
                    sessionController.updateMessage(widget.message);
                  });

                  // 通知父组件更新
                  widget.onUpdate?.call();

                  Navigator.of(context).pop();
                } else {
                  SnackBarUtils.showError(context, l10n.messageContentCannotBeEmpty);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  // 统一的重新生成方法
  void _regenerateMessage(RegenerateActionType actionType) async {
    final session = await _findSessionContainingMessageAsync(widget.message.msgId);
    if (session == null) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.sessionNotFoundForMessage);
      }
      return;
    }

    try {
      final messages = session.messages;
      final messageIndex = messages.indexWhere(
        (msg) => msg.msgId == widget.message.msgId,
      );

      if (messageIndex == -1) {
        if (mounted) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.messageNotFound);
        }
        return;
      }

      switch (actionType) {
        case RegenerateActionType.regenerate:
          await _performRegenerate(session, messageIndex);
          break;
        case RegenerateActionType.regenerateFromHere:
          await _performRegenerateFromHere(session, messageIndex);
          break;
        case RegenerateActionType.regenerateThisReply:
          await _performRegenerateThisReply(session, messageIndex);
          break;
        case RegenerateActionType.regenerateLastReply:
          await _performRegenerateLastReply(session);
          break;
      }

      // 通知父组件更新
      if (mounted) {
        widget.onUpdate?.call();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.xFailed(AppLocalizations.of(context)!.regenerate, e.toString()));
      }
    }
  }

  // 重新生成消息
  Future<void> _performRegenerate(ChatSession session, int messageIndex) async {
    // 对于用户消息，直接使用当前消息内容作为问题
    String userQuestion = widget.message.content;
    int startDeleteIndex = messageIndex + 1; // 从下一条消息开始删除

    if (userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.messageContentCannotBeEmpty);
      }
      return;
    }

    await _performRegeneration(session, userQuestion, startDeleteIndex, AppLocalizations.of(context)!.regenerate);
  }

  // 从此处重新生成
  Future<void> _performRegenerateFromHere(
    ChatSession session,
    int messageIndex,
  ) async {
    String userQuestion = widget.message.content;

    if (userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.messageContentCannotBeEmpty);
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      messageIndex + 1,
      AppLocalizations.of(context)!.regenerateFromHere,
    );
  }

  // 重新生成最后一条回复
  Future<void> _performRegenerateLastReply(ChatSession session) async {
    final messages = session.messages;
    if (messages.isEmpty) return;

    // 找到最后一条AI回复
    ChatMessage? lastAiMessage;
    int lastAiMessageIndex = -1;

    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.bot) {
        lastAiMessage = messages[i];
        lastAiMessageIndex = i;
        break;
      }
    }

    if (lastAiMessage == null) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.noAiReplyFound);
      }
      return;
    }

    // 此时 lastAiMessage 已经确定不为 null
    final aiMessage = lastAiMessage; // 类型提升

    // 找到对应的用户问题
    String? userQuestion;
    ChatMessage? userMessage;

    // 优先通过 pairedMsgId 找到对应的用户问题
    if (aiMessage.pairedMsgId != null) {
      try {
        userMessage = messages.firstWhere(
          (msg) => msg.msgId == aiMessage.pairedMsgId!,
        );
        userQuestion = userMessage.content;
      } catch (e) {
        // 如果通过 pairedMsgId 找不到，说明对应的用户消息已被删除
        if (mounted) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.messageNotFound);
        }
        return;
      }
    }

    // 如果没有 pairedMsgId 或者找不到配对消息，使用原来的方法
    if (userMessage == null) {
      for (int i = lastAiMessageIndex - 1; i >= 0; i--) {
        if (messages[i].role == MessageRole.user) {
          userQuestion = messages[i].content;
          userMessage = messages[i];
          break;
        }
      }
    }

    if (userQuestion == null || userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotFindQuestion);
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      lastAiMessageIndex,
      AppLocalizations.of(context)!.regenerateLastReply,
    );
  }

  // 重新生成此回复（对于用户消息，等同于重新生成）
  Future<void> _performRegenerateThisReply(
    ChatSession session,
    int messageIndex,
  ) async {
    await _performRegenerate(session, messageIndex);
  }

  // 通用的重新生成方法
  Future<void> _performRegeneration(
    ChatSession session,
    String userQuestion,
    int startDeleteIndex,
    String actionName,
  ) async {
    final messages = session.messages;
    if (startDeleteIndex < 0 || startDeleteIndex > messages.length) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotRegenerateInvalidIndex);
      }
      return;
    }

    try {
      // 保留到 startDeleteIndex 之前的所有消息
      final updatedMessages = messages.sublist(0, startDeleteIndex);

      // 更新会话消息
      final updatedSession = session.copyWith(
        messages: updatedMessages,
        isSending: true,
      );
      await sessionController.updateSession(updatedSession);

      // 生成新的AI回复
      await _generateAIResponse(updatedSession, userQuestion, actionName);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.xFailed(actionName, e.toString()));
      }

      // 确保重置发送状态
      final resetSession = session.copyWith(isSending: false);
      await sessionController.updateSession(resetSession);
    }
  }

  // 生成AI回复
  Future<void> _generateAIResponse(
    ChatSession session,
    String userQuestion,
    String actionName,
  ) async {
    LlmClient? client;
    try {
      // 创建AI消息用于流式更新
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final botMessageId = '${timestamp}_bot';
      final botMessage = ChatMessage(
        msgId: botMessageId,
        role: MessageRole.bot,
        content: '',
        timestamp: DateTime.now(),
        sessionId: session.sessionId,
        isError: false,
      );

      // 添加AI消息到会话
      final messagesWithBot = List<ChatMessage>.from(session.messages)
        ..add(botMessage);
      var currentSession = session.copyWith(
        messages: messagesWithBot,
        isSending: true,
        shouldStopResponse: false,
      );
      await sessionController.updateSession(currentSession);
      widget.onUpdate?.call();

      // 调用API生成流式响应
      String accumulatedContent = '';

      // 使用 LLM Hub 创建客户端
      client = LlmClient(currentSession);
      final responseStream = client.LLMChat(widget.message);

      await for (final chunkMap in responseStream) {
        // 检查是否被停止 - 通过查找会话列表中的会话状态
        final latestSession = sessionController.sessions.firstWhere(
          (s) => s.sessionId == session.sessionId,
          orElse: () => currentSession,
        );
        if (latestSession.shouldStopResponse == true) {
          break;
        }

        final contentChunk = chunkMap['content'] ?? '';
        accumulatedContent += contentChunk;

        // 处理记忆更新
        final memoryUpdatedJson = chunkMap['memory_updated'];
        if (memoryUpdatedJson is String && memoryUpdatedJson.isNotEmpty) {
          try {
            final updated = ChatSession.fromJson(
              jsonDecode(memoryUpdatedJson) as Map<String, dynamic>,
            );
            currentSession = currentSession.copyWith(
              memory: updated.memory,
              compressedMemory: updated.compressedMemory,
            );
            await sessionController.updateSession(currentSession);
          } catch (_) {}
        }

        // 更新消息内容
        final messageIndex = currentSession.messages.indexWhere(
          (msg) => msg.msgId == botMessageId,
        );

        if (messageIndex != -1) {
          final updatedMessages = List<ChatMessage>.from(
            currentSession.messages,
          );
          updatedMessages[messageIndex] = ChatMessage(
            msgId: botMessageId,
            role: MessageRole.bot,
            content: accumulatedContent,
            timestamp: botMessage.timestamp,
            sessionId: session.sessionId,
            isError:
                accumulatedContent.startsWith('请求失败') ||
                accumulatedContent.startsWith('API 错误') ||
                accumulatedContent.startsWith('网络连接错误') ||
                accumulatedContent.startsWith('连接错误'),
          );

          currentSession = currentSession.copyWith(
            messages: updatedMessages,
            isSending: true,
          );

          await sessionController.updateSession(currentSession);

          // 强制触发UI更新 - 关键修复
          if (mounted) {
            widget.onUpdate?.call();
          }
        }
      }

      // 完成生成，重置发送状态
      final finalSession = currentSession.copyWith(isSending: false);
      await sessionController.updateSession(finalSession);

      // 强制触发UI更新 - 关键修复
      if (mounted) {
        widget.onUpdate?.call();
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.xDone(actionName));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.xFailed(actionName, e.toString()));
      }

      // 重置发送状态
      final resetSession = session.copyWith(isSending: false);
      await sessionController.updateSession(resetSession);
      if (mounted) {
        widget.onUpdate?.call();
      }
    } finally {
      // 释放客户端资源
      client?.dispose();
    }
  }

  // 删除消息
  void _deleteMessage(ChatMessage message) {
    try {
      sessionController.deleteMessage(message);
      // 通知父组件更新
      if (mounted) {
        widget.onUpdate?.call();
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.messageDeleted);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.xFailed(AppLocalizations.of(context)!.deleteMessage, e.toString()));
      }
    }
  }

  // 删除该消息之后的回复
  Future<void> _deleteReplyAfterMessage(ChatMessage message) async {
    try {
      // 根据消息ID查找包含该消息的会话
      final session = await _findSessionContainingMessageAsync(message.msgId);
      if (session != null) {
        final messageIndex = session.messages.indexWhere(
          (m) => m.msgId == message.msgId,
        );
        if (messageIndex != -1) {
          // 保留到指定消息为止的所有消息
          final updatedMessages = session.messages.sublist(0, messageIndex + 1);
          final updatedSession = session.copyWith(messages: updatedMessages);
          sessionController.updateSession(updatedSession);

          // 通知父组件更新
          if (mounted) {
            widget.onUpdate?.call();
            SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.replyDeleted);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.deleteReplyFailed);
      }
    }
  }

  // 从消息创建新对话
  Future<void> _createNewSessionFromMessage(BuildContext context, ChatMessage message) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      // 根据消息ID查找包含该消息的会话
      final session = await _findSessionContainingMessageAsync(message.msgId);
      if (session == null) {
        if (mounted) {
          SnackBarUtils.showError(context, l10n.sessionNotFoundForMessage);
        }
        return;
      }

      final currentMessages = session.messages;
      final messageIndex = currentMessages.indexWhere(
        (m) => m.msgId == message.msgId,
      );

      if (messageIndex != -1) {
        final historyMessages = currentMessages.sublist(0, messageIndex + 1);

        // 创建新会话
        final newSession = ChatSession(
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          name: l10n.newChatFromHistory,
          createdAt: DateTime.now(),
          messages: historyMessages,
          chatModel: session.chatModel,
          inputContent: '',
          attachments: [],
        );

        // 添加新会话到控制器
        sessionController.addSession(newSession);

        // 通知父组件更新
        if (mounted) {
          widget.onUpdate?.call();
          SnackBarUtils.showSuccess(context, l10n.newChatCreatedFromHere);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.createNewChatFailed);
      }
    }
  }

  // 显示用户消息菜单
  void _showUserMessageMenu(BuildContext context, Offset position) {
    final l10n = AppLocalizations.of(context)!;
    // 重置展开状态
    bool isRegenerateExpanded = false;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx - 180, // 向左偏移以显示在按钮左侧
        position.dy + 8,
        position.dx,
        0,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: const BoxConstraints(minWidth: 200),
      items: [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setMenuState) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 复制消息
                    _buildMenuOption(
                      context: context,
                      icon: CupertinoIcons.doc_on_doc,
                      title: l10n.copyMessage,
                      onTap: () {
                        Navigator.pop(context);
                        _copyMessage(context, widget.message.content);
                      },
                    ),
                    const SizedBox(height: 4),

                    // 重新生成 - 可展开子菜单
                    _buildExpandableMenuOption(
                      context: context,
                      icon: CupertinoIcons.arrow_clockwise,
                      title: l10n.regenerate,
                      isExpanded: isRegenerateExpanded,
                      onToggle: () {
                        setMenuState(() {
                          isRegenerateExpanded = !isRegenerateExpanded;
                        });
                      },
                      children: [
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.play,
                          title: l10n.regenerateFromHere,
                          onTap: () {
                            Navigator.pop(context);
                            _regenerateMessage(
                              RegenerateActionType.regenerateFromHere,
                            );
                          },
                        ),
                        // _buildSubMenuOption(
                        //   context: context,
                        //   icon: CupertinoIcons.arrow_left,
                        //   title: '重新生成最后一条回复',
                        //   onTap: () {
                        //     Navigator.pop(context);
                        //     _regenerateMessage(
                        //       RegenerateActionType.regenerateLastReply,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 删除消息
                    _buildMenuOption(
                      context: context,
                      icon: CupertinoIcons.trash,
                      title: l10n.deleteMessage,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteMessage(widget.message);
                      },
                    ),
                    const SizedBox(height: 4),

                    // 从此处创建新对话
                    _buildMenuOption(
                      context: context,
                      icon: CupertinoIcons.plus,
                      title: l10n.createNewChatFromHere,
                      onTap: () {
                        Navigator.pop(context);
                        _createNewSessionFromMessage(context, widget.message);
                      },
                    ),
                    const SizedBox(height: 4),

                    // 删除回复 (仅用户消息显示)
                    _buildMenuOption(
                      context: context,
                      icon: CupertinoIcons.reply,
                      title: l10n.deleteReply,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteReplyAfterMessage(widget.message);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 构建菜单选项
  Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (hasArrow)
              Icon(
                CupertinoIcons.chevron_right,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }

  // 构建可展开的菜单选项
  Widget _buildExpandableMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ],
      ],
    );
  }

  // 构建子菜单选项
  Widget _buildSubMenuOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示附件详情对话框
  void _showAttachmentDetails(ChatAttachment attachment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              _getAttachmentIcon(attachment.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.fileInfo,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${l10n.fileNameLabel}: ${attachment.name}'),
                        if (attachment.size != null)
                          Text('${l10n.fileSizeLabel}: ${_formatFileSize(attachment.size!)}'),
                        Text('${l10n.fileTypeLabel}: ${_getFileTypeDescription(attachment.type)}'),
                        if (attachment.filePath != null)
                          Text('${l10n.filePathLabel}: ${attachment.filePath}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 文件内容
                  if (attachment.content != null &&
                      attachment.content!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.fileContent,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: SelectableText(
                        attachment.content!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 32,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noContentPreview,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.close,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            if (attachment.content != null && attachment.content!.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: attachment.content!));
                  Navigator.of(context).pop();
                  SnackBarUtils.showSuccess(context, l10n.fileContentCopied);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.copyContent),
              ),
          ],
        );
      },
    );
  }

  /// 获取附件类型图标
  Widget _getAttachmentIcon(String type) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'image':
        icon = CupertinoIcons.photo;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'document':
      case 'text':
        icon = CupertinoIcons.doc_text;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'code':
        icon = CupertinoIcons.textformat;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      case 'office':
        icon = CupertinoIcons.doc;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'web':
        icon = CupertinoIcons.globe;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'folder':
        icon = CupertinoIcons.folder;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        icon = CupertinoIcons.doc;
        iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }

    return Icon(icon, size: 18, color: iconColor);
  }

  /// 获取文件类型描述
  String _getFileTypeDescription(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'image':
        return l10n.files; // generic fallback
      case 'document':
      case 'text':
      case 'code':
      case 'office':
      case 'web':
      case 'folder':
      default:
        return type;
    }
  }

  /// 构建附件卡片
  Widget _buildAttachmentChip(ChatAttachment attachment) {
    IconData icon;
    Color iconColor;

    // 根据附件类型选择图标和颜色
    switch (attachment.type) {
      case 'image':
        icon = CupertinoIcons.photo;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'document':
      case 'text':
        icon = CupertinoIcons.doc_text;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'code':
        icon = CupertinoIcons.textformat;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      case 'office':
        icon = CupertinoIcons.doc;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'web':
        icon = CupertinoIcons.globe;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'folder':
        icon = CupertinoIcons.folder;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        icon = CupertinoIcons.doc;
        iconColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: () => _showAttachmentDetails(attachment),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, minWidth: 60),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attachment.size != null)
                        Text(
                          _formatFileSize(attachment.size!),
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      if (attachment.content != null &&
                          attachment.content!.isNotEmpty) ...[
                        if (attachment.size != null)
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        Icon(
                          Icons.check_circle,
                          size: 10,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          AppLocalizations.of(context)!.processed,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
