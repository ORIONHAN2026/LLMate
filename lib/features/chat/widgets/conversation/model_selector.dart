import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/features/utils/responsive_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final maxWidth =
        isMobile ? MediaQuery.of(context).size.width * 0.7 : double.infinity;

    // Obx：监听 SessionController.currentSession，右侧边栏模型设置更新后自动重建
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Container(
          key: widget.selectorKey,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _getDisplayModelName(),
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 13,
                            fontWeight: FontWeight.w600,
                            color:
                                _hasValidModel()
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (!isMobile && _hasValidModel()) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '/',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _getDisplayModelDetail(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.62),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
