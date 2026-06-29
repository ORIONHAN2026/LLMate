import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:llmwork/features/chat/widgets/message_widgets/ai_message_widget.dart';
import 'package:llmwork/features/chat/widgets/message_widgets/user_message_widget.dart';
import 'package:llmwork/features/chat/widgets/message_widgets/tool_message_widget.dart';
import 'package:llmwork/utils/responsive_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/models.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:llmwork/utils/snackbar_utils.dart';

class ChatConversationArea extends StatefulWidget {
  final ChatSession chatSession;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;

  const ChatConversationArea({
    super.key,
    required this.chatSession,
    required this.scrollController,
    required this.messageKeys,
  });

  @override
  State<ChatConversationArea> createState() => _ChatConversationAreaState();
}

class _ChatConversationAreaState extends State<ChatConversationArea> {
  // 截图回调方法
  Future<void> handleCaptureMessageImage(ChatMessage message) async {
    try {
      // 确保当前帧完成绘制
      await WidgetsBinding.instance.endOfFrame;
      await _generateMessageImage(context, message);
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('消息', e.toString()));
    }
  }

  Future<void> handleCaptureRoundImage(ChatMessage message) async {
    try {
      // 确保当前帧完成绘制
      await WidgetsBinding.instance.endOfFrame;
      await _generateRoundImage(context, message);
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('当前回合', e.toString()));
    }
  }

  Future<void> handleCaptureConversationImage() async {
    try {
      // 确保当前帧完成绘制
      await WidgetsBinding.instance.endOfFrame;
      await _generateConversationImage(context);
    } catch (e) {
      print(AppLocalizations.of(context)!.screenshotTypeFailed('整个对话', e.toString())); // 打印错误信息以便调试

      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('整个对话', e.toString()));
    }
  }

  // 截图：单条消息（优化版 - 使用真实widget样式）
  Future<void> _generateMessageImage(
    BuildContext context,
    ChatMessage message,
  ) async {
    try {
      print('开始优化的单条消息截图');

      // 创建一个临时的渲染上下文，包含单条消息
      final GlobalKey containerKey = GlobalKey();
      OverlayEntry? overlayEntry;

      try {
        // 创建包含单条消息的widget
        final messageWidget = Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.white,
            child: RepaintBoundary(
              key: containerKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child:
                    message.role == MessageRole.user
                        ? UserMessageWidget(
                          message: message,
                          onUpdate: () {},
                          onCaptureMessage: null,
                          onCaptureRound: null,
                          onCaptureConversation: null,
                        )
                        : message.role == MessageRole.tool
                        ? ToolMessageWidget(message: message)
                        : AiMessageWidget(
                          message: message,
                          onUpdate: () {},
                          onCaptureMessage: null,
                          onCaptureRound: null,
                          onCaptureConversation: null,
                        ),
              ),
            ),
          ),
        );

        // 创建overlay
        overlayEntry = OverlayEntry(
          builder:
              (context) => Positioned(
                left: -10000, // 移到屏幕外
                top: -10000,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: messageWidget,
                ),
              ),
        );

        // 插入overlay
        Overlay.of(context).insert(overlayEntry);

        // 等待渲染完成
        await Future.delayed(const Duration(milliseconds: 300));

        // 获取渲染边界
        final RenderRepaintBoundary? boundary =
            containerKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotFailed);
          return;
        }

        // 等待绘制完成
        if (boundary.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 截图
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.generateImageFailed);
          return;
        }

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        await _copyImageToClipboard(pngBytes);
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.messageScreenshotCopied);

        print('成功完成优化的单条消息截图');
      } finally {
        // 确保移除overlay
        overlayEntry?.remove();
      }
    } catch (e) {
      print('优化的单条消息截图失败: $e');
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('消息', e.toString()));
    }
  }

  // 截图：当前回合（优化版 - 使用真实widget样式）
  Future<void> _generateRoundImage(
    BuildContext context,
    ChatMessage message,
  ) async {
    try {
      final messages = widget.chatSession.messages;
      final messageIndex = messages.indexWhere((m) => m.msgId == message.msgId);
      if (messageIndex == -1) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotFindMessage);
        return;
      }

      List<ChatMessage> roundMessages = [];
      if (message.role == MessageRole.bot) {
        for (int i = messageIndex - 1; i >= 0; i--) {
          if (messages[i].role == MessageRole.user) {
            roundMessages = [messages[i], message];
            break;
          }
        }
      } else {
        roundMessages.add(message);
        for (int i = messageIndex + 1; i < messages.length; i++) {
          if (messages[i].role == MessageRole.bot) {
            roundMessages.add(messages[i]);
            break;
          }
        }
      }

      if (roundMessages.isEmpty) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotFindCompleteRound);
        return;
      }

      print('开始优化的回合截图，消息数: ${roundMessages.length}');

      // 创建一个临时的渲染上下文，包含回合消息
      final GlobalKey containerKey = GlobalKey();
      OverlayEntry? overlayEntry;

      try {
        // 创建包含回合消息的widget
        final roundWidget = Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.white,
            child: RepaintBoundary(
              key: containerKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      for (final msg in roundMessages)
                        Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          child:
                              msg.role == MessageRole.user
                                  ? UserMessageWidget(
                                    message: msg,
                                    onUpdate: () {},
                                    onCaptureMessage: null,
                                    onCaptureRound: null,
                                    onCaptureConversation: null,
                                  )
                                  : AiMessageWidget(
                                    message: msg,
                                    onUpdate: () {},
                                    onCaptureMessage: null,
                                    onCaptureRound: null,
                                    onCaptureConversation: null,
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // 创建overlay
        overlayEntry = OverlayEntry(
          builder:
              (context) => Positioned(
                left: -10000, // 移到屏幕外
                top: -10000,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: roundWidget,
                ),
              ),
        );

        // 插入overlay
        Overlay.of(context).insert(overlayEntry);

        // 等待渲染完成
        await Future.delayed(const Duration(milliseconds: 300));

        // 获取渲染边界
        final RenderRepaintBoundary? boundary =
            containerKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotFailed);
          return;
        }

        // 等待绘制完成
        if (boundary.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 截图
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.generateImageFailed);
          return;
        }

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        await _copyImageToClipboard(pngBytes);
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.currentRoundScreenshotCopied);

        print('成功完成优化的回合截图');
      } finally {
        // 确保移除overlay
        overlayEntry?.remove();
      }
    } catch (e) {
      print('优化的回合截图失败: $e');
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('当前回合', e.toString()));
    }
  }

  // 截图：整个对话（优化版 - 无需滚动）
  Future<void> _generateConversationImage(BuildContext context) async {
    try {
      if (widget.chatSession.messages.isEmpty) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.noMessagesInConversation);
        return;
      }

      // 使用优化的渲染方式，避免滚动
      await _generateConversationImageOptimized(context);
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('整个对话', e.toString()));
    }
  }

  // 优化的对话截图方法 - 避免滚动
  Future<void> _generateConversationImageOptimized(BuildContext context) async {
    try {
      print('开始优化的对话截图，总消息数: ${widget.chatSession.messages.length}');

      // 创建一个临时的渲染上下文，包含所有消息
      final GlobalKey containerKey = GlobalKey();
      OverlayEntry? overlayEntry;

      try {
        // 创建包含所有消息的widget
        final allMessagesWidget = Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.white,
            child: RepaintBoundary(
              key: containerKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      for (final msg in widget.chatSession.messages)
                        Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          child:
                              msg.role == MessageRole.user
                                  ? UserMessageWidget(
                                    message: msg,
                                    onUpdate: () {},
                                    onCaptureMessage: null,
                                    onCaptureRound: null,
                                    onCaptureConversation: null,
                                  )
                                  : AiMessageWidget(
                                    message: msg,
                                    onUpdate: () {},
                                    onCaptureMessage: null,
                                    onCaptureRound: null,
                                    onCaptureConversation: null,
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // 创建overlay
        overlayEntry = OverlayEntry(
          builder:
              (context) => Positioned(
                left: -10000, // 移到屏幕外
                top: -10000,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: allMessagesWidget,
                ),
              ),
        );

        // 插入overlay
        Overlay.of(context).insert(overlayEntry);

        // 等待渲染完成
        await Future.delayed(const Duration(milliseconds: 300));

        // 获取渲染边界
        final RenderRepaintBoundary? boundary =
            containerKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotFailed);
          return;
        }

        // 等待绘制完成
        if (boundary.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 截图
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.generateImageFailed);
          return;
        }

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        await _copyImageToClipboard(pngBytes);
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.fullConversationScreenshotCopied);

        print('成功完成优化的对话截图');
      } finally {
        // 确保移除overlay
        overlayEntry?.remove();
      }
    } catch (e) {
      print('优化的对话截图失败: $e');
      // 如果优化方案失败，回退到原有方案
      await _generateConversationImageFallback(context);
    }
  }

  // 回退方案：使用真实widget截图
  Future<void> _generateConversationImageFallback(BuildContext context) async {
    try {
      print('使用回退方案进行对话截图');

      // 强制滚动以确保所有消息都被渲染（快速版本）
      await _ensureAllMessagesRenderedQuick();

      await _generateMultiMessageImageFromKeys(
        context,
        widget.chatSession.messages,
        '整个对话',
      );
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed('整个对话', e.toString()));
    }
  }

  // 快速渲染所有消息（减少滚动次数）
  Future<void> _ensureAllMessagesRenderedQuick() async {
    if (!widget.scrollController.hasClients) return;

    final originalOffset = widget.scrollController.offset;

    try {
      // 只做必要的滚动
      widget.scrollController.jumpTo(0.0);
      await Future.delayed(const Duration(milliseconds: 150));

      widget.scrollController.jumpTo(
        widget.scrollController.position.maxScrollExtent,
      );
      await Future.delayed(const Duration(milliseconds: 150));
    } finally {
      // 快速恢复原位置
      try {
        widget.scrollController.jumpTo(originalOffset);
      } catch (e) {
        print('恢复滚动位置失败: $e');
      }
    }
  }

  // 截图：多条消息（使用真实widget）
  Future<void> _generateMultiMessageImageFromKeys(
    BuildContext context,
    List<ChatMessage> messages,
    String screenshotType,
  ) async {
    try {
      print('开始截图，总消息数: ${messages.length}');

      // 首先滚动到顶部，确保所有消息都被渲染
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(0.0);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 然后滚动到底部，确保所有消息都被渲染过
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        );
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 收集所有消息的渲染边界
      final List<RenderRepaintBoundary> boundaries = [];
      final List<String> missingMessages = [];

      for (final message in messages) {
        final messageKey = widget.messageKeys[message.msgId];
        if (messageKey != null && messageKey.currentContext != null) {
          final boundary =
              messageKey.currentContext?.findRenderObject()
                  as RenderRepaintBoundary?;
          if (boundary != null) {
            boundaries.add(boundary);
          } else {
            missingMessages.add(message.msgId);
          }
        } else {
          missingMessages.add(message.msgId);
        }
      }

      print('成功找到渲染边界数: ${boundaries.length}');
      print('缺失的消息数: ${missingMessages.length}');

      if (missingMessages.isNotEmpty) {
        print('缺失的消息ID: $missingMessages');
      }

      if (boundaries.isEmpty) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.cannotFindRenderObject);
        return;
      }

      // 如果缺失了一些消息，给用户提示
      if (boundaries.length < messages.length) {
        SnackBarUtils.showWarning(
          context,
          AppLocalizations.of(context)!.partialScreenshot(boundaries.length, messages.length),
        );
      }

      // 如果只有一条消息，直接截图
      if (boundaries.length == 1) {
        final boundary = boundaries.first;

        // 等待绘制完成
        if (boundary.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // 再次检查是否需要绘制
        if (boundary.debugNeedsPaint) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.renderObjectStillDrawing);
          return;
        }

        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          SnackBarUtils.showError(context, AppLocalizations.of(context)!.generateImageFailed);
          return;
        }

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        await _copyImageToClipboard(pngBytes);
        SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.screenshotCopied(screenshotType));
        return;
      }

      // 多条消息：按顺序合并截图
      await _combineMultipleScreenshotsInOrder(
        messages,
        boundaries,
        screenshotType,
      );
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.screenshotTypeFailed(screenshotType, e.toString()));
    }
  }

  // 按消息顺序合并多个截图
  Future<void> _combineMultipleScreenshotsInOrder(
    List<ChatMessage> messages,
    List<RenderRepaintBoundary> boundaries,
    String screenshotType,
  ) async {
    try {
      // 创建消息ID到边界的映射
      final Map<String, RenderRepaintBoundary> boundaryMap = {};
      int boundaryIndex = 0;

      for (final message in messages) {
        final messageKey = widget.messageKeys[message.msgId];
        if (messageKey != null && messageKey.currentContext != null) {
          final boundary =
              messageKey.currentContext?.findRenderObject()
                  as RenderRepaintBoundary?;
          if (boundary != null && boundaryIndex < boundaries.length) {
            boundaryMap[message.msgId] = boundary;
            boundaryIndex++;
          }
        }
      }

      // 等待所有边界完成绘制
      for (final boundary in boundaryMap.values) {
        if (boundary.debugNeedsPaint) {
          await WidgetsBinding.instance.endOfFrame;
        }
      }

      // 再次检查并等待
      await Future.delayed(const Duration(milliseconds: 100));

      // 按消息顺序获取图片
      final List<ui.Image> images = [];
      for (final message in messages) {
        final boundary = boundaryMap[message.msgId];
        if (boundary != null) {
          // 再次检查是否需要绘制
          if (boundary.debugNeedsPaint) {
            print(
              'Warning: boundary still needs paint, skipping message ${message.msgId}',
            );
            continue;
          }
          try {
            final image = await boundary.toImage(pixelRatio: 2.0);
            images.add(image);
            print('成功截图消息: ${message.msgId}');
          } catch (e) {
            print(
              'Error capturing image from boundary for message ${message.msgId}: $e',
            );
            continue;
          }
        }
      }

      if (images.isEmpty) return;

      // 计算合并后的总高度和最大宽度
      int totalHeight = 0;
      int maxWidth = 0;
      for (final image in images) {
        totalHeight += image.height;
        if (image.width > maxWidth) {
          maxWidth = image.width;
        }
      }

      // 添加间距
      final spacing = 20; // 消息间间距
      totalHeight += (images.length - 1) * spacing;
      totalHeight += 40; // 上下边距
      maxWidth += 40; // 左右边距

      // 创建画布
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 绘制白色背景
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, maxWidth.toDouble(), totalHeight.toDouble()),
        backgroundPaint,
      );

      // 逐个绘制消息图片
      double currentY = 20; // 顶部边距
      for (final image in images) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          20,
          currentY,
          image.width.toDouble(),
          image.height.toDouble(),
        ); // 左边距20
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
        currentY += image.height + spacing;
      }

      // 生成最终图片
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(maxWidth, totalHeight);
      final byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        SnackBarUtils.showError(context, AppLocalizations.of(context)!.generateImageFailed);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      await _copyImageToClipboard(pngBytes);
      SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.screenshotCopied(screenshotType));
    } catch (e) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.mergeScreenshotFailed(e.toString()));
      print(AppLocalizations.of(context)!.mergeScreenshotFailed(e.toString())); // 打印错误信息以便调试
    }
  }

  // 复制图片到剪贴板
  Future<void> _copyImageToClipboard(Uint8List imageBytes) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // 移动端使用base64格式
        final String base64String = base64Encode(imageBytes);
        await Clipboard.setData(ClipboardData(text: base64String));
      } else {
        // 桌面端直接复制图片文件
        await _copyImageToClipboardDesktop(imageBytes);
      }
    } catch (e) {
      throw Exception(AppLocalizations.of(context)!.copyImageFailed(e.toString()));
    }
  }

  // 桌面平台复制图片到剪贴板
  Future<void> _copyImageToClipboardDesktop(Uint8List imageBytes) async {
    try {
      final now = DateTime.now();
      final timeStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'screenshot_$timeStr.png';

      final String? workDir = widget.chatSession.workDirectory;

      String imagePath;
      bool isPersistent = false;

      if (workDir != null && workDir.trim().isNotEmpty) {
        // 保存到工作目录下的"会话截图"文件夹，不自动删除
        final trimmed = workDir.trim();
        final screenshotDir = Directory('$trimmed/会话截图');
        if (!await screenshotDir.exists()) {
          await screenshotDir.create(recursive: true);
        }
        imagePath = '${screenshotDir.path}/$fileName';
        isPersistent = true;
      } else {
        // 无工作目录时使用系统临时目录
        final tempDir = await getTemporaryDirectory();
        if (!await tempDir.exists()) {
          await tempDir.create(recursive: true);
        }
        imagePath = '${tempDir.path}/$fileName';
      }

      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      if (Platform.isWindows) {
        await _copyImageToClipboardWindows(imagePath);
      } else if (Platform.isMacOS) {
        await _copyImageToClipboardMacOS(imagePath);
      } else if (Platform.isLinux) {
        await _copyImageToClipboardLinux(imagePath);
      } else {
        throw UnsupportedError(AppLocalizations.of(context)!.unsupportedOS);
      }

      // 仅临时文件延迟删除，保存到工作目录的截图保留
      if (!isPersistent) {
        Future.delayed(const Duration(seconds: 5), () {
          try {
            if (imageFile.existsSync()) {
              imageFile.deleteSync();
            }
          } catch (e) {
            // 忽略删除错误
          }
        });
      }
    } catch (e) {
      throw Exception(AppLocalizations.of(context)!.desktopCopyFailed(e.toString()));
    }
  }

  Future<void> _copyImageToClipboardWindows(String imagePath) async {
    final result = await Process.run('powershell', [
      '-Command',
      'Add-Type -AssemblyName System.Windows.Forms; '
          '[System.Windows.Forms.Clipboard]::SetImage('
          '[System.Drawing.Image]::FromFile("$imagePath"))',
    ]);
    if (result.exitCode != 0) {
      throw Exception('PowerShell command failed: ${result.stderr}');
    }
  }

  Future<void> _copyImageToClipboardMacOS(String imagePath) async {
    final result = await Process.run('osascript', [
      '-e',
      'set the clipboard to (read (POSIX file "$imagePath") as «class PNGf»)',
    ]);
    if (result.exitCode != 0) {
      throw Exception('osascript command failed: ${result.stderr}');
    }
  }

  Future<void> _copyImageToClipboardLinux(String imagePath) async {
    try {
      final xclipResult = await Process.run('xclip', [
        '-selection',
        'clipboard',
        '-t',
        'image/png',
        '-i',
        imagePath,
      ]);
      if (xclipResult.exitCode == 0) return;
    } catch (e) {
      // xclip 不可用，尝试 wl-copy
    }

    try {
      final process = await Process.start('wl-copy', ['--type', 'image/png']);
      final imageBytes = await File(imagePath).readAsBytes();
      process.stdin.add(imageBytes);
      await process.stdin.close();
      final exitCode = await process.exitCode;
      if (exitCode == 0) return;
    } catch (e) {
      // wl-copy 也不可用
    }

    throw Exception(AppLocalizations.of(context)!.noClipboardTool);
  }

  @override
  Widget build(BuildContext context) {
    return widget.chatSession.messages.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Icon(
                  CupertinoIcons.captions_bubble,
                  size: 80,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        )
        : ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          padding: ResponsiveUtils.getPagePadding(context),
          itemCount: widget.chatSession.messages.length,
          itemBuilder: (context, idx) {
            final reversedIdx = widget.chatSession.messages.length - 1 - idx;
            final msg = widget.chatSession.messages[reversedIdx];
            if (!widget.messageKeys.containsKey(msg.msgId)) {
              widget.messageKeys[msg.msgId] = GlobalKey();
            }
            Widget messageWidget;
            if (msg.role == MessageRole.user) {
              messageWidget = UserMessageWidget(
                message: msg,
                onUpdate: () {
                  setState(() {});
                },
                onCaptureMessage: handleCaptureMessageImage,
                onCaptureRound: handleCaptureRoundImage,
                onCaptureConversation: handleCaptureConversationImage,
              );
            } else {
              messageWidget = AiMessageWidget(
                message: msg,
                onUpdate: () {
                  setState(() {});
                },
                onCaptureMessage: handleCaptureMessageImage,
                onCaptureRound: handleCaptureRoundImage,
                onCaptureConversation: handleCaptureConversationImage,
              );
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 1),
              child: RepaintBoundary(
                key: widget.messageKeys[msg.msgId],
                child: messageWidget,
              ),
            );
          },
        );
  }
}
