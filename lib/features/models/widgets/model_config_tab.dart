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
    _systemPromptController.text = _currentModel.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _buildSection(
            title: loc.basicInfo,
            icon: Icons.info_outline,
            child: _buildBasicInfoTab(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: loc.modelParams,
            icon: Icons.tune,
            child: _buildModelParamsTab(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: loc.securitySettings,
            icon: Icons.security_outlined,
            child: _buildSecurityTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableModelNameItem(),
        const SizedBox(height: 10),
        _buildAvailableModelsItem(),
        const SizedBox(height: 10),
        _buildConfigItem(
          AppLocalizations.of(context)!.platformLabel,
          _currentModel.platform ?? AppLocalizations.of(context)!.unknown,
        ),
        const SizedBox(height: 10),
        _buildConfigItem(
          AppLocalizations.of(context)!.apiAddress,
          _currentModel.apiUrl ?? widget.apiUrl,
        ),
      ],
    );
  }

  Widget _buildModelParamsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTemperatureSlider(),
        const SizedBox(height: 14),
        _buildSystemPromptField(),
      ],
    );
  }

  // ========== 安全设置 Tab（敏感信息脱敏开关） ==========
  Widget _buildSecurityTab() {
    final loc = AppLocalizations.of(context)!;
    final maskPhone = _currentModel.maskPhone;
    final maskIdCard = _currentModel.maskIdCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.sensitiveInfoMasking,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          loc.sensitiveInfoMaskingDesc,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.56),
          ),
        ),
        const SizedBox(height: 14),
        _buildSecuritySwitch(
          title: loc.maskPhoneTitle,
          subtitle: loc.maskPhoneSubtitle,
          value: maskPhone,
          onChanged: (v) => _updateSecuritySetting(maskPhone: v),
        ),
        const SizedBox(height: 10),
        _buildSecuritySwitch(
          title: loc.maskIdCardTitle,
          subtitle: loc.maskIdCardSubtitle,
          value: maskIdCard,
          onChanged: (v) => _updateSecuritySetting(maskIdCard: v),
        ),
      ],
    );
  }

  Widget _buildSecuritySwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.82),
                letterSpacing: 0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              loc.modelLabel,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
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
                                fontSize: 12,
                                fontWeight:
                                    isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              AppLocalizations.of(context)!.nameLabel,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
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
                        filled: true,
                        fillColor: scheme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: scheme.onSurface),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface,
                        letterSpacing: 0,
                      ),
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
                          constraints: const BoxConstraints(minHeight: 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  _isHoveringModelName
                                      ? scheme.onSurface.withValues(alpha: 0.26)
                                      : Colors.transparent,
                              width: 1,
                            ),
                            color:
                                _isHoveringModelName
                                    ? scheme.onSurface.withValues(alpha: 0.04)
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
                                    fontSize: 13,
                                    color:
                                        _currentModel.name.isNotEmpty
                                            ? scheme.onSurface.withValues(
                                              alpha: 0.82,
                                            )
                                            : scheme.onSurface.withValues(
                                              alpha: 0.5,
                                            ),
                                    letterSpacing: 0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Tooltip(
                                message:
                                    AppLocalizations.of(
                                      context,
                                    )!.notSetDoubleClickToEdit,
                                child: IconButton(
                                  onPressed: _startEditModelName,
                                  icon: const Icon(Icons.edit),
                                  iconSize: 14,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 28,
                                    height: 28,
                                  ),
                                  color:
                                      _isHoveringModelName
                                          ? scheme.onSurface.withValues(
                                            alpha: 0.7,
                                          )
                                          : scheme.onSurface.withValues(
                                            alpha: 0.38,
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.temperatureLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${(_currentModel.temperature ?? 1.0).toStringAsFixed(1)} (${_getTemperatureLabel(_currentModel.temperature ?? 1.0)})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: scheme.onSurface,
            inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.7),
            thumbColor: scheme.onSurface,
            overlayColor: scheme.onSurface.withValues(alpha: 0.08),
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
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.neutral,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.creative,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.5),
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
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.56),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.modelRoleSetting,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _systemPromptController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.roleDescHint,
            hintStyle: const TextStyle(fontSize: 12),
            filled: true,
            fillColor: scheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.onSurface),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface,
            letterSpacing: 0,
          ),
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
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }
}
