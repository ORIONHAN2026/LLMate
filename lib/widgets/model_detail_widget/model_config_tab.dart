import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/models/bigmodel/model_data.dart';

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

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModelConfigTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _currentModel = widget.model;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // API密钥配置卡片（放在最前面）
          _buildConfigCard('API密钥配置', CupertinoIcons.pen, [_buildApiKeyItem()]),

          const SizedBox(height: 12),
          // 基本信息卡片（合并原基本信息和技术参数）
          _buildConfigCard('基本信息', CupertinoIcons.info, [
            _buildEditableModelNameItem(),
            _buildEditableModelItem(),
            _buildConfigItem(
              '状态',
              _currentModel.status == 'active' ? '运行中' : '已停用',
            ),
            _buildConfigItem('API地址', _currentModel.apiUrl ?? widget.apiUrl),
            _buildConfigItem('模型类型', _currentModel.type ?? 'local'),
            if (_currentModel.type == 'online') ...[
              _buildConfigItem('提供商', _currentModel.provider ?? '未知'),
              _buildConfigItem('模型ID', _currentModel.modelId),
            ],
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
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
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
              'API密钥:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _isEditingApiKey
                ? TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      hintText: '请输入API密钥',
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
                            color: _isHoveringApiKey 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                          color: _isHoveringApiKey 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Text(
                                  _currentModel.apiKey?.isNotEmpty == true
                                      ? (_isApiKeyVisible
                                          ? _currentModel.apiKey!
                                          : '••••••••')
                                      : '未设置（双击编辑）',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _currentModel.apiKey?.isNotEmpty == true
                                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                                    _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                  color: _isHoveringApiKey
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
              '名称:',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: _isEditingModelName
                ? TextField(
                    controller: _modelNameController,
                    decoration: const InputDecoration(
                      hintText: '请输入模型名称',
                      border: OutlineInputBorder(),
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
                    onEnter: (_) => setState(() => _isHoveringModelName = true),
                    onExit: (_) => setState(() => _isHoveringModelName = false),
                    child: GestureDetector(
                      onDoubleTap: _startEditModelName,
                      child: Container(
                        width: double.infinity,
                        // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isHoveringModelName 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                          color: _isHoveringModelName 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _currentModel.name.isNotEmpty
                                    ? _currentModel.name
                                    : '未设置（双击编辑）',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _currentModel.name.isNotEmpty
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _startEditModelName,
                              child: Icon(
                                Icons.edit,
                                size: 12,
                                color: _isHoveringModelName
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
              '模型:',
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showModelSelectionDialog,
                  child: Icon(
                    Icons.edit,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
    return _currentModel.model.isNotEmpty ? _currentModel.model : '未设置';
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
          availableModels.add({
            'id': model['id'],
            'name': model['name'],
          });
        }
        break;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '选择模型',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                '取消',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
    SnackBarUtils.showSuccess(context, 'API密钥已保存');
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
      SnackBarUtils.showError(context, '模型名称不能为空');
      return;
    }

    setState(() {
      _currentModel = _currentModel.copyWith(name: newModelName);
      _isEditingModelName = false;
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(context, '模型名称已保存');
  }

  void _saveModel(String newModelId) {
    setState(() {
      _currentModel = _currentModel.copyWith(model: newModelId);
    });

    // 保存到本地存储
    widget.onModelUpdated(_currentModel);

    // 显示保存成功提示
    SnackBarUtils.showSuccess(context, '模型已保存');
  }
}
