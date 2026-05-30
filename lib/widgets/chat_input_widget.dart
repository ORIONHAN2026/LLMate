import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import '../controllers/session_controller.dart';
import '../models/bigmodel/models.dart';
import '../models/chat/skill.dart';
import '../models/chat/chat_setting.dart';
import '../framework/llm_framework.dart';
import '../services/model_storage_service.dart';
import 'package:mcp_client/mcp_client.dart' hide MessageRole;
import '../services/mcp_service.dart';
import '../services/mcp_storage_service.dart';
import '../utils/snackbar_utils.dart';
import 'attachment_list_widget.dart';

/// 聊天输入框组件
///
/// 完全自包含的聊天输入组件，包括：
/// - 文本输入框
/// - 发送功能（内置消息发送逻辑）
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
    this.hintText = '在这里输入消息，↵ 发送，Shift+↵ 换行',
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

  /// 获取当前会话的附件列表
  List<ChatAttachment> get _currentAttachments =>
      sessionController.currentSession.value?.attachments ?? [];

  @override
  void initState() {
    super.initState();

    // 提前加载全局 MCP 配置，确保按钮状态正确
    McpService.ensureGlobalConfigsLoaded().then((_) {
      if (mounted) setState(() {});
    });

    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();
    _hasText = _inputController.text.isNotEmpty;
    _inputController.addListener(_onTextChanged);
    widget.scrollController.addListener(
      _onScrollChanged,
    ); // 监听当前会话的变化，确保附件状态及时更新
    // 记录上一次会话的 MCP 服务名，用于生命周期管理
    String? prevMcpServiceName;

    _sessionSubscription = sessionController.currentSession.listen((
      currentSession,
    ) async {
      // MCP 客户端生命周期管理：切换会话时关闭旧客户端，初始化新客户端
      final newMcpServiceName = currentSession?.mcpServer?.name;
      if (prevMcpServiceName != null &&
          prevMcpServiceName != newMcpServiceName) {
        debugPrint('🔄 会话切换，关闭旧 MCP 客户端: $prevMcpServiceName');
        await McpService.closeClient(prevMcpServiceName!);
      }
      prevMcpServiceName = newMcpServiceName;

      // 如果新会话已配置 MCP 且客户端未初始化，则初始化
      if (newMcpServiceName != null && newMcpServiceName.isNotEmpty) {
        final existingClient = McpService.getMCPClient(newMcpServiceName);
        if (existingClient == null) {
          debugPrint('🔄 会话切换，初始化 MCP 客户端: $newMcpServiceName');
          await McpService.initializeSessionMcpServices(currentSession!);
        }
      }

      if (mounted && currentSession != null) {
        // 附件状态变化时触发UI更新
        setState(() {
          // UI会自动从getter获取最新的附件列表
        });
        // debugPrint('会话监听器 - 附件数: ${currentSession.attachments.length} 个附件');
      } else if (mounted && currentSession == null) {
        // 当前会话为空时，触发UI更新
        setState(() {
          // UI会自动从getter获取空的附件列表
        });
        // debugPrint('当前会话为空，清空附件列表');
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
    _textChangeTimer?.cancel(); // 取消定时器
    _inputController.removeListener(_onTextChanged);
    widget.scrollController.removeListener(_onScrollChanged);
    _sessionSubscription.cancel(); // 取消监听器
    _inputController.dispose();
    _inputFocusNode.dispose();
    // 关闭所有 MCP 客户端连接
    McpService.closeAllClients();
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
        _saveInputContentToSession();
      }

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
      final modelMaps = await ModelStorageService.loadModels();
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
              status: 'active',
            );

    final newSession = ChatSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新对话',
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

      // 尝试读取文件内容
      String? content;
      try {
        if (file.extension?.toLowerCase() == '.txt' ||
            file.extension?.toLowerCase() == '.md' ||
            file.extension?.toLowerCase() == '.json' ||
            file.extension?.toLowerCase() == '.go' ||
            file.extension?.toLowerCase() == '.py' ||
            file.extension?.toLowerCase() == '.js' ||
            file.extension?.toLowerCase() == '.html' ||
            file.extension?.toLowerCase() == '.css') {
          content = await File(file.path!).readAsString();
        }
      } catch (e) {
        debugPrint('读取文件内容失败: ${e.toString()}');
      }

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
        content: content, // 添加文件内容
      );

      newAttachments.add(attachment);
      debugPrint(
        '创建附件对象: ${attachment.name}, ID: ${attachment.id}, 大小: ${attachment.size}, 内容长度: ${content?.length ?? 0}',
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

  /// 后台处理附件
  Future<void> _processAttachmentInBackground(
    String attachmentId,
    ChatAttachment attachment,
    String targetSessionId, // 添加目标会话ID，确保更新正确的会话
  ) async {
    debugPrint('开始后台处理附件: ${attachment.name}，目标会话: $targetSessionId');

    try {
      // 在后台处理文件内容，不阻塞UI
      final processedAttachment =
          await FileProcessingService.processAttachmentInBackground(attachment);

      debugPrint(
        '文件处理完成: ${attachment.name}, 内容长度: ${processedAttachment.content?.length ?? 0}',
      );

      // 更新附件状态为已处理，使用指定的会话ID
      await _updateAttachmentInSession(
        attachmentId,
        processedAttachment,
        targetSessionId,
      );

      // 文件处理完成，不显示提示，通过附件状态可见
    } catch (e) {
      debugPrint('处理附件时出错: $e');

      // 处理失败时，更新附件状态为错误
      final errorAttachment = attachment.copyWith(
        content: 'ERROR_PROCESSING', // 特殊标记表示处理失败
      );
      await _updateAttachmentInSession(
        attachmentId,
        errorAttachment,
        targetSessionId,
      );

      // 处理文件失败，不显示提示，通过附件状态可见错误状态
    }
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
          children: [
            // 附件展示区域
            AttachmentListWidget(
              attachments: _currentAttachments,
              onRemoveAttachment: _removeAttachment,
            ),
            if (_currentAttachments.isNotEmpty)
              Container(
                height: 1,
                color: Theme.of(context).dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
            // 输入框
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
                  hintText: widget.hintText,
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
                maxLines: null, // 允许多行
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
                  // 左侧功能按钮
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildInputAttachToggle(),

                      const SizedBox(width: 8),

                      _buildMcpToolsToggle(),
                      const SizedBox(width: 8),

                      _buildSkillToggle(),
                      const SizedBox(width: 8),
                      _buildQuickCommandToggle(),
                      const SizedBox(width: 8),
                      _buildCleanHistoryToggle(),

                      Container(
                        height: 16,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                      _buildSessionCommandsToggle(),
                    ],
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
    // 检查是否有附件正在处理中
    final processingAttachments =
        _currentAttachments
            .where((attachment) => attachment.content == null)
            .toList();

    if (_isSending) {
      // 正在发送时显示停止按钮
      return Tooltip(
        message: '停止回答',
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
        message: '等待 ${processingAttachments.length} 个附件处理完成',
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
        message: '发送消息',
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
      message: "清除历史记录",
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

  /// 构建输入框功能按钮
  Widget _buildInputAttachToggle() {
    return Tooltip(
      message: "附件",
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
    final hasMcpServices = McpService.hasGlobalMcpServices;
    final mcpServer = currentSession?.mcpServer;
    final hasSelectedService = mcpServer != null;

    // 统一按钮：图标 + 文字（未选：请选择，已选：服务名）
    final displayText =
        hasSelectedService
            ? mcpServer.name
            : (hasMcpServices ? '请选择' : '无MCP服务');

    return Tooltip(
      message: hasMcpServices ? '点击选择MCP服务' : '当前模型未配置MCP服务',
      child: GestureDetector(
        onTap: hasMcpServices && !_isSending ? _showMcpServiceSelection : null,
        onDoubleTap:
            hasMcpServices && !_isSending ? _showMcpServicesList : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.gear,
                size: 13,
                color:
                    hasMcpServices && !_isSending
                        ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6)
                        : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
              ),
              if (hasMcpServices) ...[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    displayText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建技能切换按钮
  Widget _buildSkillToggle() {
    final currentSession = sessionController.currentSession.value;
    final currentModel = currentSession?.chatModel;

    // 检查当前模型是否配置了技能
    final hasSkills = currentModel?.skills?.isNotEmpty == true;
    final isEnabled = hasSkills && (currentSession?.skill != null);

    return Tooltip(
      message: hasSkills ? '点击显示技能列表' : '当前模型未配置技能',
      child: InkWell(
        onTap: hasSkills && !_isSending ? _showSkillSelectionList : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color:
                isEnabled
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.transparent,
          ),
          child: Icon(
            CupertinoIcons.wand_stars, // 使用魔法棒图标表示技能
            size: 13,
            color:
                hasSkills && !_isSending
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  /// 构建快捷指令切换按钮
  Widget _buildQuickCommandToggle() {
    final currentSession = sessionController.currentSession.value;
    final currentModel = currentSession?.chatModel;

    // 检查当前模型或会话是否配置了快捷指令
    final hasGlobalCommands = currentModel?.chatCommands?.isNotEmpty == true;
    final hasSessionCommands =
        currentSession?.sessionQuickCommands.isNotEmpty == true;
    final hasQuickCommands = hasGlobalCommands || hasSessionCommands;

    return Tooltip(
      message: hasQuickCommands ? '点击显示快捷指令列表' : '当前模型未配置快捷指令',
      child: InkWell(
        onTap: hasQuickCommands && !_isSending ? _showQuickCommandsList : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            CupertinoIcons.command,
            size: 13,
            color:
                hasQuickCommands && !_isSending
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  /// 构建会话快捷指令按钮组
  Widget _buildSessionCommandsToggle() {
    final currentSession = sessionController.currentSession.value;
    final sessionCommands = currentSession?.sessionQuickCommands ?? [];

    if (sessionCommands.isEmpty) {
      return const SizedBox.shrink(); // 没有会话快捷指令时不显示
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分隔线

        // 会话快捷指令图标列表
        ...sessionCommands
            .take(5)
            .map(
              (command) => // 最多显示5个
                  Container(
                margin: const EdgeInsets.only(right: 4),
                child: Tooltip(
                  message: command.content,
                  child: GestureDetector(
                    onTap:
                        !_isSending ? () => _sendQuickCommand(command) : null,
                    onLongPress:
                        !_isSending
                            ? () => _removeSessionQuickCommand(command)
                            : null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _getIconDataFromString(command.icon),
                        size: 13,
                        color:
                            !_isSending
                                ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6)
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        // 如果有超过5个指令，显示更多按钮
        if (sessionCommands.length > 5)
          Container(
            margin: const EdgeInsets.only(left: 2),
            child: Tooltip(
              message: '更多会话快捷指令 (+${sessionCommands.length - 5})',
              child: InkWell(
                onTap: !_isSending ? _showSessionQuickCommandsList : null,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 12,
                    color:
                        !_isSending
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 显示快捷指令列表弹窗
  void _showQuickCommandsList() {
    final currentSession = sessionController.currentSession.value;
    final currentModel = currentSession?.chatModel;
    final globalQuickCommands = currentModel?.chatCommands ?? [];
    final sessionQuickCommands = currentSession?.sessionQuickCommands ?? [];

    // 合并全局和会话级别的快捷指令
    final allQuickCommands = [...globalQuickCommands, ...sessionQuickCommands];

    if (allQuickCommands.isEmpty && globalQuickCommands.isEmpty) {
      SnackBarUtils.showInfo(context, '当前模型未配置快捷指令');
      return;
    }

    // 计算弹窗位置 - 在快捷指令按钮上方
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            // 透明背景，点击关闭
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // 快捷指令列表弹窗
            Positioned(
              left: offset.dx + 20,
              bottom: MediaQuery.of(context).size.height - offset.dy + 10,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 400,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 显示全局快捷指令
                      if (globalQuickCommands.isNotEmpty) ...[
                        ...globalQuickCommands.map(
                          (command) => _buildQuickCommandItem(
                            command,
                            () {
                              Navigator.of(dialogContext).pop();
                              _sendQuickCommand(command);
                            },
                            showAddButton: true,
                            onAdd:
                                () => _addCommandToSession(
                                  command,
                                  dialogContext,
                                ),
                          ),
                        ),
                      ],

                      // 如果没有任何快捷指令，显示提示
                      if (allQuickCommands.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.command,
                                size: 32,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '暂无快捷指令',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 底部操作栏
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '点击指令可快速发送',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
          ],
        );
      },
    );
  }

  /// 构建快捷指令列表项
  Widget _buildQuickCommandItem(
    ChatCommand command,
    VoidCallback onTap, {
    bool showAddButton = false,
    VoidCallback? onAdd,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 指令图标
            SizedBox(
              width: 24,
              height: 24,
              child: Center(
                child: Icon(_getIconDataFromString(command.icon), size: 12),
              ),
            ),
            const SizedBox(width: 12),
            // 指令内容
            Expanded(
              child: Text(
                command.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 添加按钮（仅全局快捷指令显示）
            if (showAddButton && onAdd != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    CupertinoIcons.add_circled,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            // 发送图标
            Icon(
              CupertinoIcons.arrow_right_circle,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// 发送快捷指令
  void _sendQuickCommand(ChatCommand command) {
    // 将快捷指令内容设置到输入框
    _inputController.text = command.content;

    // 立即发送消息
    _sendMessage();
  }

  /// 将全局快捷指令添加到当前会话
  void _addCommandToSession(ChatCommand command, BuildContext dialogContext) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // 检查是否已经存在相同的快捷指令
    final sessionCommands = currentSession.sessionQuickCommands;
    final exists = sessionCommands.any((c) => c.content == command.content);

    if (exists) {
      Navigator.of(dialogContext).pop();
      SnackBarUtils.showInfo(context, '该快捷指令已存在于当前会话中');
      return;
    }

    // 生成新的ID以避免冲突
    final newCommand = command.copyWith(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 添加到会话的快捷指令列表
    final updatedCommands = List<ChatCommand>.from(sessionCommands)
      ..add(newCommand);

    // 更新会话
    final updatedSession = currentSession.copyWith(
      sessionQuickCommands: updatedCommands,
    );

    sessionController.updateSession(updatedSession);

    Navigator.of(dialogContext).pop();
    SnackBarUtils.showSuccess(context, '快捷指令已添加到当前会话');
  }

  /// 显示会话快捷指令列表弹窗
  void _showSessionQuickCommandsList() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final sessionCommands = currentSession.sessionQuickCommands;
    if (sessionCommands.isEmpty) {
      SnackBarUtils.showInfo(context, '当前会话暂无快捷指令');
      return;
    }

    // 计算弹窗位置 - 在会话快捷指令按钮上方
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            // 透明背景，点击关闭
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // 会话快捷指令列表弹窗
            Positioned(
              left: offset.dx + 20,
              bottom: MediaQuery.of(context).size.height - offset.dy + 10,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 350,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题栏
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.bookmark,
                              size: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '会话快捷指令 (${sessionCommands.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 快捷指令列表
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: sessionCommands.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                          itemBuilder: (context, index) {
                            final command = sessionCommands[index];
                            return _buildSessionQuickCommandItem(command, () {
                              Navigator.of(dialogContext).pop();
                              _sendQuickCommand(command);
                            });
                          },
                        ),
                      ),
                      // 底部操作栏
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '点击指令可快速发送',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            // 管理按钮
                            InkWell(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _showSessionCommandsManager();
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '管理',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
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
          ],
        );
      },
    );
  }

  /// 构建会话快捷指令列表项
  Widget _buildSessionQuickCommandItem(
    ChatCommand command,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            // 指令图标
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(
                  _getIconDataFromString(command.icon),
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 指令内容
            Expanded(
              child: Text(
                command.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // 发送图标
            Icon(
              CupertinoIcons.arrow_right_circle,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 显示会话快捷指令管理器
  void _showSessionCommandsManager() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) {
      SnackBarUtils.showInfo(context, '请先选择一个会话');
      return;
    }

    final sessionCommands = currentSession.sessionQuickCommands;
    final globalCommands = currentSession.chatModel?.chatCommands ?? [];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    CupertinoIcons.settings,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '会话快捷指令管理',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 400,
                constraints: const BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 当前会话快捷指令
                    Text(
                      '当前会话快捷指令 (${sessionCommands.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (sessionCommands.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '当前会话暂无快捷指令',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: sessionCommands.length,
                          itemBuilder: (context, index) {
                            final command = sessionCommands[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconDataFromString(command.icon),
                                    size: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      command.content,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed:
                                        () => _removeSessionCommand(
                                          command,
                                          dialogContext,
                                          setState,
                                        ),
                                    icon: Icon(
                                      CupertinoIcons.delete,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    // 可添加的全局快捷指令
                    Text(
                      '可添加的全局快捷指令',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (globalCommands.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '当前模型暂无全局快捷指令',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: globalCommands.length,
                          itemBuilder: (context, index) {
                            final command = globalCommands[index];
                            final isAlreadyAdded = sessionCommands.any(
                              (c) => c.content == command.content,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    isAlreadyAdded
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest
                                        : Theme.of(
                                          context,
                                        ).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      isAlreadyAdded
                                          ? Theme.of(context).dividerColor
                                          : Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconDataFromString(command.icon),
                                    size: 16,
                                    color:
                                        isAlreadyAdded
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                                .withOpacity(0.5)
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      command.content,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isAlreadyAdded
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.6)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAlreadyAdded)
                                    Icon(
                                      CupertinoIcons.check_mark_circled,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.5),
                                    )
                                  else
                                    IconButton(
                                      onPressed:
                                          () => _addGlobalCommandToSession(
                                            command,
                                            dialogContext,
                                            setState,
                                          ),
                                      icon: Icon(
                                        CupertinoIcons.add_circled,
                                        size: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 24,
                                        minHeight: 24,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 移除会话快捷指令
  void _removeSessionQuickCommand(ChatCommand command) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // 显示确认对话框
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                CupertinoIcons.delete,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '删除快捷指令',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '确定要从当前会话中删除这个快捷指令吗？',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconDataFromString(command.icon),
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        command.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _doRemoveSessionQuickCommand(command);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  /// 执行删除会话快捷指令
  void _doRemoveSessionQuickCommand(ChatCommand command) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final updatedCommands = List<ChatCommand>.from(
      currentSession.sessionQuickCommands,
    )..removeWhere((c) => c.id == command.id);

    final updatedSession = currentSession.copyWith(
      sessionQuickCommands: updatedCommands,
    );

    sessionController.updateSession(updatedSession);

    if (mounted) {
      SnackBarUtils.showSuccess(context, '已删除快捷指令');
    }
  }

  /// 移除会话快捷指令
  void _removeSessionCommand(
    ChatCommand command,
    BuildContext dialogContext,
    void Function(void Function()) setState,
  ) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final updatedCommands = List<ChatCommand>.from(
      currentSession.sessionQuickCommands,
    )..removeWhere((c) => c.id == command.id);

    final updatedSession = currentSession.copyWith(
      sessionQuickCommands: updatedCommands,
    );

    sessionController.updateSession(updatedSession);
    setState(() {});

    SnackBarUtils.showInfo(context, '已移除快捷指令');
  }

  /// 添加全局快捷指令到会话
  void _addGlobalCommandToSession(
    ChatCommand command,
    BuildContext dialogContext,
    void Function(void Function()) setState,
  ) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // 生成新的ID以避免冲突
    final newCommand = command.copyWith(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
    );

    final updatedCommands = List<ChatCommand>.from(
      currentSession.sessionQuickCommands,
    )..add(newCommand);

    final updatedSession = currentSession.copyWith(
      sessionQuickCommands: updatedCommands,
    );

    sessionController.updateSession(updatedSession);
    setState(() {});

    SnackBarUtils.showSuccess(context, '快捷指令已添加到会话');
  }

  /// 从字符串获取图标数据
  IconData _getIconDataFromString(String iconString) {
    // 这里需要实现从字符串到IconData的映射
    // 可以参考model_detail_page.dart中的_storageStringToIconData方法
    switch (iconString) {
      case 'chat_bubble':
        return CupertinoIcons.chat_bubble;
      case 'command':
        return CupertinoIcons.command;
      case 'star':
        return CupertinoIcons.star;
      case 'heart':
        return CupertinoIcons.heart;
      case 'bookmark':
        return CupertinoIcons.bookmark;
      case 'lightbulb':
        return CupertinoIcons.lightbulb;
      case 'gear':
        return CupertinoIcons.gear;
      case 'pencil':
        return CupertinoIcons.pencil;
      case 'doc':
        return CupertinoIcons.doc;
      case 'globe':
        return CupertinoIcons.globe;
      default:
        return CupertinoIcons.chat_bubble;
    }
  }

  /// 显示MCP服务列表弹窗
  Future<void> _showMcpServicesList() async {
    final currentSession = sessionController.currentSession.value;

    // MCP 服务已全局存储，从 McpStorageService 读取
    final mcpServices = await McpStorageService.loadMcpServices();

    if (mcpServices.isEmpty) {
      SnackBarUtils.showInfo(context, '当前未配置MCP服务');
      return;
    }

    // 计算弹窗位置 - 在MCP按钮上方
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            // 透明背景，点击关闭
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // MCP服务列表弹窗
            Positioned(
              left: offset.dx + 20,
              bottom: MediaQuery.of(context).size.height - offset.dy + 10,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 400,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题栏
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.gear,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MCP服务列表 (${mcpServices.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              currentSession?.mcpServer != null ? '已启用' : '已禁用',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    currentSession?.mcpServer != null
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 服务列表
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: mcpServices.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                          itemBuilder: (context, index) {
                            final service = mcpServices[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 服务名称和状态
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          service.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // 服务命令
                                  Text(
                                    '命令: ${service.command}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  // 服务参数（如果有）
                                  if (service.args.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '参数: ${service.args.join(' ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                  // 工作目录（如果有）
                                  if (service.workingDirectory?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '工作目录: ${service.workingDirectory}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                  // 超时设置（如果有）
                                  if (service.timeout != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '超时: ${service.timeout}秒',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // 底部操作栏
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '提示：双击MCP按钮查看此列表，单击切换开关状态',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _toggleMcpTools();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                currentSession?.mcpServer != null ? '禁用' : '启用',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      currentSession?.mcpServer != null
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary,
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
          ],
        );
      },
    );
  }

  /// 切换MCP工具状态
  void _toggleMcpTools() {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    // toggle: 如果已有 MCP 服务则清空，否则保持当前状态（需先选择服务）
    final updatedSession = currentSession.copyWith(
      clearMcpServer: currentSession.mcpServer != null,
    );
    sessionController.updateSession(updatedSession);

    final isEnabled = updatedSession.mcpServer != null;
    if (mounted) {
      SnackBarUtils.showInfo(
        context,
        isEnabled ? '已开启MCP工具，发送消息时可自动调用相关工具' : '已关闭MCP工具',
      );
    }

    // 如果开启了MCP，初始化选中的服务
    if (isEnabled) {
      _initializeMcpServices(updatedSession);
    } else {
      // 关闭 MCP 时清理客户端
      final serviceName = currentSession.mcpServer?.name;
      if (serviceName != null) {
        McpService.closeClient(serviceName);
      }
    }
  }

  /// 初始化会话的MCP服务
  Future<void> _initializeMcpServices(chatSession) async {
    try {
      await McpService.initializeSessionMcpServices(chatSession);
    } catch (e) {
      debugPrint('初始化MCP服务失败: $e');
    }
  }

  /// 显示MCP服务选择弹窗
  Future<void> _showMcpServiceSelection() async {
    // MCP 服务已全局存储，从 McpStorageService 读取
    final mcpServices = await McpStorageService.loadMcpServices();

    if (mcpServices.isEmpty) {
      SnackBarUtils.showInfo(context, '当前未配置MCP服务');
      return;
    }

    // 计算弹窗位置 - 在MCP按钮上方
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final session = sessionController.currentSession.value;
            final selectedName = session?.mcpServer?.name;

            return Stack(
              children: [
                // 透明背景，点击关闭
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
                // MCP服务选择弹窗
                Positioned(
                  left: offset.dx + 20,
                  bottom: MediaQuery.of(context).size.height - offset.dy + 10,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 320,
                        maxHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题栏
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.gear,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'MCP服务 (${mcpServices.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          // 服务选择列表
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: mcpServices.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    height: 1,
                                    color: Theme.of(context).dividerColor,
                                  ),
                              itemBuilder: (context, index) {
                                final service = mcpServices[index];
                                final isSelected = service.name == selectedName;
                                final toolCount = service.tools?.length ?? 0;
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(dialogContext).pop();
                                    _applyMcpSelection(
                                      isSelected ? null : service,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color:
                                          isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3)
                                              : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service.name,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  if (service.url != null &&
                                                      service.url!.isNotEmpty)
                                                    Flexible(
                                                      child: Text(
                                                        service.url!,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Theme.of(
                                                                context,
                                                              )
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.5),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Flexible(
                                                      child: Text(
                                                        '${service.command} ${service.args.join(' ')}',
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Theme.of(
                                                                context,
                                                              )
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.5),
                                                        ),
                                                      ),
                                                    ),
                                                  if (toolCount > 0) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primaryContainer,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$toolCount个工具',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimaryContainer,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
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
                          // 底部操作栏
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedName != null
                                        ? '已选 $selectedName'
                                        : '未选择',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '确认',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
              ],
            );
          },
        );
      },
    );
  }

  /// 应用MCP服务选择
  void _applyMcpSelection(McpServerConfig? service) async {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    final updatedSession = currentSession.copyWith(mcpServer: service);

    await sessionController.updateSession(updatedSession);

    if (mounted) {
      if (service != null) {
        SnackBarUtils.showInfo(context, '已选择 MCP 服务: ${service.name}');
        try {
          await McpService.initializeSessionMcpServices(updatedSession);
        } catch (e) {
          debugPrint('初始化MCP服务失败: $e');
        }
      } else {
        // 关闭 MCP 时清理客户端
        final oldServiceName = currentSession.mcpServer?.name;
        if (oldServiceName != null) {
          McpService.closeClient(oldServiceName);
        }
        SnackBarUtils.showInfo(context, '已关闭MCP工具');
      }
    }
  }

  /// 显示技能选择列表弹窗
  void _showSkillSelectionList() {
    final currentSession = sessionController.currentSession.value;
    final currentModel = currentSession?.chatModel;
    final skills = currentModel?.skills ?? [];

    if (skills.isEmpty) {
      SnackBarUtils.showInfo(context, '当前模型未配置技能');
      return;
    }

    // 计算弹窗位置 - 在技能按钮上方
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final session = sessionController.currentSession.value;
            String? selectedId = session?.skill?.id;

            return Stack(
              children: [
                // 透明背景，点击关闭
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  ),
                ),
                // 技能选择弹窗
                Positioned(
                  left: offset.dx + 20,
                  bottom: MediaQuery.of(context).size.height - offset.dy + 10,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Theme.of(context).shadowColor.withOpacity(0.2),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 320,
                        maxHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题栏
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.wand_stars,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '技能列表 (${skills.length})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  selectedId != null ? '已启用' : '已禁用',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        selectedId != null
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 技能列表
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: skills.length,
                              separatorBuilder:
                                  (context, index) => Divider(
                                    height: 1,
                                    color: Theme.of(context).dividerColor,
                                  ),
                              itemBuilder: (context, index) {
                                final skill = skills[index];
                                final isSelected = selectedId == skill.id;

                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedId = isSelected ? null : skill.id;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 选中状态图标
                                        Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(top: 1),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                isSelected
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    : Colors.transparent,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child:
                                              isSelected
                                                  ? Icon(
                                                    CupertinoIcons
                                                        .checkmark_alt,
                                                    size: 12,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 10),
                                        // 技能信息
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    _getSkillIconName(
                                                      skill.icon,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      skill.name,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                skill.description,
                                                style: TextStyle(
                                                  fontSize: 12,
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
                                  ),
                                );
                              },
                            ),
                          ),
                          // 底部操作栏
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedId != null
                                        ? '已选: ${skills.firstWhere((s) => s.id == selectedId).name}'
                                        : '未选择',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    _applySkillSelection(selectedId);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '确定',
                                    style: TextStyle(fontSize: 12),
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
              ],
            );
          },
        );
      },
    );
  }

  /// 应用技能选择
  void _applySkillSelection(String? skillId) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession == null) return;

    Skill? selectedSkill;
    if (skillId != null) {
      selectedSkill = currentSession.chatModel?.skills?.firstWhere(
        (s) => s.id == skillId,
      );
    }

    final updatedSession = currentSession.copyWith(
      skill: selectedSkill,
      clearSkill: skillId == null,
    );

    sessionController.updateSession(updatedSession);

    if (mounted) {
      SnackBarUtils.showInfo(
        context,
        selectedSkill != null ? '已选择技能: ${selectedSkill.name}' : '已清空技能选择',
      );
    }
  }

  /// 获取技能图标显示字符
  String _getSkillIconName(String icon) {
    switch (icon) {
      case 'code':
        return '💻';
      case 'globe':
        return '🌐';
      case 'pencil':
        return '✏️';
      case 'chart':
        return '📊';
      case 'lightbulb':
        return '💡';
      case 'doc':
        return '📄';
      case 'star':
        return '⭐';
      case 'search':
        return '🔍';
      case 'image':
        return '🖼️';
      default:
        return '⭐';
    }
  }

  /// ；的主要方法
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    debugPrint('发送消息: $text');

    // 防止发送空消息（没有文本且没有附件）或重复发送
    if ((text.isEmpty && _currentAttachments.isEmpty) || _isSending) return;

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
                  attachment.content != null &&
                  attachment.content != 'ERROR_PROCESSING',
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

    // 创建用户消息对象，只包含已成功处理的附件
    final userMessage = ChatMessage(
      msgId: '${timestamp}_user',
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
      repoId: null,
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
        throw ('还未绑定模型');
      }

      if (updatedSession.chatModel?.status != 'active') {
        _handleModelInactiveForSession(
          updatedSession,
          updatedSession.chatModel?.name,
        );
        return;
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
        repoId: null,
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
      String accumulatedTool = '';


      // 直接使用LLM Hub框架
      final model = updateSession.chatModel;
      if (model == null) {
        throw Exception('未找到模型配置');
      }

      final provider = model.provider;
      if (provider == null || provider.isEmpty) {
        throw Exception('模型提供商未配置');
      }

      // 创建 LLM 客户端
      client = LlmClient(updateSession);

      // // 验证配置
      // final isValid = await client.validateConfiguration();
      // if (!isValid) {
      //   throw Exception('模型配置验证失败，请检查 API Key 和 URL 设置');
      // }

      // 发送消息并获取流式响应
      final responseStream = client.sendMessageStream(userMessage);

      // 处理流式响应并更新UI（LlmClient 已在内部处理 MCP 工具调用和 follow-up）
      // chunk 格式: {content,think,tool}  三个字段互斥，每次必有一个有值
      await for (final chunkMap in responseStream) {
        // 检查用户是否要求停止响应
        final latestSession = sessionController.sessions.firstWhere(
          (s) => s.sessionId == updateSession.sessionId,
          orElse: () => updateSession,
        );
        if (latestSession.shouldStopResponse == true) break;

        final contentChunk = chunkMap['content'] ?? '';
        final thinkChunk = chunkMap['think'] ?? '';
        final toolChunk = chunkMap['tool'] ?? '';

        if (contentChunk.isNotEmpty || thinkChunk.isNotEmpty || toolChunk.isNotEmpty) {
          accumulatedContent += contentChunk;
          accumulatedThink += thinkChunk;
          accumulatedTool += toolChunk;

          final messageIndex = updateSession.messages.indexWhere(
            (msg) => msg.msgId == botMessageId,
          );

          if (messageIndex != -1) {
            botMessage.content = accumulatedContent;
            botMessage.think = accumulatedThink;
            botMessage.toolContent = accumulatedTool;

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

        updateSession = updateSession.copyWith(
          messages: updatedMessages,
          isSending: false,
        );

        sessionController.updateSession(updateSession);
      }
      setState(() {
        _thinkingTimes[botMessageId] = generationDuration;
        _streamingMessageIds.remove(botMessageId);
      });
      widget.onStreamingChanged?.call(_streamingMessageIds);
    } catch (e) {
      rethrow;
    } finally {
      // 释放客户端资源
      try {
        client?.dispose();
      } catch (e) {
        // 忽略释放资源时的错误
      }
    }
  }

  // 旧的指令关键词判断函数已移除，统一改为基于最终输出结构判断

  // 基于输出内容特征判断是否是整理后的文档
  bool _looksLikeOrganizedDocument(String content) {
    final text = content.trim();
    if (text.isEmpty) return false;
    // 规则特征：
    // 1. 含有多级标题 / 有序或无序列表结构
    // 2. 明显章节关键字出现频率较高
    // 3. 总结/整理类关键词 + 结构性符号同时命中
    int score = 0;

    final headingPattern = RegExp(
      r'^(#{1,6}\s+.+)|(^\d+\.|^[-*+]\s+)',
      multiLine: true,
    );
    if (headingPattern.hasMatch(text)) score += 2;

    final sectionKeywords = [
      '目录',
      '引言',
      '背景',
      '概述',
      '章节',
      '总结',
      '结论',
      '实现',
      '方案',
      '目的',
      '目标',
      '特性',
      '注意事项',
      '示例',
      '使用方法',
      '原理',
    ];
    int sectionHits = 0;
    for (final k in sectionKeywords) {
      if (text.contains(k)) sectionHits++;
    }
    if (sectionHits >= 3) {
      score += 2;
    } else if (sectionHits >= 1)
      score += 1;

    final structureMarkers = RegExp(r'(\n\n)|(```)|(\r?\n#{1,6}\s)');
    if (structureMarkers.allMatches(text).length >= 2) score += 1;

    final length = text.length;
    if (length > 300) score += 1; // 适度长度

    // 如果出现“以下是.*整理|总结|归纳|优化后的”字样
    if (RegExp(
      r'以下[\s\S]{0,10}(整理|总结|归纳|优化|文档)',
      multiLine: true,
    ).hasMatch(text)) {
      score += 2;
    }

    debugPrint('🧪 文档特征评分: $score (命中章节: $sectionHits, 长度: $length)');
    return score >= 3; // 阈值可调
  }

  /// 从原始整理文本中提取纯正文主体：
  /// 1. 移除开头若干行的说明/引导语（如“以下是…整理…”, “我已为你…”, “好的，下面是…” 等）
  /// 2. 移除尾部客套/继续需求类语句（如“如果你需要…”, “希望这些…”, “如需进一步…” 等）
  /// 3. 保留所有标题 / 列表 / 代码块 / 缩进与空行，不做重排
  /// 4. 避免误删真正的第一节标题：检测到以 # / 数字. / 中文序号 / “一、” 等结构即认为正文开始
  ///
  /// 设计原则：轻量启发式，不追求完美，若误判宁可少删；所有删减有 debug 日志可追溯。
  String _extractOrganizedBody(String raw) {
    if (raw.trim().isEmpty) return raw.trim();
    final original = raw.replaceAll('\r\n', '\n');
    final lines = original.split('\n');

    // 先尝试识别 --- 分隔的正文区域：
    // 情况A：YAML front matter（开头两段 --- 包裹的元信息） -> 真正文在第二个 --- 之后
    // 情况B：正文被人工在前后加上 --- 边界 -> 取两个 --- 之间最长的段落作为正文
    // 情况C：多段 ---，选取相邻 --- 之间非空行数最多的段落
    List<int> delimIdx = [];
    final delimPattern = RegExp(r'^-{3,}\s*$');
    for (var i = 0; i < lines.length; i++) {
      if (delimPattern.hasMatch(lines[i].trim())) {
        delimIdx.add(i);
      }
    }
    bool usedDelimExtraction = false;
    if (delimIdx.length >= 2) {
      // 检测 front matter：首行是 --- 且第二个 --- 在前 20 行以内，并且中间多为 key: value
      final first = delimIdx.first;
      final second = delimIdx[1];
      bool looksLikeFrontMatter = false;
      if (first == 0 && second - first <= 20) {
        int yamlLike = 0;
        for (int i = first + 1; i < second; i++) {
          final l = lines[i].trim();
          if (l.isEmpty) continue;
          if (RegExp(r'^[A-Za-z0-9_-]+:\s').hasMatch(l)) yamlLike++;
        }
        if (yamlLike >= 1 && yamlLike >= (second - first - 1) / 2) {
          looksLikeFrontMatter = true;
        }
      }
      if (looksLikeFrontMatter) {
        // 去掉 front matter，正文从 second+1 开始，到末尾
        final removed = lines.sublist(0, second + 1).length;
        final body = lines.sublist(second + 1);
        lines
          ..clear()
          ..addAll(body);
        usedDelimExtraction = true;
        debugPrint('📎 已移除 front matter (行数=$removed)，继续正文提取');
      } else {
        // 选取相邻 --- 之间最长的段落
        int bestStart = -1;
        int bestEnd = -1;
        int bestNonEmpty = 0;
        int totalNonEmpty = lines.where((l) => l.trim().isNotEmpty).length;
        for (int i = 0; i < delimIdx.length - 1; i++) {
          final a = delimIdx[i];
          final b = delimIdx[i + 1];
          final segment = lines.sublist(a + 1, b);
          final nonEmpty = segment.where((l) => l.trim().isNotEmpty).length;
          if (nonEmpty > bestNonEmpty) {
            bestNonEmpty = nonEmpty;
            bestStart = a + 1;
            bestEnd = b - 1;
          }
        }
        if (bestStart != -1 && bestNonEmpty >= 1) {
          // 判断该段是否占据主要内容
          final ratio = totalNonEmpty == 0 ? 0 : bestNonEmpty / totalNonEmpty;
          if (ratio >= 0.5 || bestNonEmpty >= 8) {
            final body = lines.sublist(bestStart, bestEnd + 1);
            lines
              ..clear()
              ..addAll(body);
            usedDelimExtraction = true;
            debugPrint(
              '📎 使用 --- 分隔提取正文: segmentNonEmpty=$bestNonEmpty ratio=${ratio.toStringAsFixed(2)}',
            );
          }
        }
      }
    }

    final bodyStartMarkers = RegExp(
      r'^(#{1,6}\s|[0-9]+[\.|、]\s|[一二三四五六七八九十]{1,3}[、.\s]|\*\s|\-|\+\s)',
    );
    final leadingDisclaimer = RegExp(
      r'^(以下是|这是|我(已|为)?你|基于你|根据你|好的[,，]?|下面(是|为)|现对|整理如下|总结如下)',
    );
    final leadingShortWithKeywords = RegExp(r'^(以下|现在|好的).{0,20}(整理|总结|归纳|优化)');
    int removedHead = 0;

    // 去除前导说明性行（长度不超过 60，且不匹配正文开始标记）
    while (lines.isNotEmpty) {
      final l = lines.first.trim();
      if (l.isEmpty) {
        lines.removeAt(0);
        continue;
      }
      if (bodyStartMarkers.hasMatch(l)) break; // 进入正文
      final isDisclaimer =
          (l.length <= 60) &&
          (leadingDisclaimer.hasMatch(l) ||
              leadingShortWithKeywords.hasMatch(l));
      // 如果含有“整理/总结/归纳/优化”但又像句子而非标题，也删除
      final containsKeywords = RegExp(r'(整理|总结|归纳|优化)').hasMatch(l);
      final looksLikeTitle = RegExp(r'(目录|概述)$').hasMatch(l);
      if (isDisclaimer ||
          (containsKeywords &&
              !looksLikeTitle &&
              !bodyStartMarkers.hasMatch(l) &&
              l.length < 40)) {
        lines.removeAt(0);
        removedHead++;
        continue;
      }
      break; // 其他情况保留
    }
    // 清理前导多余空行
    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
      lines.removeAt(0);
    }

    // 处理尾部客套/引导继续类语句
    final trailingPatterns = RegExp(
      r'^(如果你需要|如需进一步|需要我|欢迎继续|希望这些|若还需要|可以继续|有其他|随时告诉|祝你|祝好)',
    );
    int removedTail = 0;
    while (lines.isNotEmpty) {
      final l = lines.last.trim();
      if (l.isEmpty) {
        lines.removeLast();
        continue;
      }
      if (l.length <= 40 && trailingPatterns.hasMatch(l)) {
        lines.removeLast();
        removedTail++;
        continue;
      }
      // 去掉单独一行“—— END ——”等装饰
      if (RegExp(r'^[-—~_*\s]{3,}$').hasMatch(l)) {
        lines.removeLast();
        removedTail++;
        continue;
      }
      break;
    }
    // 去除尾部多余空行
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }

    final result = lines.join('\n');
    if (removedHead > 0 || removedTail > 0) {
      debugPrint(
        '✂️ 整理正文提取: 去掉前导 $removedHead 行, 结尾 $removedTail 行; 原长度=${raw.length}, 新长度=${result.length}',
      );
    }
    if (usedDelimExtraction) {
      debugPrint('✅ 已结合 --- 分隔完成正文抽取，最终长度=${result.length}');
    }
    return result;
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

  /// 处理模型未激活状态
  void _handleModelInactiveForSession(ChatSession session, String? modelName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final botMessageId = '${timestamp}_bot';

    final systemMessage = ChatMessage(
      msgId: botMessageId,
      role: MessageRole.bot,
      content: '当前模型 "$modelName" 已停用，请先启用模型后再发送消息。',
      timestamp: DateTime.now(),
      repoId: null,
      sessionId: session.sessionId,
      isError: true,
    );

    widget.messageKeys[systemMessage.msgId] = GlobalKey();

    final updatedMessages = List<ChatMessage>.from(session.messages)
      ..add(systemMessage);
    final updatedSession = session.copyWith(
      messages: updatedMessages,
      isSending: false,
    );

    sessionController.updateSession(updatedSession);
    setState(() {});

    // 滚动到底部显示提示消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });
  }

  /// 处理发送错误
  void _handleSendError(dynamic error) {
    final currentSession = sessionController.currentSession.value;
    if (currentSession != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final errorMessage = ChatMessage(
        msgId: timestamp.toString(),
        role: MessageRole.bot,
        content: '抱歉，服务暂时不可用，$error',
        timestamp: DateTime.now(),
        repoId: null,
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
                '确认清除',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            '确定要清除当前对话的所有历史记录吗？此操作不可撤销。',
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
                '取消',
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
              child: const Text('清除', style: TextStyle(fontSize: 14)),
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
      SnackBarUtils.showSuccess(context, '历史记录已清除');
    }

    // 强制滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
      // 清除历史记录后自动聚焦到输入框
      _inputFocusNode.requestFocus();
    });
  }

  /// 处理 native tool_calls（API 原生返回的 tool_calls）
  ///
  /// 当 LLM 通过原生 tools 参数返回 tool_calls 时，
  /// 执行 MCP 工具调用并将结果发送回 LLM 以获取最终回复。
  Future<void> _handleNativeMcpToolCalls(
    LlmClient? client,
    ChatSession session,
    ChatMessage userMessage,
    String toolCallsJson,
    String botMessageId,
  ) async {
    try {
      debugPrint('🔧 开始处理 native tool_calls...');

      // 解析 tool_calls JSON
      final List<dynamic> toolCallsList;
      try {
        toolCallsList = jsonDecode(toolCallsJson) as List<dynamic>;
      } catch (e) {
        debugPrint('❌ 解析 tool_calls JSON 失败: $e');
        // 回退到文本解析方式
        final currentSession = sessionController.currentSession.value;
        if (currentSession != null) {
          final messageIndex = currentSession.messages.indexWhere(
            (msg) => msg.msgId == botMessageId,
          );
          if (messageIndex != -1) {
            await _processMcpToolCalls(
              currentSession,
              currentSession.messages[messageIndex].content,
              botMessageId,
            );
          }
        }
        return;
      }

      if (toolCallsList.isEmpty) {
        debugPrint('📝 tool_calls 列表为空');
        return;
      }

      debugPrint('🔧 解析到 ${toolCallsList.length} 个 tool_calls');

      // MCP client 应该在会话切换/选择 MCP 时已初始化，这里只做存在性检查
      final serviceName = session.mcpServer?.name;
      if (serviceName == null || McpService.getMCPClient(serviceName) == null) {
        debugPrint('⚠️ MCP 客户端未初始化，尝试初始化: $serviceName');
        final initializedServices =
            await McpService.initializeSessionMcpServices(session);
        if (initializedServices.isEmpty) {
          debugPrint('⚠️ 无法初始化 MCP 服务');
          return;
        }
      }
      if (serviceName == null) {
        debugPrint('⚠️ 会话未绑定 MCP 服务');
        return;
      }

      final mcpClient = McpService.getMCPClient(serviceName);
      if (mcpClient == null) {
        debugPrint('❌ MCP 客户端未就绪: $serviceName');
        return;
      }

      // 使用 mcp_client 标准 API 直接调用工具
      final toolResults = <McpToolResult>[];
      for (final tc in toolCallsList) {
        final toolName = tc['name'] as String? ?? '';
        final arguments = tc['arguments'] as Map<String, dynamic>? ?? {};

        if (toolName.isEmpty) continue;

        debugPrint('🔧 准备调用工具: $toolName, 参数: $arguments');

        if (mounted) {
          SnackBarUtils.showInfo(context, '正在执行工具调用: $toolName');
        }

        try {
          // 标准 MCP client.callTool API
          final callResult = await mcpClient.callTool(toolName, arguments);
          final isError = callResult.isError == true;

          // 格式化 CallToolResult 内容
          final buffer = StringBuffer();
          for (final content in callResult.content) {
            if (content is TextContent) {
              buffer.writeln(content.text);
            } else if (content is ImageContent) {
              buffer.writeln('[图片: ${content.data ?? content.url}]');
            } else {
              buffer.writeln(content.toString());
            }
          }
          final formattedResult = buffer.toString().trim();

          toolResults.add(
            McpToolResult(
              toolName: toolName,
              arguments: arguments,
              result: formattedResult,
              isSuccess: !isError,
              error: isError ? formattedResult : null,
              timestamp: DateTime.now(),
            ),
          );

          debugPrint('${isError ? "⚠️" : "✅"} 工具 $toolName: $formattedResult');
        } catch (e) {
          debugPrint('❌ 工具调用失败: $toolName, 错误: $e');
          toolResults.add(
            McpToolResult(
              toolName: toolName,
              arguments: arguments,
              result: '',
              isSuccess: false,
              error: e.toString(),
              timestamp: DateTime.now(),
            ),
          );
        }
      }

      if (toolResults.isEmpty) {
        debugPrint('⚠️ 没有成功执行任何工具调用');
        return;
      }

      debugPrint(
        '✅ 工具调用完成: ${toolResults.where((r) => r.isSuccess).length}/${toolResults.length} 成功',
      );

      // 将工具结果追加到当前 AI 消息中
      await _appendMcpToolResults(session, toolResults, botMessageId);

      // 发送工具结果回 LLM 以获取最终回复
      if (client != null) {
        await _sendMcpResultsToLLMForFinalResponse(
          client,
          session,
          userMessage,
          toolCallsList,
          toolResults,
          botMessageId,
        );
      }
    } catch (e) {
      debugPrint('❌ native tool_calls 处理失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'MCP工具调用失败: ${e.toString()}');
      }
    }
  }

  /// 将 MCP 工具调用结果发送回 LLM 并流式获取最终回复
  Future<void> _sendMcpResultsToLLMForFinalResponse(
    LlmClient client,
    ChatSession session,
    ChatMessage userMessage,
    List<dynamic> toolCallsList,
    List<McpToolResult> toolResults,
    String botMessageId,
  ) async {
    try {
      debugPrint('🔄 发送工具结果回 LLM 以获取最终回复...');

      // 获取当前会话
      final currentSession = sessionController.currentSession.value;
      if (currentSession == null) return;

      final messageIndex = currentSession.messages.indexWhere(
        (msg) => msg.msgId == botMessageId,
      );
      if (messageIndex == -1) {
        debugPrint('❌ 无法找到对应的 AI 消息: $botMessageId');
        return;
      }

      final botMessage = currentSession.messages[messageIndex];

      // 构建包含工具结果的消息列表
      final messages = <Map<String, dynamic>>[];

      // 系统提示词（包含 MCP 工具信息）
      final systemPrompt = client.buildSystemPrompt(session: session);
      if (systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }

      // 用户消息（包含附件信息）
      final userContent =
          userMessage.attachments.isEmpty
              ? userMessage.content
              : '${userMessage.attachments.map((a) => '[${a.name}]\n${a.content ?? ""}').join('\n\n')}\n\n${userMessage.content}';
      messages.add({'role': 'user', 'content': userContent});

      // 添加 assistant 消息（包含之前的 tool_calls，转换为 OpenAI 兼容格式）
      messages.add({
        'role': 'assistant',
        'content': botMessage.content.isNotEmpty ? botMessage.content : null,
        'tool_calls':
            toolCallsList.map((tc) {
              final m = tc as Map<String, dynamic>;
              return {
                'id': m['id'] ?? 'call_${m['index'] ?? 0}',
                'type': 'function',
                'function': {
                  'name': m['name'] ?? '',
                  'arguments':
                      m['arguments'] is String
                          ? m['arguments']
                          : jsonEncode(m['arguments'] ?? {}),
                },
              };
            }).toList(),
      });

      // 添加 tool 结果消息
      for (int i = 0; i < toolResults.length; i++) {
        final result = toolResults[i];
        final tc =
            i < toolCallsList.length
                ? toolCallsList[i] as Map<String, dynamic>?
                : null;
        final toolCallId = tc?['id'] as String? ?? 'call_$i';

        messages.add({
          'role': 'tool',
          'tool_call_id': toolCallId,
          'content':
              result.isSuccess
                  ? result.result
                  : '错误: ${result.error ?? "未知错误"}',
        });
      }

      // 创建新的流式 AI 消息
      final followUpTimestamp = DateTime.now().millisecondsSinceEpoch;
      final followUpMsgId = '${followUpTimestamp}_bot_followup';
      final followUpMessage = ChatMessage(
        msgId: followUpMsgId,
        role: MessageRole.bot,
        content: '',
        think: '',
        timestamp: DateTime.now(),
        repoId: null,
        sessionId: session.sessionId,
        isError: false,
        generationStartTime: DateTime.now(),
      );

      widget.messageKeys[followUpMsgId] = GlobalKey();
      _streamingMessageIds.add(followUpMsgId);
      widget.onStreamingChanged?.call(_streamingMessageIds);

      // 添加消息到会话
      var followUpSession = currentSession;
      final updatedMessages = List<ChatMessage>.from(followUpSession.messages)
        ..add(followUpMessage);
      followUpSession = followUpSession.copyWith(
        messages: updatedMessages,
        isSending: true,
      );
      sessionController.updateSession(followUpSession);
      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(force: true);
      });

      // 构建 follow-up API 请求并发送流式响应
      final followUpStream = client.sendMessageStreamWithMessages(messages);

      String followUpContent = '';
      String followUpThink = '';

      await for (final chunkMap in followUpStream) {
        final latestSession = sessionController.sessions.firstWhere(
          (s) => s.sessionId == followUpSession.sessionId,
          orElse: () => followUpSession,
        );
        if (latestSession.shouldStopResponse == true) break;

        final contentChunk = chunkMap['content'] ?? '';
        final thinkChunk = chunkMap['think'] ?? '';

        followUpContent += contentChunk;
        followUpThink += thinkChunk;

        if (contentChunk.isNotEmpty || thinkChunk.isNotEmpty) {
          final msgIndex = followUpSession.messages.indexWhere(
            (msg) => msg.msgId == followUpMsgId,
          );
          if (msgIndex != -1) {
            followUpMessage.content = followUpContent;
            followUpMessage.think = followUpThink;
            final msgs = List<ChatMessage>.from(followUpSession.messages);
            msgs[msgIndex] = followUpMessage;
            followUpSession = followUpSession.copyWith(
              messages: msgs,
              isSending: true,
            );
            sessionController.updateSession(followUpSession);
            setState(() {});
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      }

      // 完成 follow-up 响应
      final followUpEndTime = DateTime.now();
      final msgIdx = followUpSession.messages.indexWhere(
        (msg) => msg.msgId == followUpMsgId,
      );
      if (msgIdx != -1) {
        final msgs = List<ChatMessage>.from(followUpSession.messages);
        msgs[msgIdx] = followUpMessage.copyWith(
          generationEndTime: followUpEndTime,
          generationDuration: followUpEndTime.difference(
            followUpMessage.generationStartTime!,
          ),
          inputTokens: _estimateTokenCount(userMessage.content),
          outputTokens: _estimateTokenCount(followUpContent),
          totalTokens:
              _estimateTokenCount(userMessage.content) +
              _estimateTokenCount(followUpContent),
        );
        followUpSession = followUpSession.copyWith(
          messages: msgs,
          isSending: false,
        );
        sessionController.updateSession(followUpSession);
      }

      setState(() {
        _thinkingTimes[followUpMsgId] = followUpEndTime.difference(
          followUpMessage.generationStartTime!,
        );
        _streamingMessageIds.remove(followUpMsgId);
      });
      widget.onStreamingChanged?.call(_streamingMessageIds);

      debugPrint('✅ MCP 工具调用 follow-up 完成: 内容长度 ${followUpContent.length}');
    } catch (e) {
      debugPrint('❌ 发送工具结果回 LLM 失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, '获取工具调用结果失败: ${e.toString()}');
      }
    }
  }

  /// 处理MCP工具调用
  Future<void> _processMcpToolCalls(
    ChatSession session,
    String aiResponse,
    String botMessageId,
  ) async {
    try {
      // 检查会话是否启用了MCP工具
      if (session.mcpServer == null) {
        debugPrint('📝 会话未启用MCP工具，跳过工具调用');
        return;
      }

      // 检查是否配置了全局 MCP 服务
      if (!McpService.hasGlobalMcpServices) {
        debugPrint('📝 未配置 MCP 服务，跳过工具调用');
        return;
      }

      debugPrint('🔍 开始分析AI响应中的工具调用...');

      // MCP client 应该在会话切换/选择 MCP 时已初始化，这里只做存在性检查
      final serviceName = session.mcpServer!.name;
      if (McpService.getMCPClient(serviceName) == null) {
        debugPrint('⚠️ MCP 客户端未初始化，尝试初始化: $serviceName');
        final initializedServices =
            await McpService.initializeSessionMcpServices(session);
        if (initializedServices.isEmpty) {
          debugPrint('⚠️ 无法初始化任何MCP服务');
          return;
        }
        debugPrint('✅ 已初始化 ${initializedServices.length} 个MCP服务');
      }

      // 解析AI响应中的工具调用请求
      final toolCalls = McpService.parseToolCallsFromResponse(aiResponse);
      if (toolCalls.isEmpty) {
        debugPrint('📝 AI响应中未找到工具调用请求');
        return;
      }

      debugPrint('🔧 找到 ${toolCalls.length} 个工具调用请求');

      // 显示工具调用提示
      if (mounted) {
        SnackBarUtils.showInfo(context, '正在执行 ${toolCalls.length} 个工具调用...');
      }

      // 执行工具调用
      final toolResults = await McpService.executeSessionToolCalls(
        session: session,
        toolCalls: toolCalls,
      );

      if (toolResults.isEmpty) {
        debugPrint('⚠️ 没有成功执行任何工具调用');
        return;
      }

      // 将工具调用结果追加到当前AI消息中
      await _appendMcpToolResults(session, toolResults, botMessageId);

      debugPrint('✅ MCP工具调用处理完成');
    } catch (e) {
      debugPrint('❌ MCP工具调用处理失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, 'MCP工具调用失败: ${e.toString()}');
      }
    }
  }

  /// 将MCP工具调用结果追加到AI消息中
  Future<void> _appendMcpToolResults(
    ChatSession session,
    List<McpToolResult> toolResults,
    String botMessageId,
  ) async {
    try {
      // 找到对应的AI消息
      final currentSession = sessionController.currentSession.value;
      if (currentSession == null ||
          currentSession.sessionId != session.sessionId) {
        debugPrint('❌ 无法找到当前会话');
        return;
      }

      final messageIndex = currentSession.messages.indexWhere(
        (msg) => msg.msgId == botMessageId,
      );

      if (messageIndex == -1) {
        debugPrint('❌ 无法找到对应的AI消息: $botMessageId');
        return;
      }

      final originalMessage = currentSession.messages[messageIndex];

      // 格式化所有工具结果，增强显示效果
      final formattedResults = <String>[];
      for (int i = 0; i < toolResults.length; i++) {
        final result = toolResults[i];
        final formattedResult = _formatMcpToolResultForDisplay(result, i + 1);
        formattedResults.add(formattedResult);
      }

      // 将工具结果追加到AI消息内容中，使用更好的分隔符
      final separator = '\n\n---\n\n📋 **工具调用结果** 📋\n\n';
      final toolResultsText = formattedResults.join('\n\n---\n\n');
      final updatedContent =
          '${originalMessage.content}$separator$toolResultsText';

      // 创建更新后的消息
      final updatedMessage = originalMessage.copyWith(
        content: updatedContent,
        timestamp: DateTime.now(), // 更新时间戳
      );

      // 更新会话中的消息
      final updatedMessages = List<ChatMessage>.from(currentSession.messages);
      updatedMessages[messageIndex] = updatedMessage;

      final updatedSession = currentSession.copyWith(messages: updatedMessages);

      sessionController.updateSession(updatedSession);
      setState(() {});

      // 滚动到底部显示更新的内容
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(force: true);
      });

      // 显示成功提示
      if (mounted) {
        final successCount = toolResults.where((r) => r.isSuccess).length;
        SnackBarUtils.showSuccess(
          context,
          '工具调用完成: $successCount/${toolResults.length} 成功',
        );
      }

      debugPrint('✅ 工具调用结果已追加到AI消息中');
    } catch (e) {
      debugPrint('❌ 追加工具结果失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, '追加工具结果失败: ${e.toString()}');
      }
    }
  }

  /// 格式化单个MCP工具结果用于显示
  String _formatMcpToolResultForDisplay(McpToolResult result, int index) {
    final buffer = StringBuffer();

    // 工具调用标题
    buffer.writeln('🔧 **工具调用 #$index: ${result.toolName}**');

    // 调用参数
    if (result.arguments.isNotEmpty) {
      buffer.writeln('📝 **调用参数:**');
      result.arguments.forEach((key, value) {
        buffer.writeln('   • $key: $value');
      });
      buffer.writeln();
    }

    // 执行状态
    final statusIcon = result.isSuccess ? '✅' : '❌';
    final statusText = result.isSuccess ? '成功' : '失败';
    buffer.writeln('$statusIcon **执行状态:** $statusText');

    // 错误信息
    if (!result.isSuccess && result.error != null) {
      buffer.writeln('⚠️ **错误信息:** ${result.error}');
    }

    // 执行结果
    if (result.result.isNotEmpty) {
      buffer.writeln('📄 **执行结果:**');
      // 尝试格式化JSON结果
      try {
        final jsonData = jsonDecode(result.result);
        if (jsonData is Map || jsonData is List) {
          final prettyJson = const JsonEncoder.withIndent(
            '  ',
          ).convert(jsonData);
          buffer.writeln('```json\n$prettyJson\n```');
        } else {
          buffer.writeln('```\n${result.result}\n```');
        }
      } catch (e) {
        // 不是JSON格式，直接显示
        if (result.result.length > 200) {
          // 长文本使用代码块格式
          buffer.writeln('```\n${result.result}\n```');
        } else {
          // 短文本直接显示
          buffer.writeln(result.result);
        }
      }
    }

    // 执行时间
    final timeStr =
        '${result.timestamp.hour.toString().padLeft(2, '0')}:'
        '${result.timestamp.minute.toString().padLeft(2, '0')}:'
        '${result.timestamp.second.toString().padLeft(2, '0')}';
    buffer.writeln('\n⏰ **执行时间:** $timeStr');

    return buffer.toString().trim();
  }
}
