import 'package:flutter/material.dart';
import 'session_config_sidebar.dart';

/// 右侧边栏 — 显示当前会话配置
class ChatRightSidebar extends StatelessWidget {
  final double width;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const ChatRightSidebar({
    super.key,
    required this.width,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SessionConfigSidebar.buildTabContent(context),
          ),
        ],
      ),
    );
  }
}