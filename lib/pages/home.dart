import 'package:flutter/cupertino.dart';
import 'package:chathub/controllers/session_controller.dart';
import 'package:chathub/pages/modelssetting.dart';
import 'package:chathub/pages/mcp_management_page.dart';
import 'package:chathub/pages/skill_management_page.dart';
import 'package:chathub/widgets/model_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../models/bigmodel/models.dart';
import '../controllers/model_controller.dart';
import '../services/skill_service.dart';
import '../widgets/chat_left_sidebar.dart';
import '../widgets/chat_right_sidebar.dart';
import '../widgets/chat_input_widget.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/utils/responsive_utils.dart';
import '../widgets/chat_conversation_area.dart';
import 'package:url_launcher/url_launcher.dart';

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
  double _sidebarWidth = 280.0; // 左侧边栏宽度，可调整
  bool _isRightSidebarCollapsed = false; // 右侧边栏折叠状态
  double _rightSidebarWidth = 260.0; // 右侧边栏宽度
  bool _isResizeHandleHovered = false; // 拖动条悬停状态
  bool _isRightResizeHandleHovered = false; // 右侧拖动条悬停状态
  // 中间聊天区域的最小可视宽度，避免被两侧面板挤压得太窄
  static const double _minChatAreaWidth = 520.0;

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
    SkillService.ensureLoaded(); // 异步加载技能（无需 await，有缓存机制）

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

        // 加载模型并转换为ChatModel
        _availableModels =
            models.map((modelMap) => ChatModel.fromMap(modelMap)).toList();

        // 检查当前选中的模型是否仍然存在
        final stillExists = _availableModels.any(
          (model) => model.name == currentSelectedModel,
        );

        if (stillExists) {
          // 如果当前选中的模型仍然存在，保持选择
          _selectedModel = currentSelectedModel;
        } else {
          // 如果当前选中的模型不存在，找到第一个活跃的模型，或者使用第一个模型
          final activeModel = _availableModels.firstWhere(
            (model) => model.status == 'active',
            orElse:
                () =>
                    _availableModels.isNotEmpty
                        ? _availableModels.first
                        : ChatModel.empty(),
          );

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
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新对话',
      createdAt: DateTime.now(),
      messages: [],
      chatModel: selectedModelObject, // 存储完整的模型对象，没有可用模型时为null
      inputContent: '', // 发送消息后清空会话的输入内容
      attachments: [], // 新会话的附件列表为空
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

    return ChatLeftSidebar(
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
    );
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
            '请选择或创建一个会话',
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
                    final leftSidebarWidth = _isSidebarCollapsed ? 0 : 280;
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

  // 显示设置菜单
  void _showSettingsMenu() {
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
        buttonPosition.dy - 180, // 在按钮上方显示菜单
        150, // 菜单宽度
        200, // 菜单高度
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor, // 使用主题色
      items: [
        PopupMenuItem(
          height: 48,
          onTap: _sendFeedbackEmail,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.mail,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              const Text('反馈意见', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        // 设置
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.wand_stars,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              const Text('模型管理', style: TextStyle(fontSize: 12)),
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
                // 从设置页面返回时重新加载模型列表
                _loadModels();
              }
            });
          },
        ),
        // MCP 工具管理
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.gear,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              const Text('连接器管理(MCP)', style: TextStyle(fontSize: 12)),
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
        // 技能管理
        PopupMenuItem(
          height: 48,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.wand_stars,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              const Text('技能管理(SKILL)', style: TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SkillManagementPage(),
                  ),
                );
              }
            });
          },
        ),
        // PopupMenuItem(
        //   height: 48,
        //   child: Row(
        //     children: [
        //       Icon(CupertinoIcons.gear, size: 16, color: Colors.grey[700]),
        //       const SizedBox(width: 12),
        //       const Text('其他设置', style: TextStyle(fontSize: 12)),
        //     ],
        //   ),
        //   onTap: () {
        //     Future.delayed(Duration.zero, () async {
        //       if (mounted) {
        //         await Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //             builder: (context) => const SystemSettingsPage(),
        //           ),
        //         );
        //       }
        //     });
        //   },
        // ),
        // 登录
        // PopupMenuItem(
        //   height: 48,
        //   child: Row(
        //     children: [
        //       Icon(
        //         CupertinoIcons.arrow_right_square,
        //         size: 16,
        //         color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        //       ),
        //       const SizedBox(width: 12),
        //       const Text('登录', style: TextStyle(fontSize: 12)),
        //     ],
        //   ),
        //   onTap: () {
        //     // TODO: 实现登录功能
        //     // TODO: 实现登录功能
        //   },
        // ),
      ],
    );
  }

  // 显示错误提示
  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  // 发送反馈邮件
  Future<void> _sendFeedbackEmail() async {
    const String feedbackEmail = 'hanxinyc@gmail.com';
    const String subject = 'ChatHub应用反馈';
    final String body = '''

-----------------------------
非常感谢您对ChatHub应用的反馈，每一条反馈信息我们都将认真对待。

谢谢！
''';

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // 如果无法启动邮箱应用，显示错误提示
        if (mounted) {
          SnackBarUtils.showError(context, '无法打开邮箱应用，请手动发送邮件至：$feedbackEmail');
        }
      }
    } catch (e) {
      // 发生错误时显示提示
      if (mounted) {
        SnackBarUtils.showError(context, '发送邮件失败：${e.toString()}');
      }
    }
  }

  // 发送升级高级版申请邮件
  // _sendUpgradeEmail 方法已删除（不再使用）

  // 处理删除会话的回调
  void _handleDeleteSession(dynamic value) {
    setState(() {});
  }

  // 切换会话收藏状态
  void _toggleFavoriteSession(int index) {
    if (index < 0 || index >= chatSessions.length) {
      _showErrorSnackBar('无效的会话索引');
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

    double proposed = (_sidebarWidth + delta).clamp(200.0, 400.0);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isRightSidebarCollapsed = !_isRightSidebarCollapsed;
          });
        },
        icon: Icon(
          _isRightSidebarCollapsed
              ? CupertinoIcons.sidebar_right
              : CupertinoIcons.sidebar_right,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(
            alpha: _isRightSidebarCollapsed ? 0.6 : 0.4,
          ),
        ),
        tooltip: _isRightSidebarCollapsed ? '展开右侧栏' : '收起右侧栏',
      ),
    );
  }

  // 右侧可调整大小的分隔条
  Widget _buildRightResizableHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isRightResizeHandleHovered = true),
      onExit: (_) => setState(() => _isRightResizeHandleHovered = false),
      child: GestureDetector(
        onPanUpdate: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          double proposed = (_rightSidebarWidth - details.delta.dx).clamp(
            200.0,
            400.0,
          );
          // 确保左侧和聊天区有足够空间
          final leftWidth = _isSidebarCollapsed ? 0 : _sidebarWidth;
          final remaining = screenWidth - leftWidth - proposed;
          if (remaining < _minChatAreaWidth) {
            proposed = (screenWidth - leftWidth - _minChatAreaWidth).clamp(
              200.0,
              400.0,
            );
          }
          setState(() => _rightSidebarWidth = proposed);
        },
        child: Container(
          width: 2,
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color:
                      _isRightResizeHandleHovered
                          ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建右侧面板
  Widget _buildRightSidePanel() {
    return ChatRightSidebar(
      width: _rightSidebarWidth,
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
      appBar: AppBar(
        title: const Text('ChatHub'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
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
    return Scaffold(
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
          // 右侧边栏
          if (!_isRightSidebarCollapsed) ...[
            _buildRightResizableHandle(),
            SizedBox(width: _rightSidebarWidth, child: _buildRightSidePanel()),
          ],
        ],
      ),
    );
  }

  // 桌面布局 - 原有布局
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // 左侧边栏 - 可调整宽度
          if (!_isSidebarCollapsed) ...[
            SizedBox(width: _sidebarWidth, child: _buildSidePanel()),
            // 可拖动的分隔条
            _buildResizableHandle(),
          ],
          // 主内容区域
          Expanded(
            child: Column(
              children: [
                // 顶部横跨整个界面的模型选择栏
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
          // 右侧边栏
          if (!_isRightSidebarCollapsed) ...[
            _buildRightResizableHandle(),
            SizedBox(width: _rightSidebarWidth, child: _buildRightSidePanel()),
          ],
        ],
      ),
    );
  }

  // 构建顶部栏
  Widget _buildTopBar(BuildContext context) {
    final topBarHeight = ResponsiveUtils.getTopBarHeight(context);

    return Container(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _isSidebarCollapsed = false;
                  });
                },
                icon: Icon(
                  CupertinoIcons.sidebar_left,
                  size: ResponsiveUtils.isMobile(context) ? 20 : 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                tooltip: '展开边栏',
              ),
            ),
          // 模型选择器组件化，选择逻辑交由组件内部处理
          Expanded(
            child: ModelSelector(
              currentSession: currentSession,
              availableModels: _availableModels,
              selectorKey: _modelSelectorKey,
            ),
          ),
          const SizedBox(width: 8),
          // 右侧边栏折叠按钮
          _buildRightSidebarToggle(),
        ],
      ),
    );
  }
}
