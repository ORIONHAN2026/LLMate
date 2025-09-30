import 'package:chathub/controllers/session_controller.dart';
import 'package:chathub/controllers/theme_controller.dart';
import 'package:chathub/widgets/common/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../models/chat/chat_session.dart';
import '../utils/model_icon_utils.dart';

// 会话项组件
class _SessionItem extends StatefulWidget {
  final ChatSession session;
  final int index;
  final bool isSelected;
  final Function(ChatSession) onSessionSwitch; // 修改为 sessionId
  final Function(int)? onDeleteSession;
  final Function(int)? onToggleFavoriteSession;
  final Function(dynamic)? onUpdate; // 修改为 sessionId

  const _SessionItem({
    required this.session,
    required this.index,
    required this.isSelected,
    this.onUpdate,

    required this.onSessionSwitch,
    this.onDeleteSession,
    this.onToggleFavoriteSession,
  });

  @override
  State<_SessionItem> createState() => _SessionItemState();
}

class _SessionItemState extends State<_SessionItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isEditing = false;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;
  final sessionController = Get.find<SessionController>();
  List<ChatSession> get chatSessions => sessionController.sessions;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  @override
  void initState() {
    super.initState();

    // 初始化文本编辑器和焦点节点
    _nameController = TextEditingController(text: widget.session.name);
    _nameFocusNode = FocusNode();

    // 初始化加载动画控制器
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.linear,
      ),
    );

    // 根据会话发送状态控制动画
    if (widget.session.isSending) {
      _loadingAnimationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_SessionItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 更新文本控制器内容
    if (widget.session.name != oldWidget.session.name) {
      _nameController.text = widget.session.name;
    }

    // 监听会话发送状态变化
    if (widget.session.isSending != oldWidget.session.isSending) {
      if (widget.session.isSending) {
        _loadingAnimationController.repeat();
      } else {
        _loadingAnimationController.stop();
        _loadingAnimationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isSelected 
            ? (Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
                : const Color(0xFFE5E7EB)) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            widget.isSelected
                ? Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                        : const Color(0xFFD1D5DB), 
                    width: 1)
                : null,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              _isEditing
                  ? null
                  : () => widget.onSessionSwitch(widget.session), // 编辑模式下禁用会话切换
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                // 模型图标
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      widget.session.isSending
                          ? _buildLoadingIcon()
                          : (widget.session.chatModel?.buildIconWidget(
                                widget.isSelected,
                              ) ??
                              _buildModelIconWidget(
                                widget.session.modelName,
                                widget.isSelected,
                              )),
                ),
                const SizedBox(width: 6),
                // 对话信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 对话名称和收藏指示器
                      Row(
                        children: [
                          Expanded(
                            child:
                                _isEditing
                                    ? _buildNameEditor()
                                    : _buildNameDisplay(),
                          ),

                          // 收藏指示器 - 对收藏的会话始终显示小星星
                        ],
                      ),
                      // 模型信息显示
                      if (widget.session.chatModel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.session.modelDisplayInfo,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  widget.isSelected
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // 操作按钮 - 始终存在但仅在悬停或选中时可见
                const SizedBox(width: 4),
                // 收藏按钮
                SizedBox(
                  width: 24,
                  height: 24,
                  child: AnimatedOpacity(
                    opacity: (_isHovered || widget.isSelected) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      onPressed:
                          (_isHovered || widget.isSelected)
                              ? () => widget.onToggleFavoriteSession?.call(
                                widget.index,
                              )
                              : null,
                      icon: Icon(
                        widget.session.isFavorite
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        size: 12,
                        color:
                            widget.session.isFavorite
                                ? Colors.amber[600]
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: widget.session.isFavorite ? '取消收藏' : '收藏会话',
                    ),
                  ),
                ),
                // 删除按钮
                SizedBox(
                  width: 24,
                  height: 24,
                  child: AnimatedOpacity(
                    opacity: (_isHovered || widget.isSelected) ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: IconButton(
                      onLongPress: () {
                        sessionController.deleteSession(
                          widget.session.sessionId,
                        );
                      },
                      onPressed:
                          (_isHovered || widget.isSelected)
                              ? () => _showDeleteConfirmation(context)
                              : null,
                      icon: Icon(
                        CupertinoIcons.trash,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: '删除会话',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 显示删除确认对话框
  void _showDeleteConfirmation(BuildContext context) async {
    final sessionName = widget.session.name;

    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '删除会话',
      itemName: sessionName,
      description: '确定要删除会话',
      warningMessage: '此操作无法撤销',
      icon: CupertinoIcons.chat_bubble,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      sessionController.deleteSession(widget.session.sessionId);
    }
  }

  // 根据模型名称获取对应的图标
  IconData _getModelIcon(String modelName) {
    final lowercaseName = modelName.toLowerCase();

    if (lowercaseName.contains('deepseek') || lowercaseName.contains('r1')) {
      return CupertinoIcons.cube_box;
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return CupertinoIcons.chat_bubble_2;
    } else if (lowercaseName.contains('claude')) {
      return CupertinoIcons.ant_circle;
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard')) {
      return CupertinoIcons.star;
    } else if (lowercaseName.contains('llama') ||
        lowercaseName.contains('meta')) {
      return CupertinoIcons.flame;
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi')) {
      return CupertinoIcons.cloud;
    } else if (lowercaseName.contains('chatglm') ||
        lowercaseName.contains('glm')) {
      return CupertinoIcons.bolt;
    } else if (lowercaseName.contains('baichuan')) {
      return CupertinoIcons.tree;
    } else if (lowercaseName.contains('wenxin') ||
        lowercaseName.contains('ernie')) {
      return CupertinoIcons.leaf_arrow_circlepath;
    } else if (lowercaseName.contains('spark') ||
        lowercaseName.contains('讯飞')) {
      return CupertinoIcons.flame_fill;
    } else {
      return CupertinoIcons.chat_bubble;
    }
  }

  // 根据模型名称获取对应的图标颜色
  Color _getModelIconColor(String modelName, bool isSelected) {
    if (isSelected) return Theme.of(context).colorScheme.onPrimary;

    final lowercaseName = modelName.toLowerCase();

    if (lowercaseName.contains('deepseek') || lowercaseName.contains('r1')) {
      return const Color(0xFF6366F1);
    } else if (lowercaseName.contains('gpt') ||
        lowercaseName.contains('openai')) {
      return const Color(0xFF10B981);
    } else if (lowercaseName.contains('claude')) {
      return const Color(0xFFF59E0B);
    } else if (lowercaseName.contains('gemini') ||
        lowercaseName.contains('bard')) {
      return const Color(0xFF3B82F6);
    } else if (lowercaseName.contains('llama') ||
        lowercaseName.contains('meta')) {
      return const Color(0xFFEF4444);
    } else if (lowercaseName.contains('qwen') ||
        lowercaseName.contains('tongyi')) {
      return const Color(0xFF8B5CF6);
    } else if (lowercaseName.contains('chatglm') ||
        lowercaseName.contains('glm')) {
      return const Color(0xFF06B6D4);
    } else if (lowercaseName.contains('baichuan')) {
      return const Color(0xFF84CC16);
    } else if (lowercaseName.contains('wenxin') ||
        lowercaseName.contains('ernie')) {
      return const Color(0xFFF97316);
    } else if (lowercaseName.contains('spark') ||
        lowercaseName.contains('讯飞')) {
      return const Color(0xFFEC4899);
    } else {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    }
  }

  // 根据模型名称构建对应的图标Widget
  Widget _buildModelIconWidget(String modelName, bool isSelected) {
    final lowercaseName = modelName.toLowerCase();

    // 使用统一的ModelIconUtils来处理图标
    return ModelIconUtils.buildModelIconWidget(
      modelName,
      isSelected,
      provider: widget.session.chatModel?.provider,
    );
  }

  // 构建精美的菊花样式加载动画
  Widget _buildLoadingIcon() {
    return RotationTransition(
      turns: _loadingAnimation,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
        child: CustomPaint(
          painter: _LoadingSpinnerPainter(
            color: Theme.of(context).colorScheme.onSurface, // 使用主题色
          ),
        ),
      ),
    );
  }

  // 构建名称显示组件
  Widget _buildNameDisplay() {
    return GestureDetector(
      onDoubleTap: () {
        // 阻止事件冒泡到外层InkWell
        _startEditing();
      },
      child: Text(
        widget.session.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: widget.isSelected 
              ? Theme.of(context).colorScheme.onSurface 
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // 构建名称编辑器组件
  Widget _buildNameEditor() {
    return TextField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: widget.isSelected 
            ? Theme.of(context).colorScheme.onSurface 
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      cursorWidth: 1.0, // 设置光标宽度为1.0像素（约为默认的2/3）
      cursorHeight: 12.0, // 设置光标高度为8.0像素（约为12px字体的2/3）
      maxLines: 1,
      onSubmitted: _finishEditing,
      onTapOutside: (_) => _finishEditing(_nameController.text),
    );
  }

  // 开始编辑会话名称
  void _startEditing() {
    if (_isEditing) return; // 防止重复调用

    setState(() {
      _isEditing = true;
    });

    // 使用更短的延迟确保状态更新后立即获取焦点
    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted && _nameFocusNode.canRequestFocus) {
        _nameFocusNode.requestFocus();
        // 将光标定位到文字末尾，而不是选中所有文字
        _nameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _nameController.text.length),
        );
      }
    });
  }

  // 完成编辑会话名称
  void _finishEditing(String newName) {
    if (!_isEditing) return;

    setState(() {
      _isEditing = false;
    });

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      // 如果名字为空，设置为默认名称"新会话"
      final updatedSession = widget.session.copyWith(title: '新会话');
      sessionController.updateSession(updatedSession);
      _nameController.text = '新会话'; // 同步更新控制器文本
    } else if (trimmedName != widget.session.name) {
      // 更新会话名称
      final updatedSession = widget.session.copyWith(title: trimmedName);
      sessionController.updateSession(updatedSession);
    } else {
      // 恢复原始名称
      _nameController.text = widget.session.name;
    }
  }
}

