import 'dart:async';
import 'package:flutter/material.dart';
import 'package:llmate/l10n/app_localizations.dart';
import 'package:llmate/models/bigmodel/chat_model.dart';
import 'package:llmate/models/chat/mcp_config.dart';
import 'package:llmate/utils/snackbar_utils.dart';
import 'package:llmate/models/chat/chat_setting.dart';
import 'package:llmate/controllers/mcp_controller.dart';

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

  // MCP 相关
  List<String> _selectedMcpNames = [];
  List<Mcp> _selectedMcpServers = [];
  List<Mcp> _mcpServices = [];

  McpController get _mcpController => McpController.instance;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
    _systemPromptController = TextEditingController();
    _tabController = TabController(length: 5, vsync: this);
    _selectedMcpNames = List<String>.from(_currentModel.mcps ?? []);
    _initializeData();
    _loadMcpServices();
  }

  Future<void> _loadMcpServices() async {
    await _mcpController.ensureLoaded();
    if (mounted) {
      setState(() {
        _mcpServices = List<Mcp>.from(_mcpController.configs);
        // 解析已绑定的 MCP 信息
        _selectedMcpServers = _selectedMcpNames
            .map((n) => _mcpController.getMcp(n))
            .whereType<Mcp>()
            .toList();
      });
    }
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
      _selectedMcpNames = List<String>.from(_currentModel.mcps ?? []);
      _initializeData();
    }
  }

  void _initializeData() {
    _systemPromptController.text =
        _currentModel.chatSettings?.systemPrompt ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: loc.basicInfo, icon: const Icon(Icons.info_outline, size: 16)),
            Tab(text: loc.billingSettings, icon: const Icon(Icons.monetization_on_outlined, size: 16)),
            Tab(text: loc.modelParams, icon: const Icon(Icons.tune, size: 16)),
            Tab(text: loc.mcpSettings, icon: const Icon(Icons.grid_view, size: 16)),
            Tab(text: '安全设置', icon: const Icon(Icons.security, size: 16)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: 基本信息
              _buildBasicInfoTab(),
              // Tab 2: 计费设置
              _buildBillingTab(),
              // Tab 3: 模型参数
              _buildModelParamsTab(),
              // Tab 4: MCP 设置
              _buildMcpSettingsTab(),
              // Tab 5: 安全设置（敏感信息脱敏）
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
          _buildConfigItem(AppLocalizations.of(context)!.modelLabel, _currentModel.model),
          const SizedBox(height: 8),
          _buildConfigItem(AppLocalizations.of(context)!.platformLabel, _currentModel.platform ?? AppLocalizations.of(context)!.unknown),
          const SizedBox(height: 8),
          _buildConfigItem(AppLocalizations.of(context)!.apiAddress, _currentModel.apiUrl ?? widget.apiUrl),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  // 注：本 Tab 文案使用中文硬编码，未接入 gen-l10n，避免改动多语言资源文件。
  Widget _buildSecurityTab() {
    final settings = _currentModel.chatSettings;
    final maskPhone = settings?.maskPhone ?? false;
    final maskIdCard = settings?.maskIdCard ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '敏感信息脱敏',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '开启后，发送给大模型的消息及本地审计日志中的对应信息将被 * 号替换，防止明文隐私泄露。',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildSecuritySwitch(
            title: '手机号脱敏',
            subtitle: '将消息中的手机号替换为 * 号',
            value: maskPhone,
            onChanged: (v) => _updateSecuritySetting(maskPhone: v),
          ),
          const SizedBox(height: 8),
          _buildSecuritySwitch(
            title: '身份证号脱敏',
            subtitle: '将消息中的身份证号替换为 * 号',
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        value: value,
        onChanged: onChanged,
        dense: true,
      ),
    );
  }

  void _updateSecuritySetting({bool? maskPhone, bool? maskIdCard}) {
    final updatedChatSettings = (_currentModel.chatSettings ??
            ChatSettings(
              conversationName: AppLocalizations.of(context)!.newConversationDefault,
              systemPrompt: '',
              temperature: 1.0,
              replyLanguage: '',
            ))
        .copyWith(maskPhone: maskPhone, maskIdCard: maskIdCard);
    setState(() {
      _currentModel = _currentModel.copyWith(chatSettings: updatedChatSettings);
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
                            conversationName: AppLocalizations.of(context)!.newConversationDefault,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        conversationName: AppLocalizations.of(context)!.newConversationDefault,
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

  /// 获取当前价格单位描述
  String _buildPriceUnitDesc() {
    final loc = AppLocalizations.of(context)!;
    final unitText = _currentModel.currency == 'CNY' ? loc.cny : loc.usd;
    return loc.priceUnitDescription(unitText);
  }

  Widget _buildCurrencySelector() {
    final isCNY = _currentModel.currency == 'CNY';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.currencyTypeLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildCurrencyChip(AppLocalizations.of(context)!.cny, '¥', isCNY, () {
              setState(() {
                _currentModel = _currentModel.copyWith(currency: 'CNY');
              });
              widget.onModelUpdated(_currentModel);
            }),
            const SizedBox(width: 8),
            _buildCurrencyChip(AppLocalizations.of(context)!.usd, '\$', !isCNY, () {
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

  String _buildCurrencyUnitText() {
    final loc = AppLocalizations.of(context)!;
    final unitText = _currentModel.currency == 'CNY' ? loc.cny : loc.usd;
    return loc.pricePerMillionTokens(unitText);
  }

  Widget _buildPromptPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.inputPriceLabel,
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
            hintText: AppLocalizations.of(context)!.examplePriceHint,
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
              AppLocalizations.of(context)!.outputPriceLabel,
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
            hintText: AppLocalizations.of(context)!.examplePriceHint,
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

  // ========== MCP 设置 Tab ==========

  Widget _buildMcpSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明文字
          Text(
            AppLocalizations.of(context)!.mcpBindingDescription,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),

          // MCP 服务选择按钮
          OutlinedButton.icon(
            onPressed: _showMcpSelectionDialog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              AppLocalizations.of(context)!.addMcpServiceButton,
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),

          if (_selectedMcpNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 全部取消绑定按钮
            TextButton.icon(
              onPressed: _clearMcpBinding,
              icon: const Icon(Icons.link_off, size: 14),
              label: Text(AppLocalizations.of(context)!.clearAllMcpBindings, style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],

          // 已绑定 MCP 的详情卡片
          if (_selectedMcpServers.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._selectedMcpServers.map((mcp) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildMcpInfoCard(mcp),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMcpInfoCard(Mcp mcp) {
    final toolCount = mcp.tools?.length ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mcp.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _toggleMcpBinding(mcp.name),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 14,
              ),
            ],
          ),
          if (mcp.description != null && mcp.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              mcp.description!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              _buildInfoChip(Icons.build, AppLocalizations.of(context)!.xToolsCount(toolCount)),
              if (mcp.url != null && mcp.url!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _buildInfoChip(Icons.link, mcp.url!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showMcpSelectionDialog() {
    // local snapshot for dialog
    final dialogSelected = List<String>.from(_selectedMcpNames);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.toLowerCase();
            final filtered = _mcpServices.where((s) {
              if (query.isEmpty) return true;
              return s.name.toLowerCase().contains(query) ||
                  (s.description?.toLowerCase().contains(query) ?? false);
            }).toList();

            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(AppLocalizations.of(context)!.selectMcpServiceMultiSelect, style: const TextStyle(fontSize: 15)),
              content: SizedBox(
                width: 350,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchMcp,
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                _mcpServices.isEmpty ? AppLocalizations.of(context)!.noMcpServiceAddFirst : AppLocalizations.of(context)!.noMatchingResults,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final service = filtered[index];
                                final isSelected = dialogSelected.contains(service.name);
                                return CheckboxListTile(
                                  dense: true,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        if (!dialogSelected.contains(service.name)) {
                                          dialogSelected.add(service.name);
                                        }
                                      } else {
                                        dialogSelected.remove(service.name);
                                      }
                                    });
                                  },
                                  title: Text(service.name,
                                      style: const TextStyle(fontSize: 13)),
                                  subtitle: service.description?.isNotEmpty == true
                                      ? Text(service.description!,
                                          style: const TextStyle(fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis)
                                      : null,
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
                  child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _applyMcpSelection(dialogSelected);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.confirmWithCount(dialogSelected.length),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleMcpBinding(String mcpName) {
    final newList = List<String>.from(_selectedMcpNames);
    newList.remove(mcpName);
    _applyMcpSelection(newList);
  }

  void _applyMcpSelection(List<String> selectedNames) {
    final servers = selectedNames
        .map((n) => _mcpController.getMcp(n))
        .whereType<Mcp>()
        .toList();

    setState(() {
      _selectedMcpNames = List<String>.from(selectedNames);
      _selectedMcpServers = servers;
    });

    // persist to model
    final updatedModel = _currentModel.copyWith(
      mcps: selectedNames.isEmpty ? null : selectedNames,
      mcpServers: servers.isEmpty ? null : servers,
      clearMcp: selectedNames.isEmpty,
    );
    _currentModel = updatedModel;
    widget.onModelUpdated(updatedModel);
  }

  void _clearMcpBinding() {
    _applyMcpSelection([]);
  }
}
