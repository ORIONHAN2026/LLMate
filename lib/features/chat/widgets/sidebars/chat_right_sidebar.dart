import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import 'session_config_sidebar.dart';

/// 右侧边栏 — 显示当前会话的精简核心配置
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
    final sessionController = Get.find<SessionController>();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Obx(() {
        final session = sessionController.currentSession.value;
        if (session == null) {
          return SessionConfigSidebar.buildEmptyState(context);
        }
        return SessionConfigSidebar.buildCompactSidebar(context, session);
      }),
    );
  }
}
