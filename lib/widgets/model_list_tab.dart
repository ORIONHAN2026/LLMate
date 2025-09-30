import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/bigmodel/chat_model.dart';
import '../utils/model_icon_utils.dart';
import '../utils/snackbar_utils.dart';

class ModelListTab extends StatelessWidget {
  final List<ChatModel> models;
  final int selectedIndex;
  final Function(int) onModelSelected;
  final VoidCallback onAddModel;
  final Function(ChatModel)? onCopyModel; // 新增：复制模型回调

  const ModelListTab({
    super.key,
    required this.models,
    required this.selectedIndex,
    required this.onModelSelected,
    required this.onAddModel,
    this.onCopyModel, // 新增参数
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Column(
        children: [
          // 头部
          _buildHeader(),
          // 模型列表
          Expanded(
            child: models.isEmpty ? _buildEmptyState() : _buildModelList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            '模型管理',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: onAddModel,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: '添加模型',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.device_laptop, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无模型',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 号添加模型',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        final isSelected = index == selectedIndex;
        return _buildModelCard(model, isSelected, index);
      },
    );
  }

  Widget _buildModelCard(ChatModel model, bool isSelected, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (context) => GestureDetector(
          onTap: () => onModelSelected(index),
          onSecondaryTapDown: (details) => _showContextMenu(context, details, model),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 模型图标
                Container(
                  width: 32,
                  height: 32,
                  child: ModelIconUtils.buildModelIconWidget(
                    model.name,
                    isSelected,
                    provider: model.provider,
                  ),
                ),
                const SizedBox(width: 12),
                // 模型信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 状态指示器
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        model.status == 'active'
                            ? (isSelected
                                ? Colors.white
                                : const Color(0xFF10B981))
                            : (isSelected
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey[400]),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示右键菜单
  void _showContextMenu(BuildContext context, TapDownDetails details, ChatModel model) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      items: [
        PopupMenuItem(
          height: 40,
          value: 'copy',
          child: Row(
            children: [
              Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              const Text('复制模型', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'copy') {
        final newName = _generateCopyName(model.name);
        _copyModel(model);
        // 显示复制成功提示
        SnackBarUtils.showSuccess(context, '模型 "$newName" 复制成功');
      }
    });
  }

  /// 复制模型
  void _copyModel(ChatModel originalModel) {
    if (onCopyModel == null) return;

    // 生成新的模型名称，添加数字后缀
    String newName = _generateCopyName(originalModel.name);

    // 创建复制的模型，只保留基础配置
    final copiedModel = originalModel.copyWith(
      modelId: ChatModel.generateModelId(), // 生成新的ID
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // 清空不需要复制的配置
      chatSettings: null, // 不复制对话设置
      mcpServices: null,  // 不复制MCP配置
      chatCommands: null, // 不复制快捷指令
    );

    onCopyModel!(copiedModel);
  }

  /// 生成复制模型的名称
  String _generateCopyName(String originalName) {
    // 检查是否已有相同名称的模型
    final existingNames = models.map((m) => m.name).toSet();
    
    // 如果原名称没有冲突，直接添加2
    String baseName = originalName;
    String newName = '$baseName 2';
    
    // 如果新名称已存在，继续递增数字
    int counter = 2;
    while (existingNames.contains(newName)) {
      counter++;
      newName = '$baseName $counter';
    }
    
    return newName;
  }
}