class ChatLeftSidebar extends StatefulWidget {
  final List<ChatSession> chatSessions;
  final int currentSessionIndex;
  final bool isCollapsed;
  final Function(ChatSession) onSessionSwitch;
  final VoidCallback onNewSession;
  final VoidCallback onToggleCollapse;
  final VoidCallback onShowSettings;
  final GlobalKey settingsButtonKey;
  final Function(int)? onDeleteSession;
  final Function(int)? onToggleFavoriteSession;
  final VoidCallback? onToggleFullscreen; // 全屏切换回调

  const ChatLeftSidebar({
    super.key,
    required this.chatSessions,
    required this.currentSessionIndex,
    required this.isCollapsed,
    required this.onSessionSwitch,
    required this.onNewSession,
    required this.onToggleCollapse,
    required this.onShowSettings,
    required this.settingsButtonKey,
    this.onDeleteSession,
    this.onToggleFavoriteSession,
    this.onToggleFullscreen, // 添加全屏回调参数
  });

  @override
  State<ChatLeftSidebar> createState() => _ChatLeftSidebarState();
}

class _ChatLeftSidebarState extends State<ChatLeftSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  // 分组折叠状态
  bool _isFavoriteCollapsed = false;
  bool _isTodayCollapsed = false;
  bool _isYesterdayCollapsed = false;
  bool _isEarlierCollapsed = false;

  @override
  void initState() {
    super.initState();

    // 初始化呼吸动画控制器
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2秒一个呼吸周期
      vsync: this,
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  // 检查是否有正在发送的消息
  bool get _hasMessageSending {
    return widget.chatSessions.any((session) => session.isSending);
  }

  @override
  void didUpdateWidget(ChatLeftSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听发送状态变化
    if (_hasMessageSending && !_breathingController.isAnimating) {
      _breathingController.repeat(reverse: true);
    } else if (!_hasMessageSending && _breathingController.isAnimating) {
      _breathingController.stop();
      _breathingController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      decoration: BoxDecoration(
        color:Theme.of(context).scaffoldBackgroundColor ,
      ), // 适应主题的背景色
      child: Column(
        children: [
          // 顶部按钮栏
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 标题或呼吸条
                _buildGreeting(),
                Row(
                  children: [
                    // 全屏按钮
                    if (widget.onToggleFullscreen != null)
                      IconButton(
                        onPressed: widget.onToggleFullscreen,
                        icon: Icon(
                          CupertinoIcons.fullscreen,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        tooltip: '全屏',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),

                    // 新建对话按钮
                    IconButton(
                      onPressed: widget.onNewSession,
                      icon: Icon(
                        CupertinoIcons.square_pencil,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: '新建对话',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 收起边栏按钮
                    IconButton(
                      onPressed: widget.onToggleCollapse,
                      icon: Icon(
                        CupertinoIcons.sidebar_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: '收起边栏',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 对话历史列表
          Expanded(
            child: Obx(() {
              // 监听SessionController的chatSessions变化
              final sessionController = Get.find<SessionController>();

              // 使用 sessionController 中的响应式会话列表
              return _buildChatSessionsList(
                chatSessions: sessionController.sessions,
                currentSession: sessionController.currentSession.value,
              );
            }),
          ),
          // 底部设置
          Container(
            padding: const EdgeInsets.all(5),
            child: _buildBottomMenuItem(
              key: widget.settingsButtonKey,
              icon: CupertinoIcons.gear,
              onTap: widget.onShowSettings,
            ),
          ),
        ],
      ),
    );
  }

  // 修改 _buildChatSessionsList 支持传参
  Widget _buildChatSessionsList({
    List<ChatSession>? chatSessions,
    ChatSession? currentSession,
  }) {
    final sessions = chatSessions ?? widget.chatSessions;

    // 分离收藏和按时间分类的会话
    final favoriteSessions = <int>[];
    final todaySessions = <int>[];
    final yesterdaySessions = <int>[];
    final earlierSessions = <int>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];

      // 收藏的会话始终在收藏分类中
      if (session.isFavorite) {
        favoriteSessions.add(i);
        continue;
      }

      // 非收藏会话按时间分类
      final sessionDate = DateTime(
        session.lastMessageTime.year,
        session.lastMessageTime.month,
        session.lastMessageTime.day,
      );

      if (sessionDate.isAtSameMomentAs(today)) {
        todaySessions.add(i);
      } else if (sessionDate.isAtSameMomentAs(yesterday)) {
        yesterdaySessions.add(i);
      } else {
        earlierSessions.add(i);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // 收藏分类
        if (favoriteSessions.isNotEmpty) ...[
          _buildCollapsibleGroupHeader(
            title: '收藏',
            isCollapsed: _isFavoriteCollapsed,
            onToggle:
                () => setState(
                  () => _isFavoriteCollapsed = !_isFavoriteCollapsed,
                ),
          ),
          if (!_isFavoriteCollapsed) ...[
            ...favoriteSessions.map((index) {
              final session = sessions[index];
              final isSelected = session.sessionId == currentSession?.sessionId;

              return _SessionItem(
                onUpdate: (sessionId) {
                  // 更新会话状态
                },
                session: session,
                index: index,
                isSelected: isSelected,
                onSessionSwitch: widget.onSessionSwitch,
                onDeleteSession: widget.onDeleteSession,
                onToggleFavoriteSession: widget.onToggleFavoriteSession,
              );
            }),
            const SizedBox(height: 8),
          ],
        ],

        // 今日分类
        if (todaySessions.isNotEmpty) ...[
          _buildCollapsibleGroupHeader(
            title: '今日',
            isCollapsed: _isTodayCollapsed,
            onToggle:
                () => setState(() => _isTodayCollapsed = !_isTodayCollapsed),
          ),
          if (!_isTodayCollapsed) ...[
            ...todaySessions.map((index) {
              final session = sessions[index];
              final isSelected = session.sessionId == currentSession?.sessionId;

              return _SessionItem(
                session: session,
                index: index,
                isSelected: isSelected,
                onSessionSwitch: widget.onSessionSwitch,
                onDeleteSession: widget.onDeleteSession,
                onToggleFavoriteSession: widget.onToggleFavoriteSession,
              );
            }),
            const SizedBox(height: 8),
          ],
        ],

        // 昨日分类
        if (yesterdaySessions.isNotEmpty) ...[
          _buildCollapsibleGroupHeader(
            title: '昨日',
            isCollapsed: _isYesterdayCollapsed,
            onToggle:
                () => setState(
                  () => _isYesterdayCollapsed = !_isYesterdayCollapsed,
                ),
          ),
          if (!_isYesterdayCollapsed) ...[
            ...yesterdaySessions.map((index) {
              final session = sessions[index];
              final isSelected = session.sessionId == currentSession?.sessionId;

              return _SessionItem(
                session: session,
                index: index,
                isSelected: isSelected,
                onSessionSwitch: widget.onSessionSwitch,
                onDeleteSession: widget.onDeleteSession,
                onToggleFavoriteSession: widget.onToggleFavoriteSession,
              );
            }),
            const SizedBox(height: 8),
          ],
        ],

        // 更早分类
        if (earlierSessions.isNotEmpty) ...[
          _buildCollapsibleGroupHeader(
            title: '更早',
            isCollapsed: _isEarlierCollapsed,
            onToggle:
                () =>
                    setState(() => _isEarlierCollapsed = !_isEarlierCollapsed),
          ),
          if (!_isEarlierCollapsed) ...[
            ...earlierSessions.map((index) {
              final session = sessions[index];
              final isSelected = session.sessionId == currentSession?.sessionId;

              return _SessionItem(
                session: session,
                index: index,
                isSelected: isSelected,
                onSessionSwitch: widget.onSessionSwitch,
                onDeleteSession: widget.onDeleteSession,
                onToggleFavoriteSession: widget.onToggleFavoriteSession,
              );
            }),
          ],
        ],
      ],
    );
  }

  // 构建可折叠的分组标题
  Widget _buildCollapsibleGroupHeader({
    required String title,
    required bool isCollapsed,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0, // -90度到0度
              duration: const Duration(milliseconds: 200),
              child: Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建底部菜单项
  Widget _buildBottomMenuItem({
    Key? key,
    required IconData icon,
    String? title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            if (title != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 构建主题切换按钮组件
  Widget _buildGreeting() {
    final themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      
      return InkWell(
        onTap: () {
          themeController.toggleTheme();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                size: 15,
                color: isDark ? Colors.indigo[300] : Colors.amber[600],
              ),
              // const SizedBox(width: 6),
              // Text(
              //   isDark ? '暗色' : '亮色',
              //   style: TextStyle(
              //     fontSize: 12,
              //     fontWeight: FontWeight.w500,
              //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              //   ),
              // ),
            ],
          ),
        ),
      );
    });
  }
}

// 自定义加载动画的画笔
class _LoadingSpinnerPainter extends CustomPainter {
  final Color color;

  _LoadingSpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    // 绘制12个线条，形成菊花效果
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180); // 每30度一个线条
      final startRadius = radius * 0.3;
      final endRadius = radius * 0.8;

      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);

      // 创建渐变效果 - 每个线条的透明度不同
      final opacity = 1.0 - (i / 12.0);
      paint.color = color.withValues(alpha: opacity * 0.8 + 0.2);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
