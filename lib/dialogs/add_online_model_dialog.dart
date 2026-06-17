import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/bigmodel/model_data.dart';
import '../models/bigmodel/chat_model.dart';
import '../models/chat/chat_message.dart';
import '../framework/llm_hub.dart';

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
  bool _isCustomModel = false; // 是否使用自定义模型（在预设提供商下）
  bool _isCustomProvider = false; // 是否使用自定义提供商（完全手动输入）

  // 配置测试相关状态
  bool _isTesting = false;
  bool _testCompleted = false;
  bool _testPassed = false;
  String _testResponse = '';

  final TextEditingController _modelNameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _customModelController =
      TextEditingController(); // 新增：自定义模型输入控制器

  @override
  void dispose() {
    _modelNameController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _customModelController.dispose();
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
              color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                _buildStepIndicator(0, AppLocalizations.of(context)!.selectProvider),
                _buildStepConnector(),
                _buildStepIndicator(1, AppLocalizations.of(context)!.configureParams),
                _buildStepConnector(),
                _buildStepIndicator(2, AppLocalizations.of(context)!.checkConfig),
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
                  child: Text(_currentStep == 3 ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.nextStep),
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
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                    _isCustomModel = false;
                    _isCustomProvider = false;
                    _customModelController.clear();
                    _apiUrlController.text = provider['defaultUrl'];

                    if (provider['models'] != null &&
                        (provider['models'] as List).isNotEmpty) {
                      _selectedOnlineModel = provider['models'][0]['id'];
                    }
                    _testCompleted = false;
                    _testPassed = false;
                    _testResponse = '';
                  });

                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
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
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.8),
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
                            ).colorScheme.onSurface.withOpacity(0.6),
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
          _isCustomModel = true; // 自定义提供商下强制使用自定义模型输入
          _customModelController.clear();
          _apiUrlController.clear(); // 清空，让用户手动输入
          _apiKeyController.clear();

          _testCompleted = false;
          _testPassed = false;
          _testResponse = '';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
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
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
      case 'chatgpt':
        return 'assets/icons/openai.webp';
      case 'gemini':
        return 'assets/icons/gemini-color.webp';
      case 'aliyun':
        return 'assets/icons/qwen-color.webp';
      case 'tencent':
        return 'assets/icons/yuanbao-color.webp';
      case 'xiaomi':
        return 'assets/icons/yuanbao-color.webp';
      default:
        return null;
    }
  }

  Widget _buildApiConfiguration() {
    // 自定义提供商模式：完全手动输入
    if (_isCustomProvider) {
      return _buildCustomProviderConfig();
    }

    final selectedProviderData = onlineProviders.firstWhere(
      (provider) => provider['id'] == _selectedProvider,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.configureProviderParams(selectedProviderData['name']),
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
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ), // 减少内边距
            ),
            onChanged: (value) {
              // 自动去除空格
              final trimmedValue = value.replaceAll(' ', '');
              if (trimmedValue != value) {
                _apiKeyController.value = TextEditingValue(
                  text: trimmedValue,
                  selection: TextSelection.collapsed(
                    offset: trimmedValue.length,
                  ),
                );
              }
              setState(() {
                // 重置测试状态（如果用户更改了配置）
                if (_testCompleted) {
                  _testCompleted = false;
                  _testPassed = false;
                  _testResponse = '';
                }
              });
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
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              // 自动去除空格
              final trimmedValue = value.replaceAll(' ', '');
              if (trimmedValue != value) {
                _apiUrlController.value = TextEditingValue(
                  text: trimmedValue,
                  selection: TextSelection.collapsed(
                    offset: trimmedValue.length,
                  ),
                );
              }
              setState(() {
                // 重置测试状态（如果用户更改了配置）
                if (_testCompleted) {
                  _testCompleted = false;
                  _testPassed = false;
                  _testResponse = '';
                }

              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.defaultApiUrlNote,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
          // 选择方式：预设模型 vs 自定义输入
          Row(
            children: [
              Flexible(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomModel = false;
                      _selectedModelSizes.clear(); // 清空所有模型的规格选择
                      // 如果有预设模型，默认选择第一个
                      if ((selectedProviderData['models'] as List).isNotEmpty) {
                        _selectedOnlineModel =
                            selectedProviderData['models'][0]['id'];
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          !_isCustomModel
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color:
                            !_isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.presetModel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            !_isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight:
                            !_isCustomModel
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomModel = true;
                      _selectedOnlineModel = ''; // 清空预设选择
                      _selectedModelSizes.clear(); // 清空所有模型的规格选择
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isCustomModel
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color:
                            _isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.customModel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight:
                            _isCustomModel
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 根据选择显示不同的输入方式
          if (!_isCustomModel) ...[
            // 预设模型列表
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                        children:
                            (selectedProviderData['models']
                                    as List<Map<String, dynamic>>)
                                .map((model) {
                                  final isSelected =
                                      _selectedOnlineModel == model['id'];
                                  final hasCapabilities =
                                      model['context'] != null;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedOnlineModel = model['id'];
                                        // 不需要重置该模型的规格选择，保持用户已选择的状态
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
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.08)
                                                : null,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).dividerColor.withOpacity(0.5),
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
                                                        ).colorScheme.primary
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .outline
                                                            .withOpacity(0.5),
                                                width: 2,
                                              ),
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.transparent,
                                            ),
                                            child:
                                                isSelected
                                                    ? Icon(
                                                      Icons.circle,
                                                      size: 8,
                                                      color:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .onPrimary,
                                                    )
                                                    : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.8,
                                                                ),
                                                  ),
                                                ),
                                                // 模型能力指标（带勾选标记）
                                                if (hasCapabilities) ...[
                                                  const SizedBox(height: 4),
                                                  _buildCapabilityTags(
                                                    model,
                                                    isSelected,
                                                  ),
                                                ] else if (model['specs'] !=
                                                    null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    model['specs'],
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.5),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],

                                                // 如果模型有 size 字段且选中了该模型，显示 size 选择标签
                                                if (isSelected &&
                                                    model['size'] != null &&
                                                    (model['size'] as List)
                                                        .isNotEmpty) ...[
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
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    isSizeSelected
                                                                        ? const Color(
                                                                          0xFF3B82F6,
                                                                        )
                                                                        : const Color(
                                                                          0xFF3B82F6,
                                                                        ).withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                border: Border.all(
                                                                  color: const Color(
                                                                    0xFF3B82F6,
                                                                  ),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Text(
                                                                size,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color:
                                                                      isSizeSelected
                                                                          ? Colors
                                                                              .white
                                                                          : const Color(
                                                                            0xFF3B82F6,
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
                                })
                                .toList(),
                      ),
            ),
          ] else ...[
            // 自定义模型输入
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
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedOnlineModel = value.trim();
                  // 重置测试状态
                  if (_testCompleted) {
                    _testCompleted = false;
                    _testPassed = false;
                    _testResponse = '';
                  }
                });
              },
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.enterFullModelName,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
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
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              final trimmedValue = value.replaceAll(' ', '');
              if (trimmedValue != value) {
                _apiUrlController.value = TextEditingValue(
                  text: trimmedValue,
                  selection: TextSelection.collapsed(offset: trimmedValue.length),
                );
              }
              setState(() {
                if (_testCompleted) {
                  _testCompleted = false;
                  _testPassed = false;
                  _testResponse = '';
                }
              });
            },
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context)!.defaultApiUrlNote,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
            onChanged: (value) {
              final trimmedValue = value.replaceAll(' ', '');
              if (trimmedValue != value) {
                _apiKeyController.value = TextEditingValue(
                  text: trimmedValue,
                  selection: TextSelection.collapsed(offset: trimmedValue.length),
                );
              }
              setState(() {
                if (_testCompleted) {
                  _testCompleted = false;
                  _testPassed = false;
                  _testResponse = '';
                }
              });
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
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedOnlineModel = value.trim();
                if (_testCompleted) {
                  _testCompleted = false;
                  _testPassed = false;
                  _testResponse = '';
                }
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.check_mark_circled,
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
                  CupertinoIcons.cloud,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.apiAddress,
                  _apiUrlController.text.trim().isNotEmpty
                      ? _apiUrlController.text.trim()
                      : AppLocalizations.of(context)!.notSet,
                  CupertinoIcons.link,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  AppLocalizations.of(context)!.modelLabel,
                  _selectedOnlineModel.isNotEmpty
                      ? _isCustomModel || _isCustomProvider
                          ? '$_selectedOnlineModel ${AppLocalizations.of(context)!.customSuffix}'
                          : (_getSelectedProviderData()['models'] as List)
                              .firstWhere(
                                (m) => m['id'] == _selectedOnlineModel,
                                orElse: () => {'name': _selectedOnlineModel},
                              )['name']
                      : AppLocalizations.of(context)!.notSelected,
                  CupertinoIcons.device_desktop,
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
              hintText: AppLocalizations.of(context)!.enterModelNameHint(platformDisplayName),
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
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
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

        // 如果是预设模型且有 size 选项，需要检查是否选择了 size
        if (!_isCustomModel && basicRequirementsMet) {
          final selectedProviderData = onlineProviders.firstWhere(
            (provider) => provider['id'] == _selectedProvider,
          );
          try {
            final selectedModel = (selectedProviderData['models'] as List)
                .firstWhere((model) => model['id'] == _selectedOnlineModel);
            if (selectedModel != null &&
                selectedModel['size'] != null &&
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
        return _testCompleted && _testPassed;
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
      });
    } else {
      // 完成创建
      final inputApiUrl = _apiUrlController.text.trim();
      final inputApiKey = _apiKeyController.text.trim();
      String finalApiUrl = inputApiUrl;

      final String protocol;
      final String platformName;

      if (_isCustomProvider) {
        // 自定义提供商：默认 OpenAI 协议
        protocol = 'openai';
        platformName = AppLocalizations.of(context)!.customProvider;

        // OpenAI 协议自动补全端点
        if (!finalApiUrl.endsWith('/chat/completions')) {
          finalApiUrl =
              finalApiUrl.endsWith('/')
                  ? '${finalApiUrl}chat/completions'
                  : '$finalApiUrl/chat/completions';
        }
      } else {
        final selectedProviderData = onlineProviders.firstWhere(
          (provider) => provider['id'] == _selectedProvider,
        );

        protocol = selectedProviderData['protocol'];
        platformName = _resolveProviderPlatformName(_selectedProvider);

        // 根据协议自动补全API端点路径
        switch (protocol) {
          case 'anthropic':
            if (!finalApiUrl.endsWith('/messages')) {
              finalApiUrl =
                  finalApiUrl.endsWith('/')
                      ? '${finalApiUrl}messages'
                      : '$finalApiUrl/messages';
            }
            break;
          case 'gemini':
            if (!finalApiUrl.contains('/models/')) {
              finalApiUrl =
                  finalApiUrl.endsWith('/')
                      ? '${finalApiUrl}models/$_selectedOnlineModel:generateContent?key=$inputApiKey'
                      : '$finalApiUrl/models/$_selectedOnlineModel:generateContent?key=$inputApiKey';
            }
            break;
          // OpenAI 兼容协议
          default:
            if (!finalApiUrl.endsWith('/chat/completions')) {
              finalApiUrl =
                  finalApiUrl.endsWith('/')
                      ? '${finalApiUrl}chat/completions'
                      : '$finalApiUrl/chat/completions';
            }
        }
      }

      // 构建最终的模型标识符
      String finalModelId = _selectedOnlineModel;
      if (!_isCustomModel &&
          _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty == true) {
        finalModelId =
            '$_selectedOnlineModel:${_selectedModelSizes[_selectedOnlineModel]}';
      }

      final newModel = {
        'modelId': ChatModel.generateModelId(),
        'name': _customModelName,
        'model': finalModelId,
        'type': 'online',
        'protocol': protocol,
        'platform': platformName,
        'apiKey': inputApiKey,
        'apiUrl': finalApiUrl,
        'chatSettings': {
          'conversationName': '新对话',
          'systemPrompt': '',
          'temperature': 1.0,
          'replyLanguage': '',
        },
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dimColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.35);
    final tagColor =
        isSelected
            ? primaryColor.withOpacity(0.15)
            : Theme.of(context).colorScheme.surface;
    final tagBorder =
        isSelected
            ? primaryColor.withOpacity(0.3)
            : Theme.of(context).dividerColor.withOpacity(0.5);

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
                          ? primaryColor.withOpacity(0.12)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color:
                        isSelected
                            ? primaryColor.withOpacity(0.4)
                            : Theme.of(context).dividerColor.withOpacity(0.4),
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
                            ).colorScheme.onSurface.withOpacity(0.7),
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
                  color: isSupported ? tagBorder : dimColor.withOpacity(0.3),
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
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7))
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
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]), // 从14减少到12
        const SizedBox(width: 6), // 从8减少到6
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12, // 从14减少到12
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12, // 从14减少到12
              color: Colors.black87,
              fontWeight: FontWeight.w500, // 从w600减少到w500
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationTest() {
    // 如果还没有开始测试且不在测试中，自动开始测试
    if (!_testCompleted && !_isTesting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startConfigurationTest();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.testConnectionDesc,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // 测试对话区域 - 固定高度并支持滚动
        Container(
          height: 240, // 固定高度，避免溢出
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
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
                      if (_isTesting && _testResponse.isEmpty)
                        _buildTestMessage(
                          AppLocalizations.of(context)!.waitingForResponse,
                          isUser: false,
                          isLoading: true,
                        )
                      else if (_testCompleted)
                        _buildTestMessage(
                          _testResponse,
                          isUser: false,
                          isError: !_testPassed,
                        )
                      else if (_testResponse.isNotEmpty && !_testCompleted)
                        _buildTestMessage(
                          _testResponse,
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
                    ? const Color(0xFF3B82F6)
                    : isError
                    ? Colors.red
                    : Colors.grey[100], // AI头像使用浅灰色背景
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
                    CupertinoIcons.device_desktop,
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
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : isError
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                else if (isStreaming)
                  // 流式显示时添加光标效果
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: content.replaceAll('▌', '')),
                        const TextSpan(
                          text: '▌',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
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
                      color: isError ? Colors.red : Colors.black87,
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
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                      icon: const Icon(
                        Icons.refresh,
                        size: 12,
                        color: Colors.red,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.retry,
                        style: const TextStyle(fontSize: 11, color: Colors.red),
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
      _isTesting = true;
      _testCompleted = false;
      _testPassed = false;
      _testResponse = '';
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

      if (testApiUrl.isEmpty ||
          (apiKeyRequired && testApiKey.isEmpty) ||
          _selectedOnlineModel.isEmpty) {
        setState(() {
          _isTesting = false;
          _testCompleted = true;
          _testPassed = false;
          _testResponse = AppLocalizations.of(context)!.configIncomplete;
        });
        return;
      }

      // 构建完整API端点
      String finalApiUrl = testApiUrl;

      // 构建最终的模型标识符
      String testModelId = _selectedOnlineModel;
      if (!_isCustomModel &&
          _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty == true) {
        testModelId =
            '$_selectedOnlineModel:${_selectedModelSizes[_selectedOnlineModel]}';
      }

      // 根据协议自动补全API端点路径
      switch (testProtocol) {
        case 'anthropic':
          if (!finalApiUrl.endsWith('/messages')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}messages'
                    : '$finalApiUrl/messages';
          }
          break;
        case 'gemini':
          if (!finalApiUrl.contains('/models/')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}models/$_selectedOnlineModel:generateContent?key=$testApiKey'
                    : '$finalApiUrl/models/$_selectedOnlineModel:generateContent?key=$testApiKey';
          }
          break;
        // OpenAI 兼容协议
        default:
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
      }

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
      print(tempModel.toJson());

      // 使用 LLM Hub 创建 provider 进行测试
      final provider = LlmHub.createProvider(tempModel);

      // 创建测试消息
      final testMessage = ChatMessage(
        msgId: 'test_msg_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.user,
        content: '你好',
        timestamp: DateTime.now(),
      );

      // 使用流式响应进行测试
      String accumulatedResponse = '';
      bool hasReceived = false;

      await for (final chunkMap in provider.sendMessageStream(
        userMessage: testMessage,
        session: null,
      ).timeout(const Duration(seconds: 10))) {
        hasReceived = true;

        final chunk = chunkMap['content'] ?? '';

        // 检查是否是错误响应
        if (chunk.startsWith('错误:')) {
          setState(() {
            _isTesting = false;
            _testCompleted = true;
            _testPassed = false;
            _testResponse = chunk;
          });
          break;
        }

        accumulatedResponse += chunk;

        // 实时更新UI显示流式响应
        if (mounted) {
          setState(() {
            _testResponse = accumulatedResponse;
            _testCompleted = false;
          });
        }
      }

      // 处理测试完成
      if (mounted && hasReceived && !_testCompleted) {
        setState(() {
          _isTesting = false;
          _testCompleted = true;
          _testPassed =
              accumulatedResponse.isNotEmpty &&
              !accumulatedResponse.startsWith('错误:');
          if (accumulatedResponse.isEmpty) {
            _testResponse = AppLocalizations.of(context)!.receivedEmptyResponse;
            _testPassed = false;
          }
        });
      } else if (mounted && !hasReceived) {
        setState(() {
          _isTesting = false;
          _testCompleted = true;
          _testPassed = false;
          _testResponse = AppLocalizations.of(context)!.receivedNoResponse;
        });
      }

      // 测试完成
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testCompleted = true;
        _testPassed = false;
        _testResponse = AppLocalizations.of(context)!.connectionFailed(e.toString());
      });
    }
  }

  void _retryTest() {
    setState(() {
      _testCompleted = false;
      _testPassed = false;
      _testResponse = '';
    });
  }

}

