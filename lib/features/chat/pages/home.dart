import 'package:flutter/services.dart';
import 'package:llmate/controllers/session_controller.dart';
import 'package:llmate/features/chat/widgets/model_selector.dart';
import 'package:llmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../../../models/models.dart';
import '../../../widgets/standard_app_bar.dart';
import '../../../controllers/model_controller.dart';

import '../widgets/sidebars/chat_left_sidebar.dart';
import '../widgets/sidebars/chat_right_sidebar.dart';
import '../widgets/chat_input_widget.dart';
import 'package:llmate/utils/snackbar_utils.dart';
import 'package:llmate/utils/responsive_utils.dart';
import '../widgets/chat_conversation_area.dart';
import '../../settings/pages/modelssetting.dart';
import '../../mcp/pages/mcp_management_page.dart';

import '../../settings/pages/other_settings_page.dart';
import '../../settings/pages/domain_management_page.dart';
import '../widgets/usage_dashboard.dart';
import '../widgets/audit_viewer.dart';
import '../widgets/session_detail_page.dart';
import 'package:llmate/widgets/command_palette.dart';

class CodeChatHomePage extends StatefulWidget {
  const CodeChatHomePage({super.key});

  @override
  State<CodeChatHomePage> createState() => _CodeChatHomePageState();
}

