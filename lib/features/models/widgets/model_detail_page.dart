import 'package:llmwork/l10n/app_localizations.dart';
import 'package:llmwork/models/bigmodel/chat_model.dart';
import 'package:llmwork/models/chat/chat_setting.dart';
import 'package:llmwork/utils/snackbar_utils.dart';
import 'package:llmwork/features/models/widgets/model_config_tab.dart';
import 'package:llmwork/widgets/common/confirm_delete_dialog.dart';
import 'package:flutter/cupertino.dart';
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
    _systemPromptController.text =
        _currentModel.chatSettings?.systemPrompt ?? '';

    // 如果模型的语言需要标准化，更新模型
    final normalizedReplyLanguage = _currentModel.chatSettings?.replyLanguage;

    if (normalizedReplyLanguage != _currentModel.chatSettings?.replyLanguage) {
      final updatedChatSettings = (_currentModel.chatSettings ??
              ChatSettings(
                conversationName: '新对话',
                systemPrompt: '',
                temperature: 0.7,
                replyLanguage: 'auto',
              ))
          .copyWith(replyLanguage: normalizedReplyLanguage);
      _currentModel = _currentModel.copyWith(chatSettings: updatedChatSettings);
    }
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
              color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.selectOtherModelFromList,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 模型详情头部
        _buildModelHeader(),
        const SizedBox(height: 12),
        // 模型配置内容
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
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
        ),
      ],
    );
  }

  Widget _buildModelHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 模型图标和信息
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentModel.name.isNotEmpty ? _currentModel.name : AppLocalizations.of(context)!.unnamedModel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentModel.platform ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // 操作按钮
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // 删除模型
                  _showDeleteConfirmation();
                },
                icon: const Icon(CupertinoIcons.trash, size: 10),
                label: Text(AppLocalizations.of(context)!.delete),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(50, 28),
                  textStyle: const TextStyle(fontSize: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
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
      icon: CupertinoIcons.exclamationmark_triangle,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      // 设置删除状态
      setState(() {
        _isModelDeleted = true;
      });
      // 调用删除回调
      if (widget.onModelDeleted != null) {
        widget.onModelDeleted!(_currentModel.modelId);
      }
      // 显示删除成功提示
      SnackBarUtils.showSuccess(context, loc.modelDeletedToast(_currentModel.name));
    }
  }
}
