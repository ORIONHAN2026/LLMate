import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:llmwork/l10n/app_localizations.dart';
import 'package:llmwork/models/bigmodel/chat_model.dart';
import 'package:llmwork/utils/snackbar_utils.dart';
import 'package:llmwork/models/chat/chat_setting.dart';

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
  bool _isEditingModelName = false;
  bool _isHoveringModelName = false; // 新增：鼠标悬停状态
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
            _buildConfigItem(AppLocalizations.of(context)!.modelLabel, _currentModel.model),
            _buildConfigItem(AppLocalizations.of(context)!.platformLabel, _currentModel.platform ?? AppLocalizations.of(context)!.unknown),
            _buildConfigItem(AppLocalizations.of(context)!.apiAddress, _currentModel.apiUrl ?? widget.apiUrl),
          ]),
          const SizedBox(height: 12),
          _buildConfigCard('计费设置', CupertinoIcons.money_dollar_circle, [
            _buildCurrencySelector(),
            const SizedBox(height: 12),
            _buildPromptPriceField(),
            const SizedBox(height: 12),
            _buildCompletionPriceField(),
            const SizedBox(height: 8),
            Text(
              _buildPriceUnitDesc(),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ]),
          const SizedBox(height: 12),
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
              '${(_currentModel.chatSettings?.temperature ?? 1.0).toStringAsFixed(1)} (${_getTemperatureLabel(_currentModel.chatSettings?.temperature ?? 1.0)})',
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
            value: _currentModel.chatSettings?.temperature ?? 1.0,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                final updatedChatSettings = (_currentModel.chatSettings ??
                        ChatSettings(
                          conversationName: '新对话',
                          systemPrompt: '',
                          temperature: 1.0,
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

  /// 根据温度值返回对应标签
  String _getTemperatureLabel(double temperature) {
    if (temperature <= 0.1) return '精准';
    if (temperature <= 0.5) return '保守';
    if (temperature <= 1.1) return '中性';
    if (temperature <= 1.5) return '创造';
    return '随机';
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
                        temperature: 1.0,
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
              temperature: 1.0,
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

  /// 获取当前价格单位描述
  String _buildPriceUnitDesc() {
    final unitText = _currentModel.currency == 'CNY' ? '元' : '美元';
    return '价格单位：$unitText/百万Token。用于计算会话累计费用。';
  }

  Widget _buildCurrencySelector() {
    final isCNY = _currentModel.currency == 'CNY';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '货币类型',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildCurrencyChip('人民币', '¥', isCNY, () {
              setState(() {
                _currentModel = _currentModel.copyWith(currency: 'CNY');
              });
              widget.onModelUpdated(_currentModel);
            }),
            const SizedBox(width: 8),
            _buildCurrencyChip('美元', '\$', !isCNY, () {
              setState(() {
                _currentModel = _currentModel.copyWith(currency: 'USD');
              });
              widget.onModelUpdated(_currentModel);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyChip(
      String label, String symbol, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCurrencyUnitText() => _currentModel.currency == 'CNY' ? '元/百万Token' : '美元/百万Token';

  Widget _buildPromptPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '输入价格',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              _buildCurrencyUnitText(),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(
            text: _currentModel.promptPrice?.toString() ?? '',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '例如: 0.14',
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
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 1), () {
              final price = double.tryParse(value);
              setState(() {
                _currentModel = _currentModel.copyWith(promptPrice: price);
              });
              widget.onModelUpdated(_currentModel);
            });
          },
        ),
      ],
    );
  }

  Widget _buildCompletionPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '输出价格',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              _buildCurrencyUnitText(),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(
            text: _currentModel.completionPrice?.toString() ?? '',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '例如: 0.28',
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
            isDense: true,
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 1), () {
              final price = double.tryParse(value);
              setState(() {
                _currentModel = _currentModel.copyWith(completionPrice: price);
              });
              widget.onModelUpdated(_currentModel);
            });
          },
        ),
      ],
    );
  }
}
