import 'package:flutter/material.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';

/// 聊天设置 Tab（模型参数已迁移至 ModelConfigTab）
class ChatSettingsTab extends StatelessWidget {
  final ChatModel model;
  final Function(ChatModel) onModelUpdated;

  const ChatSettingsTab({
    super.key,
    required this.model,
    required this.onModelUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '模型参数设置已合并到「基本信息」Tab 中',
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
