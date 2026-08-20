import 'package:llmate/features/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../controllers/session_controller.dart';
import '../../../models/chat/session.dart';
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
              (ctx) =>
                  SessionConfigSidebar.buildModelSettingsSection(ctx, session),
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
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: StandardAppBar(title: l10n.sessionDetails),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SessionDetailHeader(session: session),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: _SessionDetailTabs(tabs: tabs),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children:
                      tabs.map((t) {
                        final content = t.builder(context);
                        return t.scrollable
                            ? SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              child: content,
                            )
                            : content;
                      }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SessionDetailHeader extends StatelessWidget {
  final ChatSession session;

  const _SessionDetailHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            session.group?.toString().isNotEmpty == true
                ? session.group!
                : l10n.notGrouped,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionDetailTabs extends StatelessWidget {
  final List<_DetailTab> tabs;

  const _SessionDetailTabs({required this.tabs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 50,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.55,
        ),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs:
            tabs
                .map(
                  (t) => Tab(
                    height: 38,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
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
