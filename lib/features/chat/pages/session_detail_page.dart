import 'package:llmate/features/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../controllers/session_controller.dart';
import '../widgets/sidebars/session_config_sidebar.dart';
import '../widgets/panels/usage_dashboard.dart';
import '../widgets/panels/audit_viewer.dart';

/// 会话详情页 — 以 Tab 形式展示原本位于右侧边栏的全部会话配置信息
class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionController = Get.find<SessionController>();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      final session = sessionController.currentSession.value;

      if (session == null) {
        return Scaffold(
          appBar: StandardAppBar(title: l10n.sessionDetails),
          body: Center(
            child: Text(
              l10n.selectOrCreateSession,
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
          label: l10n.basicInfoLabel,
          icon: Icons.info_outline,
          builder:
              (ctx) => SessionConfigSidebar.buildBasicInfoSection(ctx, session),
        ),
        _DetailTab(
          label: l10n.modelSettings,
          icon: Icons.smart_toy_outlined,
          builder:
              (ctx) => SessionConfigSidebar.buildModelSettingsSection(
                ctx,
                session,
              ),
        ),
        _DetailTab(
          label: l10n.sessionSettingsTab,
          icon: Icons.tune,
          builder:
              (ctx) => SessionConfigSidebar.buildSessionSettingsSection(
                ctx,
                session,
              ),
        ),
        _DetailTab(
          label: l10n.serviceConfigLabel,
          icon: Icons.settings_ethernet,
          builder:
              (ctx) =>
                  SessionConfigSidebar.buildServiceConfigSection(ctx, session),
        ),
        _DetailTab(
          label: l10n.mcpConfigLabel,
          icon: Icons.grid_view,
          builder: (ctx) => SessionConfigSidebar.buildMcpSection(ctx, session),
        ),
        _DetailTab(
          label: l10n.usageQuotaLabel,
          icon: Icons.speed,
          builder:
              (ctx) => SessionConfigSidebar.buildQuotaSection(ctx, session),
        ),
        _DetailTab(
          label: l10n.usageQueryLabel,
          icon: Icons.monetization_on_outlined,
          builder: (ctx) => UsageDashboard(session: session, embedded: true),
        ),
        _DetailTab(
          label: l10n.audit,
          icon: Icons.gavel_rounded,
          // 审计内容自带 Expanded，需要填满 Tab 高度，故不包 ScrollView
          scrollable: false,
          builder: (ctx) => AuditViewer(session: session, embedded: true),
        ),
      ];

      return DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: StandardAppBar(
            title: session.name,
            bottom: TabBar(
              isScrollable: true,
              labelColor: theme.colorScheme.onSurface,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.55,
              ),
              indicatorColor: theme.colorScheme.onSurface,
              indicatorWeight: 3,
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
                    .map((t) {
                      final content = t.builder(context);
                      return t.scrollable
                          ? SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: content,
                          )
                          : content;
                    })
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

  /// 是否用 SingleChildScrollView 包裹（内容自带 Expanded 的 Tab 应设为 false）
  final bool scrollable;

  const _DetailTab({
    required this.label,
    required this.icon,
    required this.builder,
    this.scrollable = true,
  });
}
