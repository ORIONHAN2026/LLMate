import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/model.dart';
import '../../../models/model_catalog.dart';
import '../../../models/chat/session.dart';
import '../../../core/llm/common/openai_provider.dart';
import '../services/model_endpoint_builder.dart';
import '../view_models/model_connection_test_state.dart';

class AddOnlineModelDialog extends StatefulWidget {
  const AddOnlineModelDialog({super.key});

  @override
  State<AddOnlineModelDialog> createState() => _AddOnlineModelDialogState();
}

class _AddOnlineModelDialogState extends State<AddOnlineModelDialog> {
  int _currentStep = 0;
  String _selectedProvider = '';
  String _selectedOnlineModel = '';
  final Map<String, String> _selectedModelSizes = {}; // 改为 Map，为每个模型独立存储选中的规格
  String _customModelName = '';
  bool _isCustomProvider = false; // 是否使用自定义提供商（完全手动输入）

  // 智能选模相关状态
  List<String> _availableModels = []; // 供应商候选模型池（来自 /models 或本地 fallback）
  bool _routingEnabled = true; // 智能选模开关（关闭则强制使用指定模型）

  // 配置测试相关状态
  final ModelConnectionTestState _connectionTest = ModelConnectionTestState();

  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _customModelController =
      TextEditingController(); // 新增：自定义模型输入控制器
  final TextEditingController _promptPriceController = TextEditingController();
  final TextEditingController _completionPriceController =
      TextEditingController();

