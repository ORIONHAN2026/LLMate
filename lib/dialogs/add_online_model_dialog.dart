import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  Map<String, String> _selectedModelSizes = {}; // 改为 Map，为每个模型独立存储选中的规格
  String _customModelName = '';
  bool _isCustomModel = false; // 新增：是否使用自定义模型

  // 配置测试相关状态
  bool _isTesting = false;
  bool _testCompleted = false;
  bool _testPassed = false;
  String _testResponse = '';

  // Ollama模型获取相关状态
  bool _isLoadingOllamaModels = false;
  List<Map<String, dynamic>> _ollamaModels = [];
  String _ollamaModelsError = '';

  // ModelScope模型获取相关状态  
  bool _isLoadingModelScopeModels = false;
  List<Map<String, dynamic>> _modelScopeModels = [];
  String _modelScopeModelsError = '';

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
                const Text(
                  '添加在线模型',
                  style: TextStyle(
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
                _buildStepIndicator(0, '选择提供商'),
                _buildStepConnector(),
                _buildStepIndicator(1, '配置参数'),
                _buildStepConnector(),
                _buildStepIndicator(2, '检查配置'),
                _buildStepConnector(),
                _buildStepIndicator(3, '设置名称'),
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
                    child: const Text('上一步'),
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
                  child: Text(_currentStep == 3 ? '完成' : '下一步'),
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
        const SizedBox(width: 6), // 从8减少到6
        Text(
          title,
          style: TextStyle(
            fontSize: 11, // 从12减少到11
            color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 30, // 从40减少到30
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6), // 从8减少到6
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
        const Text(
          '选择在线模型提供商',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2, // 从2.0增加到2.2，让卡片更扁平紧凑
              crossAxisSpacing: 10, // 从12减少到10
              mainAxisSpacing: 10, // 从12减少到10
            ),
            itemCount: onlineProviders.length,
            itemBuilder: (context, index) {
              final provider = onlineProviders[index];
              final isSelected = _selectedProvider == provider['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedProvider = provider['id'];
                    _selectedOnlineModel = '';
                    _selectedModelSizes.clear(); // 清空所有模型的规格选择
                    _isCustomModel = false; // 重置为预设模型模式
                    _customModelController.clear(); // 清空自定义模型输入
                    // 设置默认API地址
                    _apiUrlController.text = provider['defaultUrl'];
                    
                    // 重置Ollama模型相关状态
                    _ollamaModels.clear();
                    _ollamaModelsError = '';
                    
                    // 重置ModelScope模型相关状态
                    _modelScopeModels.clear();
                    _modelScopeModelsError = '';
                    
                    // 默认选择第一个模型
                    if (provider['models'] != null &&
                        (provider['models'] as List).isNotEmpty) {
                      _selectedOnlineModel = provider['models'][0]['id'];
                    }
                    // 重置测试状态（如果用户更换了提供商）
                    _testCompleted = false;
                    _testPassed = false;
                    _testResponse = '';
                  });
                  
                  // 如果选择了Ollama，自动获取模型列表
                  if (provider['id'] == 'ollama') {
                    // 延迟一点执行，确保API URL已经设置
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _fetchOllamaModels();
                    });
                  }
                  
                  // 如果选择了ModelScope，自动获取模型列表
                  if (provider['id'] == 'modelscope') {
                    // 延迟一点执行，确保API URL已经设置
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _fetchModelScopeModels();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12), // 从16减少到12
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8), // 从12减少到8
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getProviderIcon(provider),
                          const SizedBox(width: 6), // 从8减少到6
                          Expanded(
                            child: Text(
                              provider['name'],
                              style: TextStyle(
                                fontSize: 12, // 从14减少到12，与home页面一致
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6), // 从8减少到6
                      Expanded(
                        child: Text(
                          provider['description'],
                          style: TextStyle(
                            fontSize: 11, // 从12减少到11
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            height: 1.3, // 添加行高以更好的显示
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

  // Helper method to get provider icon widget
  Widget _getProviderIcon(
    Map<String, dynamic> provider, {
    double size = 18,
    Color? color,
  }) {
    if (provider['id'] == 'deepseek') {
      return Image.asset(
        'assets/icons/deepseek-color.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (provider['id'] == 'ollama') {
      return Image.asset(
        'assets/icons/ollama.webp',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      return Icon(
        provider['icon'],
        size: size,
        color: color ?? provider['color'],
      );
    }
  }

  Widget _buildApiConfiguration() {
    final selectedProviderData = onlineProviders.firstWhere(
      (provider) => provider['id'] == _selectedProvider,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '配置 ${selectedProviderData['name']} 参数',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ), // 从16减少到14
          ),
          const SizedBox(height: 16), // 从20减少到16
          // API Key 输入
          const Text(
            'API 密钥',
            style: TextStyle(
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
              hintText: _selectedProvider == 'ollama' 
                  ? '本地 Ollama 服务通常不需要 API 密钥，可留空'
                  : '输入您的 API 密钥',
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
          const Text(
            'API 地址',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
              hintText: '输入API地址',
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
                
                // 如果是Ollama，重置模型列表状态
                if (_selectedProvider == 'ollama') {
                  _ollamaModels.clear();
                  _ollamaModelsError = '';
                  _selectedOnlineModel = '';
                }
                
                // 如果是ModelScope，重置模型列表状态
                if (_selectedProvider == 'modelscope') {
                  _modelScopeModels.clear();
                  _modelScopeModelsError = '';
                  _selectedOnlineModel = '';
                }
              });
              
              // 如果是Ollama，延迟重新获取模型列表
              if (_selectedProvider == 'ollama' && trimmedValue.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_selectedProvider == 'ollama' && 
                      _apiUrlController.text.trim() == trimmedValue) {
                    _fetchOllamaModels();
                  }
                });
              }
              
              // 如果是ModelScope，延迟重新获取模型列表
              if (_selectedProvider == 'modelscope' && trimmedValue.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_selectedProvider == 'modelscope' && 
                      _apiUrlController.text.trim() == trimmedValue) {
                    _fetchModelScopeModels();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 6),
          Text(
            '默认为官方API地址，可根据需要修改为本地或私有部署地址',
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 12), // 从16减少到12
          // 模型选择
          const Text(
            '选择模型',
            style: TextStyle(
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
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
                      '预设模型',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            !_isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
                      '自定义模型',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isCustomModel
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              child: _selectedProvider == 'ollama' 
                  ? _buildOllamaModelList()
                  : _selectedProvider == 'modelscope'
                  ? _buildModelScopeModelList()
                  : Column(
                      children:
                          (selectedProviderData['models']
                                  as List<Map<String, dynamic>>)
                              .map((model) {
                          final isSelected =
                              _selectedOnlineModel == model['id'];
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
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                        : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor.withOpacity(0.5),
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
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
                                              color: Theme.of(context).colorScheme.onPrimary,
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
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                          ),
                                        ),
                                     
                                        // 如果模型有 size 字段且选中了该模型，显示 size 选择标签
                                        if (isSelected && model['size'] != null && (model['size'] as List).isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: (model['size'] as List<String>).map((size) {
                                              final isSizeSelected = _selectedModelSizes[model['id']] == size;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedModelSizes[model['id']] = size;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isSizeSelected
                                                        ? const Color(0xFF3B82F6)
                                                        : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: const Color(0xFF3B82F6),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    size,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: isSizeSelected
                                                          ? Colors.white
                                                          : const Color(0xFF3B82F6),
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
                hintText: '输入模型名称，如：gpt-4o-mini, claude-3-haiku 等',
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
              '请输入提供商支持的完整模型名称',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  // 构建Ollama模型列表
  Widget _buildOllamaModelList() {
    return Column(
      children: [
        // 刷新按钮和状态
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Ollama 运行中的模型',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (_isLoadingOllamaModels)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _fetchOllamaModels,
                  icon: const Icon(Icons.refresh, size: 16),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(24, 24),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: '刷新模型列表',
                ),
            ],
          ),
        ),
        
        // 模型列表或错误信息
        if (_ollamaModelsError.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[300],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _ollamaModelsError,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchOllamaModels,
                  child: const Text('重试', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )
        else if (_ollamaModels.isEmpty && !_isLoadingOllamaModels)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '请先启动 Ollama 服务并下载模型\n然后点击刷新按钮获取模型列表',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchOllamaModels,
                  child: const Text('获取模型列表', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )
        else
          ..._ollamaModels.map((model) {
            final isSelected = _selectedOnlineModel == model['id'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedOnlineModel = model['id'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
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
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.black87,
                            ),
                          ),
                          if (model['size'] != null && model['size'] > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '大小: ${_formatFileSize(model['size'])}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
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
      ],
    );
  }

  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  // 构建ModelScope模型列表
  Widget _buildModelScopeModelList() {
    return Column(
      children: [
        // 刷新按钮和状态
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'ModelScope 可用模型',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (_isLoadingModelScopeModels)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _fetchModelScopeModels,
                  icon: const Icon(Icons.refresh, size: 16),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(24, 24),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: '刷新模型列表',
                ),
            ],
          ),
        ),
        
        // 模型列表或错误信息
        if (_modelScopeModelsError.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[300],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _modelScopeModelsError,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchModelScopeModels,
                  child: const Text('重试', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )
        else if (_modelScopeModels.isEmpty && !_isLoadingModelScopeModels)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '请确保 API 密钥正确\n然后点击刷新按钮获取模型列表',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _fetchModelScopeModels,
                  child: const Text('获取模型列表', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          )
        else
          ..._modelScopeModels.map((model) {
            final isSelected = _selectedOnlineModel == model['id'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedOnlineModel = model['id'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
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
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.black87,
                            ),
                          ),
                          if (model['object'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '类型: ${model['object']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
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
      ],
    );
  }

  Widget _buildModelNameSetting() {
    final selectedProviderData = onlineProviders.firstWhere(
      (provider) => provider['id'] == _selectedProvider,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置模型名称',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ), // 从16减少到14
          ),
          const SizedBox(height: 12), // 从16减少到12
          // 配置摘要
          Container(
            padding: const EdgeInsets.all(16), // 从20减少到16
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // 从12减少到8
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.check_mark_circled,
                      size: 14, // 从16减少到14
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6), // 从8减少到6
                    const Text(
                      '配置摘要',
                      style: TextStyle(
                        fontSize: 12, // 从16减少到12
                        fontWeight: FontWeight.w500, // 从w600减少到w500
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // 从16减少到12
                _buildSummaryItem(
                  '提供商',
                  selectedProviderData['name'],
                  CupertinoIcons.device_desktop,
                ),
                const SizedBox(height: 8), // 从12减少到8
                _buildSummaryItem(
                  'API 地址',
                  _apiUrlController.text.trim().isNotEmpty
                      ? _apiUrlController.text.trim()
                      : '未设置',
                  CupertinoIcons.link,
                ),
                const SizedBox(height: 8), // 从12减少到8
                _buildSummaryItem(
                  '模型',
                  _selectedOnlineModel.isNotEmpty
                      ? _isCustomModel
                          ? '$_selectedOnlineModel (自定义)'
                          : selectedProviderData['models'].firstWhere(
                            (m) => m['id'] == _selectedOnlineModel,
                            orElse:
                                () => {
                                  'name': _selectedOnlineModel,
                                }, // 如果找不到，显示原始名称
                          )['name']
                      : '未选择',
                  CupertinoIcons.device_desktop,
                ),
                const SizedBox(height: 8), // 从12减少到8
                
              ],
            ),
          ),

          const SizedBox(height: 16), // 从24减少到16
          // 自定义名称输入
          const Text(
            '自定义模型名称',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ), // 从14减少到12
          ),
          const SizedBox(height: 6), // 从8减少到6
          TextField(
            controller: _modelNameController,
            style: const TextStyle(fontSize: 12), // 从14减少到12
            decoration: InputDecoration(
              hintText: '输入模型名称，如：${selectedProviderData['name']}-Chat',
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
                horizontal: 10, // 从12减少到10
                vertical: 6, // 从8减少到6
              ),
            ),
            onChanged: (value) {
              setState(() {
                _customModelName = value;
              });
            },
          ),
          const SizedBox(height: 6), // 从8减少到6
          Text(
            '建议使用有意义的名称，便于识别模型用途',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]), // 从12减少到11
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedProvider.isNotEmpty;
      case 1:
        // Ollama 可能不需要 API Key，其他提供商需要
        final apiKeyRequired = _selectedProvider != 'ollama';
        final basicRequirementsMet = (apiKeyRequired ? _apiKeyController.text.trim().isNotEmpty : true) &&
            _apiUrlController.text.trim().isNotEmpty &&
            _selectedOnlineModel.isNotEmpty;
        
        // 如果是预设模型且有 size 选项，需要检查是否选择了 size
        if (!_isCustomModel && basicRequirementsMet) {
          final selectedProviderData = onlineProviders.firstWhere(
            (provider) => provider['id'] == _selectedProvider,
          );
          try {
            final selectedModel = (selectedProviderData['models'] as List).firstWhere(
              (model) => model['id'] == _selectedOnlineModel,
            );
            if (selectedModel != null && selectedModel['size'] != null && (selectedModel['size'] as List).isNotEmpty) {
              return _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty == true;
            }
          } catch (e) {
            // 如果找不到对应的模型，返回基本要求的结果
            return basicRequirementsMet;
          }
        }
        
        return basicRequirementsMet;
      case 2:
        return _testCompleted && _testPassed; // 必须测试通过才能继续
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
      // 完成创建 - 确保使用测试时的完整API端点
      final selectedProviderData = onlineProviders.firstWhere(
        (provider) => provider['id'] == _selectedProvider,
      );

      // 构建与测试时相同的完整API端点
      final inputApiUrl = _apiUrlController.text.trim();
      final inputApiKey = _apiKeyController.text.trim();
      String finalApiUrl = inputApiUrl;

      // 根据提供商自动补全API端点路径，与测试逻辑保持一致
      switch (_selectedProvider) {
        case 'openai':
        case 'deepseek':
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
          break;
        case 'modelscope': // 魔塔兼容OpenAI API格式
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
          break;
        case 'anthropic':
          if (!finalApiUrl.endsWith('/messages')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}messages'
                    : '$finalApiUrl/messages';
          }
          break;
        case 'google':
          if (!finalApiUrl.contains('/models/')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}models/$_selectedOnlineModel:generateContent?key=$inputApiKey'
                    : '$finalApiUrl/models/$_selectedOnlineModel:generateContent?key=$inputApiKey';
          }
          break;
        case 'ollama':
          // Ollama 需要自动添加 /chat 路径
          if (!finalApiUrl.endsWith('/chat')) {
            finalApiUrl = finalApiUrl.endsWith('/') ? '${finalApiUrl}chat' : '$finalApiUrl/chat';
          }
          break;
        // 其他提供商使用通用格式
        default:
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
      }

      // 构建最终的模型标识符
      String finalModelId = _selectedOnlineModel;
      if (!_isCustomModel && _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty == true) {
        // 如果是预设模型且选择了 size，构建完整的模型标识符
        finalModelId = '$_selectedOnlineModel:${_selectedModelSizes[_selectedOnlineModel]}';
      }

      final newModel = {
        'modelId': ChatModel.generateModelId(), // 内部唯一标识符
        'name': _customModelName,
        'model': finalModelId,
        'status': 'active', // 默认状态改为激活
        'businessType': '在线模型',
        'description': '${selectedProviderData['name']} 在线模型服务',
        'type': 'online', // 标记为在线模型
        'provider': _selectedProvider,
        'apiKey': inputApiKey, // 使用控制器中的最新值
        'apiUrl': finalApiUrl, // 使用完整的API端点
      };
      Navigator.pop(context, newModel);
    }
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
          '测试模型连接和响应能力',
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
              // 对话标题
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.grey[50],
              //     borderRadius: const BorderRadius.only(
              //       topLeft: Radius.circular(6),
              //       topRight: Radius.circular(6),
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       const Icon(
              //         CupertinoIcons.chat_bubble_2,
              //         size: 14,
              //         color: Color(0xFF3B82F6),
              //       ),
              //       const SizedBox(width: 8),
              //       const Text(
              //         '配置测试对话',
              //         style: TextStyle(
              //           fontSize: 12,
              //           fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // 对话内容 - 可滚动
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
                          '正在等待回复...',
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
                      label: const Text(
                        '重试',
                        style: TextStyle(fontSize: 11, color: Colors.red),
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
      // 确保使用控制器中的最新值
      final testApiUrl = _apiUrlController.text.trim();
      final testApiKey = _apiKeyController.text.trim();

      // Ollama 可能不需要 API Key，其他提供商需要
      final apiKeyRequired = _selectedProvider != 'ollama';
      
      if (testApiUrl.isEmpty ||
          (apiKeyRequired && testApiKey.isEmpty) ||
          _selectedOnlineModel.isEmpty) {
        setState(() {
          _isTesting = false;
          _testCompleted = true;
          _testPassed = false;
          _testResponse = '配置信息不完整';
        });
        return;
      }

      // 构建与测试时相同的完整API端点
      String finalApiUrl = testApiUrl;

      // 构建最终的模型标识符（与创建时保持一致）
      String testModelId = _selectedOnlineModel;
      if (!_isCustomModel && _selectedModelSizes[_selectedOnlineModel]?.isNotEmpty == true) {
        testModelId = '$_selectedOnlineModel:${_selectedModelSizes[_selectedOnlineModel]}';
      }

      // 根据提供商自动补全API端点路径
      switch (_selectedProvider) {
        case 'openai':
        case 'deepseek':
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
          break;
        case 'modelscope': // 魔塔兼容OpenAI API格式
          if (!finalApiUrl.endsWith('/chat/completions')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}chat/completions'
                    : '$finalApiUrl/chat/completions';
          }
          break;
        case 'anthropic':
          if (!finalApiUrl.endsWith('/messages')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}messages'
                    : '$finalApiUrl/messages';
          }
          break;
        case 'google':
          if (!finalApiUrl.contains('/models/')) {
            finalApiUrl =
                finalApiUrl.endsWith('/')
                    ? '${finalApiUrl}models/$_selectedOnlineModel:generateContent?key=$testApiKey'
                    : '$finalApiUrl/models/$_selectedOnlineModel:generateContent?key=$testApiKey';
          }
          break;
        case 'ollama':
          // Ollama 需要自动添加 /chat 路径
          if (!finalApiUrl.endsWith('/chat')) {
            finalApiUrl = finalApiUrl.endsWith('/') ? '${finalApiUrl}chat' : '$finalApiUrl/chat';
          }
          break;
        // 其他提供商使用通用格式
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
        model: testModelId, // 使用包含规格的模型标识符
        status: 'active',
        provider: _selectedProvider,
        apiKey: testApiKey,
        apiUrl: finalApiUrl,
        createdAt: DateTime.now(),
      );

      // 使用 LLM Hub 创建客户端进行测试
      final client = LlmHub.instance.createClient(tempModel);

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

      await for (final chunkMap in client.sendMessageStream(
        userMessage: testMessage,
        session: null,
      )) {
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
            _testResponse = '接收到空响应';
            _testPassed = false;
          }
        });
      } else if (mounted && !hasReceived) {
        setState(() {
          _isTesting = false;
          _testCompleted = true;
          _testPassed = false;
          _testResponse = '未收到任何响应';
        });
      }

      // 清理资源
      client.dispose();
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testCompleted = true;
        _testPassed = false;
        _testResponse = '连接失败：${e.toString()}';
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

  // 获取Ollama运行中的模型列表
  Future<void> _fetchOllamaModels() async {
    if (_selectedProvider != 'ollama') return;

    setState(() {
      _isLoadingOllamaModels = true;
      _ollamaModelsError = '';
    });

    try {
      final apiUrl = _apiUrlController.text.trim().isNotEmpty 
          ? _apiUrlController.text.trim()
          : 'http://localhost:11434/api';
      
      // 确保URL以/api结尾
      String baseUrl = apiUrl;
      if (!baseUrl.endsWith('/api')) {
        baseUrl = baseUrl.endsWith('/') ? '${baseUrl}api' : '$baseUrl/api';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['models'] != null) {
          setState(() {
            _ollamaModels = (data['models'] as List).map((model) {
              return {
                'id': model['name'] ?? '',
                'name': model['name'] ?? '',
                'size': model['size'] ?? 0,
                'modified_at': model['modified_at'] ?? '',
              };
            }).toList();
            _isLoadingOllamaModels = false;
          });
        }
      } else {
        setState(() {
          _ollamaModelsError = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
          _isLoadingOllamaModels = false;
        });
      }
    } catch (e) {
      setState(() {
        _ollamaModelsError = '连接失败: ${e.toString()}';
        _isLoadingOllamaModels = false;
      });
    }
  }

  // 获取ModelScope可用的模型列表
  Future<void> _fetchModelScopeModels() async {
    if (_selectedProvider != 'modelscope') return;

    setState(() {
      _isLoadingModelScopeModels = true;
      _modelScopeModelsError = '';
    });

    try {
      final apiUrl = _apiUrlController.text.trim().isNotEmpty 
          ? _apiUrlController.text.trim()
          : 'https://api-inference.modelscope.cn/v1/';
      
      // 确保URL以v1/结尾
      String baseUrl = apiUrl;
      if (!baseUrl.endsWith('/v1/')) {
        if (baseUrl.endsWith('/')) {
          baseUrl = '${baseUrl}v1/';
        } else {
          baseUrl = '$baseUrl/v1/';
        }
      }
      
      final response = await http.get(
        Uri.parse('${baseUrl}models'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKeyController.text.trim()}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _modelScopeModels = (data['data'] as List).map((model) {
              return {
                'id': model['id'] ?? '',
                'name': model['id'] ?? '',
                'object': model['object'] ?? '',
                'created': model['created'] ?? 0,
              };
            }).toList();
            _isLoadingModelScopeModels = false;
          });
        }
      } else {
        setState(() {
          _modelScopeModelsError = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
          _isLoadingModelScopeModels = false;
        });
      }
    } catch (e) {
      setState(() {
        _modelScopeModelsError = '连接失败: ${e.toString()}';
        _isLoadingModelScopeModels = false;
      });
    }
  }
}
