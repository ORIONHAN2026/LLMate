import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/features/utils/snackbar_utils.dart';
import 'package:llmate/features/utils/responsive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:llmate/controllers/session_controller.dart';
import 'package:llmate/models/chat/session.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ignore: must_be_immutable
class ModelSelector extends StatefulWidget {
  ChatSession? currentSession;
  final List<dynamic> availableModels;
  final Key? selectorKey;

  ModelSelector({
    super.key,
    required this.availableModels,
    this.currentSession,
    this.selectorKey,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  final sessionController = Get.find<SessionController>();

  /// 优先使用 SessionController 中的实时会话，保证右侧边栏模型设置
  /// （智能选模/手动模型/绑定模型）更新后，顶部选择器同步刷新。
  ChatSession? get _liveSession =>
      sessionController.currentSession.value ?? widget.currentSession;

  // 检查是否有有效的模型配置
  bool _hasValidModel() {
    final chatModel = _liveSession?.chatModel;
    return chatModel?.name != null && chatModel!.name.isNotEmpty;
  }

  // 获取显示的模型名称
  String _getDisplayModelName() {
    final chatModel = _liveSession?.chatModel;
    if (chatModel?.name != null && chatModel!.name.isNotEmpty) {
      return chatModel.name;
    }
    return AppLocalizations.of(context)!.pleaseSetupModel;
  }

  // 获取显示的模型详情（反映实际生效的模型）
  String _getDisplayModelDetail() {
    final session = _liveSession;
    final chatModel = session?.chatModel;
    if (chatModel != null && chatModel.model.isNotEmpty) {
      final platform = chatModel.platform ?? 'Unknown';
      // 智能选模开启：自动在轻量/高能力模型间路由
      if (session?.autoSelectModel == true) {
        return "$platform/${AppLocalizations.of(context)!.autoSelectModel}";
      }
      // 手动选择过具体模型：优先显示会话选定模型
      final selected = session?.model;
      final modelId =
          (selected != null && selected.isNotEmpty)
              ? selected
              : chatModel.model;
      final prompt = chatModel.systemPrompt ?? '';
      if (prompt.isNotEmpty) {
        return "$platform/$modelId | $prompt ";
      }

      return "$platform/$modelId";
    }
    return AppLocalizations.of(context)!.clickToSelectModel;
  }

  void _showModelSelectorPopup(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (isMobile) {
      // 移动端使用底部弹出框
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 拖拽指示器
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.selectModel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // 模型列表
                  Expanded(
                    child:
                        widget.availableModels.isEmpty
                            ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.noAvailableModels,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: widget.availableModels.length,
                              itemBuilder: (context, index) {
                                final model = widget.availableModels[index];
                                final isSelected =
                                    model.modelId ==
                                    widget.currentSession?.chatModel?.modelId;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  leading: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: model.buildIconWidget(isSelected),
                                  ),
                                  title: Text(
                                    model.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${model.platform ?? 'Unknown'}/${model.model}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (model.systemPrompt != null &&
                                          model.systemPrompt!.isNotEmpty)
                                        Text(
                                          model.systemPrompt!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  trailing:
                                      isSelected
                                          ? Icon(
                                            CupertinoIcons
                                                .checkmark_circle_fill,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                          )
                                          : null,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _selectModel(model);
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
      );
      return;
    }

    // 桌面端使用原有的菜单
    final RenderBox? button =
        widget.selectorKey != null && widget.selectorKey is GlobalKey
            ? (widget.selectorKey as GlobalKey).currentContext
                    ?.findRenderObject()
                as RenderBox?
            : null;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    RelativeRect position;
    if (button != null) {
      final Offset buttonPosition = button.localToGlobal(
        Offset.zero,
        ancestor: overlay,
      );
      // 直接使用按钮左下角作为锚点，宽高设为0，让菜单以 left/top 为起点展开
      position = RelativeRect.fromRect(
        Rect.fromLTWH(
          buttonPosition.dx, // 与触发按钮左边缘对齐
          buttonPosition.dy + button.size.height, // 紧贴按钮下方
          0,
          0,
        ),
        Offset.zero & overlay.size,
      );
    } else {
      // fallback：靠页面左上角一个合理偏移
      position = RelativeRect.fromLTRB(24, 60, 0, 0);
    }

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      constraints: BoxConstraints(
        minWidth: 280,
        maxWidth: screenWidth < 420 ? screenWidth - 32 : 320,
        maxHeight: 360,
      ),
      items: <PopupMenuEntry<dynamic>>[
        const PopupMenuDivider(height: 1),
        if (widget.availableModels.isEmpty)
          PopupMenuItem<dynamic>(
            enabled: false,
            height: 80,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.noAvailableModels,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...widget.availableModels.map<PopupMenuEntry<dynamic>>((model) {
            final isSelected =
                model.modelId == _liveSession?.chatModel?.modelId;
            return PopupMenuItem<dynamic>(
              height: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 25,
                      height: 25,
                      margin: const EdgeInsets.only(right: 12),
                      child: model.buildIconWidget(isSelected),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            model.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${model.platform ?? 'Unknown'}/${model.model}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          model.systemPrompt != null &&
                                  model.systemPrompt!.isNotEmpty
                              ? Text(
                                "${model.systemPrompt ?? ''}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                              : const SizedBox(),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  ],
                ),
              ),
              onTap: () => _selectModel(model),
            );
          }),
      ],
    );
  }

  void _selectModel(dynamic model) {
    // 始终从控制器获取最新会话，widget.currentSession 可能因不在 GetX 内而过时
    final current = sessionController.currentSession.value;
    if (current == null) {
      SnackBarUtils.showWarning(
        context,
        AppLocalizations.of(context)!.sessionNotFoundCannotSelectModel,
      );
      return;
    }

    final updatedSession = current.copyWith(chatModel: model);
    sessionController.updateSession(updatedSession);
    setState(() {
      widget.currentSession = updatedSession;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final maxWidth =
        isMobile ? MediaQuery.of(context).size.width * 0.7 : double.infinity;

    // Obx：监听 SessionController.currentSession，右侧边栏模型设置更新后自动重建
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          key: widget.selectorKey,
          onTap: () => _showModelSelectorPopup(context),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _getDisplayModelName(),
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _hasValidModel()
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        if (!isMobile || _hasValidModel()) ...[
                          const SizedBox(height: 0),
                          Text(
                            _getDisplayModelDetail(),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  _hasValidModel()
                                      ? Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7)
                                      : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ],
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
}
