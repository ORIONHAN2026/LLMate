import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/models/model.dart';
import 'package:llmate/features/utils/snackbar_utils.dart';
import 'package:llmate/features/models/widgets/model_config_tab.dart';
import 'package:llmate/features/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ModelDetailPage extends StatefulWidget {
  final ChatModel model;
  final String apiUrl;
  final Function(ChatModel) onModelUpdated; // 参数为 updatedModel
  final Function(String)? onModelDeleted; // 参数为 modelId

  const ModelDetailPage({
    super.key,
    required this.model,
    required this.apiUrl,
    required this.onModelUpdated,
    this.onModelDeleted,
  });

  @override
  State<ModelDetailPage> createState() => _ModelDetailPageState();
}

class _ModelDetailPageState extends State<ModelDetailPage> {
  late ChatModel _currentModel;
  bool _isModelDeleted = false; // 添加删除状态标记
  late TextEditingController _apiKeyController;
  late TextEditingController _modelNameController;
  late TextEditingController _systemPromptController;
  late TextEditingController _quickCommandController; // 快捷指令输入控制器
  Timer? _debounceTimer; // 防抖定时器

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
    _systemPromptController = TextEditingController();
    _quickCommandController = TextEditingController(); // 初始化快捷指令控制器
    _initializeData();
  }

  @override
  void didUpdateWidget(ModelDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      setState(() {
        _isModelDeleted = false; // 重置删除状态
      });
      _initializeData();
    }
  }

  void _initializeData() {
    _currentModel = widget.model;

    _apiKeyController.text = _currentModel.apiKey ?? '';
    _modelNameController.text = _currentModel.name;

    // 初始化系统提示词控制器
    _systemPromptController.text = _currentModel.systemPrompt ?? '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _systemPromptController.dispose();
    _quickCommandController.dispose(); // 释放快捷指令控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果模型已被删除，显示删除提示界面
    if (_isModelDeleted) {
      final loc = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 16),
            Text(
              loc.modelDeleted,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.modelDeletedSuccessfully(_currentModel.name),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.selectOtherModelFromList,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildModelHeader(),
          Expanded(
            child: ModelConfigTab(
              model: _currentModel,
              apiUrl: widget.apiUrl,
              onModelUpdated: (model) {
                setState(() {
                  _currentModel = model;
                });
                widget.onModelUpdated(model);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelHeader() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.36),
              ),
            ),
            child: Icon(
              Icons.memory_outlined,
              color: scheme.onSurface.withValues(alpha: 0.74),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentModel.name.isNotEmpty
                      ? _currentModel.name
                      : AppLocalizations.of(context)!.unnamedModel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentModel.platform != null &&
                          _currentModel.platform!.isNotEmpty
                      ? AppLocalizations.of(
                        context,
                      )!.modelDetailsWithPlatform(_currentModel.platform!)
                      : AppLocalizations.of(context)!.modelDetails,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.56),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(AppLocalizations.of(context)!.delete),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.error,
              side: BorderSide(
                color: scheme.error.withValues(alpha: 0.45),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              minimumSize: const Size(74, 40),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() async {
    final loc = AppLocalizations.of(context)!;
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: loc.confirmDeleteTitle,
      itemName: _currentModel.name,
      description: loc.confirmDeleteModel,
      warningMessage: loc.irreversibleAction,
      icon: Icons.warning_amber_rounded,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      if (!mounted) return;
      // 设置删除状态
      setState(() {
        _isModelDeleted = true;
      });
      // 调用删除回调
      if (widget.onModelDeleted != null) {
        widget.onModelDeleted!(_currentModel.modelId);
      }
      // 显示删除成功提示
      SnackBarUtils.showSuccess(
        context,
        loc.modelDeletedToast(_currentModel.name),
      );
    }
  }
}
