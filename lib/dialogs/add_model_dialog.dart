import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/bigmodel/model_data.dart';
import '../models/bigmodel/chat_model.dart';

class AddModelDialog extends StatefulWidget {
  const AddModelDialog({super.key});

  @override
  State<AddModelDialog> createState() => _AddModelDialogState();
}

class _AddModelDialogState extends State<AddModelDialog> {
  int _currentStep = 0;
  String _selectedBusinessType = '';
  String _selectedModel = '';
  String _selectedModelSize = '';
  String _selectedModelFullName = '';
  String _customModelName = '';

  final TextEditingController _modelNameController = TextEditingController();

  @override
  void dispose() {
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和步骤指示器
            Row(
              children: [
                const Text(
                  '添加新模型',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ), // 从18/w600调整为16/w500
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 步骤指示器
            Row(
              children: [
                _buildStepIndicator(0, '选择业务场景'),
                _buildStepConnector(),
                _buildStepIndicator(1, '选择大模型'),
                _buildStepConnector(),
                _buildStepIndicator(2, '设置模型名称'),
              ],
            ),
            const SizedBox(height: 24),

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
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
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
                  child: Text(_currentStep == 2 ? '完成' : '下一步'),
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
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Colors.green
                    : isActive
                    ? Colors.blue
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : null,
            size: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBusinessTypeSelection();
      case 1:
        return _buildModelSelection();
      case 2:
        return _buildModelNameSetting();
      default:
        return const SizedBox();
    }
  }

  Widget _buildBusinessTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请选择您的业务场景',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ), // 从16减少到14
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: businessTypes.length,
            itemBuilder: (context, index) {
              final businessType = businessTypes[index];
              final isSelected = _selectedBusinessType == businessType['name'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBusinessType = businessType['name'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? businessType['color'].withValues(alpha: 0.1)
                            : Colors.white,
                    border: Border.all(
                      color:
                          isSelected
                              ? businessType['color']
                              : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            businessType['icon'],
                            size: 20,
                            color: businessType['color'],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            businessType['name'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color:
                                  isSelected
                                      ? businessType['color']
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          businessType['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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

  Widget _buildModelSelection() {
    final availableModels = businessModels[_selectedBusinessType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '为 "$_selectedBusinessType" 选择合适的大模型',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: availableModels.length,
            itemBuilder: (context, index) {
              final model = availableModels[index];
              final isSelected = _selectedModel == model['name'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedModel = model['name'];
                    // 重置模型大小选择
                    _selectedModelSize = '';
                    _selectedModelFullName = '';
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.05)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // 模型信息头部
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 选择图标
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF3B82F6)
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFF3B82F6)
                                          : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            // 模型图标
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.desktopcomputer,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 模型信息
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? const Color(0xFF3B82F6)
                                              : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    model['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 模型大小选择
                      if (isSelected) ...[
                        const Divider(height: 1),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.microchip,
                                    size: 14,
                                    color: Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '选择模型参数',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    (model['sizes'] as List<String>).map((
                                      size,
                                    ) {
                                      final isSizeSelected =
                                          _selectedModelSize == size;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedModelSize = size;
                                            _selectedModelFullName =
                                                '${model['baseName']}:${size.toLowerCase()}';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSizeSelected
                                                    ? const Color(0xFF3B82F6)
                                                    : const Color(
                                                      0xFF3B82F6,
                                                    ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF3B82F6),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (size.contains('B')) ...[
                                                FaIcon(
                                                  CupertinoIcons.cloud_download,
                                                  size: 10,
                                                  color:
                                                      isSizeSelected
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF3B82F6,
                                                          ),
                                                ),
                                                const SizedBox(width: 4),
                                              ],
                                              Text(
                                                size,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      isSizeSelected
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFF3B82F6,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              if (_selectedModelSize.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const FaIcon(
                                        CupertinoIcons.info,
                                        size: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '完整模型名称: ${model['baseName']}:${_selectedModelSize.toLowerCase()}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildModelNameSetting() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设置模型名称',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),

          // 选择摘要
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      CupertinoIcons.check_mark_circled,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '您的选择',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryItem(
                  '业务场景',
                  _selectedBusinessType.isNotEmpty
                      ? _selectedBusinessType
                      : '未选择',
                  CupertinoIcons.briefcase,
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '选择模型',
                  _selectedModel.isNotEmpty ? _selectedModel : '未选择',
                  CupertinoIcons.device_laptop,
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '模型参数',
                  _selectedModelSize.isNotEmpty ? _selectedModelSize : '未选择',
                  FontAwesomeIcons.microchip,
                ),
                const SizedBox(height: 12),
                _buildSummaryItem(
                  '完整名称',
                  _selectedModelFullName.isNotEmpty
                      ? _selectedModelFullName
                      : '请先选择模型参数',
                  CupertinoIcons.tag,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 自定义名称输入
          const Text(
            '自定义模型名称',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _modelNameController,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  _selectedModel.isNotEmpty && _selectedBusinessType.isNotEmpty
                      ? '输入模型名称，如：$_selectedModel-$_selectedBusinessType'
                      : '输入模型名称',
              hintStyle: const TextStyle(fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _customModelName = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            '建议使用有意义的名称，便于识别模型用途',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedBusinessType.isNotEmpty;
      case 1:
        return _selectedModel.isNotEmpty && _selectedModelSize.isNotEmpty;
      case 2:
        return _customModelName.isNotEmpty;
      default:
        return false;
    }
  }

  void _handleNext() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      // 完成创建
      final newModel = {
        'modelId': ChatModel.generateModelId(),
        'name': _customModelName,
        'model': _selectedModelFullName,
        'status': 'inactive',
        'businessType': _selectedBusinessType,
        'description':
            businessTypes.firstWhere(
              (type) => type['name'] == _selectedBusinessType,
            )['description'],
      };
      Navigator.pop(context, newModel);
    }
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        FaIcon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
