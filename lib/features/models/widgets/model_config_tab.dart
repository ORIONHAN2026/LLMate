import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/models/model.dart';
import 'package:llmate/features/utils/snackbar_utils.dart';

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

class _ModelConfigTabState extends State<ModelConfigTab>
    with SingleTickerProviderStateMixin {
  late ChatModel _currentModel;
  bool _isEditingModelName = false;
  bool _isHoveringModelName = false; // 新增：鼠标悬停状态
  late TextEditingController _apiKeyController;
  late TextEditingController _modelNameController;
  late TextEditingController _systemPromptController;
  Timer? _debounceTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
    _systemPromptController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _systemPromptController.dispose();
    _tabController.dispose();
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
    _systemPromptController.text = _currentModel.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
          indicatorColor: Theme.of(context).colorScheme.onSurface,
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: loc.basicInfo,
              icon: const Icon(Icons.info_outline, size: 16),
            ),
            Tab(text: loc.modelParams, icon: const Icon(Icons.tune, size: 16)),
            Tab(
              text: loc.securitySettings,
              icon: const Icon(Icons.security, size: 16),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: 基本信息
              _buildBasicInfoTab(),
              // Tab 2: 模型参数
              _buildModelParamsTab(),
              // Tab 3: 安全设置（敏感信息脱敏）
              _buildSecurityTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditableModelNameItem(),
          const SizedBox(height: 8),
          _buildAvailableModelsItem(),
          const SizedBox(height: 8),
          _buildConfigItem(
            AppLocalizations.of(context)!.platformLabel,
            _currentModel.platform ?? AppLocalizations.of(context)!.unknown,
          ),
          const SizedBox(height: 8),
          _buildConfigItem(
            AppLocalizations.of(context)!.apiAddress,
            _currentModel.apiUrl ?? widget.apiUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildModelParamsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTemperatureSlider(),
          const SizedBox(height: 12),
          _buildSystemPromptField(),
        ],
      ),
    );
  }

  // ========== 安全设置 Tab（敏感信息脱敏开关） ==========
  Widget _buildSecurityTab() {
    final loc = AppLocalizations.of(context)!;
    final maskPhone = _currentModel.maskPhone;
    final maskIdCard = _currentModel.maskIdCard;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.sensitiveInfoMasking,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.sensitiveInfoMaskingDesc,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildSecuritySwitch(
            title: loc.maskPhoneTitle,
            subtitle: loc.maskPhoneSubtitle,
            value: maskPhone,
            onChanged: (v) => _updateSecuritySetting(maskPhone: v),
          ),
          const SizedBox(height: 8),
          _buildSecuritySwitch(
            title: loc.maskIdCardTitle,
            subtitle: loc.maskIdCardSubtitle,
            value: maskIdCard,
            onChanged: (v) => _updateSecuritySetting(maskIdCard: v),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        value: value,
        onChanged: onChanged,
        dense: true,
      ),
    );
  }

  void _updateSecuritySetting({bool? maskPhone, bool? maskIdCard}) {
    setState(() {
      _currentModel = _currentModel.copyWith(
        maskPhone: maskPhone,
        maskIdCard: maskIdCard,
      );
    });
    widget.onModelUpdated(_currentModel);
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 可用模型列表：以标签样式展示当前模型与可用模型，不支持选择。
  /// 无可用模型（availableModels 为空）时退化为只读文本显示。
  Widget _buildAvailableModelsItem() {
    final loc = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final options =
        <String>{
          if (_currentModel.model.isNotEmpty) _currentModel.model,
          ..._currentModel.availableModels,
        }.toList();

    // 没有可用模型列表时，保持原有只读展示
    if (options.isEmpty) {
      return _buildConfigItem(loc.modelLabel, _currentModel.model);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${loc.modelLabel}:',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chipMaxWidth =
                    constraints.maxWidth.isFinite
                        ? constraints.maxWidth.clamp(120.0, 260.0)
                        : 260.0;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      options.map((m) {
                        final isCurrent = m == _currentModel.model;
                        return ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: chipMaxWidth),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isCurrent
                                      ? scheme.primary.withValues(alpha: 0.12)
                                      : scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    isCurrent
                                        ? scheme.primary.withValues(alpha: 0.5)
                                        : scheme.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                              ),
                            ),
                            child: Text(
                              m,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isCurrent
                                        ? scheme.primary
                                        : scheme.onSurface.withValues(
                                          alpha: 0.75,
                                        ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                                      ? Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.3)
                                      : Colors.transparent,
                              width: 1,
                            ),
                            color:
                                _isHoveringModelName
                                    ? Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.05)
                                    : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _currentModel.name.isNotEmpty
                                      ? _currentModel.name
                                      : AppLocalizations.of(
                                        context,
                                      )!.notSetDoubleClickToEdit,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        _currentModel.name.isNotEmpty
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
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
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.4),
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
      SnackBarUtils.showError(
        context,
        AppLocalizations.of(context)!.modelNameCannotBeEmpty,
      );
      return;
    }

    setState(() {
      _currentModel = _currentModel.copyWith(name: newModelName);
      _isEditingModelName = false;
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(
      context,
      AppLocalizations.of(context)!.modelNameSaved,
    );
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              '${(_currentModel.temperature ?? 1.0).toStringAsFixed(1)} (${_getTemperatureLabel(_currentModel.temperature ?? 1.0)})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.onSurface,
            inactiveTrackColor: Theme.of(context).dividerColor,
            thumbColor: Theme.of(context).colorScheme.onSurface,
            overlayColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: _currentModel.temperature ?? 1.0,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _currentModel = _currentModel.copyWith(temperature: value);
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
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.neutral,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.creative,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// 根据温度值返回对应标签
  String _getTemperatureLabel(double temperature) {
    final loc = AppLocalizations.of(context)!;
    if (temperature <= 0.1) return loc.temperaturePrecise;
    if (temperature <= 0.5) return loc.temperatureConservative;
    if (temperature <= 1.1) return loc.temperatureNeutral;
    if (temperature <= 1.5) return loc.temperatureCreative;
    return loc.temperatureRandom;
  }

  Widget _buildSystemPromptField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.modelRoleSetting,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            contentPadding: const EdgeInsets.all(10),
          ),
          style: const TextStyle(fontSize: 12),
          onChanged: (value) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(seconds: 1), () {
              setState(() {
                _currentModel = _currentModel.copyWith(systemPrompt: value);
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