class _CodeChatHomePageState extends State<CodeChatHomePage>
    with TickerProviderStateMixin {
  final sessionController = Get.find<SessionController>();
  List<ChatSession> get chatSessions => sessionController.sessions;
  ChatSession? get currentSession => sessionController.currentSession.value;

  // 滚动控制器和消息键映射（在 home 中创建和管理）
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};

  final GlobalKey _settingsButtonKey = GlobalKey(); // 设置按钮的key
  final GlobalKey _modelSelectorKey = GlobalKey(); // 模型选择器的key
  bool _isSidebarCollapsed = false; // 侧边栏折叠状态
  double _sidebarWidth = 200.0; // 左侧边栏宽度，可调整
  bool _isRightSidebarCollapsed = false; // 右侧边栏折叠状态（默认显示）
  bool _isResizeHandleHovered = false; // 拖动条悬停状态
  // 中间聊天区域的最小可视宽度，避免被两侧面板挤压得太窄
  static const double _minChatAreaWidth = 700.0;

  // 从 ChatInputWidget 获取的状态
  bool _autoScrollEnabled = true; // 是否启用自动滚动
  Set<String> _streamingMessageIds = {}; // 正在流式更新的消息ID集合

  // 滚动位置保存防抖Timer
  Timer? _scrollSaveTimer;
  // 模型相关数据
  String _selectedModel = 'DeepSeekR1';
  List<ChatModel> _availableModels = [];

  // 获取当前会话的消息历史
  List<ChatMessage> get chatHistory {
    final messages = currentSession?.messages ?? [];
    return messages;
  }

  @override
  void initState() {
    super.initState();

    _loadModels();
    _loadSessions(); // 加载保存的会话


    // 添加滚动监听器来保存滚动位置
    _scrollController.addListener(_onScrollChanged);
  }

  // 滚动位置变化时的回调
  void _onScrollChanged() {
    if (currentSession != null && _scrollController.hasClients) {
      // 取消之前的定时器
      _scrollSaveTimer?.cancel();

      // 防抖：避免频繁更新，只在滚动停止500ms后保存位置
      _scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        if (currentSession != null && _scrollController.hasClients) {
          final currentScrollPosition = _scrollController.offset;
          final updatedSession = currentSession!.copyWith(
            scrollPosition: currentScrollPosition,
          );
          sessionController.updateSession(updatedSession);
        }
      });
    }
  }

  // 加载模型数据
  Future<void> _loadModels() async {
    try {
      final modelController = Get.find<ModelController>();
      final models = await modelController.loadModels();

      setState(() {
        // 保存当前选中的模型名称
        final currentSelectedModel = _selectedModel;

        // 加载模型
        _availableModels = models;

        // 检查当前选中的模型是否仍然存在
        final stillExists = _availableModels.any(
          (model) => model.name == currentSelectedModel,
        );

        if (stillExists) {
          // 如果当前选中的模型仍然存在，保持选择
          _selectedModel = currentSelectedModel;
        } else {
          // 如果当前选中的模型不存在，使用第一个模型
          final activeModel =
              _availableModels.isNotEmpty
                  ? _availableModels.first
                  : ChatModel.empty();

          if (activeModel.name.isNotEmpty) {
            _selectedModel = activeModel.name;
          }
        }
      });
    } catch (e) {
      debugPrint('加载模型失败：$e');
    }
  }

  // 加载保存的会话
  Future<void> _loadSessions() async {
    try {
      // 同步模型选择器到当前会话绑定的模型
      if (currentSession?.chatModel != null) {
        // 确保绑定的模型在可用模型列表中
        final modelExists = _availableModels.any(
          (model) => model.name == currentSession!.chatModel!.name,
        );
        if (modelExists) {
          _selectedModel = currentSession!.chatModel!.name;
        }
      }

      debugPrint('成功加载 ${chatSessions.length} 个会话');
    } catch (e) {
      debugPrint('加载会话失败：$e');
    }
  }

  @override
  void dispose() {
    // 在组件销毁前保存最新的会话数据
    _scrollSaveTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();

    super.dispose();
  }

  // 创建新会话
  void _createNewSession() {
    // 获取当前选择的模型对象
    ChatModel? selectedModelObject;

    if (currentSession?.chatModel != null) {
      // 如果当前会话有绑定的模型，使用它
      selectedModelObject = currentSession!.chatModel;
    } else if (_availableModels.isNotEmpty) {
      // 如果有可用模型，尝试找到匹配的模型
      try {
        selectedModelObject = _availableModels.firstWhere(
          (model) => model.name == _selectedModel,
        );
      } catch (e) {
        // 如果没有找到匹配的模型，设置为null
        selectedModelObject = null;
      }
    } else {
      // 如果没有可用模型，设置为null
      selectedModelObject = null;
    }

    final newSession = ChatSession(
      sessionId: ChatSession.generateSessionId(),
      name: AppLocalizations.of(context)!.newSession,
      createdAt: DateTime.now(),
      messages: [],
      chatModel: selectedModelObject, // 存储完整的模型对象，没有可用模型时为null
      inputContent: '', // 发送消息后清空会话的输入内容
      mode: sessionController.currentMode.value, // 继承当前全局模式
    );

    // 先更新会话列表和当前会话，不要在setState中调用
    final newSessions = List<ChatSession>.from(chatSessions);
    newSessions.insert(0, newSession);
    sessionController.setSessions(newSessions);
    sessionController.setCurrentSession(newSession);

    // 然后更新UI状态
    setState(() {
      // 触发UI重建
    });
  }

  // 计算自适应右侧面板宽度，防止在小屏下出现 Row 溢出

  // 切换到指定会话（通过 sessionId）
  void _switchToSession(ChatSession chatSession) {
    // 保存当前会话的滚动位置
    if (currentSession != null && _scrollController.hasClients) {
      final currentScrollPosition = _scrollController.offset;
      final updatedCurrentSession = currentSession!.copyWith(
        scrollPosition: currentScrollPosition,
      );
      sessionController.updateSession(updatedCurrentSession);
    }

    // 先设置当前会话，不要在setState中调用
    sessionController.setCurrentSession(chatSession);

    // 然后更新模型选择器
    setState(() {
      // 同步模型选择器到当前会话绑定的模型
      if (chatSession.chatModel != null) {
        // 确保绑定的模型在可用模型列表中
        final modelExists = _availableModels.any(
          (model) => model.name == chatSession.chatModel!.name,
        );
        if (modelExists) {
          _selectedModel = chatSession.chatModel!.name;
        }
      }
    });

    // 恢复新会话的滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          chatSession.scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // 调试信息：会话切换

    // 验证会话列表的一致性
    _validateSessionConsistency();
  }

  // 验证会话列表的一致性（调试用）
  void _validateSessionConsistency() {
    // 这个方法在生产环境中被简化，仅在开发时使用
    if (currentSession != null) {
      final sessionInList = chatSessions.firstWhere(
        (session) => session.sessionId == currentSession!.sessionId,
        orElse:
            () => ChatSession(
              sessionId: '',
              name: '',
              createdAt: DateTime.now(),
              messages: [],
            ),
      );
      // 静默验证，不打印日志
      assert(sessionInList.sessionId.isNotEmpty, '当前会话在会话列表中不存在');
    }
  }

  Widget _buildSidePanel() {
    // 计算当前会话的索引
    final currentSessionIndex =
        currentSession != null
            ? chatSessions.indexWhere(
              (session) => session.sessionId == currentSession!.sessionId,
            )
            : -1;

    final bool hideHeader = Platform.isMacOS;
    final sidebar = ChatLeftSidebar(
      chatSessions: chatSessions,
      currentSessionIndex: currentSessionIndex,
      isCollapsed: _isSidebarCollapsed,
      onSessionSwitch: _switchToSession,
      onNewSession: _createNewSession,
      onToggleCollapse: () {
        setState(() {
          _isSidebarCollapsed = !_isSidebarCollapsed;
        });
      },
      onShowSettings: _showSettingsMenu,
      settingsButtonKey: _settingsButtonKey,
      onDeleteSession: _handleDeleteSession,
      onToggleFavoriteSession: _toggleFavoriteSession,
      hideHeaderRow: hideHeader,
    );

    // macOS: 把侧边栏顶部按钮和系统红绿灯放在同一行
    if (Platform.isMacOS) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 3, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _createNewSession,
                      icon: Icon(
                        Icons.edit,
                        size: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      tooltip: AppLocalizations.of(context)!.newSession,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(
                          () => _isSidebarCollapsed = !_isSidebarCollapsed,
                        );
                      },
                      icon: Icon(
                        Icons.menu_open,
                        size: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      tooltip: AppLocalizations.of(context)!.collapseSidebar,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: sidebar),
        ],
      );
    }
    return sidebar;
  }

  Widget _buildChatArea() {
    // 添加空会话检查
    if (currentSession == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.selectOrCreateSession,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 对话区域
              Flexible(
                child: ChatConversationArea(
                  chatSession: currentSession!,
                  scrollController: _scrollController,
                  messageKeys: _messageKeys,
                ),
              ),
              // 附件显示区域
              // _buildAttachmentsArea(),
              // 输入区域
              ChatInputWidget(
                currentSession: currentSession,
                scrollController: _scrollController,
                messageKeys: _messageKeys,
                onAutoScrollChanged: (autoScrollEnabled) {
                  setState(() {
                    _autoScrollEnabled = autoScrollEnabled;
                  });
                },
                onStreamingChanged: (streamingMessageIds) {
                  setState(() {
                    _streamingMessageIds = streamingMessageIds;
                  });
                },
              ),
            ],
          ),
          // 滚动到底部按钮 - 当用户手动滚动时显示
          if (!_autoScrollEnabled && chatHistory.isNotEmpty)
            Builder(
              builder: (context) {
                return Positioned(
                  left: () {
                    final leftSidebarWidth = _isSidebarCollapsed ? 0 : _sidebarWidth;
                    final screenWidth = MediaQuery.of(context).size.width;
                    final chatAreaWidth = screenWidth - leftSidebarWidth;
                    // 按钮居中于整个对话区域
                    return (chatAreaWidth / 2) - 12.5; // 12.5是按钮宽度的一半
                  }(),
                  bottom: 130, // 在输入区域上方
                  child: AnimatedOpacity(
                    opacity: !_autoScrollEnabled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Stack(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _autoScrollEnabled = true;
                              });
                              // 强制滚动到底部
                              if (_scrollController.hasClients) {
                                _scrollController.jumpTo(0.0);
                              }
                            },
                            icon: const Icon(
                              Icons.arrow_downward,
                              color: Colors.black,
                              size: 15,
                            ),
                          ),
                        ),
                        // 当前会话有流式消息正在更新时，显示小红点提示
                        if (_streamingMessageIds.isNotEmpty &&
                            currentSession != null &&
                            _streamingMessageIds.any(
                              (messageId) => currentSession!.messages.any(
                                (message) => message.msgId == messageId,
                              ),
                            ))
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    final l10n = AppLocalizations.of(context)!;
    // 获取设置按钮的渲染位置
    final RenderBox? button =
        _settingsButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    // 计算菜单显示位置 - 在按钮上方显示
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(
        buttonPosition.dx - 20, // 稍微向左偏移
        buttonPosition.dy - 310, // 在按钮上方显示菜单
        160, // 菜单宽度
        340, // 菜单高度
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      items: [
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 16,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              Text(l10n.usageDashboard, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              if (mounted) {
                UsageDashboard.show(context, global: true);
              }
            });
          },
        ),
        PopupMenuItem(
          enabled: false,
          height: 1,
          child: const Divider(height: 1, thickness: 1),
        ),
        PopupMenuItem(
          height: 48,
          onTap: _openFeedbackPage,
          child: Row(
            children: [
              Icon(
                Icons.mail_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(l10n.feedback, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(l10n.modelManagement, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModelSettingPage(),
                  ),
                );
                _loadModels();
              }
            });
          },
        ),
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.link,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(l10n.connectorManagement, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const McpManagementPage(),
                  ),
                );
              }
            });
          },
        ),
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.language,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(l10n.domainManagement, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DomainManagementPage(),
                  ),
                );
              }
            });
          },
        ),
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                Icons.tune,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Text(l10n.otherSettings, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OtherSettingsPage(),
                  ),
                );
              }
            });
          },
        ),
      ],
    );
  }

  // 显示命令面板
  void _showCommandPalette() {
    final l10n = AppLocalizations.of(context)!;
    final actions = <CommandPaletteAction>[
      CommandPaletteAction(
        id: 'new-session',
        title: l10n.newSession,
        subtitle: 'Create a new chat session',
        icon: Icons.edit,
        shortcut: '\u2318N',
        onTap: _createNewSession,
      ),
      CommandPaletteAction(
        id: 'toggle-sidebar',
        title: _isSidebarCollapsed
            ? (l10n.expandSidebar)
            : (l10n.collapseSidebar),
        icon: Icons.menu,
        shortcut: '\u2318B',
        onTap: () {
          setState(() {
            _isSidebarCollapsed = !_isSidebarCollapsed;
          });
        },
      ),
      CommandPaletteAction(
        id: 'toggle-right-panel',
        title: _isRightSidebarCollapsed
            ? (l10n.expandRightSidebar)
            : (l10n.collapseRightSidebar),
        icon: Icons.menu_open,
        shortcut: '\u2318]',
        onTap: () {
          setState(() {
            _isRightSidebarCollapsed = !_isRightSidebarCollapsed;
          });
        },
      ),
      CommandPaletteAction(
        id: 'settings',
        title: l10n.otherSettings,
        subtitle: 'Configure app preferences',
        icon: Icons.tune,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OtherSettingsPage(),
            ),
          );
        },
      ),
      CommandPaletteAction(
        id: 'model-management',
        title: l10n.modelManagement,
        subtitle: 'Manage AI models',
        icon: Icons.auto_awesome,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModelSettingPage(),
            ),
          );
          _loadModels();
        },
      ),
      CommandPaletteAction(
        id: 'mcp-management',
        title: l10n.connectorManagement,
        subtitle: 'Manage MCP connectors',
        icon: Icons.link,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const McpManagementPage(),
            ),
          );
        },
      ),
      CommandPaletteAction(
        id: 'send-feedback',
        title: l10n.feedback,
        subtitle: 'Open feedback page on GitHub',
        icon: Icons.mail_outline,
        onTap: _openFeedbackPage,
      ),
    ];
    CommandPalette.show(context, actions: actions);
  }

  // 打开反馈网页
  Future<void> _openFeedbackPage() async {
    final Uri feedbackUri = Uri.parse(
      'https://github.com/ORIONHAN2026/LLMate/issues',
    );
    try {
      if (await canLaunchUrl(feedbackUri)) {
        await launchUrl(
          feedbackUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  // 处理删除会话的回调
  void _handleDeleteSession(dynamic value) {
    setState(() {});
  }

  // 切换会话收藏状态
  void _toggleFavoriteSession(int index) {
    if (index < 0 || index >= chatSessions.length) {
      _showErrorSnackBar(AppLocalizations.of(context)!.invalidSessionIndex);
      return;
    }

    setState(() {
      final session = chatSessions[index];
      final newFavoriteStatus = !session.isFavorite;
      chatSessions[index] = session.copyWith(isFavorite: newFavoriteStatus);
      sessionController.updateSession(chatSessions[index]);
    });
  }

  // 处理侧边栏宽度调整
  void _onSidebarResize(double delta) {
    final screenWidth = MediaQuery.of(context).size.width;

    double proposed = (_sidebarWidth + delta).clamp(150.0, 400.0);
    // 计算剩余聊天区域宽度
    double remaining = screenWidth - proposed;
    if (remaining < _minChatAreaWidth) {
      // 调整左侧栏宽度使聊天区保持最小宽度
      proposed = (screenWidth - _minChatAreaWidth).clamp(200.0, 400.0);
      remaining = screenWidth - proposed;
    }

    // 如果屏幕太窄导致无法满足最小聊天宽度，允许聊天区变窄（降级处理）
    setState(() => _sidebarWidth = proposed);
  }

  // 构建可调整大小的分隔条
  Widget _buildResizableHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isResizeHandleHovered = true),
      onExit: (_) => setState(() => _isResizeHandleHovered = false),
      child: GestureDetector(
        onPanUpdate: (details) {
          _onSidebarResize(details.delta.dx);
        },
        child: Container(
          width: 2,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              right: BorderSide(
                color:
                    _isResizeHandleHovered
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3)
                        : Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 右侧边栏折叠按钮（顶部栏右侧）
  Widget _buildRightSidebarToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 审计查看入口
        IconButton(
          onPressed: () => AuditViewer.show(context, session: currentSession),
          icon: Icon(
            Icons.gavel_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: '审计查看',
        ),
        // 使用量仪表盘按钮
        IconButton(
          onPressed: () => UsageDashboard.show(context, session: currentSession),
          icon: Icon(
            Icons.bar_chart_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: AppLocalizations.of(context)!.usageDashboard,
        ),
        // 会话详情按钮 - 以 Tab 形式查看完整会话配置
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SessionDetailPage(),
              ),
            );
          },
          icon: Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: AppLocalizations.of(context)!.sessionDetails,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isRightSidebarCollapsed = !_isRightSidebarCollapsed;
              });
            },
            icon: Icon(
              _isRightSidebarCollapsed
                  ? Icons.menu_open
                  : Icons.menu_open,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: _isRightSidebarCollapsed ? 0.6 : 0.4,
              ),
            ),
            visualDensity: VisualDensity.compact,
            tooltip:
                _isRightSidebarCollapsed
                    ? AppLocalizations.of(context)!.expandRightSidebar
                    : AppLocalizations.of(context)!.collapseRightSidebar,
          ),
        ),
      ],
    );
  }

  // 右侧分隔条（固定宽度，不可拖拽）
  Widget _buildRightResizableHandle() {
    return Container(
      width: 2,
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  // 构建右侧面板
  Widget _buildRightSidePanel() {
    return ChatRightSidebar(
      width: 0, // 宽度由父级 Expanded 决定，不再需要此参数
      isCollapsed: _isRightSidebarCollapsed,
      onToggleCollapse: () {
        setState(() {
          _isRightSidebarCollapsed = !_isRightSidebarCollapsed;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBreakpoints(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  // 移动端布局 - 使用 Drawer 和全屏对话
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: StandardAppBar(
        showBack: false,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: AppLocalizations.of(context)!.appTitle,
        leadingWidth: Platform.isMacOS ? 70 : null,
        actions: [
          // 模型选择器 - 移动端简化版
          Expanded(
            child: ModelSelector(
              currentSession: currentSession,
              availableModels: _availableModels,
              selectorKey: _modelSelectorKey,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        width: ResponsiveUtils.getSidebarWidth(context),
        child: _buildSidePanel(),
      ),
      body: Column(
        children: [
          Expanded(
            child: GetX<SessionController>(
              builder: (controller) {
                return _buildChatArea();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 平板布局 - 混合桌面和移动端特性
  Widget _buildTabletLayout(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _showCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Row(
            children: [
              // 左侧边栏 - 可折叠
              if (!_isSidebarCollapsed) ...[
                SizedBox(
                  width: ResponsiveUtils.getSidebarWidth(context),
                  child: _buildSidePanel(),
                ),
                _buildResizableHandle(),
              ],
              // 主内容区域
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // 顶部模型选择栏
                    _buildTopBar(context),
                    Expanded(
                      child: GetX<SessionController>(
                        builder: (controller) {
                          return _buildChatArea();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧边栏 - 宽度为聊天窗口的 2/3
              if (!_isRightSidebarCollapsed) ...[
                _buildRightResizableHandle(),
                Expanded(flex: 2, child: _buildRightSidePanel()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 桌面布局
  Widget _buildDesktopLayout(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _showCommandPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Row(
            children: [
              // 左侧边栏 - 可调整宽度
              if (!_isSidebarCollapsed) ...[
                SizedBox(width: _sidebarWidth, child: _buildSidePanel()),
                _buildResizableHandle(),
              ],
              // 主内容区域
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // 顶部栏
                    _buildTopBar(context),
                    Expanded(
                      child: GetX<SessionController>(
                        builder: (controller) {
                          return _buildChatArea();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧边栏 - 宽度为聊天窗口的 2/3
              if (!_isRightSidebarCollapsed) ...[
                _buildRightResizableHandle(),
                Expanded(flex: 2, child: _buildRightSidePanel()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 构建顶部栏
  Widget _buildTopBar(BuildContext context) {
    final topBarHeight = ResponsiveUtils.getTopBarHeight(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (Platform.isMacOS) {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        }
      },
      child: Container(
        height: topBarHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            // 左侧展开按钮（当侧边栏折叠时显示）
            if (_isSidebarCollapsed)
              Transform.translate(
                offset: Offset(0, Platform.isMacOS ? -6 : 0),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: Platform.isMacOS ? 64 : 8,
                    top: 3,
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isSidebarCollapsed = false;
                      });
                    },
                    icon: Icon(
                      Icons.menu,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: AppLocalizations.of(context)!.expandSidebar,
                  ),
                ),
              ),
            const SizedBox(width: 2),
            // 模型选择器 - 贴着窗口控制按钮右边
            ModelSelector(
              currentSession: currentSession,
              availableModels: _availableModels,
              selectorKey: _modelSelectorKey,
            ),
            const Spacer(),
            // 右侧边栏折叠按钮
            _buildRightSidebarToggle(),
          ],
        ),
      ),
    );
  }
}
