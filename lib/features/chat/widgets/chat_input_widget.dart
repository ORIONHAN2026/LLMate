import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../controllers/session_controller.dart';
import '../../../controllers/message_controller.dart';
import '../../../controllers/mcp_controller.dart';
import '../../../models/models.dart';
import '../../../core/llm/llm_framework.dart';
import '../../../controllers/model_controller.dart';
import '../../../core/config/feature_toggle_service.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/confirm_delete_dialog.dart';
import '../../../services/storage_service.dart';

/// 聊天输入框组件
///
/// 完全自包含的聊天输入组件，包括：
/// - 文本输入框
/// - 发送功能
/// - 模型管理
/// - 会话管理
/// - 滚动控制
class ChatInputWidget extends StatefulWidget {
  /// 当前会话
  final ChatSession? currentSession;

  /// 滚动控制器（由父组件提供）
  final ScrollController scrollController;

  /// 消息键映射（由父组件提供）
  final Map<String, GlobalKey> messageKeys;

  /// 输入框提示文本
  final String hintText;

  /// 输入框最大行数
  final int maxLines;

  /// 自动滚动状态变化回调
  final Function(bool autoScrollEnabled)? onAutoScrollChanged;

  /// 流式消息状态变化回调
  final Function(Set<String> streamingMessageIds)? onStreamingChanged;

