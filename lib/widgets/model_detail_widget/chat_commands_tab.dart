import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:llmwork/models/bigmodel/chat_model.dart';
import 'package:llmwork/models/chat/chat_setting.dart';
import 'package:llmwork/utils/snackbar_utils.dart';
import 'package:llmwork/widgets/common/confirm_delete_dialog.dart';

class ChatCommandsTab extends StatefulWidget {
  final ChatModel model;
  final Function(ChatModel) onModelUpdated;

  const ChatCommandsTab({
    super.key,
    required this.model,
    required this.onModelUpdated,
  });

  @override
  State<ChatCommandsTab> createState() => _ChatCommandsTabState();
}

class _ChatCommandsTabState extends State<ChatCommandsTab> {
  late ChatModel _currentModel;
  final TextEditingController _quickCommandController = TextEditingController();
  IconData _selectedQuickIcon = CupertinoIcons.chat_bubble;

  // 聊天指令图标列表
  final List<IconData> _chatCommandIcons = [
    CupertinoIcons.chat_bubble,
    CupertinoIcons.pencil,
    CupertinoIcons.doc_text,
    CupertinoIcons.lightbulb,
    CupertinoIcons.star,
    CupertinoIcons.heart,
    CupertinoIcons.checkmark_circle,
    CupertinoIcons.question_circle,
    CupertinoIcons.info_circle,
    CupertinoIcons.exclamationmark_circle,
    CupertinoIcons.gear,
    CupertinoIcons.folder,
    CupertinoIcons.photo,
    CupertinoIcons.videocam,
    CupertinoIcons.music_note,
    CupertinoIcons.game_controller,
    CupertinoIcons.book,
    CupertinoIcons.calendar,
    CupertinoIcons.clock,
    CupertinoIcons.map,
  ];

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
  }

  @override
  void dispose() {
    _quickCommandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷指令',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // 添加快捷指令区域
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '添加快捷指令',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // 图标选择按钮
                  GestureDetector(
                    onTap: _showIconSelector,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Theme.of(context).primaryColor
                        ),
                      ),
                      child: Icon(
                        _selectedQuickIcon,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: _quickCommandController,
                      decoration: InputDecoration(
                        hintText: '输入快捷指令内容',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 12),
                      onSubmitted: (_) => _saveQuickCommand(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 添加按钮
                  ElevatedButton(
                    onPressed: _saveQuickCommand,
                    style: ElevatedButton.styleFrom(
                    
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(60, 33),
                      textStyle: const TextStyle(fontSize: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 快捷指令列表
        Expanded(
          child:
              (_currentModel.chatCommands?.isEmpty ?? true)
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_2,
                          size: 48,
                          color: Theme.of(context).primaryColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无快捷指令',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).primaryColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '添加快捷指令来提高聊天效率',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _currentModel.chatCommands?.length ?? 0,
                    itemBuilder: (context, index) {
                      final command = _currentModel.chatCommands![index];
                      return _buildCommandCard(command);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCommandCard(ChatCommand command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // 指令图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Icon(
                _storageStringToIconData(command.icon),
                size: 16,
                color: Theme.of(context).primaryColor
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 指令内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.content,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '更新于 ${_formatDateTime(command.updatedAt)}',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _showEditChatCommandDialog(command),
                tooltip: '编辑',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.trash,
                  size: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _showDeleteChatCommandDialog(command),
                tooltip: '删除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showIconSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            '选择快捷指令图标',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _chatCommandIcons.map((icon) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedQuickIcon = icon;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              _selectedQuickIcon == icon
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                _selectedQuickIcon == icon
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: 20,
                            color:
                                _selectedQuickIcon == icon
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(fontSize: 11)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteChatCommandDialog(ChatCommand command) async {
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '确认删除',
      itemName: command.content,
      description: '确定要删除快捷指令',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.command,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true) {
      // 删除指令
      final currentCommands = List<ChatCommand>.from(
        _currentModel.chatCommands ?? [],
      );
      currentCommands.removeWhere((c) => c == command);

      setState(() {
        _currentModel = _currentModel.copyWith(chatCommands: currentCommands);
      });

      // 自动保存
      widget.onModelUpdated(_currentModel);

      // 显示删除成功提示
      SnackBarUtils.showSuccess(context, "快捷指令已删除");
    }
  }

  void _saveQuickCommand() {
    final content = _quickCommandController.text.trim();

    if (content.isEmpty) {
      SnackBarUtils.showWarning(context, '请输入快捷指令内容');
      return;
    }

    // 创建新的快捷指令
    final newCommand = ChatCommand.create(
      name: '快捷指令', // 不再显示名称，但内部仍需要一个标识
      content: content,
      icon: _iconDataToStorageString(_selectedQuickIcon),
    );

    setState(() {
      _currentModel = _currentModel.copyWith(
        chatCommands: [...(widget.model.chatCommands ?? []), newCommand],
      );

      // 清空输入框和重置图标
      _quickCommandController.clear();
      _selectedQuickIcon = CupertinoIcons.chat_bubble;
    });

    // 保存到模型配置
    widget.onModelUpdated(_currentModel);

    // 显示成功提示
    SnackBarUtils.showSuccess(context, "快捷指令添加成功");
  }

  void _showEditChatCommandDialog(ChatCommand command) {
    final contentController = TextEditingController(text: command.content);
    IconData selectedIcon = _storageStringToIconData(command.icon);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              title: Row(
                children: [
                  Icon(
                    CupertinoIcons.pencil,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '编辑快捷指令',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '指令内容:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '请输入指令内容',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '选择图标:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final icon in _chatCommandIcons)
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedIcon = icon;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      selectedIcon == icon
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color:
                                        selectedIcon == icon
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).dividerColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    size: 16,
                                    color:
                                        selectedIcon == icon
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '取消',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final content = contentController.text.trim();

                    if (content.isEmpty) {
                      SnackBarUtils.showWarning(context, '指令内容不能为空');
                      return;
                    }

                    setState(() {
                      final updatedCommands =
                          (_currentModel.chatCommands ?? [])
                              .map(
                                (cmd) =>
                                    cmd.id == command.id
                                        ? cmd.copyWith(
                                          content: content,
                                          icon: _iconDataToStorageString(
                                            selectedIcon,
                                          ),
                                          updatedAt: DateTime.now(),
                                        )
                                        : cmd,
                              )
                              .toList();

                      _currentModel = _currentModel.copyWith(
                        chatCommands: updatedCommands,
                      );
                    });

                    widget.onModelUpdated(_currentModel);

                    Navigator.pop(context);
                    SnackBarUtils.showSuccess(context, "快捷指令编辑成功");
                  },
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.checkmark, size: 10),
                      const SizedBox(width: 4),
                      Text('保存'),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 图标转换工具方法
  String _iconDataToStorageString(IconData iconData) {
    // 遍历预定义图标列表，找到匹配的图标
    for (int i = 0; i < _chatCommandIcons.length; i++) {
      if (_chatCommandIcons[i] == iconData) {
        return 'cupertino_$i';
      }
    }
    // 默认返回第一个图标
    return 'cupertino_0';
  }

  IconData _storageStringToIconData(String storageString) {
    if (storageString.startsWith('cupertino_')) {
      final indexStr = storageString.substring('cupertino_'.length);
      final index = int.tryParse(indexStr);
      if (index != null && index >= 0 && index < _chatCommandIcons.length) {
        return _chatCommandIcons[index];
      }
    }
    // 默认返回第一个图标
    return _chatCommandIcons[0];
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
