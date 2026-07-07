import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../../../controllers/session_controller.dart';
import '../../../controllers/mcp_controller.dart';
import '../../../models/models.dart';
import '../../../core/llm/llm_framework.dart';
import '../../models/controllers/model_controller.dart';
import '../../../core/config/feature_toggle_service.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/common/confirm_delete_dialog.dart';
import '../../../data/storage_service.dart';
import '../../../models/chat/contract_info.dart';
import './scheduled_task_dialog.dart';

/// 聊天输入框组件
///
/// 完全自包含的聊天输入组件，包括：
/// - 文本输入框
/// - 发送功能
/// - 附件、图片、网页等功能按钮
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

  // @文件提及相关状态
  bool _showFileMention = false;
  String _fileMentionFilter = '';
  int _fileMentionAtOffset = 0;
  OverlayEntry? _fileMentionOverlayEntry;

  List<FileSystemEntity> _workDirFiles = [];
  bool _hasFileMention = false;

  // 监听器
  late final StreamSubscription _sessionSubscription;
  Timer? _textChangeTimer;

  /// 获取当前会话的发送状态
  bool get _isSending =>
      sessionController.currentSession.value?.isSending ?? false;

  /// 获取当前会话的附件列表
  List<ChatAttachment> get _currentAttachments =>
      sessionController.currentSession.value?.attachments ?? [];

  // ── @文件提及相关方法 ──

  /// 检测输入中的 @ 并显示文件选择列表
  void _checkForFileMention() {
    final text = _inputController.text;
    final cursorPos = _inputController.selection.baseOffset;

    if (cursorPos < 0) {
      _hideFileMentionOverlay();
      return;
    }

    int atPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == '@') {
        atPos = i;
        break;
      } else if (ch == ' ' || ch == '\n' || ch == '\r') {
        break;
      }
    }

    if (atPos >= 0) {
      final filter = text.substring(atPos + 1, cursorPos);
      if (filter.contains(' ') || filter.contains('\n')) {
        _hideFileMentionOverlay();
        return;
      }
      _fileMentionFilter = filter;
      _fileMentionAtOffset = atPos;
      _loadWorkDirFiles();
    } else {
      _hideFileMentionOverlay();
    }
  }

  /// 加载工作目录下的文件列表
  Future<void> _loadWorkDirFiles() async {
    final currentSession = sessionController.currentSession.value;
    final workDir = currentSession?.workDirectory;

    if (workDir == null || workDir.trim().isEmpty) {
      setState(() {
        _workDirFiles = [];
        _showFileMention = false;
      });
      return;
    }

    try {
      final dir = Directory(workDir);
      if (!await dir.exists()) {
        setState(() {
          _workDirFiles = [];
          _showFileMention = false;
        });
        return;
      }

      // 递归获取所有文件（排除隐藏文件和常见忽略目录）
      final files = <FileSystemEntity>[];
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final relativePath = entity.path.substring(workDir.length + 1);
          // 跳过隐藏文件和常见忽略目录
          if (relativePath.startsWith('.') ||
              relativePath.contains('/.') ||
              relativePath.contains('node_modules') ||
              relativePath.contains('.git') ||
              relativePath.contains('build') ||
              relativePath.contains('.dart_tool')) {
            continue;
          }
          files.add(entity);
        }
      }

      setState(() {
        _workDirFiles = files;
        _showFileMention = true;
      });
      _updateFileMentionOverlay();
    } catch (e) {
      debugPrint('加载工作目录文件失败: $e');
      setState(() {
        _workDirFiles = [];
        _showFileMention = false;
      });
    }
  }

  /// 过滤文件列表
  List<FileSystemEntity> _getFilteredFiles() {
    if (_fileMentionFilter.isEmpty) return _workDirFiles;

    final filter = _fileMentionFilter.toLowerCase();
    return _workDirFiles.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      final relativePath =
          file.path
              .substring(
                (sessionController
                            .currentSession
                            .value
                            ?.workDirectory
                            ?.length ??
                        0) +
                    1,
              )
              .toLowerCase();
      return fileName.contains(filter) || relativePath.contains(filter);
    }).toList();
  }

  /// 插入文件引用到输入框
  void _insertFileMention(String filePath) {
    final text = _inputController.text;
    final currentCursor = _inputController.selection.baseOffset;

    final workDir = sessionController.currentSession.value?.workDirectory ?? '';
    final relativePath =
        filePath.startsWith(workDir)
            ? filePath.substring(workDir.length + 1)
            : filePath;

    final insertText = '@$relativePath ';

    final before = text.substring(0, _fileMentionAtOffset);
    final after = text.substring(currentCursor);
    final newText = '$before$insertText$after';

    _inputController.text = newText;
    final newCursorPos = _fileMentionAtOffset + insertText.length;
    _inputController.selection = TextSelection.collapsed(offset: newCursorPos);

    _hideFileMentionOverlay();
    setState(() {
      _showFileMention = false;
      _hasFileMention = true; // 标记有文件引用，启用修订模式
    });
  }

  /// 显示文件提及弹出层
  void _updateFileMentionOverlay() {
    _hideFileMentionOverlay();

    final filtered = _getFilteredFiles();
    if (filtered.isEmpty) return;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (ctx) => _buildFileMentionPopup());
    _fileMentionOverlayEntry = entry;
    overlay.insert(entry);
  }

  /// 隐藏文件提及弹出层
  void _hideFileMentionOverlay() {
    _fileMentionOverlayEntry?.remove();
    _fileMentionOverlayEntry = null;
  }

  /// 构建文件提及弹出层
  Widget _buildFileMentionPopup() {
    final filtered = _getFilteredFiles();
    final workDir = sessionController.currentSession.value?.workDirectory ?? '';

    return Positioned(
      left: 20,
      right: 20,
      bottom: 120, // 在输入框上方显示
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索提示
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '选择工作目录下的文件',
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
              // 文件列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length > 8 ? 8 : filtered.length,
                  itemBuilder: (context, index) {
                    final file = filtered[index];
                    final relativePath = file.path.substring(
                      workDir.length + 1,
                    );
                    final fileName = file.path.split('/').last;

                    return InkWell(
                      onTap: () => _insertFileMention(file.path),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.doc,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (relativePath != fileName)
                                    Text(
                                      relativePath,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
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
    widget.scrollController.addListener(
      _onScrollChanged,
    ); // 监听当前会话的变化，确保附件状态及时更新

    _sessionSubscription = sessionController.currentSession.listen((
      currentSession,
    ) async {
      // MCP 懒连接：不在会话切换时预初始化，等 LLM 返回工具调用时再按需连接。
      // 切换时由 SessionController.switchToSession() 统一断开旧连接。

      if (mounted && currentSession != null) {
        // 附件状态变化时触发UI更新
        setState(() {
          // UI会自动从getter获取最新的附件列表
        });
      } else if (mounted && currentSession == null) {
        // 当前会话为空时，触发UI更新
        setState(() {
          // UI会自动从getter获取空的附件列表
        });
      }
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
    _hideFileMentionOverlay();
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
      final modelMaps = await modelController.loadModels();
      final models = modelMaps.map((map) => ChatModel.fromMap(map)).toList();
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

      // 延迟触发UI更新以加载会话的附件（通过getter获取）
      if (mounted) {
        setState(() {
          // UI会自动从getter获取最新的附件列表
        });
      }
    } else {
      if (mounted) {
        setState(() {
          // UI会自动从getter获取空的附件列表
        });
      }
    }
  }

  /// 保存选择的目录到当前会话
  void _saveLastSelectedDirectory(String filePath) {
    try {
      final directory = File(filePath).parent.path;
      final currentSession = sessionController.currentSession.value;
      if (currentSession != null) {
        // 更新会话的目录记录
        final updatedSession = currentSession.copyWith(
          lastSelectedDirectory: directory,
        );
        sessionController.updateSession(updatedSession);
        debugPrint('保存目录到会话: $directory');
      }
    } catch (e) {
      debugPrint('保存目录失败: $e');
    }
  }

  /// 获取文件选择的初始目录（从当前会话）
  String? _getInitialDirectory() {
    final currentSession = sessionController.currentSession.value;
    return currentSession?.getInitialDirectory();
  }

  void _onTextChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // 检测 @ 文件提及相关输入
    _checkForFileMention();

    // 检查是否还有文件引用
    final text = _inputController.text;
    final hasAtMention = text.contains('@') && _showFileMention;
    if (_hasFileMention && !hasAtMention && text.trim().isEmpty) {
      setState(() {
        _hasFileMention = false;
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
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: AppLocalizations.of(context)!.newSession,
      createdAt: DateTime.now(),
      messages: [],
      chatModel: selectedModelObject,
      inputContent: '',
      attachments: [],
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

  /// 选择文件附件
  Future<void> _pickFile() async {
    try {
      debugPrint("开始选择文件...");

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: false,
        withReadStream: false,
        allowCompression: false,
        dialogTitle: '选择文件',
        initialDirectory: _getInitialDirectory(), // 使用初始目录
      );

      debugPrint("文件选择结果: $result");

      if (result == null) {
        debugPrint("用户取消了文件选择");
        // 用户主动取消，不显示提示避免闪烁
        return;
      }

      if (result.files.isEmpty) {
        debugPrint("没有选择任何文件");
        // 文件列表为空，不显示提示避免闪烁
        return;
      }

      debugPrint("选择了 ${result.files.length} 个文件");

      // 处理多个文件 - 批量添加避免竞态条件
      final validFiles = <PlatformFile>[];
      int duplicateCount = 0;
      int oversizedCount = 0;

      // 先过滤所有有效文件
      for (final file in result.files) {
        debugPrint("检查文件: ${file.name}, 路径: ${file.path}, 大小: ${file.size}");

        if (file.path == null) {
          debugPrint("文件路径为空: ${file.name}");
          // 文件路径为空，跳过处理，不显示提示避免闪烁
          continue;
        }

        // 检查文件大小并显示相应提示
        if (file.size > 50 * 1024 * 1024) {
          // 50MB 以上拒绝，不显示提示避免闪烁
          oversizedCount++;
          continue;
        }

        // 检查是否已存在相同文件（通过文件路径和大小判断）
        final isDuplicate = _currentAttachments.any(
          (attachment) =>
              attachment.filePath == file.path && attachment.size == file.size,
        );

        if (isDuplicate) {
          debugPrint("文件已存在，跳过: ${file.name}");
          duplicateCount++;
          continue;
        }

        validFiles.add(file);
      }

      debugPrint(
        "文件处理统计: 总计${result.files.length}个，有效${validFiles.length}个，重复$duplicateCount个，超大$oversizedCount个",
      );

      if (validFiles.isNotEmpty) {
        // 批量添加所有有效文件
        await _addMultipleAttachments(validFiles, 'document');

        // 保存选择的目录（使用第一个文件的目录）
        if (validFiles.isNotEmpty && validFiles.first.path != null) {
          _saveLastSelectedDirectory(validFiles.first.path!);
        }

        // 文件添加成功，不显示提示，通过附件状态可见
      }
      // 移除 "没有成功添加任何文件" 的提示，避免不必要的闪烁
    } catch (e) {
      debugPrint("选择文件时发生错误: $e");
      // 选择文件失败，不显示提示避免闪烁
    }
  }

  /// 批量添加多个附件到当前会话（避免竞态条件）
  Future<void> _addMultipleAttachments(
    List<PlatformFile> files,
    String defaultType,
  ) async {
    if (files.isEmpty) return;

    // 检查文件大小限制并过滤
    final oversizedFiles =
        files.where((file) => file.size > 50 * 1024 * 1024).toList();
    final validFiles =
        files.where((file) => file.size <= 50 * 1024 * 1024).toList();

    if (oversizedFiles.isNotEmpty && mounted) {
      // 超过大小限制的文件，不显示弹窗，直接过滤掉避免闪烁
      debugPrint('过滤掉 ${oversizedFiles.length} 个超大文件');
    }

    if (validFiles.isEmpty) return;

    // 确保有当前会话
    ChatSession? currentSession = sessionController.currentSession.value;
    if (currentSession == null) {
      _createNewSession();
      await Future.delayed(const Duration(milliseconds: 100));
      // 重新获取当前会话
      currentSession = sessionController.currentSession.value;
      if (currentSession == null) {
        // 无法创建会话，不显示提示避免闪烁
        return;
      }
    }

    // 再次过滤重复文件（基于当前会话中的附件）
    final currentAttachments = currentSession.attachments;
    final uniqueFiles =
        validFiles.where((file) {
          final isDuplicate = currentAttachments.any(
            (attachment) =>
                attachment.filePath == file.path &&
                attachment.size == file.size,
          );
          if (isDuplicate) {
            debugPrint("批量添加时发现重复文件，跳过: ${file.name}");
          }
          return !isDuplicate;
        }).toList();

    if (uniqueFiles.isEmpty) {
      debugPrint("所有文件都已存在，无需添加");
      return;
    }

    // 批量创建所有附件对象
    final List<ChatAttachment> newAttachments = [];
    final List<String> attachmentIds = [];

    for (final file in uniqueFiles) {
      final attachmentId =
          '${DateTime.now().millisecondsSinceEpoch}_${newAttachments.length}';
      attachmentIds.add(attachmentId);

      // 根据文件扩展名判断类型
      String attachmentType = defaultType;
      if (file.extension != null) {
        final ext = file.extension!.toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext)) {
          attachmentType = 'image';
        } else if (['.md', '.txt', '.doc', '.docx', '.pdf'].contains(ext)) {
          attachmentType = 'document';
        } else if ([
          '.go',
          '.py',
          '.js',
          '.html',
          '.css',
          '.dart',
          '.java',
          '.cpp',
        ].contains(ext)) {
          attachmentType = 'code';
        }
      }

      final attachment = ChatAttachment(
        id: attachmentId,
        name: file.name,
        type: attachmentType,
        filePath: file.path!,
        size: file.size,
        createdAt: DateTime.now(),
      );

      newAttachments.add(attachment);
      debugPrint(
        '创建附件对象: ${attachment.name}, ID: ${attachment.id}, 大小: ${attachment.size}',
      );
    } // 一次性更新会话，添加所有附件
    final updatedAttachments = List<ChatAttachment>.from(
      currentSession.attachments,
    );
    updatedAttachments.addAll(newAttachments);

    final updatedSession = currentSession.copyWith(
      attachments: updatedAttachments,
    );

    await sessionController.updateSession(updatedSession);
    debugPrint('批量添加 ${newAttachments.length} 个附件到会话: ${updatedSession.name}');

    // 异步处理每个文件内容
    for (int i = 0; i < newAttachments.length; i++) {
      final attachment = newAttachments[i];
      final attachmentId = attachmentIds[i];

      // 不等待，让文件处理在后台进行
      _processAttachmentInBackground(
        attachmentId,
        attachment,
        currentSession.sessionId,
      );
    }
  }

  /// 后台处理附件（使用系统内置工具读取文件内容）
  Future<void> _processAttachmentInBackground(
    String attachmentId,
    ChatAttachment attachment,
    String targetSessionId,
  ) async {
    debugPrint('开始后台处理附件: ${attachment.name}，目标会话: $targetSessionId');

    try {
      final processedAttachment = await _readAttachmentContent(attachment);

      debugPrint(
        '文件处理完成: ${attachment.name}, 内容长度: ${processedAttachment.content?.length ?? 0}',
      );

      await _updateAttachmentInSession(
        attachmentId,
        processedAttachment,
        targetSessionId,
      );
    } catch (e) {
      debugPrint('处理附件时出错: $e');

      final errorAttachment = attachment.copyWith(content: 'ERROR_PROCESSING');
      await _updateAttachmentInSession(
        attachmentId,
        errorAttachment,
        targetSessionId,
      );
    }
  }

  /// 根据文件格式读取附件内容
  Future<ChatAttachment> _readAttachmentContent(
    ChatAttachment attachment,
  ) async {
    if (attachment.filePath == null || attachment.filePath!.isEmpty) {
      return attachment;
    }

    final file = File(attachment.filePath!);
    if (!await file.exists()) {
      return attachment.copyWith(content: '[文件不存在或已被移动]');
    }

    final ext = p.extension(attachment.name).toLowerCase();

    try {
      // ── 图片：base64 编码原文 ──
      if (const [
        '.png',
        '.jpg',
        '.jpeg',
        '.gif',
        '.webp',
        '.bmp',
        '.tiff',
        '.ico',
      ].contains(ext)) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        final mimeType = _imageMimeType(ext);
        return attachment.copyWith(
          type: 'image',
          content: '图片文件: ${attachment.name}',
          base64Data: base64Str,
          mimeType: mimeType,
          size: await file.length(),
        );
      }

      // ── 文本/代码与二进制文件：尝试作为文本读取 ──
      try {
        final content = await file.readAsString(encoding: utf8);
        final isCode = _isCodeExtension(ext);
        return attachment.copyWith(
          type: isCode ? 'code' : 'text',
          content: content.isEmpty ? '[空文件]' : content,
          size: await file.length(),
        );
      } catch (_) {
        return attachment.copyWith(
          content: '[不支持的文件格式: $ext]',
          size: await file.length(),
        );
      }
    } catch (e) {
      debugPrint('读取附件失败: $e');
      return attachment.copyWith(content: '[读取文件失败: $e]');
    }
  }

  /// 获取图片 MIME 类型
  String _imageMimeType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.tiff':
        return 'image/tiff';
      case '.ico':
        return 'image/x-icon';
      default:
        return 'image/png';
    }
  }

  /// 判断是否为代码文件扩展名
  bool _isCodeExtension(String ext) {
    return const {
      '.dart',
      '.java',
      '.kt',
      '.swift',
      '.py',
      '.js',
      '.ts',
      '.tsx',
      '.jsx',
      '.c',
      '.cpp',
      '.h',
      '.hpp',
      '.cs',
      '.go',
      '.rs',
      '.rb',
      '.php',
      '.sh',
      '.lua',
      '.r',
      '.sql',
      '.vue',
      '.svelte',
    }.contains(ext);
  }

  /// 更新会话中的附件
  Future<void> _updateAttachmentInSession(
    String attachmentId,
    ChatAttachment updatedAttachment,
    String targetSessionId, // 添加目标会话ID参数
  ) async {
    // 通过会话ID查找目标会话
    ChatSession? targetSession;
    try {
      targetSession = sessionController.sessions.firstWhere(
        (session) => session.sessionId == targetSessionId,
      );
    } catch (e) {
      // 如果找不到目标会话，尝试使用当前会话
      debugPrint('未找到目标会话 $targetSessionId，尝试使用当前会话');
      targetSession = sessionController.currentSession.value;
    }

    if (targetSession == null) {
      debugPrint('目标会话和当前会话都不存在，无法更新附件');
      return;
    }

    // 找到附件并更新
    final attachments = List<ChatAttachment>.from(targetSession.attachments);
    final attachmentIndex = attachments.indexWhere(
      (att) => att.id == attachmentId,
    );

    if (attachmentIndex != -1) {
      attachments[attachmentIndex] = updatedAttachment;

      final updatedSession = targetSession.copyWith(attachments: attachments);

      // 直接使用 updateSession 方法，避免复杂的状态管理
      debugPrint(
        '更新附件状态: ${updatedAttachment.name}, 状态: ${updatedAttachment.content != null ? "已处理" : "处理中"}, 会话: $targetSessionId',
      );
      sessionController.updateSession(updatedSession);
    } else {
      debugPrint('在会话 $targetSessionId 中未找到附件: $attachmentId');
    }
  }

  /// 移除附件
  void _removeAttachment(ChatAttachment attachment) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final updatedAttachments = List<ChatAttachment>.from(
      currentSession.attachments,
    );
    updatedAttachments.removeWhere((att) => att.id == attachment.id);

    final updatedSession = currentSession.copyWith(
      attachments: updatedAttachments,
    );

    // 只更新会话状态，依靠监听器来同步 _currentAttachments
    sessionController.updateSession(updatedSession);

    // 附件已移除，不显示提示，通过UI状态可见
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
            // 内联附件展示区域（在输入框和按钮之间）
            if (_currentAttachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _currentAttachments.map((attachment) {
                        return _buildInlineAttachmentChip(attachment);
                      }).toList(),
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
                          _buildInputAttachToggle(),
                          const SizedBox(width: 8),
                          _buildDeepThinkToggle(),
                          const SizedBox(width: 8),
                          _buildMcpToolsToggle(),
                          const SizedBox(width: 8),

                          if (FeatureToggleService()
                              .isScheduledTaskEnabled) ...[
                            _buildScheduledTaskToggle(),
                            const SizedBox(width: 8),
                          ],
                          _buildWorkDirectoryToggle(),
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

  /// 构建内联附件 chip（显示在输入框内）
  Widget _buildInlineAttachmentChip(ChatAttachment attachment) {
    final iconData = _getAttachmentIcon(attachment.type);
    final iconColor = _getAttachmentIconColor(attachment.type);
    final isProcessing = attachment.content == null;
    final hasError = attachment.content == 'ERROR_PROCESSING';

    return Container(
      constraints: const BoxConstraints(maxWidth: 200, minWidth: 80),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文件图标
            Icon(iconData, size: 14, color: iconColor),
            const SizedBox(width: 8),
            // 文件信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (attachment.size != null)
                        Text(
                          _formatFileSize(attachment.size!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      if (isProcessing) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange[600]!,
                            ),
                          ),
                        ),
                      ] else if (hasError) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.error_outline,
                          size: 10,
                          color: Colors.red[600],
                        ),
                      ] else ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 10,
                          color: Colors.green[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 删除按钮
            GestureDetector(
              onTap: () => _removeAttachment(attachment),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据附件类型获取图标
  IconData _getAttachmentIcon(String type) {
    switch (type) {
      case 'image':
        return CupertinoIcons.photo;
      case 'document':
      case 'text':
        return CupertinoIcons.doc_text;
      case 'code':
        return CupertinoIcons.textformat;
      case 'office':
        return CupertinoIcons.doc;
      case 'web':
        return CupertinoIcons.globe;
      case 'folder':
        return CupertinoIcons.folder;
      default:
        return CupertinoIcons.doc;
    }
  }

  /// 根据附件类型获取图标颜色
  Color _getAttachmentIconColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'document':
      case 'text':
        return Colors.green;
      case 'code':
        return Colors.purple;
      case 'office':
        return Colors.indigo;
      case 'web':
        return Colors.orange;
      case 'folder':
        return Colors.amber;
      default:
        return Colors.grey;
    }
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

  /// 构建发送/停止按钮
  Widget _buildSendStopButton() {
    // 检查是否有附件正在处理中
    final processingAttachments =
        _currentAttachments
            .where((attachment) => attachment.content == null)
            .toList();

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
    } else if (processingAttachments.isNotEmpty) {
      // 有附件正在处理时显示处理中状态
      return Tooltip(
        message: AppLocalizations.of(
          context,
        )!.waitingAttachments(processingAttachments.length),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ),
      );
    } else if (_hasText || _currentAttachments.isNotEmpty) {
      // 有文字输入或有附件时显示发送按钮
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
            CupertinoIcons.paintbrush,
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
                  fontSize: 11,
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

  /// 构建工作目录按钮
  Widget _buildWorkDirectoryToggle() {
    final currentSession = sessionController.currentSession.value;
    final workDir = currentSession?.workDirectory;
    final hasWorkDir = workDir != null && workDir.isNotEmpty;
    final displayText =
        hasWorkDir
            ? p.basename(workDir)
            : AppLocalizations.of(context)!.workingDirectoryLabel;

    return Tooltip(
      message:
          hasWorkDir
              ? '双击打开，长按修改'
              : AppLocalizations.of(context)!.setWorkingDirHint,
      child: GestureDetector(
        // 未设置时单击选择，已设置时双击打开/长按修改
        onTap:
            _isSending
                ? null
                : hasWorkDir
                ? null
                : _showWorkDirectoryPicker,
        onLongPress:
            _isSending || !hasWorkDir ? null : () => _showWorkDirectoryPicker(),
        onDoubleTap:
            hasWorkDir && !_isSending
                ? () {
                  try {
                    Process.run('open', [workDir]);
                  } catch (_) {}
                }
                : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.folder,
                size: 13,
                color:
                    _isSending
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3)
                        : hasWorkDir
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasWorkDir ? FontWeight.w700 : FontWeight.w500,
                    color:
                        _isSending
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3)
                            : hasWorkDir
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 选择工作目录
  void _showWorkDirectoryPicker() async {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context)!.selectWorkingDir,
      initialDirectory: currentSession.workDirectory,
    );

    if (result != null && mounted) {
      debugPrint('📂 选择工作目录: $result');

      // 检查目录冲突
      final conflictError = await _checkDirectoryConflict(
        currentSession.sessionId,
        result,
      );
      if (conflictError != null) {
        debugPrint('❌ 目录冲突: $conflictError');
        SnackBarUtils.showError(context, conflictError);
        return;
      }

      // 迁移已有的模式文件到工作目录
      await StoragePaths.migrateModeFiles(
        sessionId: currentSession.sessionId,
        workDirectory: result,
      );

      // 设置工作目录
      final dirName = p.basename(result);

      // 如果会话名称是"新建会话"，则改为目录名称
      final shouldUpdateTitle =
          currentSession.name == '新建会话' || currentSession.name.isEmpty;

      sessionController.updateSession(
        currentSession.copyWith(
          workDirectory: result,
          title: shouldUpdateTitle ? dirName : null,
        ),
      );
      SnackBarUtils.showSuccess(
        context,
        AppLocalizations.of(context)!.workingDirSet,
      );
    }
  }

  /// 检查目录冲突
  Future<String?> _checkDirectoryConflict(
    String sessionId,
    String targetDir,
  ) async {
    // 检查目标目录是否有 .llmwork 目录
    final llmworkDir = Directory(p.join(targetDir, '.llmwork'));
    final hasLlmwork = await llmworkDir.exists();
    debugPrint('🔍 检查 .llmwork 目录: ${llmworkDir.path}, 存在: $hasLlmwork');

    if (!hasLlmwork) return null;

    // 检查会话目录是否有模式文件
    final sessionHasModeFiles = await _sessionHasModeFiles(sessionId);
    debugPrint('🔍 会话目录有模式文件: $sessionHasModeFiles');

    // 如果会话已有模式文件，拒绝
    if (sessionHasModeFiles) {
      return '该目录已存在 LLM 工作文件（.llmwork），请选择其他目录';
    }

    // 允许（首次设置）
    return null;
  }

  /// 检查会话目录是否有任何模式文件
  Future<bool> _sessionHasModeFiles(String sessionId) async {
    final modes = ['contract', 'invoice', 'chatroom', 'creative', 'task'];
    for (final mode in modes) {
      final modeDir = StoragePaths.modeDir(
        sessionId: sessionId,
        workMode: mode,
      );
      final dir = Directory(modeDir);
      if (await dir.exists()) {
        final files = await dir.list(recursive: true).toList();
        if (files.any((e) => e is File)) {
          return true;
        }
      }
    }
    return false;
  }

  /// 检测目录中的文件类型
  ///
  /// 优先级：
  /// 1. 检查 .llmwork/ 目录是否存在
  ///    - 如果存在，检查里面有哪个模式的目录
  /// 2. 根据文件名关键词检测
  Future<String> _detectFileType(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 'conversation';

      // 检查 .llmwork 目录
      final llmworkDir = Directory(p.join(dirPath, '.llmwork'));
      if (await llmworkDir.exists()) {
        // 检查里面有哪些模式目录
        if (await Directory(p.join(llmworkDir.path, 'contract')).exists()) {
          debugPrint('✅ 检测到 .llmwork/contract 目录');
          return 'contract';
        }
        if (await Directory(p.join(llmworkDir.path, 'chatroom')).exists()) {
          debugPrint('✅ 检测到 .llmwork/chatroom 目录');
          return 'chatroom';
        }
        if (await Directory(p.join(llmworkDir.path, 'invoice')).exists()) {
          debugPrint('✅ 检测到 .llmwork/invoice 目录');
          return 'invoice';
        }
        if (await Directory(p.join(llmworkDir.path, 'creative')).exists()) {
          debugPrint('✅ 检测到 .llmwork/creative 目录');
          return 'creative';
        }
        // .llmwork 存在但没有模式目录，默认对话模式
        return 'conversation';
      }

      // 根据文件名关键词检测
      const contractKeywords = ['合同', '协议', '契约', '合约', '合同书', '协议书'];
      const invoiceKeywords = [
        '发票',
        'invoice',
        '收据',
        'receipt',
        '开票',
        '报销',
        '费用',
      ];

      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path).toLowerCase();

          for (final keyword in invoiceKeywords) {
            if (fileName.contains(keyword)) {
              debugPrint('✅ 检测到发票文件: ${entity.path}');
              return 'invoice';
            }
          }

          for (final keyword in contractKeywords) {
            if (fileName.contains(keyword)) {
              debugPrint('✅ 检测到合同文件: ${entity.path}');
              return 'contract';
            }
          }
        }
      }

      return 'conversation';
    } catch (e) {
      debugPrint('文件类型检测失败: $e');
      return 'conversation';
    }
  }

  /// 商务模式：解析工作目录下的合同文件
  Future<void> _parseContracts() async {
    if (_isSending || _sendingInProgress) return;

    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;
    final workDir = currentSession.workDirectory;
    if (workDir == null || workDir.trim().isEmpty) return;

    // 扫描工作目录下的合同文件
    final dir = Directory(workDir);
    if (!await dir.exists()) {
      SnackBarUtils.showError(
        context,
        AppLocalizations.of(context)!.workingDirectoryPath(workDir),
      );
      return;
    }

    // 合同解析：第一轮筛选 - 只选择 Word 文件
    const wordExtensions = ['.doc', '.docx'];

    final allWordFiles = <File>[];
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (wordExtensions.contains(ext)) {
          allWordFiles.add(entity);
        }
      }
    }

    if (allWordFiles.isEmpty) {
      SnackBarUtils.showInfo(context, '工作目录下未找到 Word 文件');
      return;
    }

    debugPrint('📄 合同解析：找到 ${allWordFiles.length} 个 Word 文件，开始关键词筛选...');

    // 合同正向关键词（文件名命中任一即通过）
    const fileNameKeywords = ['合同', '协议', '契约', '合约', '合同书', '协议书'];

    // 非合同文件名排除词
    const excludeFileNameKeywords = [
      '说明',
      '证明',
      '告知',
      '通知',
      '清单',
      '目录',
      '附件',
      '附表',
      '模板',
      '空白',
      '范本',
      '草稿',
    ];

    // 第二轮筛选
    final files = <File>[];
    for (final file in allWordFiles) {
      final fileName = p.basenameWithoutExtension(file.path);

      bool excluded = false;
      for (final keyword in excludeFileNameKeywords) {
        if (fileName.contains(keyword)) {
          excluded = true;
          debugPrint('📄 文件名命中排除词"$keyword"，跳过: ${p.basename(file.path)}');
          break;
        }
      }
      if (excluded) continue;

      bool fileNameMatch = false;
      for (final keyword in fileNameKeywords) {
        if (fileName.contains(keyword)) {
          fileNameMatch = true;
          break;
        }
      }

      if (fileNameMatch) {
        files.add(file);
        debugPrint('📄 文件名匹配: ${p.basename(file.path)}');
        continue;
      }

      // 文件名不匹配，读取内容做更严格判定
      bool contentMatch = false;
      try {
        final ext = p.extension(file.path).toLowerCase();
        String? fileContent;

        if (ext == '.doc') {
          try {
            final bytes = await file.readAsBytes();
            final buffer = StringBuffer();
            for (final byte in bytes) {
              if (byte >= 32 && byte <= 126 || byte >= 128) {
                buffer.writeCharCode(byte);
              }
            }
            fileContent = buffer.toString();
          } catch (_) {
            fileContent = null;
          }
        }

        if (fileContent != null && fileContent.isNotEmpty) {
          const strongKeywords = ['合同', '协议', '契约', '合约'];
          bool hasStrongKeyword = false;
          for (final kw in strongKeywords) {
            if (fileContent.contains(kw)) {
              hasStrongKeyword = true;
              break;
            }
          }

          if (hasStrongKeyword) {
            const evidenceKeywords = [
              '公章',
              '违约',
              '盖章',
              '甲方',
              '乙方',
              '签署',
              '签章',
              '法定代表',
              '条款',
              '违约责任',
            ];
            for (final kw in evidenceKeywords) {
              if (fileContent.contains(kw)) {
                contentMatch = true;
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('📄 读取文件内容失败: ${file.path}, $e');
      }

      if (contentMatch) {
        files.add(file);
        debugPrint('📄 内容匹配（强特征+佐证）: ${p.basename(file.path)}');
      } else {
        debugPrint('📄 跳过（未通过内容严格判定）: ${p.basename(file.path)}');
      }
    }

    if (files.isEmpty) {
      SnackBarUtils.showInfo(context, '工作目录下未找到包含合同关键词的 Word 文件');
      return;
    }

    debugPrint('📄 合同解析：筛选后 ${files.length} 个文件');

    // 将文件添加为附件，然后发送解析提示词（走正常聊天流程）
    _sendingInProgress = true;

    try {
      // 将文件转换为 PlatformFile 列表
      final platformFiles = <PlatformFile>[];
      for (final file in files) {
        final stat = await file.stat();
        if (stat.size > 50 * 1024 * 1024) continue;
        platformFiles.add(
          PlatformFile(
            name: p.basename(file.path),
            path: file.path,
            size: stat.size,
          ),
        );
      }

      if (platformFiles.isEmpty) {
        _sendingInProgress = false;
        return;
      }

      // 添加文件附件
      await _addMultipleAttachments(platformFiles, 'document');

      // 轮询等待所有附件处理完成（最多等待 60 秒）
      final attachmentNames = platformFiles.map((f) => f.name).toSet();
      bool allProcessed = false;
      for (int i = 0; i < 120; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final currentAttachments =
            sessionController.currentSession.value?.attachments ?? [];
        final pending = currentAttachments.where(
          (a) => attachmentNames.contains(a.name) && a.content == null,
        );
        if (pending.isEmpty) {
          allProcessed = true;
          break;
        }
        debugPrint('📄 等待附件处理... 剩余 ${pending.length} 个');
      }

      if (!allProcessed) {
        debugPrint('📄 部分附件处理超时，继续发送');
      }

      // 设置新提示词到输入框
      _inputController.text = _buildContractParsePrompt();
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
      setState(() {
        _hasText = true;
      });

      // 标记：响应完成后需要解析 JSON 写入 business.md
      _contractParsePending = true;

      // 走正常发送流程
      await _doSendMessage(_inputController.text.trim());
      _sendingInProgress = false;
    } catch (e) {
      debugPrint('合同解析出错: $e');
      _sendingInProgress = false;
      _contractParsePending = false;
    }
  }

  /// 构建合同解析提示词（发送到聊天中）
  String _buildContractParsePrompt() {
    return '请分析以上合同文件，提取关键信息，然后使用专用工具写入对应文件：\n\n'
        '**1. 合同要点** → 调用 `contract_content_update` 工具\n'
        '   包含：合同名称、类型、签署方、期限、金额、收支条款、支付计划、违约条款、违约责任\n\n'
        '**2. 合同履约跟踪** → 调用 `contract_process_update` 工具\n'
        '   包含：合同状态（进行中）、履约进度、初始付款记录等\n\n'
        '**3. 合同争议记录** → 调用 `contract_disguss_update` 工具\n'
        '   如无争议，写入初始状态（争议状态：无）\n\n'
        '⚠️ 必须使用专用工具写入文件，不要只在回复中输出内容。';
  }

  /// 从 LLM 响应中提取合同 JSON
  List<ContractInfo> _extractContractsFromResponse(String response) {
    try {
      // 尝试提取 markdown 代码块中的 JSON
      final codeBlockMatch = RegExp(
        r'```(?:json)?\s*([\s\S]*?)\s*```',
      ).firstMatch(response);

      String jsonStr;
      if (codeBlockMatch != null) {
        jsonStr = codeBlockMatch.group(1)!.trim();
      } else {
        // 尝试直接找到 JSON 数组
        final arrayMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
        if (arrayMatch != null) {
          jsonStr = arrayMatch.group(0)!;
        } else {
          debugPrint('📄 无法从响应中提取 JSON');
          return [];
        }
      }

      // 尝试解析完整 JSON
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        return _parseContractList(jsonList);
      } catch (_) {
        // JSON 可能被截断，尝试修复后解析
        debugPrint('📄 JSON 解析失败，尝试修复截断...');
        final fixed = _fixTruncatedJson(jsonStr);
        if (fixed != null) {
          try {
            final List<dynamic> jsonList = jsonDecode(fixed);
            return _parseContractList(jsonList);
          } catch (_) {}
        }
        return [];
      }
    } catch (e) {
      debugPrint('📄 解析合同 JSON 失败: $e');
      return [];
    }
  }

  List<ContractInfo> _parseContractList(List<dynamic> jsonList) {
    return jsonList
        .map((item) {
          try {
            return ContractInfo.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            debugPrint('📄 解析单个合同失败: $e');
            return null;
          }
        })
        .whereType<ContractInfo>()
        .toList();
  }

  /// 尝试修复被截断的 JSON（补全缺失的括号）
  String? _fixTruncatedJson(String json) {
    try {
      // 补全缺失的 } 和 ]
      var fixed = json.trimRight();
      // 计算未闭合的括号
      int openBraces = 0, openBrackets = 0;
      bool inString = false;
      bool escape = false;
      for (int i = 0; i < fixed.length; i++) {
        final c = fixed[i];
        if (escape) {
          escape = false;
          continue;
        }
        if (c == '\\') {
          escape = true;
          continue;
        }
        if (c == '"') {
          inString = !inString;
          continue;
        }
        if (inString) continue;
        if (c == '{') openBraces++;
        if (c == '}') openBraces--;
        if (c == '[') openBrackets++;
        if (c == ']') openBrackets--;
      }
      // 补全
      while (openBraces > 0) {
        fixed += '}';
        openBraces--;
      }
      while (openBrackets > 0) {
        fixed += ']';
        openBrackets--;
      }
      return fixed;
    } catch (_) {
      return null;
    }
  }

  /// 合同解析响应完成后：解析 JSON 并写入 business.md
  Future<void> _onContractParseComplete(String accumulatedContent) async {
    _contractParsePending = false;

    final contracts = _extractContractsFromResponse(accumulatedContent);
    if (contracts.isEmpty) {
      debugPrint('📄 合同解析：未能从响应中提取合同信息');
      return;
    }

    final sessionId = sessionController.currentSession.value?.sessionId;
    if (sessionId == null) return;

    // 写入 business.md
    final mdContent = StringBuffer();
    mdContent.writeln('# 合约要点');
    mdContent.writeln();
    for (final c in contracts) {
      mdContent.write(c.toMarkdown());
    }
    await SessionFileStore.writeBusiness(sessionId, mdContent.toString());

    // 同步更新会话
    final updatedSession = sessionController.currentSession.value;
    if (updatedSession != null && updatedSession.sessionId == sessionId) {
      await sessionController.updateSession(
        updatedSession.copyWith(contracts: contracts),
      );
    }

    debugPrint('📄 合同解析完成：已写入 ${contracts.length} 份合同到 business.md');
  }

  /// 构建定时任务按钮
  Widget _buildScheduledTaskToggle() {
    final currentSession = sessionController.currentSession.value;
    final task = currentSession?.scheduledTask;
    final hasTask = task != null;
    final label =
        hasTask
            ? task.humanReadable
            : AppLocalizations.of(context)!.scheduledTaskLabel;

    return Tooltip(
      message:
          hasTask
              ? '${AppLocalizations.of(context)!.scheduledLabelColon}: ${task.humanReadable}'
              : AppLocalizations.of(context)!.setScheduledMessage,
      child: GestureDetector(
        onTap: _isSending ? null : () => ScheduledTaskDialog.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasTask ? Icons.schedule : Icons.schedule_outlined,
                size: 13,
                color:
                    _isSending
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3)
                        : hasTask
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: hasTask ? FontWeight.w700 : FontWeight.w500,
                    color:
                        _isSending
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3)
                            : hasTask
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建输入框功能按钮
  Widget _buildInputAttachToggle() {
    return Tooltip(
      message: AppLocalizations.of(context)!.attach,
      child: InkWell(
        onTap: _isSending ? null : _pickFile,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            CupertinoIcons.paperclip,
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

  /// 构建MCP工具切换按钮
  Widget _buildMcpToolsToggle() {
    final currentSession = sessionController.currentSession.value;

    // MCP 服务已全局存储，不依赖 ChatModel
    final hasMcpServices = McpController.instance.hasGlobalMcpServices;
    final mcpServer = currentSession?.mcpServer;
    final hasSelectedService = mcpServer != null;

    // 统一按钮：图标 + 文字（未选：请选择，已选：服务名）
    final displayText =
        hasSelectedService
            ? mcpServer?.name ?? ''
            : (hasMcpServices
                ? AppLocalizations.of(context)!.selectMcpTool
                : AppLocalizations.of(context)!.noMcpTool);

    return Tooltip(
      message:
          hasSelectedService
              ? '${AppLocalizations.of(context)!.viewMcpToolDetail}\n长按移除'
              : (hasMcpServices
                  ? AppLocalizations.of(context)!.clickToSelectMcpTool
                  : AppLocalizations.of(context)!.noMcpToolConfigured),
      child: GestureDetector(
        onTap:
            hasMcpServices && !_isSending
                ? (hasSelectedService
                    ? () => _showMcpDetail(mcpServer)
                    : _showMcpServiceSelection)
                : null,
        onLongPress:
            hasSelectedService && !_isSending
                ? () => _showRemoveMcpDialog()
                : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.link,
                size: 13,
                color:
                    _isSending
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3)
                        : hasSelectedService
                        ? Theme.of(context).colorScheme.onSurface
                        : hasMcpServices
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6)
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        hasSelectedService ? FontWeight.w700 : FontWeight.w500,
                    color:
                        _isSending
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3)
                            : hasSelectedService
                            ? Theme.of(context).colorScheme.onSurface
                            : hasMcpServices
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6)
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            CupertinoIcons.search,
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
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }

  /// 命令面板通用列表项组件
  Widget _buildCommandItem({
    required String title,
    String? subtitle,
    String? tag,
    bool isSelected = false,
    bool isClearAction = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration:
            isSelected && !isClearAction
                ? BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.4),
                )
                : null,
        child: Row(
          crossAxisAlignment:
              subtitle != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                      color:
                          isClearAction
                              ? Theme.of(
                                context,
                              ).colorScheme.error.withOpacity(0.75)
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_alt,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              )
            else if (tag != null)
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 显示MCP服务选择弹窗，点击服务直接绑定
  Future<void> _showMcpServiceSelection() async {
    // MCP 服务从 McpController 读取
    final mcpc = Get.find<McpController>();
    await mcpc.ensureLoaded();
    final mcpServices = mcpc.configs.toList();

    if (mcpServices.isEmpty) {
      SnackBarUtils.showInfo(
        context,
        AppLocalizations.of(context)!.noMcpServiceConfigured,
      );
      return;
    }

    final session = sessionController.currentSession.value;
    final selectedName = session?.mcp;
    final searchController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.15),
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 120,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 480),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final query = searchController.text.trim().toLowerCase();
                final filtered =
                    mcpServices.where((s) {
                      if (query.isEmpty) return true;
                      return s.name.toLowerCase().contains(query) ||
                          (s.url?.toLowerCase().contains(query) ?? false) ||
                          (s.command?.toLowerCase().contains(query) ?? false) ||
                          (s.args?.any(
                                (a) => a.toLowerCase().contains(query),
                              ) ??
                              false);
                    }).toList();

                final clearCount =
                    selectedName != null &&
                            (query.isEmpty ||
                                '清空'.contains(query) ||
                                '取消'.contains(query) ||
                                '清空mcp'.contains(query))
                        ? 1
                        : 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommandPaletteSearchBar(
                      controller: searchController,
                      title: AppLocalizations.of(context)!.mcpServiceTitle,
                      onChanged: () => setDialogState(() {}),
                    ),
                    Flexible(
                      child:
                          filtered.isEmpty && clearCount == 0
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noMatchingResults,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                itemCount: filtered.length + clearCount,
                                itemBuilder: (context, index) {
                                  if (clearCount > 0 && index == 0) {
                                    return _buildCommandItem(
                                      title:
                                          AppLocalizations.of(
                                            context,
                                          )!.clearMcpService,
                                      tag:
                                          AppLocalizations.of(
                                            context,
                                          )!.unbindAction,
                                      isClearAction: true,
                                      onTap: () {
                                        Navigator.of(dialogContext).pop();
                                        _applyMcpSelection(null);
                                      },
                                    );
                                  }
                                  final serviceIndex = index - clearCount;
                                  final service = filtered[serviceIndex];
                                  final isSelected =
                                      service.name == selectedName;
                                  final toolCount = service.name == selectedName
                                      ? (session?.mcpServer?.tools?.length ?? 0)
                                      : 0;
                                  return _buildCommandItem(
                                    title: service.name,
                                    subtitle:
                                        service.description?.isNotEmpty == true
                                            ? service.description
                                            : service.url?.isNotEmpty == true
                                            ? service.url
                                            : '${service.command ?? ''} ${service.args?.join(' ') ?? ''}',
                                    tag:
                                        toolCount > 0
                                            ? AppLocalizations.of(
                                              context,
                                            )!.xTools(toolCount)
                                            : null,
                                    isSelected: isSelected,
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                      _applyMcpSelection(
                                        isSelected ? null : service,
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          searchController.dispose();
        } catch (_) {}
      });
    });
  }

  /// 应用MCP服务选择
  void _applyMcpSelection(Mcp? service) async {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    var updatedSession = currentSession.copyWith(
      mcp: service == null ? null : service.name,
      mcpServer: service,
      clearMcp: service == null,
    );

    // 如果会话名是默认的"新对话"，自动改为 MCP 服务名
    if (service != null &&
        updatedSession.name == AppLocalizations.of(context)!.newSession) {
      updatedSession = updatedSession.copyWith(title: service.name);
    }

    await sessionController.updateSession(updatedSession);

    if (mounted) {
      if (service != null) {
        SnackBarUtils.showInfo(
          context,
          AppLocalizations.of(context)!.mcpServiceSelected(service.name),
        );
        // 等待 MCP 初始化完成，确保 tools 已填充到 session.mcp 中
        final refreshed = await McpController.instance.initForSessionSync(updatedSession);
        if (refreshed != null && refreshed.tools != null && refreshed.tools!.isNotEmpty) {
          // 将刷新后的 McpServer（含 tools）同步到 session
          final syncedSession = updatedSession.copyWith(mcpServer: refreshed);
          await sessionController.updateSession(syncedSession);
        }
      } else {
        // 关闭 MCP 时清理客户端
        final oldServiceName = currentSession.mcp;
        if (oldServiceName != null) {
          McpController.instance.closeClient(oldServiceName);
        }
        SnackBarUtils.showInfo(
          context,
          AppLocalizations.of(context)!.mcpToolsDisabled,
        );
      }
    }
  }

  bool _sendingInProgress = false; // 本地防重入锁
  bool _contractParsePending = false; // 合同解析标记：响应完成后写入 business.md

  /// 发送消息的主要方法
  Future<void> _sendMessage() async {
    // 本地防重入锁：避免并发调用
    if (_sendingInProgress) return;
    _sendingInProgress = true;

    try {
      final text = _inputController.text.trim();
      debugPrint('发送消息: $text');

      // 防止发送空消息（没有文本且没有附件）或重复发送
      if ((text.isEmpty && _currentAttachments.isEmpty) || _isSending) {
        return;
      }

      // 检查是否有附件正在处理中
      final processingAttachments =
          _currentAttachments
              .where((attachment) => attachment.content == null)
              .toList();

      if (processingAttachments.isNotEmpty) {
        // 有附件正在处理中，不发送消息，发送按钮状态已显示处理中
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
    debugPrint('🚀 当前会话附件数量: ${_currentAttachments.length}');
    // for (int i = 0; i < _currentAttachments.length; i++) {
    //   final attachment = _currentAttachments[i];
    //   debugPrint('🚀 附件 $i: ${attachment.name}, 类型: ${attachment.type}');
    // }

    // 过滤出已成功处理的附件（排除处理失败的）
    final validAttachments =
        _currentAttachments
            .where(
              (attachment) =>
                  (attachment.content != null &&
                      attachment.content != 'ERROR_PROCESSING') ||
                  (attachment.base64Data != null &&
                      attachment.base64Data!.isNotEmpty),
            )
            .toList();

    debugPrint(
      '发送消息 - 总附件数: ${_currentAttachments.length}, 有效附件数: ${validAttachments.length}',
    );
    for (int i = 0; i < validAttachments.length; i++) {
      final attachment = validAttachments[i];
      debugPrint(
        '有效附件 $i: ${attachment.name}, 类型: ${attachment.type}, 内容长度: ${attachment.content?.length ?? 0}',
      );
    }

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

    // 如果有文件引用，添加修订模式指令
    String messageContent = text;
    if (_hasFileMention) {
      messageContent =
          '【修订模式】$text\n\n'
          '注意：你正在修改文件，请务必保留文件的原始格式（包括字体、缩进、换行等），'
          '只修改内容部分，不要添加额外的格式化或改变文件结构。';
      // 重置修订模式标记
      setState(() {
        _hasFileMention = false;
      });
    }

    // 创建用户消息对象，只包含已成功处理的附件
    final userMessage = ChatMessage(
      msgId: '${timestamp}_user',
      role: MessageRole.user,
      content: messageContent,
      timestamp: DateTime.now(),
      sessionId: updateSession.sessionId,
      attachments: List<ChatAttachment>.from(validAttachments), // 只包含已处理的附件
    );

    // 为用户消息创建GlobalKey
    widget.messageKeys[userMessage.msgId] = GlobalKey();

    // 立即更新会话状态，但保留附件信息用于发送
    final updatedSession = updateSession.copyWith(
      messages: [...updateSession.messages, userMessage],
      inputContent: '',
      attachments: [], // 保留附件信息用于发送
      isSending: true,
    );

    sessionController.updateSession(updatedSession);

    // 强制触发UI更新以立即清除附件显示
    setState(() {});

    debugPrint('💡 发送消息后附件状态: ${updatedSession.attachments.length} 个附件');
    debugPrint('💡 _currentAttachments: ${_currentAttachments.length} 个附件');

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
        think: '',
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
            botMessage.think = accumulatedThink;
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

      if (messageIndex != -1) {
        final updatedMessages = List<ChatMessage>.from(updateSession.messages);
        updatedMessages[messageIndex] = botMessage.copyWith(
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
        updateSession = updateSession.copyWith(messages: updatedMessages);
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

      // 合同解析响应完成后：解析 JSON 写入 business.md
      if (_contractParsePending && accumulatedContent.isNotEmpty) {
        _onContractParseComplete(accumulatedContent);
      }
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

  /// 显示移除MCP确认弹窗
  void _showRemoveMcpDialog() async {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final bool? shouldRemove = await ConfirmDeleteDialog.show(
      context: context,
      title: '移除 MCP',
      itemName: currentSession.mcpServer?.name ?? '',
      description: '确定要移除当前 MCP',
      warningMessage: '此操作无法撤销',
      icon: CupertinoIcons.link,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldRemove == true) {
      sessionController.updateSession(currentSession.copyWith(clearMcp: true));
    }
  }

  /// 显示 MCP 服务详情弹窗（与 MCP 管理页面保持一致）
  void _showMcpDetail(Mcp service) {
    final mcpc = Get.find<McpController>();
    final config = mcpc.getMcp(service.name);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.mcpDetail,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        Mcp mutableService = service;
        return Center(
          child: FadeTransition(
            opacity: anim1,
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                final tools = mutableService.tools;
                final hasTools = tools != null && tools.isNotEmpty;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 700,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                  ),
                  child: Material(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 头部
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            mutableService.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            _getMcpTypeLabel(config),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mutableService.description?.isNotEmpty ==
                                              true
                                          ? mutableService.description!
                                          : _buildMcpSubtitle(config),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 工具列表
                          if (hasTools) ...[
                            Row(
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.toolList(tools.length),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      final cfg = config ??
                                          McpController.instance.getMcp(
                                            mutableService.name,
                                          );
                                      if (cfg == null) {
                                        throw Exception(
                                            '未找到 MCP 配置: ${mutableService.name}');
                                      }
                                      final newTools =
                                          await McpController.instance.refreshServiceTools(
                                            cfg,
                                          );
                                      final base = mutableService;
                                      final prompt = McpController.instance
                                          .buildMcpPrompt(
                                            base.copyWith(tools: newTools),
                                          );
                                      final updatedService = base.copyWith(
                                        tools: newTools,
                                        prompt: prompt,
                                        lastUpdated: DateTime.now(),
                                      );
                                      await mcpc.updateService(
                                        cfg.name,
                                        cfg.copyWith(
                                          description: updatedService.description,
                                        ),
                                      );
                                      mutableService = updatedService;
                                      final sess =
                                          sessionController.currentSession.value;
                                      if (sess != null) {
                                        await sessionController.updateSession(
                                          sess.copyWith(mcpServer: updatedService),
                                        );
                                      }
                                      setSheetState(() {});
                                      SnackBarUtils.showSuccess(
                                        ctx,
                                        AppLocalizations.of(
                                          context,
                                        )!.toolsRefreshed(newTools.length),
                                      );
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        SnackBarUtils.showError(
                                          ctx,
                                          AppLocalizations.of(
                                            context,
                                          )!.refreshFailed(
                                            e.toString().substring(
                                              0,
                                              e.toString().length.clamp(0, 80),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.refresh,
                                        size: 13,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.refreshAction,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children:
                                  tools.take(50).map((t) {
                                    final label =
                                        t.description.isNotEmpty
                                            ? '${t.name}: ${t.description}'
                                            : t.name;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                            if (tools.length > 50)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.moreXTools(tools.length - 50),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            const Divider(),
                            const SizedBox(height: 12),
                          ],

                          // 未获取工具时的获取按钮
                          if (!hasTools) ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final cfg = config ??
                                        McpController.instance.getMcp(
                                          mutableService.name,
                                        );
                                    if (cfg == null) {
                                      throw Exception(
                                          '未找到 MCP 配置: ${mutableService.name}');
                                    }
                                    final newTools =
                                        await McpController.instance.refreshServiceTools(
                                          cfg,
                                        );
                                    final base = mutableService;
                                    final prompt = McpController.instance
                                        .buildMcpPrompt(
                                          base.copyWith(tools: newTools),
                                        );
                                    final updatedService = base.copyWith(
                                      tools: newTools,
                                      prompt: prompt,
                                      lastUpdated: DateTime.now(),
                                    );
                                    await mcpc.updateService(
                                      cfg.name,
                                      cfg.copyWith(
                                        description: updatedService.description,
                                      ),
                                    );
                                    mutableService = updatedService;
                                    final sess =
                                        sessionController.currentSession.value;
                                    if (sess != null) {
                                      await sessionController.updateSession(
                                        sess.copyWith(mcpServer: updatedService),
                                      );
                                    }
                                    setSheetState(() {});
                                    SnackBarUtils.showSuccess(
                                      ctx,
                                      AppLocalizations.of(
                                        context,
                                      )!.toolsFetched(newTools.length),
                                    );
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      SnackBarUtils.showError(
                                        ctx,
                                        AppLocalizations.of(
                                          context,
                                        )!.fetchFailed(
                                          e.toString().substring(
                                            0,
                                            e.toString().length.clamp(0, 80),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.arrow_down_to_line_alt,
                                  size: 15,
                                ),
                                label: Text(
                                  AppLocalizations.of(context)!.fetchTools,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // JSON 配置
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 代码块标题栏
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  color: const Color(0xFFF0F0F0),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '{ }',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'JSON',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text:
                                                  const JsonEncoder.withIndent(
                                                    '  ',
                                                  ).convert(
                                                    mutableService.toJson(),
                                                  ),
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.jsonCopied,
                                              ),
                                              duration: const Duration(
                                                seconds: 1,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Icon(
                                          CupertinoIcons.doc_on_clipboard,
                                          size: 12,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 代码内容
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  color: const Color(0xFFF5F5F5),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(mutableService.toJson()),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF333333),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// MCP 服务类型标签
  String _getMcpTypeLabel(Mcp? service) {
    if (service == null) return '';
    if (service.url != null && service.url!.isNotEmpty) {
      switch (service.type) {
        case McpTransportType.sse:
          return 'SSE';
        case McpTransportType.http:
        case McpTransportType.streamableHttp:
          return 'HTTP';
        default:
          return 'URL';
      }
    }
    return 'Stdio';
  }

  /// MCP 服务副标题（URL 或 命令）
  String _buildMcpSubtitle(Mcp? service) {
    if (service == null) return '';
    if (service.url != null && service.url!.isNotEmpty) {
      final typeLabel =
          (service.type == McpTransportType.http ||
                  service.type == McpTransportType.streamableHttp)
              ? ' [HTTP]'
              : (service.type == McpTransportType.sse ? ' [SSE]' : '');
      return '${service.url!}$typeLabel';
    }
    return '${service.command ?? ''} ${service.args?.join(' ') ?? ''}';
  }

  /// 将 MCP 工具调用结果发送回 LLM 并流式获取最终回复
}
