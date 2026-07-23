import 'package:llmate/controllers/session_controller.dart';
import 'package:llmate/controllers/settings_controller.dart';
import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../models/chat/session.dart';

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

class _SessionItemState extends State<_SessionItem> {
  bool _isHovered = false;
  final sessionController = Get.find<SessionController>();
  List<ChatSession> get chatSessions => sessionController.sessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            widget.isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3)
                    : const Color(0xFFE5E7EB))
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            widget.isSelected
                ? Border.all(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2)
                          : const Color(0xFFD1D5DB),
                  width: 1,
                )
                : null,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onSessionSwitch(widget.session),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                // 对话信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 对话名称和收藏指示器
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.session.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    widget.isSelected
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // 收藏指示器 - 对收藏的会话始终显示小星星
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.session.chatModel?.name ??
                            widget.session.chatModel?.model ??
                            '未绑定模型',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            ? Icons.star
                            : Icons.star_border,
                        size: 12,
                        color:
                            widget.session.isFavorite
                                ? Colors.amber[600]
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      padding: EdgeInsets.zero,
                      tooltip:
                          widget.session.isFavorite
                              ? AppLocalizations.of(context)!.unfavorite
                              : AppLocalizations.of(context)!.favoriteSession,
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
                        Icons.delete_outline,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: AppLocalizations.of(context)!.deleteConversation,
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
    final l10n = AppLocalizations.of(context)!;
    final sessionName = widget.session.name;

    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: l10n.deleteConversation,
      itemName: sessionName,
      description: l10n.deleteConfirmMsg,
      warningMessage: l10n.deleteSessionTitle_warning,
      icon: Icons.chat_bubble_outline,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      sessionController.deleteSession(widget.session.sessionId);
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
  final bool hideHeaderRow; // macOS 自定义标题栏时隐藏内部顶部按钮栏

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
    this.onToggleFullscreen,
    this.hideHeaderRow = false,
  });

  @override
  State<ChatLeftSidebar> createState() => _ChatLeftSidebarState();
}

class _ChatLeftSidebarState extends State<ChatLeftSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  // 分组折叠状态
  bool _isFavoriteCollapsed = false;
  final Map<String, bool> _groupCollapsed = {};

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
        color: Theme.of(context).scaffoldBackgroundColor,
      ), // 适应主题的背景色
      child: Column(
        children: [
          // 顶部按钮栏（macOS 自定义标题栏时由外部控制，这里隐藏）
          if (!widget.hideHeaderRow)
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
                            Icons.fullscreen,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          tooltip: AppLocalizations.of(context)!.fullscreen,
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
                          Icons.edit,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        tooltip: AppLocalizations.of(context)!.newSession,
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
                          Icons.menu_open,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        tooltip: AppLocalizations.of(context)!.collapseSidebar,
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
          // 底部设置 + 主题切换
          Container(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                _buildSettingsButton(),
                const Spacer(),
                _buildThemeToggle(),
              ],
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
    final sessionController = Get.find<SessionController>();
    // 仅展示与当前全局模式匹配的会话，实现会话/管理模式列表完全独立
    final currentMode = sessionController.currentMode.value;
    final sessions = chatSessions ?? widget.chatSessions;

    // 收集收藏会话（在各自分组中仍保留显示，此处用于收藏区重复展示）
    final favoriteSessions = <int>[];
    final ungroupedSessions = <int>[];
    final groupMap = <String, List<int>>{}; // groupName -> [indices]

    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];

      // 过滤掉非当前模式的会话（index 仍为完整列表索引，供收藏回调使用）
      if (session.mode != currentMode) continue;

      // 收藏的会话仍保留在其所属分组/未分组中，同时在收藏区重复显示
      if (session.isFavorite) {
        favoriteSessions.add(i);
      }

      final groupName =
          (session.group != null && session.group!.trim().isNotEmpty)
              ? session.group!.trim()
              : null;

      if (groupName == null) {
        ungroupedSessions.add(i);
      } else {
        groupMap.putIfAbsent(groupName, () => []);
        groupMap[groupName]!.add(i);
      }
    }

    // 获取有会话的分组列表，按首次出现顺序
    final groups =
        groupMap.entries.toList()
          ..sort((a, b) => a.value.first.compareTo(b.value.first));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // 当前模式下无会话时的空状态提示
        if (favoriteSessions.isEmpty &&
            ungroupedSessions.isEmpty &&
            groups.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 8, right: 8),
            child: Text(
              currentMode == SessionMode.management
                  ? '暂无管理模式会话\n点击左上角「新建」开始'
                  : '暂无会话\n点击左上角「新建」开始',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.4),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        // 收藏分类
        if (favoriteSessions.isNotEmpty) ...[
          _buildCollapsibleGroupHeader(
            title: AppLocalizations.of(context)!.favorites,
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

        // 未分组会话
        if (ungroupedSessions.isNotEmpty) ...[
          ...ungroupedSessions.map((index) {
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

        // 各分组会话
        if (groups.isNotEmpty) ...[
          ...groups.map((entry) {
            final groupName = entry.key;
            final indices = entry.value;
            final isCollapsed = _groupCollapsed[groupName] ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCollapsibleGroupHeader(
                  title: groupName,
                  isCollapsed: isCollapsed,
                  onToggle:
                      () => setState(() {
                        _groupCollapsed[groupName] = !isCollapsed;
                      }),
                ),
                if (!isCollapsed) ...[
                  ...indices.map((index) {
                    final session = sessions[index];
                    final isSelected =
                        session.sessionId == currentSession?.sessionId;

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
            );
          }),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0, // -90度到0度
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 底部设置按钮
  Widget _buildSettingsButton() {
    return InkWell(
      key: widget.settingsButtonKey,
      onTap: widget.onShowSettings,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.settings, size: 15),
      ),
    );
  }

  // 底部主题切换按钮
  Widget _buildThemeToggle() {
    final themeController = Get.find<SettingsController>();
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return InkWell(
        onTap: () => themeController.toggleTheme(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            size: 15,
            color: isDark ? Colors.indigo[300] : Colors.amber[600],
          ),
        ),
      );
    });
  }

  // 构建主题切换按钮组件
  Widget _buildGreeting() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
