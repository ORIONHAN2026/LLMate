import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/chat/chat_setting.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/widgets/model_detail_widget/model_config_tab.dart';
import 'package:chathub/widgets/model_detail_widget/chat_settings_tab.dart';
import 'package:chathub/widgets/model_detail_widget/chat_commands_tab.dart';
import 'package:chathub/widgets/model_detail_widget/mcp_tab.dart';
import 'package:chathub/widgets/model_detail_widget/rag_tab.dart';
import 'package:chathub/widgets/common/confirm_delete_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

class ModelDetailPage extends StatefulWidget {
  final ChatModel model;
  final String apiUrl;
  final Function(ChatModel) onModelUpdated; // 参数为 updatedModel
  final Function(String)? onModelDeleted; // 参数为 modelId

  const ModelDetailPage({
    super.key,
    required this.model,
    required this.apiUrl,
    required this.onModelUpdated,
    this.onModelDeleted,
  });

  @override
  State<ModelDetailPage> createState() => _ModelDetailPageState();
}

class _ModelDetailPageState extends State<ModelDetailPage> {
  // 静态Map用于记录每个模型的tab状态
  static final Map<String, int> _modelTabStates = <String, int>{};

  int _selectedDetailTab = 0;
  late ChatModel _currentModel;
  bool _isModelDeleted = false; // 添加删除状态标记
  late TextEditingController _apiKeyController;
  late TextEditingController _modelNameController;
  late TextEditingController _systemPromptController;
  late TextEditingController _quickCommandController; // 快捷指令输入控制器
  Timer? _debounceTimer; // 防抖定时器
  // 当前选择的快捷指令图标

  // 快捷指令图标选项 - 使用 CupertinoIcons

