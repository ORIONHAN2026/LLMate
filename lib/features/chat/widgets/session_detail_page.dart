import '../../../widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import 'sidebars/session_config_sidebar.dart';

/// 会话详情页 — 以 Tab 形式展示原本位于右侧边栏的全部会话配置信息
class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    final theme = Theme.of(context);

    return Obx(() {
      final session = sessionController.currentSession.value;

      if (session == null) {
        return Scaffold(
          appBar: StandardAppBar(title: '会话详情'),
          body: Center(
            child: Text(
              '请先选择或创建一个会话',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }

      final tabs = <_DetailTab>[
        _DetailTab(
          label: '基础信息',
          icon: Icons.info_outline,
          builder:
              (ctx) => SessionConfigSidebar.buildBasicInfoSection(ctx, session),
        ),
        _DetailTab(
          label: '会话设定',
          icon: Icons.tune,
          builder:
              (ctx) => SessionConfigSidebar.buildSessionSettingsSection(
                ctx,
                session,
              ),
        ),
        _DetailTab(
          label: '服务配置',
          icon: Icons.settings_ethernet,
          builder:
              (ctx) =>
                  SessionConfigSidebar.buildServiceConfigSection(ctx, session),
        ),
        _DetailTab(
          label: 'MCP配置',
          icon: Icons.grid_view,
          builder: (ctx) => SessionConfigSidebar.buildMcpSection(ctx, session),
        ),
        _DetailTab(
          label: '用量配额',
          icon: Icons.speed,
          builder:
              (ctx) => SessionConfigSidebar.buildQuotaSection(ctx, session),
        ),
        _DetailTab(
          label: '用量查询',
          icon: Icons.monetization_on_outlined,
          builder: (ctx) => SessionConfigSidebar.buildBillingInfo(ctx, session),
        ),
      ];

      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: StandardAppBar(
            title: session.name,
            bottom: TabBar(
              isScrollable: true,
              tabs:
                  tabs
                      .map(
                        (t) => Tab(text: t.label, icon: Icon(t.icon, size: 16)),
                      )
                      .toList(),
            ),
          ),
          body: TabBarView(
            children:
                tabs
                    .map(
                      (t) => SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: t.builder(context),
                      ),
                    )
                    .toList(),
          ),
        ),
      );
    });
  }
}

class _DetailTab {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  const _DetailTab({
    required this.label,
    required this.icon,
    required this.builder,
  });
}