  @override
  void dispose() {
    _modelNameController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _customModelController.dispose();
    _promptPriceController.dispose();
    _completionPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // 从16减少到12
      child: Container(
        width: 550, // 从600减少到550
        height: 520, // 从600减少到520
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20), // 从24减少到20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和关闭按钮
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.addOnlineModel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ), // 从18减少到16
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20), // 添加大小规格
                ),
              ],
            ),
            const SizedBox(height: 12), // 从16减少到12
            // 步骤指示器
            Row(
              children: [
                _buildStepIndicator(
                  0,
                  AppLocalizations.of(context)!.selectProvider,
                ),
                _buildStepConnector(),
                _buildStepIndicator(
                  1,
                  AppLocalizations.of(context)!.configureParams,
                ),
                _buildStepConnector(),
                _buildStepIndicator(
                  2,
                  AppLocalizations.of(context)!.checkConfig,
                ),
                _buildStepConnector(),
                _buildStepIndicator(3, AppLocalizations.of(context)!.setName),
              ],
            ),
            const SizedBox(height: 20), // 从24减少到20
            // 步骤内容
            Expanded(child: _buildStepContent()),

            // 底部按钮
            Row(
              children: [
                const Spacer(),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentStep--;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(60, 28),
                      textStyle: const TextStyle(fontSize: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.previousStep),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canProceed() ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(60, 28),
                    textStyle: const TextStyle(fontSize: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    _currentStep == 3
                        ? AppLocalizations.of(context)!.done
                        : AppLocalizations.of(context)!.nextStep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Row(
      children: [
        Container(
          width: 14, // 从20减少到14 (20 * 2/3 ≈ 14)
          height: 14, // 从20减少到14 (20 * 2/3 ≈ 14)
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : null,
            size: 8, // 从12减少到8 (12 * 2/3 = 8)
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 4), // 缩小以适应英文标签
        Text(
          title,
          style: TextStyle(
            fontSize: 11, // 从12减少到11
            color:
                isActive
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 12, // 缩小以适应英文标签长度
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 3), // 缩小边距
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProviderSelection();
      case 1:
        return _buildApiConfiguration();
      case 2:
        return _buildConfigurationTest();
      case 3:
        return _buildModelNameSetting();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectOnlineProvider,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: onlineProviders.length + 1, // +1 为自定义选项
            itemBuilder: (context, index) {
              // 最后一项是"自定义"
              if (index == onlineProviders.length) {
                return _buildCustomProviderCard();
              }

              final provider = onlineProviders[index];
              final isSelected = _selectedProvider == provider['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedProvider = provider['id'];
                    _selectedOnlineModel = '';
                    _selectedModelSizes.clear();
                    _availableModels = [];
                    _isCustomProvider = false;
                    _customModelController.clear();
                    _apiUrlController.text = provider['defaultUrl'];

                    final providerModels = _modelsForProvider(provider);
                    if (providerModels.isNotEmpty) {
                      _selectedOnlineModel = providerModels.first['id'];
                    }
                    _connectionTest.reset();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            child: _getProviderIcon(provider),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              provider['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          provider['description'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建"自定义提供商"卡片
  Widget _buildCustomProviderCard() {
    final isSelected = _isCustomProvider;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isCustomProvider = true;
          _selectedProvider = 'custom';
          _selectedOnlineModel = '';
          _selectedModelSizes.clear();
          _availableModels = [];
          _customModelController.clear();
          _apiUrlController.clear(); // 清空，让用户手动输入
          _apiKeyController.clear();

          _connectionTest.reset();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 18,
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.customProvider,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.customProviderDesc,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get provider icon widget
  Widget _getProviderIcon(
    Map<String, dynamic> provider, {
    double size = 18,
    Color? color,
  }) {
    final iconPath = _getProviderIconPath(provider['id']);
    if (iconPath != null) {
      return Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Icon(
      provider['icon'],
      size: size,
      color: color ?? provider['color'],
    );
  }

  /// 根据 provider id 获取图标路径
  String? _getProviderIconPath(String providerId) {
    switch (providerId) {
      case 'deepseek':
        return 'assets/icons/deepseek-color.webp';
      case 'openai':
        return 'assets/icons/openai.webp';
      case 'google':
        return 'assets/icons/gemini-color.webp';
      case 'qwen':
        return 'assets/icons/qwen-color.webp';
      case 'zhipu':
        return 'assets/icons/yuanbao-color.webp';
      case 'tencent':
        return 'assets/icons/tencent-color.webp';
      case 'xiaomi_mimo':
        return 'assets/icons/xiaomi.webp';
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _modelsForProvider(Map<String, dynamic> provider) {
    final models = <Map<String, dynamic>>[];
    final seen = <String>{};

    final configuredModels = provider['models'] as List<dynamic>? ?? const [];
    for (final model in configuredModels) {
      if (model is! Map) continue;
      final normalized = Map<String, dynamic>.from(model);
      final id = normalized['id'] as String?;
      if (id == null || id.isEmpty || !seen.add(id)) continue;
      models.add(normalized);
    }

    for (final id in ModelCatalog.builtinModels[provider['id']] ?? const []) {
      if (!seen.add(id)) continue;
      models.add({
        'id': id,
        'name': ModelCatalog.displayName(id),
        'specs': ModelCatalog.shortDescription(id),
      });
    }

    return models;
  }

  List<String> _modelIdsForProvider(Map<String, dynamic> provider) {
    return _modelsForProvider(
      provider,
    ).map((model) => model['id'] as String).toList(growable: false);
  }

  String _selectedModelIdWithSize() {
    final selectedSize = _selectedModelSizes[_selectedOnlineModel];
    if (selectedSize == null || selectedSize.isEmpty) {
      return _selectedOnlineModel;
    }
    return '$_selectedOnlineModel:$selectedSize';
  }

  String _selectedModelDisplayName() {
    if (_selectedOnlineModel.isEmpty) {
      return AppLocalizations.of(context)!.notSelected;
    }
    if (_isCustomProvider) {
      return '$_selectedOnlineModel ${AppLocalizations.of(context)!.customSuffix}';
    }
    final selectedProviderData = _getSelectedProviderData();
    final selectedModel = _modelsForProvider(selectedProviderData).firstWhere(
      (model) => model['id'] == _selectedOnlineModel,
      orElse: () => {'name': ModelCatalog.displayName(_selectedOnlineModel)},
    );
    return selectedModel['name'] as String? ?? _selectedOnlineModel;
  }

  Widget _buildApiConfiguration() {
    // 自定义提供商模式：完全手动输入
    if (_isCustomProvider) {
      return _buildCustomProviderConfig();
    }

    final selectedProviderData = onlineProviders.firstWhere(
      (provider) => provider['id'] == _selectedProvider,
    );
    final modelOptions = _modelsForProvider(selectedProviderData);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(
              context,
            )!.configureProviderParams(selectedProviderData['name']),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ), // 从16减少到14
          ),
          const SizedBox(height: 16), // 从20减少到16
          // API Key 输入
          Text(
            AppLocalizations.of(context)!.modelApiKey,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ), // 从14减少到12
          ),
          const SizedBox(height: 6), // 从8减少到6
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(fontSize: 12), // 从14减少到12
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9\-_.:/=?&+]'),
              ), // 只允许英文、数字和常用API密钥字符
            ],
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.apiKeyHint,
              hintStyle: const TextStyle(fontSize: 12), // 从14减少到12
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ), // 减少内边距
            ),
            onChanged: (value) {
              _removeSpaces(_apiKeyController, value);
              _resetConnectionTestIfCompleted();
            },
          ),
          const SizedBox(height: 12), // 从16减少到12
          // API URL 配置区域
          Text(
            AppLocalizations.of(context)!.apiAddress,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiUrlController,
            style: const TextStyle(fontSize: 12),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9\-_.:/=?&+#@]'),
              ), // 只允许英文、数字和URL常用字符
            ],
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.apiUrlHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              _removeSpaces(_apiUrlController, value);
              _resetConnectionTestIfCompleted();
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.defaultApiUrlNote,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12), // 从16减少到12
          // 模型选择
          Text(
            AppLocalizations.of(context)!.selectModel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ), // 从14减少到12
          ),
          const SizedBox(height: 6), // 从8减少到6
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children:
                  modelOptions.map((model) {
                    final isSelected = _selectedOnlineModel == model['id'];
                    final hasCapabilities = model['context'] != null;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOnlineModel = model['id'];
                          _connectionTest.resetIfCompleted();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.08)
                                  : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                              ),
                              child:
                                  isSelected
                                      ? Icon(
                                        Icons.circle,
                                        size: 8,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${model['name']}${_selectedModelSizes[model['id']]?.isNotEmpty == true ? ':${_selectedModelSizes[model['id']]}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                      color:
                                          isSelected
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  if (hasCapabilities) ...[
                                    const SizedBox(height: 4),
                                    _buildCapabilityTags(model, isSelected),
                                  ] else if (model['specs'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      model['specs'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (isSelected &&
                                      model['size'] != null &&
                                      (model['size'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children:
                                          (model['size'] as List<String>).map((
                                            size,
                                          ) {
                                            final isSizeSelected =
                                                _selectedModelSizes[model['id']] ==
                                                size;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedModelSizes[model['id']] =
                                                      size;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSizeSelected
                                                          ? const Color(
                                                            0xFF1F2937,
                                                          )
                                                          : const Color(
                                                            0xFF1F2937,
                                                          ).withValues(
                                                            alpha: 0.1,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF1F2937,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  size,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        isSizeSelected
                                                            ? Colors.white
                                                            : const Color(
                                                              0xFF1F2937,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 自定义提供商配置界面 — 地址、密钥、模型名全部手动输入
  Widget _buildCustomProviderConfig() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.customProviderConfigTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          // API 地址
          Text(
            AppLocalizations.of(context)!.apiAddress,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiUrlController,
            style: const TextStyle(fontSize: 12),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9\-_.:/=?&+#@]'),
              ),
            ],
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.apiUrlHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              _removeSpaces(_apiUrlController, value);
              _resetConnectionTestIfCompleted();
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.defaultApiUrlNote,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          // API 密钥
          Text(
            AppLocalizations.of(context)!.modelApiKey,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _apiKeyController,
            style: const TextStyle(fontSize: 12),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9\-_.:/=?&+]'),
              ),
            ],
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.apiKeyHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              _removeSpaces(_apiKeyController, value);
              _resetConnectionTestIfCompleted();
            },
          ),
          const SizedBox(height: 12),
          // 模型名称
          Text(
            AppLocalizations.of(context)!.modelLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _customModelController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.modelSearchHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedOnlineModel = value.trim();
                _connectionTest.resetIfCompleted();
              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.enterFullModelName,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildModelNameSetting() {
    final colorScheme = Theme.of(context).colorScheme;
    final String platformDisplayName;

    if (_isCustomProvider) {
      platformDisplayName = AppLocalizations.of(context)!.customProvider;
    } else {
      platformDisplayName = _resolveProviderPlatformName(_selectedProvider);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.setModelName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          // 配置摘要
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.configSummary,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.platformLabel,
                  platformDisplayName,
                  Icons.cloud_outlined,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.apiAddress,
                  _apiUrlController.text.trim().isNotEmpty
                      ? _apiUrlController.text.trim()
                      : AppLocalizations.of(context)!.notSet,
                  Icons.link,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.modelLabel,
                  _selectedModelDisplayName(),
                  Icons.desktop_windows,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // 自定义名称输入
          Text(
            AppLocalizations.of(context)!.customModelName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _modelNameController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(
                context,
              )!.enterModelNameHint(platformDisplayName),
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _customModelName = value;
              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.modelNameSuggestion,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: 16),
          // 价格设置（每百万 token，用于成本统计）
          Text(
            AppLocalizations.of(context)!.inputPriceLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promptPriceController,
            style: const TextStyle(fontSize: 12),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.examplePriceHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.outputPriceLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _completionPriceController,
            style: const TextStyle(fontSize: 12),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.examplePriceHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF1F2937)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _buildPriceUnitDesc(),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: 16),
          // 智能选模开关
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: SwitchListTile(
              value: _routingEnabled,
              onChanged: (value) {
                setState(() {
                  _routingEnabled = value;
                });
              },
              activeThumbColor: const Color(0xFF10B981),
              title: const Text(
                '会话自动选择模型',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                '开启后会保存完整模型列表，会话里可自动选择或手动指定模型',
                style: TextStyle(fontSize: 11),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取当前选中的提供商数据（仅预设提供商时有效）
  Map<String, dynamic> _getSelectedProviderData() {
    if (_isCustomProvider) return {};
    return onlineProviders.firstWhere(
      (provider) => provider['id'] == _selectedProvider,
      orElse: () => {},
    );
  }

  void _removeSpaces(TextEditingController controller, String value) {
    final trimmedValue = value.replaceAll(' ', '');
    if (trimmedValue == value) return;

    controller.value = TextEditingValue(
      text: trimmedValue,
      selection: TextSelection.collapsed(offset: trimmedValue.length),
    );
  }

  void _resetConnectionTestIfCompleted() {
    setState(_connectionTest.resetIfCompleted);
  }

  /// 当前模型的货币单位（自定义提供商默认人民币）
  String _currentCurrency() {
    if (_isCustomProvider) return 'CNY';
    return _getSelectedProviderData()['currency'] as String? ?? 'CNY';
  }

  /// 价格单位描述（复用模型配置页文案）
  String _buildPriceUnitDesc() {
    final loc = AppLocalizations.of(context)!;
    final unitText = _currentCurrency() == 'CNY' ? loc.cny : loc.usd;
    return loc.priceUnitDescription(unitText);
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedProvider.isNotEmpty;
      case 1:
        // 自定义提供商：地址、密钥、模型名都需要填写
        if (_isCustomProvider) {
          return _apiUrlController.text.trim().isNotEmpty &&
              _apiKeyController.text.trim().isNotEmpty &&
              _selectedOnlineModel.isNotEmpty;
        }

        final basicRequirementsMet =
            _apiKeyController.text.trim().isNotEmpty &&
            _apiUrlController.text.trim().isNotEmpty &&
            _selectedOnlineModel.isNotEmpty;

        if (basicRequirementsMet) {
          final selectedProviderData = onlineProviders.firstWhere(
            (provider) => provider['id'] == _selectedProvider,
          );
          try {
            final selectedModel = _modelsForProvider(
              selectedProviderData,
            ).firstWhere((model) => model['id'] == _selectedOnlineModel);
            if (selectedModel['size'] != null &&
                (selectedModel['size'] as List).isNotEmpty) {
              return _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty ==
                  true;
            }
          } catch (e) {
            return basicRequirementsMet;
          }
        }

        return basicRequirementsMet;
      case 2:
        return _connectionTest.completed && _connectionTest.passed;
      case 3:
        return _customModelName.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        // 转到最终步骤时，设置模型名称默认值为 provider/model
        if (_currentStep == 3) {
          final providerName = _resolveProviderPlatformName(_selectedProvider);
          final modelName = _selectedOnlineModel;
          if (_modelNameController.text.isEmpty) {
            _modelNameController.text = '$providerName/$modelName';
            _customModelName = '$providerName/$modelName';
          }
        }
      });
    } else {
      // 完成创建
      final inputApiUrl = _apiUrlController.text.trim();
      final inputApiKey = _apiKeyController.text.trim();

      final String protocol;
      final String platformName;
      final String currency;

      if (_isCustomProvider) {
        // 自定义提供商：默认 OpenAI 协议，默认人民币
        protocol = 'openai';
        platformName = AppLocalizations.of(context)!.customProvider;
        currency = 'CNY';
      } else {
        final selectedProviderData = onlineProviders.firstWhere(
          (provider) => provider['id'] == _selectedProvider,
        );

        protocol = selectedProviderData['protocol'];
        platformName = _resolveProviderPlatformName(_selectedProvider);
        currency = selectedProviderData['currency'] as String? ?? 'CNY';
      }

      final finalApiUrl = ModelEndpointBuilder.chatCompletionUrl(
        baseUrl: inputApiUrl,
        protocol: protocol,
        modelId: _selectedOnlineModel,
        apiKey: inputApiKey,
      );

      final finalModelId = _selectedModelIdWithSize();

      // 智能选模：候选池 + 轻量/高能力模型 + 开关
      final routeModels =
          _availableModels.isNotEmpty
              ? _availableModels
              : _isCustomProvider
              ? <String>[_selectedOnlineModel]
              : _modelIdsForProvider(_getSelectedProviderData());
      final lightweightModel = ModelCatalog.pickLightweight(routeModels);
      final capableModel = ModelCatalog.pickCapable(routeModels);

      final newModel = {
        'modelId': ChatModel.generateModelId(),
        'name': _customModelName,
        'model': finalModelId,
        'type': 'online',
        'protocol': protocol,
        'platform': platformName,
        'currency': currency,
        'apiKey': inputApiKey,
        'apiUrl': finalApiUrl,
        'conversationName':
            AppLocalizations.of(context)!.newConversationDefault,
        'systemPrompt': '',
        'temperature': 1.0,
        'replyLanguage': '',
        if (_promptPriceController.text.trim().isNotEmpty)
          'promptPrice': double.tryParse(_promptPriceController.text.trim()),
        if (_completionPriceController.text.trim().isNotEmpty)
          'completionPrice': double.tryParse(
            _completionPriceController.text.trim(),
          ),
        'availableModels': routeModels,
        if (lightweightModel != null) 'lightweightModel': lightweightModel,
        if (capableModel != null) 'capableModel': capableModel,
        'routingEnabled':
            _routingEnabled &&
            lightweightModel != null &&
            capableModel != null &&
            routeModels.length >= 2,
      };
      Navigator.pop(context, newModel);
    }
  }

  /// 根据 provider ID 解析平台中文展示名
  String _resolveProviderPlatformName(String providerId) {
    final p = ModelProvider.fromString(providerId);
    return p?.displayName ?? providerId;
  }

  // 构建模型能力标签（带勾选标记）
  Widget _buildCapabilityTags(Map<String, dynamic> model, bool isSelected) {
    final primaryColor = Theme.of(context).colorScheme.onSurface;
    final dimColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.35);
    final tagColor =
        isSelected
            ? primaryColor.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface;
    final tagBorder =
        isSelected
            ? primaryColor.withValues(alpha: 0.3)
            : Theme.of(context).dividerColor.withValues(alpha: 0.5);

    // 能力列表：[标签名, 字段key, 显示名]
    final loc = AppLocalizations.of(context)!;
    final capabilities = [
      ['context', loc.contextCap],
      ['thinking', loc.thinkingCap],
      ['fc', 'FC'],
      ['tools', loc.builtinToolsCap],
      ['structuredOutput', loc.structuredCap],
      ['batchCalling', loc.batchCap],
    ];

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children:
          capabilities.map((cap) {
            final fieldKey = cap[0];
            final label = cap[1];
            final isSupported = model[fieldKey] == true;
            final isContext = fieldKey == 'context';

            // 上下文用特殊样式显示值
            if (isContext) {
              final contextValue = model['context'] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color:
                        isSelected
                            ? primaryColor.withValues(alpha: 0.4)
                            : Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  contextValue,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? primaryColor
                            : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSupported ? tagColor : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color:
                      isSupported ? tagBorder : dimColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSupported
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 9,
                    color:
                        isSupported
                            ? (isSelected
                                ? primaryColor
                                : const Color(0xFF10B981))
                            : dimColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          isSupported
                              ? (isSelected
                                  ? primaryColor
                                  : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7))
                              : dimColor,
                      fontWeight:
                          isSupported ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 6), // 从8减少到6
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12, // 从14减少到12
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12, // 从14减少到12
              color: colorScheme.onSurface.withValues(alpha: 0.86),
              fontWeight: FontWeight.w500, // 从w600减少到w500
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationTest() {
    // 如果还没有开始测试且不在测试中，自动开始测试
    if (!_connectionTest.completed && !_connectionTest.isTesting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startConfigurationTest();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.testConnectionDesc,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),

        // 测试对话区域 - 固定高度并支持滚动
        Container(
          height: 240, // 固定高度，避免溢出
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户消息
                      _buildTestMessage('你好', isUser: true),
                      const SizedBox(height: 12),

                      // AI回复
                      if (_connectionTest.isTesting &&
                          _connectionTest.response.isEmpty)
                        _buildTestMessage(
                          AppLocalizations.of(context)!.waitingForResponse,
                          isUser: false,
                          isLoading: true,
                        )
                      else if (_connectionTest.completed)
                        _buildTestMessage(
                          _connectionTest.response,
                          isUser: false,
                          isError: !_connectionTest.passed,
                        )
                      else if (_connectionTest.response.isNotEmpty &&
                          !_connectionTest.completed)
                        _buildTestMessage(
                          _connectionTest.response,
                          isUser: false,
                          isStreaming: true,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestMessage(
    String content, {
    required bool isUser,
    bool isLoading = false,
    bool isError = false,
    bool isStreaming = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final userColor = colorScheme.onSurface;
    final errorColor = colorScheme.error;
    final assistantColor = colorScheme.surfaceContainerHighest;
    // 获取选中的提供商数据，用于显示图标
    Map<String, dynamic>? selectedProviderData;
    if (_selectedProvider.isNotEmpty) {
      selectedProviderData = onlineProviders.firstWhere(
        (provider) => provider['id'] == _selectedProvider,
        orElse: () => {},
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头像
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color:
                isUser
                    ? userColor
                    : isError
                    ? errorColor
                    : assistantColor,
            shape: BoxShape.circle,
          ),
          child:
              isUser
                  ? const Icon(Icons.person, size: 12, color: Colors.white)
                  : isError
                  ? const Icon(
                    Icons.error_outline,
                    size: 12,
                    color: Colors.white,
                  )
                  : (selectedProviderData != null &&
                      selectedProviderData.isNotEmpty)
                  ? _getProviderIcon(
                    selectedProviderData,
                    size: 12,
                    color: null, // 让图标使用原本的颜色
                  )
                  : const Icon(
                    Icons.desktop_windows,
                    size: 12,
                    color: Colors.grey,
                  ),
        ),
        const SizedBox(width: 8),

        // 消息内容
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? userColor.withValues(alpha: 0.08)
                      : isError
                      ? errorColor.withValues(alpha: 0.1)
                      : assistantColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          content,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isStreaming)
                  // 流式显示时添加光标效果
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.86),
                      ),
                      children: [
                        TextSpan(text: content.replaceAll('▌', '')),
                        TextSpan(
                          text: '▌',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isError
                              ? errorColor
                              : colorScheme.onSurface.withValues(alpha: 0.86),
                    ),
                  ),

                // 如果是错误消息，显示重试按钮
                if (isError && !isLoading) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _retryTest,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: errorColor.withValues(alpha: 0.1),
                      ),
                      icon: Icon(Icons.refresh, size: 12, color: errorColor),
                      label: Text(
                        AppLocalizations.of(context)!.retry,
                        style: TextStyle(fontSize: 11, color: errorColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startConfigurationTest() async {
    setState(() {
      _connectionTest.start();
    });

    try {
      final testApiUrl = _apiUrlController.text.trim();
      final testApiKey = _apiKeyController.text.trim();

      // 自定义提供商：所有字段必须填写
      final bool apiKeyRequired;
      final String testProtocol;

      if (_isCustomProvider) {
        apiKeyRequired = true;
        testProtocol = 'openai'; // 默认 OpenAI 协议
      } else {
        final selectedProviderData = onlineProviders.firstWhere(
          (provider) => provider['id'] == _selectedProvider,
        );
        apiKeyRequired = true;
        testProtocol = selectedProviderData['protocol'];
      }

      // 查询供应商模型列表（仅 OpenAI 兼容协议）：有接口就拉，否则本地写死 fallback
      if (testProtocol == 'openai' &&
          testApiUrl.isNotEmpty &&
          testApiKey.isNotEmpty) {
        await _fetchProviderModels(testApiUrl, testApiKey);
      }

      final testModelId = _selectedModelIdWithSize();

      if (testApiUrl.isEmpty ||
          (apiKeyRequired && testApiKey.isEmpty) ||
          testModelId.isEmpty) {
        setState(() {
          _connectionTest.fail(AppLocalizations.of(context)!.configIncomplete);
        });
        return;
      }

      final finalApiUrl = ModelEndpointBuilder.chatCompletionUrl(
        baseUrl: testApiUrl,
        protocol: testProtocol,
        modelId: _selectedOnlineModel,
        apiKey: testApiKey,
      );

      // 创建临时的 ChatModel 对象用于测试
      final tempModel = ChatModel(
        modelId: 'temp_test_model',
        name: 'Test Model',
        model: testModelId,
        protocol: testProtocol,
        apiKey: testApiKey,
        apiUrl: finalApiUrl,
        createdAt: DateTime.now(),
      );

      // 使用 OpenAiProvider 进行测试
      final provider = OpenAiProvider();
      provider.configure(tempModel);

      // 构建测试会话（用于 buildRequestData）
      final testSession = ChatSession(
        sessionId: 'test_session',
        name: 'Test',
        createdAt: DateTime.now(),
        messages: [],
        chatModel: tempModel,
      );

      // 使用流式响应进行测试
      String accumulatedResponse = '';
      bool hasReceived = false;

      await for (final chunkMap in provider
          .sendMessageStream(
            messages: [
              {'role': 'user', 'content': '你好'},
            ],
            session: testSession,
          )
          .timeout(const Duration(seconds: 10))) {
        hasReceived = true;

        final chunk = chunkMap['content'] ?? '';

        // 检查是否是错误响应
        if (chunk.startsWith('错误:')) {
          setState(() {
            _connectionTest.fail(chunk);
          });
          break;
        }

        accumulatedResponse += chunk;

        // 实时更新UI显示流式响应
        if (mounted) {
          setState(() {
            _connectionTest.stream(accumulatedResponse);
          });
        }
      }

      // 处理测试完成
      if (mounted && hasReceived && !_connectionTest.completed) {
        setState(() {
          _connectionTest.finish(
            hasReceived: true,
            accumulatedResponse: accumulatedResponse,
            emptyResponseMessage:
                AppLocalizations.of(context)!.receivedEmptyResponse,
            noResponseMessage: AppLocalizations.of(context)!.receivedNoResponse,
          );
        });
      } else if (mounted && !hasReceived) {
        setState(() {
          _connectionTest.finish(
            hasReceived: false,
            accumulatedResponse: accumulatedResponse,
            emptyResponseMessage:
                AppLocalizations.of(context)!.receivedEmptyResponse,
            noResponseMessage: AppLocalizations.of(context)!.receivedNoResponse,
          );
        });
      }

      // 测试完成
    } catch (e) {
      setState(() {
        _connectionTest.fail(
          AppLocalizations.of(context)!.connectionFailed(e.toString()),
        );
      });
    }
  }

  void _retryTest() {
    setState(() {
      _connectionTest.reset();
    });
  }

  /// 查询供应商模型列表：优先 GET /models，失败则回退本地写死清单
  Future<void> _fetchProviderModels(String apiUrl, String apiKey) async {
    if (_availableModels.isNotEmpty) return;
    try {
      final tmp = ChatModel(
        modelId: 'tmp_fetch',
        name: 'tmp',
        model: '',
        protocol: 'openai',
        apiKey: apiKey,
        apiUrl: apiUrl,
      );
      final provider = OpenAiProvider()..configure(tmp);
      final online = await provider.fetchAvailableModels();
      _availableModels = ModelCatalog.resolveModels(_selectedProvider, online);
    } catch (_) {
      _availableModels = ModelCatalog.resolveModels(
        _selectedProvider,
        const [],
      );
    }
  }
}
