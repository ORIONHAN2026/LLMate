import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chathub/l10n/app_localizations.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/models/bigmodel/model_data.dart';
import 'package:chathub/models/chat/chat_setting.dart';

class ModelConfigTab extends StatefulWidget {
  final ChatModel model;
  final String apiUrl;
  final Function(ChatModel) onModelUpdated;

  const ModelConfigTab({
    super.key,
    required this.model,
    required this.apiUrl,
    required this.onModelUpdated,
  });

  @override
  State<ModelConfigTab> createState() => _ModelConfigTabState();
}

class _ModelConfigTabState extends State<ModelConfigTab> {
  late ChatModel _currentModel;
  bool _isEditingApiKey = false;
  bool _isApiKeyVisible = false;
  bool _isEditingModelName = false;
  bool _isHoveringModelName = false; // 新增：鼠标悬停状态
  bool _isHoveringApiKey = false; // 新增：API密钥鼠标悬停状态
  late TextEditingController _apiKeyController;
  late TextEditingController _modelNameController;
  late TextEditingController _systemPromptController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
    _systemPromptController = TextEditingController();
    _initializeData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModelConfigTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _currentModel = widget.model;
      _initializeData();
    }
  }

  void _initializeData() {
    _systemPromptController.text =
        _currentModel.chatSettings?.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigCard(AppLocalizations.of(context)!.basicInfo, CupertinoIcons.info, [
            _buildEditableModelNameItem(),
            _buildConfigItem(AppLocalizations.of(context)!.modelLabel, _currentModel.provider ?? AppLocalizations.of(context)!.unknown),

            _buildEditableModelItem(),
            _buildConfigItem(AppLocalizations.of(context)!.platformLabel, _currentModel.platform ?? AppLocalizations.of(context)!.unknown),

            _buildConfigItem(AppLocalizations.of(context)!.apiAddress, _currentModel.apiUrl ?? widget.apiUrl),
            // _buildConfigItem('模型ID', _currentModel.modelId),
          ]),
          const SizedBox(height: 12),
          // 模型参数卡片（从 ChatSettingsTab 移入）
          _buildConfigCard(AppLocalizations.of(context)!.modelParams, CupertinoIcons.slider_horizontal_3, [
            _buildTemperatureSlider(),
            const SizedBox(height: 12),
            _buildSystemPromptField(),
          ]),
        ],
      ),
    );
  }

  Widget _buildConfigCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${AppLocalizations.of(context)!.apiKeyLabel}:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child:
                _isEditingApiKey
                    ? TextField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.apiKeyHint,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                      obscureText: !_isApiKeyVisible,
                      style: const TextStyle(fontSize: 12),
                      autofocus: true,
                      onSubmitted: (value) => _saveApiKey(),
                      onTapOutside: (event) => _cancelEditApiKey(),
                    )
                    : MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isHoveringApiKey = true),
                      onExit: (_) => setState(() => _isHoveringApiKey = false),
                      child: GestureDetector(
                        onDoubleTap: _startEditApiKey,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  _isHoveringApiKey
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3)
                                      : Colors.transparent,
                              width: 1,
                            ),
                            color:
                                _isHoveringApiKey
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.05)
                                    : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    _currentModel.apiKey?.isNotEmpty == true
                                        ? (_isApiKeyVisible
                                            ? _currentModel.apiKey!
                                            : '••••••••')
                                        : AppLocalizations.of(context)!.notSetDoubleClickToEdit,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _currentModel.apiKey?.isNotEmpty ==
                                                  true
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              // 眼睛图标 - 切换密码可见性
                              if (_currentModel.apiKey?.isNotEmpty == true)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isApiKeyVisible = !_isApiKeyVisible;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _isApiKeyVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              // 编辑图标
                              GestureDetector(
                                onTap: _startEditApiKey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 12,
                                    color:
                                        _isHoveringApiKey
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.7)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableModelNameItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${AppLocalizations.of(context)!.nameLabel}:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child:
                _isEditingModelName
                    ? TextField(
                      controller: _modelNameController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.modelNameHint,
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      autofocus: true,
                      onSubmitted: (value) => _saveModelName(),
                      onTapOutside: (event) => _cancelEditModelName(),
                    )
                    : MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter:
                          (_) => setState(() => _isHoveringModelName = true),
                      onExit:
                          (_) => setState(() => _isHoveringModelName = false),
                      child: GestureDetector(
                        onDoubleTap: _startEditModelName,
                        child: Container(
                          width: double.infinity,
                          // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  _isHoveringModelName
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3)
                                      : Colors.transparent,
                              width: 1,
                            ),
                            color:
                                _isHoveringModelName
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.05)
                                    : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentModel.name.isNotEmpty
                                      ? _currentModel.name
                                      : AppLocalizations.of(context)!.notSetDoubleClickToEdit,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        _currentModel.name.isNotEmpty
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.5),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _startEditModelName,
                                child: Icon(
                                  Icons.edit,
                                  size: 12,
                                  color:
                                      _isHoveringModelName
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary.withOpacity(0.7)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableModelItem() {
    // 获取当前模型的显示名称
    String currentModelName = _getCurrentModelDisplayName();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${AppLocalizations.of(context)!.versionLabel}:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentModelName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showModelSelectionDialog,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取当前模型的显示名称
  String _getCurrentModelDisplayName() {
    String? currentProvider = _currentModel.provider;

    // 从供应商数据中查找当前模型的显示名称
    for (var provider in onlineProviders) {
      if (provider['id'] == currentProvider && provider['models'] != null) {
        for (var model in provider['models']) {
          if (model['id'] == _currentModel.model) {
            return model['name'] ?? _currentModel.model;
          }
        }
        break;
      }
    }

    // 如果没找到，返回原始模型ID
    return _currentModel.model.isNotEmpty ? _currentModel.model : AppLocalizations.of(context)!.notSet;
  }

  // 显示模型选择对话框
  void _showModelSelectionDialog() {
    // 获取当前模型的供应商
    String? currentProvider = _currentModel.provider;

    // 根据供应商筛选模型
    List<Map<String, dynamic>> availableModels = [];
    for (var provider in onlineProviders) {
      if (provider['id'] == currentProvider && provider['models'] != null) {
        for (var model in provider['models']) {
          availableModels.add({'id': model['id'], 'name': model['name']});
        }
        break;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.selectModel,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableModels.length,
              itemBuilder: (context, index) {
                final model = availableModels[index];
                final isSelected = model['id'] == _currentModel.model;

                return ListTile(
                  title: Text(
                    model['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _saveModel(model['id']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startEditApiKey() {
    setState(() {
      _isEditingApiKey = true;
      _isApiKeyVisible = true; // 进入编辑模式时默认显示明文
      _apiKeyController.text = _currentModel.apiKey ?? '';
    });
  }

  void _cancelEditApiKey() {
    setState(() {
      _isEditingApiKey = false;
      _apiKeyController.text = _currentModel.apiKey ?? '';
    });
  }

  void _saveApiKey() {
    final newApiKey = _apiKeyController.text.trim();
    setState(() {
      _currentModel = _currentModel.copyWith(apiKey: newApiKey);
      _isEditingApiKey = false;
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.apiKeySaved);
  }

  void _startEditModelName() {
    setState(() {
      _isEditingModelName = true;
      _modelNameController.text = _currentModel.name;
    });
  }

  void _cancelEditModelName() {
    setState(() {
      _isEditingModelName = false;
      _modelNameController.text = _currentModel.name;
    });
  }

  void _saveModelName() {
    final newModelName = _modelNameController.text.trim();
    if (newModelName.isEmpty) {
      SnackBarUtils.showError(context, AppLocalizations.of(context)!.modelNameCannotBeEmpty);
      return;
    }

    setState(() {
      _currentModel = _currentModel.copyWith(name: newModelName);
      _isEditingModelName = false;
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.modelNameSaved);
  }

  void _saveModel(String newModelId) {
    setState(() {
      _currentModel = _currentModel.copyWith(model: newModelId);
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(context, AppLocalizations.of(context)!.modelSaved);
  }

  // ========== 模型参数 (Temperature + System Prompt) ==========

  Widget _buildTemperatureSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.temperatureLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              (_currentModel.chatSettings?.temperature ?? 0.7).toStringAsFixed(
                1,
              ),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).dividerColor,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: _currentModel.chatSettings?.temperature ?? 0.7,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                final updatedChatSettings = (_currentModel.chatSettings ??
                        ChatSettings(
                          conversationName: '新对话',
                          systemPrompt: '',
                          temperature: 0.7,
                          replyLanguage: '',
                        ))
                    .copyWith(temperature: value);
                _currentModel = _currentModel.copyWith(
                  chatSettings: updatedChatSettings,
                );
              });
              widget.onModelUpdated(_currentModel);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.precise,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.neutral,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.creative,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.temperatureDescription,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.modelRoleSetting,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            GestureDetector(
              onTap: _showPresetRolesDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.presetRole,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.roleDescHint,
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 1), () {
              final updatedChatSettings = (_currentModel.chatSettings ??
                      ChatSettings(
                        conversationName: '新对话',
                        systemPrompt: '',
                        temperature: 0.7,
                        replyLanguage: '',
                      ))
                  .copyWith(systemPrompt: value);
              setState(() {
                _currentModel = _currentModel.copyWith(
                  chatSettings: updatedChatSettings,
                );
              });
              widget.onModelUpdated(_currentModel);
            });
          },
        ),
        const SizedBox(height: 3),
        Text(
          AppLocalizations.of(context)!.roleSettingDescription,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  List<Map<String, String>> _getPresetRoles() {
    final loc = AppLocalizations.of(context)!;
    return [
      {
        'name': loc.generalAssistant,
        'description': loc.friendlyAssistantDesc,
        'prompt': '你是一个友善、专业且乐于助人的AI助手。请用清晰、准确的语言回答用户的问题，并在适当时提供有用的建议和解释。',
      },
      {
        'name': loc.spellCheck,
        'description': loc.spellCheckDesc,
        'prompt': '你是一个经验丰富的文字编辑工作者，可以发现并纠正文章中的错别字以及相关语法问题。',
      },
      {
        'name': loc.codeExpert,
        'description': loc.codeExpertDesc,
        'prompt':
            '你是一个经验丰富的软件开发专家，精通多种编程语言和开发框架。请为用户提供高质量的代码解决方案，包括代码示例、最佳实践和技术建议。回答时要考虑代码的可读性、性能和安全性。',
      },
      {
        'name': loc.legalExpert,
        'description': loc.legalExpertDesc,
        'prompt':
            '你是一位经验丰富的法律专家，熟悉各种法律法规。请为用户提供专业的法律建议和解释，但请注意提醒用户这些建议仅供参考，具体法律问题应咨询专业律师。',
      },
      {
        'name': loc.copywriter,
        'description': loc.copywriterDesc,
        'prompt':
            '你是一位富有创意的文案写手，擅长创作各种类型的文案内容。请根据用户需求，创作引人入胜、表达清晰且符合目标受众的文案。注意语言的感染力和传播效果。',
      },
      {
        'name': loc.dataAnalyst,
        'description': loc.dataAnalystDesc,
        'prompt':
            '你是一位专业的数据分析师，精通统计学、数据挖掘和数据可视化。请为用户提供准确的数据分析、统计解释和可视化建议。用清晰的语言解释复杂的数据概念。',
      },
      {
        'name': loc.educationTutor,
        'description': loc.educationTutorDesc,
        'prompt':
            '你是一位耐心、专业的教育导师，擅长用简单易懂的方式解释复杂概念。请根据用户的学习水平，提供循序渐进的教学内容，并鼓励用户主动思考和提问。',
      },
      {
        'name': loc.businessConsultant,
        'description': loc.businessConsultantDesc,
        'prompt':
            '你是一位经验丰富的商业顾问，精通企业管理、市场营销和商业策略。请为用户提供实用的商业建议，包括市场分析、运营优化和战略规划等方面的专业见解。',
      },
      {
        'name': loc.psychologist,
        'description': loc.psychologistDesc,
        'prompt':
            '你是一位专业、温暖的心理咨询师，具备丰富的心理学知识。请以同理心倾听用户的困扰，提供支持性的建议和心理健康知识。但请提醒用户，严重的心理问题需要寻求专业心理医生的帮助。',
      },
    ];
  }

  void _showPresetRolesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Row(
            children: [
              Icon(
                Icons.psychology,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.selectPresetRole,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.separated(
              itemCount: _getPresetRoles().length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final role = _getPresetRoles()[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      role['name']![0],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    role['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      role['prompt']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _applyPresetRole(role['prompt']!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyPresetRole(String prompt) {
    _systemPromptController.text = prompt;

    final updatedChatSettings = (_currentModel.chatSettings ??
            ChatSettings(
              conversationName: '新对话',
              systemPrompt: '',
              temperature: 0.7,
              replyLanguage: '',
            ))
        .copyWith(systemPrompt: prompt);

    setState(() {
      _currentModel = _currentModel.copyWith(chatSettings: updatedChatSettings);
    });

    widget.onModelUpdated(_currentModel);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.presetRoleApplied),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
