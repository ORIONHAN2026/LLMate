import 'dart:convert';
import 'dart:io';

import 'package:llmwork/controllers/session_controller.dart';
import 'package:llmwork/models/models.dart';
import 'package:llmwork/utils/snackbar_utils.dart';
import 'package:llmwork/core/llm/llm_client.dart';
import 'package:llmwork/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import './chat_message_widget.dart';

// AI消息组件
class AiMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onUpdate;
  final Future<void> Function(ChatMessage)? onCaptureMessage;
  final Future<void> Function(ChatMessage)? onCaptureRound;
  final Future<void> Function()? onCaptureConversation;

  const AiMessageWidget({
    super.key,
    required this.message,
    this.onUpdate,
    this.onCaptureMessage,
    this.onCaptureRound,
    this.onCaptureConversation,
  });

  @override
  State<AiMessageWidget> createState() => _AiMessageWidgetState();
}

class _AiMessageWidgetState extends State<AiMessageWidget>
    with TickerProviderStateMixin {
  bool _isHovered = false;
  final sessionController = Get.find<SessionController>();
  final GlobalKey _messageKey = GlobalKey();

  // 是否为当前会话最后一条消息
  bool get _isLastMessage {
    final msgs = sessionController.currentSession.value?.messages ?? [];
    return msgs.isNotEmpty && msgs.last.msgId == widget.message.msgId;
  }

  // 内部动画控制器和动画
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;

  // 工具执行呼吸灯动画
  late AnimationController _toolIndicatorController;
  late Animation<double> _toolIndicatorAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化思考呼吸动画
    _breathingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _breathingAnimationController.repeat(reverse: true);

    // 初始化工具执行呼吸灯动画（opacity 脉冲）
    _toolIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _toolIndicatorAnimation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _toolIndicatorController,
        curve: Curves.easeInOut,
      ),
    );
    // 如果消息正在工具调用中，启动呼吸
    if (widget.message.isToolCalling) {
      _toolIndicatorController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathingAnimationController.dispose();
    _toolIndicatorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AiMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.isToolCalling != widget.message.isToolCalling) {
      if (widget.message.isToolCalling) {
        _toolIndicatorController.repeat(reverse: true);
      } else {
        _toolIndicatorController.stop();
        _toolIndicatorController.reset();
      }
      setState(() {});
    }
  }

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
  Future<ChatSession?> _findSessionContainingMessageAsync(
    String messageId,
  ) async {
    // 先尝试内存查找
    final memorySession = _findSessionContainingMessage(messageId);
    if (memorySession != null) return memorySession;

    // 内存未找到，从Isar加载
    return await sessionController.findSessionByMessageId(messageId);
  }

  // 检查消息是否正在流式更新
  bool get _isStreaming {
    final session = _findSessionContainingMessage(widget.message.msgId);
    return session?.isSending == true &&
        widget.message.role == MessageRole.bot &&
        widget.message.content.isEmpty;
  }

  // 格式化时间显示（24小时制）
  String _formatTime(DateTime timestamp) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final timeString =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return l10n.todayTime(timeString);
    } else {
      return l10n.monthDayTime(
        timestamp.month.toString(),
        timestamp.day.toString(),
        timeString,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 调试信息：打印think内容状态

    return Container(
      key: ValueKey(widget.message.msgId),
      margin: const EdgeInsets.only(bottom: 32),
      child: RepaintBoundary(
        key: _messageKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // final session = _findSessionContainingMessage(widget.message.msgId);
            // if (session != null) {
            //   final updated = session.copyWith(
            //     selectedOrganizedMessageId: widget.message.msgId,
            //     pendingAutoOpenRightPanel: true,
            //   );
            //   sessionController.updateSession(updated);
            // }
          },
          onSecondaryTapDown: (details) {
            _showAiMessageMenu(context, details.globalPosition);
          },
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI头像
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        _findSessionContainingMessage(
                          widget.message.msgId,
                        )?.chatModel?.buildIconWidget(false, size: 20) ??
                        Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(width: 12),
                  // 消息内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 消息内容区域 - 统一布局避免跳动
                        if (_isStreaming &&
                            widget.message.content.isEmpty &&
                            widget.message.think.isEmpty &&
                            !widget.message.isToolCalling)
                          // 流式传输时显示呼吸动画，保持最小高度
                          Container(
                            constraints: const BoxConstraints(minHeight: 24),
                            child: Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _breathingAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6)
                                            .withValues(
                                              alpha: _breathingAnimation.value,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _breathingAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6)
                                            .withValues(
                                              alpha:
                                                  _breathingAnimation.value *
                                                  0.7,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _breathingAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6)
                                            .withValues(
                                              alpha:
                                                  _breathingAnimation.value *
                                                  0.4,
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        else
                          // 显示消息内容（按 contentBlocks 顺序渲染）
                          _buildContentBlocks(),

                        //

                        // 底部时间信息和操作按钮 - 悬停时显示，但保持布局高度
                        SizedBox(
                          height: 32,
                          child: AnimatedOpacity(
                            opacity:
                                (_isHovered ||
                                        widget.message.isToolCalling ||
                                        _isLastMessage)
                                    ? 1.0
                                    : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 操作按钮组
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                    // 编辑按钮
                                    _buildActionButton(
                                      icon: CupertinoIcons.pencil,
                                      tooltip: l10n.edit,
                                      onTap:
                                          () => _editMessage(
                                            context,
                                            widget.message,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    // 更多操作按钮
                                    Builder(
                                      builder: (buttonContext) {
                                        return _buildActionButton(
                                          icon:
                                              CupertinoIcons.ellipsis_vertical,
                                          tooltip: l10n.more,
                                          onTap: () {},
                                          onTapDown:
                                              (details) => _showAiMessageMenu(
                                                buttonContext,
                                                details.globalPosition,
                                              ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    // 工具执行呼吸灯（始终显示，执行时呼吸脉冲）
                                    Tooltip(
                                      message: '工具执行指示灯',
                                      child: _buildToolIndicator(),
                                    ),
                                  ],
                                ),
                                // 时间信息
                                Text(
                                  _formatTime(widget.message.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 复制消息内容
  void _copyMessage(BuildContext context, String content) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.copiedToClipboard);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.copyFailed);
      }
    }
  }

  // 打开链接
  Future<void> _openLink(String url) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      debugPrint('尝试打开链接: $url');

      // 处理 file:// 协议 - 打开本地文件
      if (url.startsWith('file://')) {
        final filePath = url.substring(7); // 去掉 "file://" 前缀
        await _openFile(filePath);
        return;
      }

      // 验证URL格式
      Uri? uri;
      try {
        // 如果URL没有协议前缀，添加https://
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          url = 'https://$url';
        }
        uri = Uri.parse(url);
      } catch (e) {
        debugPrint('URL格式错误: $e');
        if (mounted) {
          SnackBarUtils.showError(context, l10n.invalidLinkFormat);
        }
        return;
      }

      // 检查是否可以启动该URL
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 在外部浏览器中打开
        );

        if (!success) {
          debugPrint('启动URL失败');
          if (mounted) {
            SnackBarUtils.showError(context, l10n.cannotOpenLink);
          }
        } else {
          debugPrint('成功打开链接: $url');
          if (mounted) {
            SnackBarUtils.showInfo(context, l10n.linkOpenedInBrowser);
          }
        }
      } else {
        debugPrint('无法启动URL: $url');
        if (mounted) {
          SnackBarUtils.showError(context, l10n.cannotOpenThisLinkType);
        }
      }
    } catch (e) {
      debugPrint('打开链接时发生错误: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.openLinkFailed,
        );
      }
    }
  }

  // 打开本地文件
  Future<void> _openFile(String filePath) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          SnackBarUtils.showError(context, '${l10n.fileNotFound}: $filePath');
        }
        return;
      }

      // 根据操作系统选择命令打开文件
      final command =
          Platform.isWindows
              ? 'start'
              : Platform.isMacOS
              ? 'open'
              : 'xdg-open';
      final args = Platform.isWindows ? ['', filePath] : [filePath];
      final result = await Process.run(command, args, runInShell: true);
      if (result.exitCode == 0) {
        debugPrint('成功打开文件: $filePath');
        if (mounted) {
          SnackBarUtils.showInfo(context, l10n.fileOpened);
        }
      } else {
        debugPrint('打开文件失败: ${result.stderr}');
        if (mounted) {
          SnackBarUtils.showError(
            context,
            '${l10n.cannotOpenFile}: ${result.stderr}',
          );
        }
      }
    } catch (e) {
      debugPrint('打开文件时发生错误: $e');
      if (mounted) {
        SnackBarUtils.showError(
          context,
          '${AppLocalizations.of(context)!.openFileFailed}: $e',
        );
      }
    }
  }

  // 统一的重新生成方法
  void _regenerateMessage(RegenerateActionType actionType) async {
    final l10n = AppLocalizations.of(context)!;
    final session = await _findSessionContainingMessageAsync(
      widget.message.msgId,
    );
    if (session == null) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.sessionNotFoundForMessage);
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
          SnackBarUtils.showError(context, l10n.messageNotFound);
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
      widget.onUpdate?.call();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          l10n.xFailed(l10n.regenerate, e.toString()),
        );
      }
    }
  }

  // 重新生成消息
  Future<void> _performRegenerate(ChatSession session, int messageIndex) async {
    final messages = session.messages;

    // 找到对应的用户问题
    String? userQuestion;
    ChatMessage? userMessage;
    int startDeleteIndex = messageIndex;

    if (widget.message.role == MessageRole.bot) {
      // 如果点击的是AI回答，找到对应的用户问题
      for (int i = messageIndex - 1; i >= 0; i--) {
        if (messages[i].role == MessageRole.user) {
          userQuestion = messages[i].content;
          userMessage = messages[i]; // 保存完整的用户消息对象
          startDeleteIndex = i + 1; // 从AI回答开始删除
          break;
        }
      }
    } else {
      // 如果点击的是用户问题，直接使用该问题
      userQuestion = widget.message.content;
      userMessage = widget.message; // 当前消息就是用户消息
      startDeleteIndex = messageIndex + 1; // 从下一条消息开始删除
    }

    if (userQuestion == null || userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.cannotFindQuestion,
        );
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      userMessage, // 传递完整的用户消息对象
      startDeleteIndex,
      AppLocalizations.of(context)!.regenerate,
      RegenerateActionType.regenerate,
    );
  }

  // 从此处重新生成
  Future<void> _performRegenerateFromHere(
    ChatSession session,
    int messageIndex,
  ) async {
    final messages = session.messages;

    // 找到当前消息对应的用户问题
    String? userQuestion;
    ChatMessage? userMessage;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        userQuestion = messages[i].content;
        userMessage = messages[i]; // 保存完整的用户消息对象
        break;
      }
    }

    if (userQuestion == null || userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.cannotFindQuestion,
        );
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      userMessage, // 传递完整的用户消息对象
      messageIndex,
      AppLocalizations.of(context)!.regenerateFromHere,
      RegenerateActionType.regenerateFromHere,
    );
  }

  // 重新生成此回复
  Future<void> _performRegenerateThisReply(
    ChatSession session,
    int messageIndex,
  ) async {
    final messages = session.messages;

    // 找到当前消息对应的用户问题
    String? userQuestion;
    ChatMessage? userMessage;
    for (int i = messageIndex - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        userQuestion = messages[i].content;
        userMessage = messages[i]; // 保存完整的用户消息对象
        break;
      }
    }

    if (userQuestion == null || userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.cannotFindQuestion,
        );
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      userMessage, // 传递完整的用户消息对象
      messageIndex,
      AppLocalizations.of(context)!.regenerateThisReply,
      RegenerateActionType.regenerateThisReply,
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
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.noAiReplyFound,
        );
      }
      return;
    }

    // 找到对应的用户问题
    String? userQuestion;
    ChatMessage? userMessage; // 存储完整的用户消息对象
    for (int i = lastAiMessageIndex - 1; i >= 0; i--) {
      if (messages[i].role == MessageRole.user) {
        userQuestion = messages[i].content;
        userMessage = messages[i]; // 保存完整的消息对象，包含附件
        break;
      }
    }

    if (userQuestion == null || userQuestion.isEmpty) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.cannotFindQuestion,
        );
      }
      return;
    }

    await _performRegeneration(
      session,
      userQuestion,
      userMessage, // 传递完整的用户消息对象
      lastAiMessageIndex,
      AppLocalizations.of(context)!.regenerateLastReply,
      RegenerateActionType.regenerateLastReply,
    );
  }

  // 通用的重新生成方法
  Future<void> _performRegeneration(
    ChatSession session,
    String userQuestion,
    ChatMessage? userMessage, // 添加用户消息对象参数
    int targetIndex,
    String actionName,
    RegenerateActionType actionType,
  ) async {
    final messages = session.messages;

    try {
      ChatSession updatedSession;

      switch (actionType) {
        case RegenerateActionType.regenerateThisReply:
          // 重新生成此回复：只替换当前消息内容，保留前后所有消息
          if (targetIndex < 0 || targetIndex >= messages.length) {
            if (mounted) {
              SnackBarUtils.showError(
                context,
                AppLocalizations.of(context)!.cannotRegenerateInvalidIndex,
              );
            }
            return;
          }

          // 创建一个临时的更新会话，将目标消息内容清空但保留消息位置
          final updatedMessages = List<ChatMessage>.from(messages);
          updatedMessages[targetIndex] = ChatMessage(
            msgId: messages[targetIndex].msgId,
            role: MessageRole.bot,
            content: '', // 清空内容，准备重新生成
            timestamp: messages[targetIndex].timestamp,
            sessionId: session.sessionId,
            isError: false,
          );

          updatedSession = session.copyWith(
            messages: updatedMessages,
            isSending: true,
          );
          break;

        case RegenerateActionType.regenerateFromHere:
        case RegenerateActionType.regenerate:
        case RegenerateActionType.regenerateLastReply:
          // 其他情况：删除从目标索引开始的所有消息
          if (targetIndex < 0 || targetIndex > messages.length) {
            if (mounted) {
              SnackBarUtils.showError(
                context,
                AppLocalizations.of(context)!.cannotRegenerateInvalidIndex,
              );
            }
            return;
          }

          final updatedMessages = messages.sublist(0, targetIndex);
          updatedSession = session.copyWith(
            messages: updatedMessages,
            isSending: true,
          );
          break;
      }

      await sessionController.updateSession(updatedSession);

      // 生成新的AI回复
      await _generateAIResponse(
        updatedSession,
        userMessage!, // 传递完整的用户消息对象
        actionName,
        actionType,
        targetIndex,
      );
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.xFailed(actionName, e.toString()),
        );
      }

      // 确保重置发送状态
      final resetSession = session.copyWith(isSending: false);
      await sessionController.updateSession(resetSession);
    }
  }

  // 生成AI回复
  Future<void> _generateAIResponse(
    ChatSession session,
    ChatMessage userMessage, // 添加用户消息对象参数
    String actionName, [
    RegenerateActionType? actionType,
    int? targetIndex,
  ]) async {
    LlmClient? client;
    try {
      final startTime = DateTime.now(); // 记录开始时间

      String botMessageId;
      ChatMessage botMessage;

      // 根据重新生成类型决定如何处理消息
      if (actionType == RegenerateActionType.regenerateThisReply &&
          targetIndex != null) {
        // 重新生成此回复：使用现有消息的ID，只更新内容
        final existingMessage = session.messages[targetIndex];
        botMessageId = existingMessage.msgId;
        botMessage = existingMessage.copyWith(
          content: '',
          generationStartTime: startTime, // 更新开始时间
          generationEndTime: null,
          generationDuration: null,
          inputTokens: null,
          outputTokens: null,
          totalTokens: null,
        );
      } else {
        // 其他情况：创建新的AI消息
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        botMessageId = '${timestamp}_bot';
        botMessage = ChatMessage(
          msgId: botMessageId,
          role: MessageRole.bot,
          content: '',
          timestamp: DateTime.now(),
          sessionId: session.sessionId,
          isError: false,
          generationStartTime: startTime, // 设置开始时间
        );

        // 添加AI消息到会话
        final messagesWithBot = List<ChatMessage>.from(session.messages)
          ..add(botMessage);
        session = session.copyWith(
          messages: messagesWithBot,
          isSending: true,
          shouldStopResponse: false,
        );
        await sessionController.updateSession(session);
        widget.onUpdate?.call();
      }

      var currentSession = session;

      // 调用API生成流式响应
      String accumulatedContent = '';
      String accumulatedThink = ''; // 累积思考内容
      final List<ContentBlock> blocks = [];

      // 使用 LLM Hub 创建客户端
      client = LlmClient(currentSession);
      final responseStream = client.LLMChat(userMessage);

      await for (final chunkMap in responseStream) {
        // 检查是否被停止 - 通过查找会话列表中的会话状态
        final latestSession = sessionController.sessions.firstWhere(
          (s) => s.sessionId == session.sessionId,
          orElse: () => currentSession,
        );
        if (latestSession.shouldStopResponse == true) {
          break;
        }

        // 处理content、think、tool 状态、toolcall 内容
        final contentChunk = chunkMap['content'] ?? '';
        final thinkChunk = chunkMap['think'] ?? '';
        final tool = (chunkMap['tool'] ?? '').toString();
        final toolcall = (chunkMap['toolcall'] ?? '').toString();

        // 处理工具调用状态标记（布尔值）
        if (tool == 'true') {
          botMessage.isToolCalling = true;
        } else if (tool == 'false') {
          botMessage.isToolCalling = false;
        }

        // 处理流结束信号
        final done = chunkMap['done'] ?? '';
        if (done == 'true') {
          botMessage.isToolCalling = false;
        }

        accumulatedContent += contentChunk;
        accumulatedThink += thinkChunk;

        // 按顺序构建内容块
        void appendBlock(ContentBlockType type, String text) {
          if (blocks.isNotEmpty && blocks.last.type == type) {
            blocks.last.text += text;
          } else {
            blocks.add(ContentBlock(type: type, text: text));
          }
        }

        if (thinkChunk.isNotEmpty) {
          appendBlock(ContentBlockType.think, thinkChunk);
        } else if (toolcall.isNotEmpty) {
          // 工具调用内容（来自 toolcall key）
          appendBlock(ContentBlockType.tool, toolcall);
        } else if (contentChunk.isNotEmpty) {
          appendBlock(ContentBlockType.content, contentChunk);
        }

        // 更新消息内容
        final messageIndex = currentSession.messages.indexWhere(
          (msg) => msg.msgId == botMessageId,
        );

        if (messageIndex != -1) {
          final updatedMessages = List<ChatMessage>.from(
            currentSession.messages,
          );

          final isError =
              accumulatedContent.startsWith('请求失败') ||
              accumulatedContent.startsWith('API 错误') ||
              accumulatedContent.startsWith('网络连接错误') ||
              accumulatedContent.startsWith('连接错误');

          updatedMessages[messageIndex] = ChatMessage(
            msgId: botMessageId,
            role: MessageRole.bot,
            content: accumulatedContent,
            think:
                accumulatedThink.isNotEmpty ? accumulatedThink : '', // 保存思考内容
            contentBlocks: List<ContentBlock>.from(blocks),
            isToolCalling: botMessage.isToolCalling,
            timestamp: botMessage.timestamp,
            sessionId: session.sessionId,
            isError: isError,
            generationStartTime: startTime,
            // 在流式更新过程中不设置结束时间
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

      // 生成完成，计算性能统计
      final endTime = DateTime.now();
      final generationDuration = endTime.difference(startTime);

      // 估算token数量
      final estimatedOutputTokens = _estimateTokenCount(accumulatedContent);
      final estimatedInputTokens = _estimateTokenCount(userMessage.content);
      final estimatedTotalTokens = estimatedOutputTokens + estimatedInputTokens;

      // 完成生成，重置发送状态并更新性能统计
      final messageIndex = currentSession.messages.indexWhere(
        (msg) => msg.msgId == botMessageId,
      );

      if (messageIndex != -1) {
        final updatedMessages = List<ChatMessage>.from(currentSession.messages);
        updatedMessages[messageIndex] = ChatMessage(
          msgId: botMessageId,
          role: MessageRole.bot,
          content: accumulatedContent,
          think: accumulatedThink.isNotEmpty ? accumulatedThink : '', // 保存思考内容
          contentBlocks: List<ContentBlock>.from(blocks),
          timestamp: botMessage.timestamp,
          sessionId: session.sessionId,
          isError:
              accumulatedContent.startsWith('请求失败') ||
              accumulatedContent.startsWith('API 错误') ||
              accumulatedContent.startsWith('网络连接错误') ||
              accumulatedContent.startsWith('连接错误'),
          generationStartTime: startTime,
          generationEndTime: endTime,
          generationDuration: generationDuration,
          inputTokens: estimatedInputTokens,
          outputTokens: estimatedOutputTokens,
          totalTokens: estimatedTotalTokens,
        );

        final finalSession = currentSession.copyWith(
          messages: updatedMessages,
          isSending: false,
        );

        await sessionController.updateSession(finalSession);
      }

      // 无论是否找到 bot 消息，都必须重置发送状态
      final finalCheckSession = sessionController.currentSession.value;
      if (finalCheckSession?.isSending == true) {
        await sessionController.updateSession(
          finalCheckSession!.copyWith(isSending: false),
        );
      }

      // 强制触发UI更新 - 关键修复
      if (mounted) {
        widget.onUpdate?.call();
      }

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          AppLocalizations.of(context)!.xDone(actionName),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context)!.xFailed(actionName, e.toString()),
        );
      }

      // 重置发送状态
      final resetSession = session.copyWith(isSending: false);
      await sessionController.updateSession(resetSession);
      widget.onUpdate?.call();
    } finally {
      // 释放客户端资源
      client?.dispose();
    }
  }

  /// 估算文本的token数量
  /// 这是一个简单的估算方法，实际的token计算可能更复杂
  int _estimateTokenCount(String text) {
    if (text.isEmpty) return 0;

    // 简单估算：
    // - 中文字符：约1字符 = 1token
    // - 英文单词：约4字符 = 1token
    // - 标点符号：约1符号 = 0.5token

    int chineseChars = 0;
    int englishChars = 0;
    int punctuation = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text.codeUnitAt(i);
      if (char >= 0x4e00 && char <= 0x9fff) {
        // 中文字符范围
        chineseChars++;
      } else if ((char >= 65 && char <= 90) || (char >= 97 && char <= 122)) {
        // 英文字母
        englishChars++;
      } else if (char >= 33 && char <= 126) {
        // 标点符号和数字
        punctuation++;
      }
    }

    // 估算token数量
    final chineseTokens = chineseChars; // 中文1字符≈1token
    final englishTokens = (englishChars / 4).ceil(); // 英文4字符≈1token
    final punctuationTokens = (punctuation / 2).ceil(); // 标点2符号≈1token

    return chineseTokens + englishTokens + punctuationTokens;
  }

  // 编辑消息
  void _editMessage(BuildContext context, ChatMessage message) {
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
                  // 使用专用的编辑回调
                  if (newContent.trim().isEmpty) {
                    SnackBarUtils.showError(
                      context,
                      l10n.messageContentCannotBeEmpty,
                    );
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
                  SnackBarUtils.showError(
                    context,
                    l10n.messageContentCannotBeEmpty,
                  );
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

  // 从消息创建新对话
  Future<void> _createNewSessionFromMessage(
    BuildContext context,
    ChatMessage message,
  ) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      // 根据消息ID查找包含该消息的会话
      final session = await _findSessionContainingMessageAsync(message.msgId);
      if (session == null) {
        SnackBarUtils.showError(context, l10n.sessionNotFoundForMessage);
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
        widget.onUpdate?.call();

        SnackBarUtils.showSuccess(context, l10n.newChatCreatedFromHere);
      }
    } catch (e) {
      SnackBarUtils.showError(
        context,
        AppLocalizations.of(context)!.createNewChatFailed,
      );
    }
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
      ),
      h1: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      code: TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        color: Theme.of(context).colorScheme.onSurface,
      ),
      codeblockDecoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(
        fontSize: 12, // 思考内容使用更小的字体
        fontStyle: FontStyle.italic,
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6), // 更淡的颜色
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[400]!, width: 4)),
      ),
      listBullet: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
      tableHead: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
      tableHeadAlign: TextAlign.center,
      tableBody: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
      ),
      // 添加链接样式
      a: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue,
      ),
      // 思考内容样式 - 使用em标签的样式
      em: TextStyle(
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
    );
  }

  // ========== 内容块渲染 ==========

  /// 清理可能导致 flutter_markdown _inlines.isEmpty 断言的 markdown 内容
  /// 主要处理空内联元素：****, ** **, __, _ _, `` ` ``, []() 等
  static String _sanitizeMarkdown(String text) {
    if (text.isEmpty) return text;

    // 1. 移除零宽字符和不可见 Unicode 字符
    text = text.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u00A0\u2060]'), '');

    // 2. 空加粗: **** 或 **  ** 或 ** **  → 替换为占位内容
    text = text.replaceAll(RegExp(r'\*\*\s*\*\*'), '');

    // 3. 空斜体: * * → 移除 (仅独立出现时)
    text = text.replaceAll(RegExp(r'(?<!\*)\*\s\*(?!\*)'), '');

    // 4. 空下划线加粗: __ __ → 移除
    text = text.replaceAll(RegExp(r'__\s*__'), '');

    // 5. 空删除线: ~~ ~~ → 移除
    text = text.replaceAll(RegExp(r'~~\s*~~'), '');

    // 6. 空行内代码: ` ` → 移除
    text = text.replaceAll(RegExp(r'`\s*`'), '');

    // 7. 空链接: []() 或 [ ](url) → 移除
    text = text.replaceAll(RegExp(r'\[\s*\]\(.*?\)'), '');

    // 8. 连续空行压缩为单个空行
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 9. 表格文字居中：给分隔行添加 :---: 标记
    text = _centerTableAlign(text);

    return text;
  }

  /// 给 markdown 表格分隔行添加居中对齐标记
  /// 将 |------|------| 转换为 |:------:|:------:|
  /// 这样 flutter_markdown 会为 <td> 设置 align="center"
  static String _centerTableAlign(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // 判断是否为表格分隔行：以 | 开头，包含 --- 序列，只含 |-:空格字符
      if (_isTableSeparator(line)) {
        buffer.writeln(
          line.replaceAllMapped(
            RegExp(r'(?<!:)(-{3,})(?!:)'),
            (m) => ':${m.group(0)}:',
          ),
        );
      } else {
        buffer.writeln(line);
      }
    }

    return buffer.toString().trimRight();
  }

  /// 判断一行是否为 markdown 表格分隔行
  static bool _isTableSeparator(String line) {
    final trimmed = line.trim();
    return trimmed.isNotEmpty &&
        trimmed.startsWith('|') &&
        trimmed.contains(RegExp(r'-{3,}')) &&
        RegExp(r'^[\s\|\-:]+$').hasMatch(trimmed);
  }

  /// 按内容块构建 UI：
  /// 1. 思考块（原顺序）
  /// 2. 正文内容块（原顺序，纯内容不穿插工具）
  /// 3. 工具执行块（倒序，统一放在消息底部）
  /// 如果 contentBlocks 为空，回退到旧版渲染方式
  Widget _buildContentBlocks() {
    final blocks = widget.message.contentBlocks;

    // 回退兼容：旧消息没有 contentBlocks
    if (blocks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.think.isNotEmpty)
            _buildThinkBlock(widget.message.think),

          if (widget.message.content.isNotEmpty)
            MarkdownBody(
              data: _sanitizeMarkdown(widget.message.content),
              styleSheet: _buildMarkdownStyleSheet(),
              selectable: true,
              onTapLink: (text, href, title) {
                if (href != null) _openLink(href);
              },
            ),
          _buildFileTags(widget.message.content),
        ],
      );
    }

    final allContentText = StringBuffer();
    final contentTextBuffer = StringBuffer();
    final thinkWidgets = <Widget>[];
    final toolBlocks = <(int, ContentBlock)>[];

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      switch (block.type) {
        case ContentBlockType.think:
          thinkWidgets.add(_buildThinkBlock(block.text));
        case ContentBlockType.content:
          allContentText.write(block.text);
          contentTextBuffer.write(block.text);
        case ContentBlockType.tool:
        case ContentBlockType.toolCalling:
          allContentText.write(block.text);
          toolBlocks.add((i, block));
      }
    }

    // 工具块聚合：所有工具调用内容合并为一个块显示
    final children = <Widget>[
      ...thinkWidgets,
      // 所有 content 块合并为一个 MarkdownBody，保证跨段落文本可选
      if (contentTextBuffer.isNotEmpty)
        MarkdownBody(
          data: _sanitizeMarkdown(contentTextBuffer.toString()),
          styleSheet: _buildMarkdownStyleSheet(),
          selectable: true,
          onTapLink: (text, href, title) {
            if (href != null) _openLink(href);
          },
        ),
      _buildFileTags(allContentText.toString()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// 思考块（保持原有样式）
  Widget _buildThinkBlock(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.thinking,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建工具执行呼吸灯（执行时呼吸脉冲，闲置时暗淡常亮）
  Widget _buildToolIndicator() {
    final isCalling = widget.message.isToolCalling;
    return AnimatedBuilder(
      animation: _toolIndicatorAnimation,
      builder: (context, child) {
        final opacity = isCalling ? _toolIndicatorAnimation.value : 0.3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color:
                    isCalling
                        ? const Color.fromARGB(
                          255,
                          0,
                          100,
                          0,
                        ).withValues(alpha: opacity)
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: opacity),
                shape: BoxShape.circle,
                boxShadow:
                    isCalling
                        ? [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              0,
                              100,
                              0,
                            ).withValues(alpha: opacity * 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                        : null,
              ),
            ),
            if (isCalling) ...[
              const SizedBox(width: 6),
              Text(
                '正在执行工具',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// 从正文中提取本地绝对文件路径
  static List<String> _extractFilePaths(String text) {
    if (text.isEmpty) return [];
    final pathRegex = RegExp(
      r'(?<![(\[])(?<!file:\/{1,3})(\/(?:Users|home|tmp|var|etc|opt|srv)\/[\w./\-_\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]+\.(?:docx?|xlsx?|xls|csv|pdf|pptx?|png|jpe?g|gif|webp|bmp|tiff?|md|txt|json|html?|css|dart|py|js|ts|java|xml|yaml|yml|toml|sh|log))',
      caseSensitive: false,
    );
    return pathRegex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  /// 构建文件路径标签行（位于消息内容下方）
  Widget _buildFileTags(String text) {
    final paths = _extractFilePaths(text);
    if (paths.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children:
            paths.map((path) {
              final fileName =
                  path.contains('/')
                      ? path.substring(path.lastIndexOf('/') + 1)
                      : path;
              return GestureDetector(
                onTap: () => _openFile(path),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForExtension(fileName),
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// 根据文件扩展名返回对应图标
  IconData _iconForExtension(String fileName) {
    final ext =
        fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
            : '';
    switch (ext) {
      case 'pdf':
        return CupertinoIcons.doc_text;
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc_plaintext;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return CupertinoIcons.table;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
        return CupertinoIcons.photo;
      case 'pptx':
      case 'ppt':
        return CupertinoIcons.doc_richtext;
      case 'md':
      case 'txt':
        return CupertinoIcons.doc_text;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'toml':
        return CupertinoIcons.doc_text;
      default:
        return CupertinoIcons.doc;
    }
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

  // 显示AI消息菜单
  void _showAiMessageMenu(BuildContext context, Offset position) {
    final l10n = AppLocalizations.of(context)!;
    // 重置展开状态
    bool isRegenerateExpanded = false;
    bool isScreenshotExpanded = false;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
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

                    // 重新生成
                    _buildExpandableMenuOption(
                      context: context,
                      icon: CupertinoIcons.arrow_clockwise,
                      title: l10n.regenerate,
                      isExpanded: isRegenerateExpanded,
                      onToggle: () {
                        setMenuState(() {
                          isRegenerateExpanded = !isRegenerateExpanded;
                          // 关闭其他展开的菜单
                          isScreenshotExpanded = false;
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
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.reply,
                          title: l10n.regenerateThisReply,
                          onTap: () {
                            Navigator.pop(context);
                            _regenerateMessage(
                              RegenerateActionType.regenerateThisReply,
                            );
                          },
                        ),
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.arrow_left,
                          title: l10n.regenerateLastReply,
                          onTap: () {
                            Navigator.pop(context);
                            _regenerateMessage(
                              RegenerateActionType.regenerateLastReply,
                            );
                          },
                        ),
                      ],
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

                    // 截图
                    _buildExpandableMenuOption(
                      context: context,
                      icon: CupertinoIcons.camera,
                      title: l10n.screenshot,
                      isExpanded: isScreenshotExpanded,
                      onToggle: () {
                        setMenuState(() {
                          isScreenshotExpanded = !isScreenshotExpanded;
                          // 关闭其他展开的菜单
                          isRegenerateExpanded = false;
                        });
                      },
                      children: [
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.crop,
                          title: l10n.entireConversation,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onCaptureConversation?.call();
                          },
                        ),
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.arrow_down,
                          title: l10n.currentRound,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onCaptureRound?.call(widget.message);
                          },
                        ),
                        _buildSubMenuOption(
                          context: context,
                          icon: CupertinoIcons.square_on_square,
                          title: l10n.currentMessage,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onCaptureMessage?.call(widget.message);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 删除消息
                    _buildMenuOption(
                      context: context,
                      icon: CupertinoIcons.trash,
                      title: l10n.deleteMessage,
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await sessionController.deleteMessage(widget.message);
                          // 通知父组件更新
                          widget.onUpdate?.call();
                          SnackBarUtils.showSuccess(
                            context,
                            l10n.messageDeleted,
                          );
                        } catch (e) {
                          SnackBarUtils.showError(
                            context,
                            l10n.xFailed(l10n.deleteMessage, e.toString()),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 性能信息区域
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 显示真实的性能数据
                          if (widget.message.formattedDuration != null)
                            Text(
                              '${l10n.duration}: ${widget.message.formattedDuration}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Text(
                              '${l10n.duration}: ${l10n.calculating}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 2),
                          if (widget.message.formattedTokensPerSecond != null)
                            Text(
                              '${l10n.speed}: ${widget.message.formattedTokensPerSecond}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Text(
                              '${l10n.speed}: ${l10n.calculating}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 2),
                          if (widget.message.outputTokens != null)
                            Text(
                              '${l10n.outputTokensLabel}: ${widget.message.outputTokens}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Text(
                              '${l10n.outputTokensLabel}: ${l10n.calculating}',
                              style: TextStyle(
                                fontSize: 12,
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
                color: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.onSurface,
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
}