  // IconData 和 String 之间的转换映射

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _modelNameController = TextEditingController();
    _systemPromptController = TextEditingController();
    _quickCommandController = TextEditingController(); // 初始化快捷指令控制器
    _initializeData();
  }

  @override
  void didUpdateWidget(ModelDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 widget 更新时，保存旧模型的tab状态
    if (oldWidget.model != widget.model) {
      // 保存旧模型的tab状态
      if (oldWidget.model.modelId.isNotEmpty) {
        _modelTabStates[oldWidget.model.modelId] = _selectedDetailTab;
      }

      setState(() {
        _isModelDeleted = false; // 重置删除状态
      });
      _initializeData();
    }
  }

  void _initializeData() {
    _currentModel = widget.model;

    // 恢复该模型之前的tab状态，如果没有记录则默认为0
    _selectedDetailTab = _modelTabStates[_currentModel.modelId] ?? 0;

    _apiKeyController.text = _currentModel.apiKey ?? '';
    _modelNameController.text = _currentModel.name;

    //打印 MCP的配置内容
    print('MCP Services: ${jsonEncode(_currentModel.mcpServices)}');

    // 初始化系统提示词控制器
    _systemPromptController.text =
        _currentModel.chatSettings?.systemPrompt ?? '';

    // 如果模型的语言需要标准化，更新模型
    final normalizedReplyLanguage = _currentModel.chatSettings?.replyLanguage;

    if (normalizedReplyLanguage != _currentModel.chatSettings?.replyLanguage) {
      final updatedChatSettings = (_currentModel.chatSettings ??
              ChatSettings(
                conversationName: '新对话',
                systemPrompt: '',
                temperature: 0.7,
                replyLanguage: 'auto',
              ))
          .copyWith(replyLanguage: normalizedReplyLanguage);
      _currentModel = _currentModel.copyWith(chatSettings: updatedChatSettings);
    }
  }

  @override
  void dispose() {
    // 在页面销毁前保存当前模型的tab状态
    if (_currentModel.modelId.isNotEmpty) {
      _modelTabStates[_currentModel.modelId] = _selectedDetailTab;
    }

    _debounceTimer?.cancel();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    _systemPromptController.dispose();
    _quickCommandController.dispose(); // 释放快捷指令控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果模型已被删除，显示删除提示界面
    if (_isModelDeleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '模型已删除',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '模型 "${_currentModel.name}" 已成功删除',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Text(
              '请从左侧列表选择其他模型查看详情',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 模型详情头部
        _buildModelHeader(),
        const SizedBox(height: 12), // 从16减少到12
        // Tab导航
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16), // 从24减少到16
          child: Row(
            children: [
              _buildTab('模型设置', 0, CupertinoIcons.gear),
              _buildTab('对话设置', 1, CupertinoIcons.chat_bubble_2),
              _buildTab('快捷指令', 2, CupertinoIcons.command),
              // _buildTab('RAG知识库', 3, CupertinoIcons.book_fill),
              _buildTab('MCP服务', 4, CupertinoIcons.cloud),
            ],
          ),
        ),
        // Tab内容
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16), // 从24减少到16
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = _selectedDetailTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDetailTab = index;
            // 保存当前模型的tab状态
            _modelTabStates[_currentModel.modelId] = index;
          });
        },
        borderRadius: BorderRadius.circular(8), // 从12减少到8
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8), // 从12减少到8
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), // 从12减少到8
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 12, // 从14减少到12
                color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6), // 从8减少到6
              Text(
                title,
                style: TextStyle(
                  fontSize: 12, // 从14减少到12
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelHeader() {
    return Container(
      padding: const EdgeInsets.all(16), // 从24减少到16
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12), // 从16减少到12
      //   border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
      // ),
      child: Row(
        children: [
          // 模型图标和信息
          const SizedBox(width: 12), // 从20减少到12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentModel.name.isNotEmpty ? _currentModel.name : '未命名模型',
                  style: TextStyle(
                    fontSize: 18, // 从24减少到18
                    fontWeight: FontWeight.w600, // 从w700减少到w600
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6), // 从8减少到6
                Text(
                  _currentModel.description ?? '无描述',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ), // 从14减少到12
                ),
              ],
            ),
          ),
          // 操作按钮
          Column(
            children: [
              // Elevates
              //   onPressed: _toggleModelStatus,
              //   icon: Icon(
              //     _currentModel.status == 'active'
              //         ? CupertinoIcons.pause
              //         : CupertinoIcons.play,
              //     size: 10,
              //   ),
              //   label: Text(_currentModel.status == 'active' ? '停用' : '启用'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor:
              //         _currentModel.status == 'active'
              //             ? Colors.orange
              //             : const Color(0xFF10B981),
              //     foregroundColor: Colors.white,
              //     padding: const EdgeInsets.symmetric(
              //       horizontal: 8,
              //       vertical: 4,
              //     ),
              //     minimumSize: const Size(60, 28),
              //     textStyle: const TextStyle(fontSize: 11),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(6),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  // 删除模型
                  _showDeleteConfirmation();
                },
                icon: const Icon(CupertinoIcons.trash, size: 10),
                label: const Text('删除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error, width: 1),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedDetailTab) {
      case 0:
        return ModelConfigTab(
          model: _currentModel,
          apiUrl: widget.apiUrl,
          onModelUpdated: (model) {
            setState(() {
              _currentModel = model;
            });
            widget.onModelUpdated(model);
          },
        );
      case 1:
        return ChatSettingsTab(
          model: _currentModel,
          onModelUpdated: (model) {
            setState(() {
              _currentModel = model;
            });
            widget.onModelUpdated(model);
          },
        );
      case 2:
        return ChatCommandsTab(
          model: _currentModel,
          onModelUpdated: (model) {
            setState(() {
              _currentModel = model;
            });
            widget.onModelUpdated(model);
          },
        );
      case 3:
        return RagTab(
          model: _currentModel,
          onModelUpdated: (model) {
            setState(() {
              _currentModel = model;
            });
            widget.onModelUpdated(model);
          },
        );
      case 4:
        return McpTab(
          model: _currentModel,
          onModelUpdated: (model) {
            setState(() {
              _currentModel = model;
            });
            widget.onModelUpdated(model);
          },
        );
      default:
        return const SizedBox();
    }
  }

  void _showDeleteConfirmation() async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '确认删除',
      itemName: _currentModel.name,
      description: '确定要删除大模型',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.exclamationmark_triangle,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      // 设置删除状态
      setState(() {
        _isModelDeleted = true;
      });
      // 调用删除回调
      if (widget.onModelDeleted != null) {
        widget.onModelDeleted!(_currentModel.modelId);
      }
      // 显示删除成功提示
      SnackBarUtils.showSuccess(context, '模型 "${_currentModel.name}" 已删除');
    }
  }
}