  const ChatInputWidget({
    super.key,
    required this.currentSession,
    required this.scrollController,
    required this.messageKeys,
    this.hintText = '',
    this.maxLines = 1,
    this.onAutoScrollChanged,
    this.onStreamingChanged,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final sessionController = Get.find<SessionController>();

  // 输入控制器和焦点
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;

  // 内部状态
  bool _hasText = false;
  bool _autoScrollEnabled = true;
  bool _isProgrammaticScroll = false; // 是否为程序触发的滚动

  // 消息发送相关状态
  final Set<String> _streamingMessageIds = {};

  final Map<String, Duration> _thinkingTimes = {};

  // 模型相关数据
  String _selectedModel = 'DeepSeekR1';
  List<ChatModel> _availableModels = [];
  // 预判是否为本次发送的文档整理类任务（避免多次判定不一致）
  // 移除原先的 _pendingOrganizeDoc 预判逻辑，改为仅依据最终 AI 回复内容判定是否保存整理文档

  // 监听器
  late final StreamSubscription _sessionSubscription;
  Timer? _textChangeTimer;

  /// 获取当前会话的发送状态
  bool get _isSending =>
      sessionController.currentSession.value?.isSending ?? false;

  // ── 方法 ──
  void initState() {
    super.initState();

    // 提前加载全局 MCP 配置，确保按钮状态正确
    McpController.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    // 加载功能开关配置
    FeatureToggleService().init();

    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();
    _hasText = _inputController.text.isNotEmpty;
    _inputController.addListener(_onTextChanged);
    widget.scrollController.addListener(_onScrollChanged);

    _sessionSubscription = sessionController.currentSession.listen((
      currentSession,
    ) async {
      // MCP 懒连接：不在会话切换时预初始化，等 LLM 返回工具调用时再按需连接。
      // 切换时由 SessionController.switchToSession() 统一断开旧连接。
    });

    _loadModels();

    // 延迟加载会话输入，避免在build期间调用setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSessionInput();
        // 初始化时自动聚焦到输入框
        _inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textChangeTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    widget.scrollController.removeListener(_onScrollChanged);
    _sessionSubscription.cancel(); // 先取消监听，阻止后续 setState
    // 关闭所有 MCP 客户端连接（在 dispose controller 之前）
    McpController.instance.closeAllClients();
    _inputController.dispose();
    _inputFocusNode.dispose();
    // scrollController 由父组件管理，不需要在这里 dispose
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSession?.sessionId !=
        widget.currentSession?.sessionId) {
      // 在切换会话前先保存当前输入内容
      _textChangeTimer?.cancel();
      if (oldWidget.currentSession != null) {
        // 延迟到 build 完成后执行，避免在 build 期间触发 Obx 的 setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _saveInputContentToSession();
        });
      }

      // 切换会话时重置本地发送锁，确保新会话可以正常发送
      _sendingInProgress = false;

      // 延迟加载新会话输入，避免在build期间调用setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadSessionInput();
          // 自动聚焦到输入框
          _inputFocusNode.requestFocus();
        }
      });
    }
  }

  /// 加载可用模型列表
  Future<void> _loadModels() async {
    try {
      final modelController = Get.find<ModelController>();
      final models = await modelController.loadModels();
      setState(() {
        _availableModels = models;
        if (models.isNotEmpty && !models.any((m) => m.name == _selectedModel)) {
          _selectedModel = models.first.name;
        }
      });
    } catch (e) {
      debugPrint('加载模型失败: $e');
    }
  }

  /// 加载会话的输入内容
  void _loadSessionInput() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession != null) {
      final inputContent = currentSession.inputContent;
      if (_inputController.text != inputContent) {
        _inputController.text = inputContent;
      }
    }
  }

  void _onTextChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // 使用定时器防抖，避免在build期间频繁更新会话
    _textChangeTimer?.cancel();
    _textChangeTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _saveInputContentToSession();
      }
    });
  }

  /// 保存输入内容到会话
  void _saveInputContentToSession() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession != null) {
      final updatedSession = currentSession.copyWith(
        inputContent: _inputController.text,
      );
      sessionController.updateSession(updatedSession);
    }
  }

  /// 创建新会话
  void _createNewSession() {
    // 获取当前选择的模型对象
    final selectedModelObject =
        _availableModels.isNotEmpty
            ? _availableModels.firstWhere(
              (model) => model.name == _selectedModel,
              orElse: () => _availableModels.first,
            )
            : ChatModel(
              modelId: ChatModel.generateModelId(),
              name: _selectedModel,
              model: _selectedModel,
            );

    final newSession = ChatSession(
      sessionId: ChatSession.generateSessionId(),
      name: AppLocalizations.of(context)!.newSession,
      createdAt: DateTime.now(),
      messages: [],
      chatModel: selectedModelObject,
      inputContent: '',
    );

    // 添加新会话到顶部并设为当前会话
    final newSessions = [newSession, ...sessionController.sessions];
    sessionController.setSessions(newSessions);
    sessionController.setCurrentSession(newSession);

    // 创建新会话后自动聚焦到输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  /// 将会话移到顶部
  void _moveSessionToTop(String sessionId) {
    final sessionIndex = sessionController.sessions.indexWhere(
      (session) => session.sessionId == sessionId,
    );

    if (sessionIndex > 0) {
      final newSessions = List<ChatSession>.from(sessionController.sessions);
      final session = newSessions.removeAt(sessionIndex);
      newSessions.insert(0, session);
      sessionController.setSessions(newSessions);
    }
  }

  /// 滚动监听器 - 检测用户是否正在手动滚动
  void _onScrollChanged() {
    if (widget.scrollController.hasClients) {
      // 如果是程序触发的滚动，忽略此次监听
      if (_isProgrammaticScroll) {
        return;
      }

      // 在反转的列表中，检查是否滚动到底部（实际上是位置接近0）
      final isAtBottom = widget.scrollController.position.pixels < 10;

      // 如果用户向上滚动（不在底部），禁用自动滚动
      if (!isAtBottom && _autoScrollEnabled) {
        setState(() {
          _autoScrollEnabled = false;
        });
        widget.onAutoScrollChanged?.call(_autoScrollEnabled);
      }
      // 如果用户手动滚动到底部，重新启用自动滚动
      else if (isAtBottom && !_autoScrollEnabled) {
        setState(() {
          _autoScrollEnabled = true;
        });
        widget.onAutoScrollChanged?.call(_autoScrollEnabled);
      }
    }
  }

  /// 滚动到底部
  void _scrollToBottom({bool force = false}) {
    if (!mounted) return;

    // 只有在启用自动滚动或强制滚动时才滚动到底部
    if (widget.scrollController.hasClients && (_autoScrollEnabled || force)) {
      _isProgrammaticScroll = true; // 立即标记为程序触发的滚动，防止监听器干扰

      // 对于强制滚动（点击按钮），立即执行，不需要延迟
      if (force) {
        // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在下一帧执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients) {
            // 在反转的列表中，滚动到底部实际上是滚动到位置0
            debugPrint('强制滚动到底部（反转列表的位置0）');
            widget.scrollController.jumpTo(0.0);
          }
          // 短暂延迟后重置标志
          Future.delayed(const Duration(milliseconds: 100), () {
            _isProgrammaticScroll = false;
          });
        });
      } else {
        // 对于自动滚动，保持原有延迟逻辑，但在执行前再次检查状态
        Future.delayed(const Duration(milliseconds: 100), () {
          // 再次检查自动滚动状态，防止在延迟期间用户已滚动
          if (widget.scrollController.hasClients && _autoScrollEnabled) {
            // 在反转的列表中，滚动到底部实际上是滚动到位置0
            widget.scrollController.jumpTo(0.0);
          }
          // 延迟重置标志，确保滚动完全完成
          Future.delayed(const Duration(milliseconds: 50), () {
            _isProgrammaticScroll = false;
          });
        });
      }
    }
  }

  /// 公共方法：强制滚动到底部并启用自动滚动（供父组件调用）
  void forceScrollToBottom() {
    setState(() {
      _autoScrollEnabled = true;
    });
    widget.onAutoScrollChanged?.call(_autoScrollEnabled);
    _scrollToBottom(force: true);
  }

  /// 获取当前自动滚动状态
  bool get autoScrollEnabled => _autoScrollEnabled;

  /// 获取当前流式消息ID集合
  Set<String> get streamingMessageIds => _streamingMessageIds;

  /// 停止消息生成
  void _stopMessage() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession != null) {
      final updatedSession = currentSession.copyWith(
        shouldStopResponse: true,
        isSending: false,
      );
      sessionController.updateSession(updatedSession);

      // 停止消息生成后自动聚焦到输入框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 输入框（附件显示在输入框下方）
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  final isEnterPressed =
                      event.logicalKey == LogicalKeyboardKey.enter;
                  final isShiftPressed = event.isShiftPressed;

                  if (isEnterPressed && !isShiftPressed && !_isSending) {
                    // 普通回车发送消息
                    _sendMessage();
                    return;
                  }
                  // Shift+回车会自然地插入换行符，无需特殊处理
                }
              },
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                style: const TextStyle(fontSize: 14),
                cursorHeight: 16, // 设置光标高度与文字大小匹配
                decoration: InputDecoration(
                  hintText:
                      widget.hintText.isNotEmpty
                          ? widget.hintText
                          : l10n.inputHint,
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                maxLines: 8, // 最多显示8行，超出后内部滚动
                minLines: 1, // 最少显示1行
              ),
            ),
            // 功能按钮组
            Container(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧功能按钮（可横向滚动）
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildChatModeToggle(),
                          const SizedBox(width: 8),
                          _buildDeepThinkToggle(),
                          const SizedBox(width: 8),
                          _buildMcpToolsToggle(),
                          const SizedBox(width: 8),

                          _buildCleanHistoryToggle(),
                          // Container(
                          //   height: 16,
                          //   width: 1,
                          //   color: Theme.of(context).dividerColor,
                          //   margin: const EdgeInsets.symmetric(horizontal: 2),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  // 右侧发送/停止按钮
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: _buildSendStopButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建发送/停止按钮
  Widget _buildSendStopButton() {
    if (_isSending) {
      // 正在发送时显示停止按钮
      return Tooltip(
        message: AppLocalizations.of(context)!.stopAnswer,
        child: InkWell(
          onTap: _stopMessage,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.stop,
              size: 10,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      );
    } else if (_hasText) {
      // 有文字输入时显示发送按钮
      return Tooltip(
        message: AppLocalizations.of(context)!.sendMessageAction,
        child: InkWell(
          onTap: _sendMessage,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_upward,
              size: 10,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      );
    } else {
      // 无文字输入时不显示按钮，但保持高度一致
      return const SizedBox(width: 16, height: 16);
    }
  }

  /// 构建聊天模式切换按钮（会话模式 / 管理模式）
  /// 模式是每个会话各自的设置：点击切换「当前会话」的模式。
  Widget _buildChatModeToggle() {
    return Obx(() {
      final currentSession = sessionController.currentSession.value;
      final isManagement = currentSession?.mode == SessionMode.management;
      final onSurface = Theme.of(context).colorScheme.onSurface;
      final active = !_isSending && currentSession != null;
      return Tooltip(
        message:
            isManagement
                ? '管理模式：本地直连大模型，不计入用量统计'
                : '会话模式：经本地服务做审计与用量统计',
        child: GestureDetector(
          onTap:
              active
                  ? () {
                    if (currentSession != null) {
                      sessionController.updateSession(
                        currentSession.copyWith(
                          mode:
                              isManagement
                                  ? SessionMode.session
                                  : SessionMode.management,
                        ),
                      );
                    }
                  }
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isManagement
                      ? Icons.admin_panel_settings_outlined
                      : Icons.chat_bubble_outline,
                  size: 13,
                  color:
                      active ? onSurface : onSurface.withOpacity(0.3),
                ),
                const SizedBox(width: 4),
                Text(
                  isManagement ? '管理模式' : '会话模式',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isManagement ? FontWeight.w700 : FontWeight.w500,
                    color:
                        active ? onSurface : onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 删除历史记录
  Widget _buildCleanHistoryToggle() {
    return Tooltip(
      message: AppLocalizations.of(context)!.clearConversation,
      child: InkWell(
        onTap: _isSending ? null : _clearHistory,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.brush,
            size: 13,
            color:
                _isSending
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// 构建深度思考开关按钮
  Widget _buildDeepThinkToggle() {
    final currentSession = sessionController.currentSession.value;
    final isDeepThink = currentSession?.deepThink ?? false;

    return Tooltip(
      message:
          isDeepThink
              ? AppLocalizations.of(context)!.deepThinkEnabled
              : AppLocalizations.of(context)!.deepThinkDisabled,
      child: GestureDetector(
        onTap:
            _isSending
                ? null
                : () {
                  if (currentSession != null) {
                    sessionController.updateSession(
                      currentSession.copyWith(deepThink: !isDeepThink),
                    );
                  }
                },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDeepThink ? Icons.psychology : Icons.psychology_outlined,
                size: 13,
                color:
                    _isSending
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3)
                        : isDeepThink
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context)!.deepThink,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDeepThink ? FontWeight.w700 : FontWeight.w500,
                  color:
                      _isSending
                          ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3)
                          : isDeepThink
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 聊天窗口的 MCP 仅为展示查看（实际配置在「会话详情 - MCP配置」tab 中完成）。
  /// 若当前会话未绑定任何 MCP，则显示「无MCP配置」；若已绑定，点击可弹出只读查看面板。
  Widget _buildMcpToolsToggle() {
    return Obx(() {
      final currentSession = sessionController.currentSession.value;

      // 管理模式：不向大模型注入会话 MCP 工具，隐藏聊天输入框的 MCP 入口
      if (currentSession?.mode == SessionMode.management) {
        return const SizedBox.shrink();
      }

      final sessionMcps = currentSession?.mcps;
      final mcpCount = sessionMcps?.length ?? 0;

      final displayText = mcpCount > 0 ? '$mcpCount 个 MCP' : '无MCP配置';

      final onSurface = Theme.of(context).colorScheme.onSurface;

      final canView = mcpCount > 0 && !_isSending;

      return Tooltip(
        message:
            mcpCount > 0
                ? '当前会话绑定的 MCP（点击查看，可在会话详情中配置）'
                : '当前会话未配置 MCP',
        child: GestureDetector(
          onTap: canView ? () => _showMcpViewDialog(sessionMcps!) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link,
                  size: 13,
                  color:
                      _isSending
                          ? onSurface.withOpacity(0.3)
                          : mcpCount > 0
                          ? onSurface
                          : onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          mcpCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      color:
                          _isSending
                              ? onSurface.withOpacity(0.3)
                              : mcpCount > 0
                              ? onSurface
                              : onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 弹出当前会话已绑定 MCP 的只读查看面板（不可在此新增/编辑）。
  void _showMcpViewDialog(List<String> mcpNames) {
    final l10n = AppLocalizations.of(context)!;
    final mcpc = McpController.instance;
    final resolved =
        mcpNames
            .map((name) => mcpc.getMcp(name))
            .where((m) => m != null)
            .cast<Mcp>()
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.link,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.mcpBoundTitle(resolved.length),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child:
                resolved.isEmpty
                    ? Text(
                      l10n.noMcpServiceConfigured,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    )
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children:
                            resolved
                                .map((mcp) => _buildMcpViewCard(theme, mcp))
                                .toList(),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 单个 MCP 的只读展示卡片
  Widget _buildMcpViewCard(ThemeData theme, Mcp mcp) {
    final typeLabel =
        mcp.url != null && mcp.url!.isNotEmpty
            ? (mcp.type?.value ?? 'url')
            : 'stdio';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mcp.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          if (mcp.description != null && mcp.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mcp.description!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          if (mcp.tools != null && mcp.tools!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '工具 (${mcp.tools!.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 4),
            ...mcp.tools!.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t.description.isNotEmpty
                            ? '${t.name}：${t.description}'
                            : t.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 命令面板通用搜索栏
  Widget _buildCommandPaletteSearchBar({
    required TextEditingController controller,
    required String title,
    required VoidCallback onChanged,
    bool autofocus = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: (_) => onChanged(),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeCommandOrSearch,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  bool _sendingInProgress = false; // 本地防重入锁

  /// 发送消息的主要方法
  Future<void> _sendMessage() async {
    // 本地防重入锁：避免并发调用
    if (_sendingInProgress) return;
    _sendingInProgress = true;

    try {
      final text = _inputController.text.trim();
      debugPrint('发送消息: $text');

      // 防止发送空消息或重复发送
      if (text.isEmpty || _isSending) {
        return;
      }

      // 直接发送消息，MCP工具调用将在AI响应过程中处理
      await _doSendMessage(text);
    } finally {
      _sendingInProgress = false;
    }
  }

  /// 实际执行发送消息的方法
  Future<void> _doSendMessage(String text) async {
    debugPrint('🚀 开始执行 _doSendMessage');

    // 如果没有当前会话，创建一个新会话
    var updateSession = sessionController.currentSession.value;
    if (updateSession == null) {
      _createNewSession();
      // 等待一帧以确保新会话被创建
      await Future.delayed(const Duration(milliseconds: 50));
      updateSession = sessionController.currentSession.value;
      if (updateSession == null) {
        // 无法创建会话，停止发送
        return;
      }
    }

    // 生成唯一的时间戳ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 创建用户消息对象
    final userMessage = ChatMessage(
      msgId: '${timestamp}_user',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
      sessionId: updateSession.sessionId,
    );

    // 为用户消息创建GlobalKey
    widget.messageKeys[userMessage.msgId] = GlobalKey();

    // 立即更新会话状态
    final updatedSession = updateSession.copyWith(
      messages: [...updateSession.messages, userMessage],
      inputContent: '',
      isSending: true,
    );

    sessionController.updateSession(updatedSession);
    // 用户消息单条落盘
    MessageController.instance.addMessage(userMessage);

    setState(() {});

    // 等待下一帧确保UI更新完成
    await Future.delayed(const Duration(milliseconds: 50));

    // UI操作
    _inputController.clear();
    // 不再直接清空本地附件状态，依靠监听器同步
    _moveSessionToTop(updatedSession.sessionId);
    _inputFocusNode.requestFocus();
    _autoScrollEnabled = true;

    // 强制滚动到底部显示新消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });

    // 生成AI响应，使用包含附件的会话
    try {
      final modelId = updatedSession.chatModel?.modelId ?? "";
      if (modelId.isEmpty) {
        throw (AppLocalizations.of(context)!.noModelBound);
      }

      await _generateAIResponse(updatedSession, userMessage);
    } catch (e) {
      _handleSendError(e);
    }
  }

  /// 生成AI响应
  Future<void> _generateAIResponse(
    ChatSession updateSession,
    ChatMessage userMessage,
  ) async {
    LlmClient? client;
    try {
      final startTime = DateTime.now();

      // 创建空白AI消息对象
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final botMessageId = '${timestamp}_bot';
      final botMessage = ChatMessage(
        msgId: botMessageId,
        role: MessageRole.bot,
        content: '',
        reason: '',
        timestamp: DateTime.now(),
        sessionId: updateSession.sessionId,
        isError: false,
        generationStartTime: startTime, // 记录生成开始时间
      );

      // 为AI消息创建GlobalKey
      widget.messageKeys[botMessage.msgId] = GlobalKey();

      // 标记消息为流式更新中
      _streamingMessageIds.add(botMessageId);
      widget.onStreamingChanged?.call(_streamingMessageIds);

      // 添加AI消息到会话
      final messagesWithBot = List<ChatMessage>.from(updateSession.messages)
        ..add(botMessage);
      updateSession = updateSession.copyWith(
        messages: messagesWithBot,
        isSending: true,
        shouldStopResponse: false,
      );

      sessionController.updateSession(updateSession);
      // AI 消息单条落盘
      MessageController.instance.addMessage(botMessage);
      setState(() {});

      // 调用API生成流式响应
      String accumulatedContent = '';
      String accumulatedThink = '';
      final List<ContentBlock> blocks = [];

      // 直接使用LLM Hub框架
      final model = updateSession.chatModel;
      if (model == null) {
        throw Exception(AppLocalizations.of(context)!.modelConfigNotFound);
      }

      // 创建 LLM 客户端
      client = LlmClient(updateSession);

      // // 验证配置
      // final isValid = await client.validateConfiguration();
      // if (!isValid) {
      //   throw Exception('Model config validation failed, please check API Key and URL settings');
      // }

      // 直接调用 LLMClient（本地聊天不走 HTTP）
      final responseStream = client.LLMChat(userMessage);

      // 处理流式响应并更新UI（LlmClient 已在内部处理 MCP 工具调用和 follow-up）
      // chunk 格式: {content,think,tool}  三个字段互斥，每次必有一个有值
      await for (final chunkMap in responseStream) {
        // 检查用户是否要求停止响应，同时获取最新会话状态（含 deepThink）
        final latestSession = sessionController.sessions.firstWhere(
          (s) => s.sessionId == updateSession.sessionId,
          orElse: () => updateSession,
        );
        if (latestSession.shouldStopResponse == true) break;

        final contentChunk = chunkMap['content'] ?? '';
        final thinkChunk = chunkMap['think'] ?? '';
        final tool = (chunkMap['tool'] ?? '').toString();
        final toolcall = (chunkMap['toolcall'] ?? '').toString();

        // 深度思考关闭时，过滤掉 think 数据（即使模型原生产生推理内容也不展示）
        final effectiveThinkChunk = latestSession.deepThink ? thinkChunk : '';

        // 处理工具调用状态标记（布尔值）
        if (tool == 'true') {
          botMessage.isToolCalling = true;
        } else if (tool == 'false') {
          botMessage.isToolCalling = false;
        }

        // 处理流结束信号
        if ((chunkMap['done'] ?? '') == 'true') {
          botMessage.isToolCalling = false;
          updateSession = updateSession.copyWith(isSending: false);
          sessionController.updateSession(updateSession);
          // 落盘最终 AI 消息
          MessageController.instance.updateMessage(botMessage);
          setState(() {});
          break; // 收到 done 后立即退出循环
        }

        if (contentChunk.isNotEmpty ||
            effectiveThinkChunk.isNotEmpty ||
            toolcall.isNotEmpty) {
          accumulatedContent += contentChunk;
          accumulatedThink += effectiveThinkChunk;

          // 按顺序构建内容块（toolcall 不再混入 think）
          void appendBlock(ContentBlockType type, String text) {
            if (blocks.isNotEmpty && blocks.last.type == type) {
              blocks.last.text += text;
            } else {
              blocks.add(ContentBlock(type: type, text: text));
            }
          }

          if (effectiveThinkChunk.isNotEmpty) {
            appendBlock(ContentBlockType.think, effectiveThinkChunk);
          } else if (toolcall.isNotEmpty) {
            appendBlock(ContentBlockType.tool, toolcall);
          } else if (contentChunk.isNotEmpty) {
            appendBlock(ContentBlockType.content, contentChunk);
          }

          final messageIndex = updateSession.messages.indexWhere(
            (msg) => msg.msgId == botMessageId,
          );

          if (messageIndex != -1) {
            botMessage.content = accumulatedContent;
            botMessage.reason = accumulatedThink;
            botMessage.contentBlocks = List<ContentBlock>.from(blocks);

            final updatedMessages = List<ChatMessage>.from(
              updateSession.messages,
            );
            updatedMessages[messageIndex] = botMessage;

            updateSession = updateSession.copyWith(
              messages: updatedMessages,
              isSending: true,
            );

            sessionController.updateSession(updateSession);
            // 流式更新期间持续落盘 AI 消息
            MessageController.instance.updateMessage(botMessage);
            setState(() {});

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      }

      // 流式响应完成后的清理工作和性能统计
      final endTime = DateTime.now();
      final generationDuration = endTime.difference(startTime);

      // 估算token数量（简单估算：按字符数计算，中文约2字符=1token，英文约4字符=1token）
      final estimatedOutputTokens = _estimateTokenCount(accumulatedContent);
      final estimatedInputTokens = _estimateTokenCount(userMessage.content);
      final estimatedTotalTokens = estimatedOutputTokens + estimatedInputTokens;

      // 更新最终的AI消息，包含完整的性能统计
      final messageIndex = updateSession.messages.indexWhere(
        (msg) => msg.msgId == botMessageId,
      );

      ChatMessage? finalBotMessage;
      if (messageIndex != -1) {
        final updatedMessages = List<ChatMessage>.from(updateSession.messages);
        finalBotMessage = botMessage.copyWith(
          isError:
              accumulatedContent.startsWith('请求失败') ||
              accumulatedContent.startsWith('API 错误') ||
              accumulatedContent.startsWith('网络连接错误') ||
              accumulatedContent.startsWith('连接错误'),
          generationStartTime: startTime,
          generationEndTime: endTime,
          generationDuration: generationDuration,
          promptTokens: estimatedInputTokens,
          completionTokens: estimatedOutputTokens,
          totalTokens: estimatedTotalTokens,
        );
        updatedMessages[messageIndex] = finalBotMessage;
        updateSession = updateSession.copyWith(messages: updatedMessages);
      }
      // 落盘最终的 AI 消息（含性能统计）
      if (finalBotMessage != null) {
        MessageController.instance.updateMessage(finalBotMessage);
      }

      // 流式响应完成，无论是否找到 bot 消息，都必须重置发送状态
      final finalSession = sessionController.currentSession.value;
      if (finalSession?.sessionId == updateSession.sessionId) {
        sessionController.updateSession(
          updateSession.copyWith(isSending: false),
        );
      }

      setState(() {
        _thinkingTimes[botMessageId] = generationDuration;
        _streamingMessageIds.remove(botMessageId);
      });
      widget.onStreamingChanged?.call(_streamingMessageIds);
    } catch (e) {
      rethrow;
    } finally {
      // 一律重置发送状态，避免 stop 按钮残留
      // 注意：必须使用局部变量 updateSession，不能读取 sessionController.currentSession.value
      // 因为 updateSession() 内部是 Future.microtask 异步执行，
      // finally 块同步运行时 currentSession.value 还是旧值（可能丢失 memory），
      // 如果写入旧值会覆盖掉已写入的 memory 数据。
      try {
        if (updateSession.isSending == true) {
          sessionController.updateSession(
            updateSession.copyWith(isSending: false),
          );
        }
        if (_streamingMessageIds.isNotEmpty) {
          setState(() {
            _streamingMessageIds.clear();
          });
          widget.onStreamingChanged?.call(_streamingMessageIds);
        }
      } catch (_) {}

      // 释放客户端资源
      try {
        client?.dispose();
      } catch (e) {
        // 忽略释放资源时的错误
      }

      _sendingInProgress = false;
    }
  }

  // 旧的指令关键词判断函数已移除，统一改为基于最终输出结构判断

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

  /// 处理发送错误
  void _handleSendError(dynamic error) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final errorMessage = ChatMessage(
        msgId: timestamp.toString(),
        role: MessageRole.bot,
        content: AppLocalizations.of(
          context,
        )!.serviceUnavailable(error.toString()),
        timestamp: DateTime.now(),
        sessionId: currentSession.sessionId,
        isError: true,
      );

      widget.messageKeys[errorMessage.msgId] = GlobalKey();

      final updatedMessages = List<ChatMessage>.from(currentSession.messages)
        ..add(errorMessage);

      sessionController.updateSession(
        currentSession.copyWith(messages: updatedMessages, isSending: false),
      );
      // 错误消息单条落盘
      MessageController.instance.addMessage(errorMessage);
      setState(() {});

      _scrollToBottom();
    }
  }

  /// 清除当前会话的历史记录
  void _clearHistory() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // 显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Theme.of(context).colorScheme.secondary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.confirmClear,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.clearHistoryConfirmMsg,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
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
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performClearHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.clear,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 执行清除历史记录操作
  void _performClearHistory() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // 清空消息列表，保留会话其他信息
    final clearedSession = currentSession.copyWith(
      messages: [],
      isSending: false,
      shouldStopResponse: false,
    );

    // 更新会话
    sessionController.updateSession(clearedSession);
    // 清空 DB 中的消息（保留会话与目录）
    MessageController.instance.clearMessages(currentSession.sessionId);

    // 清空相关的UI状态
    setState(() {
      _streamingMessageIds.clear();
      _thinkingTimes.clear();
    });
    widget.onStreamingChanged?.call(_streamingMessageIds);

    // 清空消息键映射
    widget.messageKeys.clear();

    // 显示成功提示
    if (mounted) {
      SnackBarUtils.showSuccess(
        context,
        AppLocalizations.of(context)!.historyCleared,
      );
    }

    // 强制滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
      // 清除历史记录后自动聚焦到输入框
      _inputFocusNode.requestFocus();
    });
  }
}
