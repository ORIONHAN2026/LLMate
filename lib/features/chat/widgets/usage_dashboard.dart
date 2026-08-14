import 'package:llmate/features/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:llmate/l10n/app_localizations.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../controllers/usage_controller.dart';
import '../../../models/model.dart';
import '../../../models/chat/session.dart';
import '../../../models/chat/usage.dart';
import '../services/usage_loader.dart';
import 'usage_curve_chart.dart';

/// 使用量仪表盘
/// - global=true: 全局统计（所有会话汇总）
/// - global=false + session: 单会话统计
class UsageDashboard extends StatefulWidget {
  final ChatSession? session;
  final bool global;

  /// 嵌入模式：为 true 时不包裹 Scaffold / AppBar，用于嵌入到会话设置 Tab 中
  final bool embedded;

  const UsageDashboard({
    super.key,
    this.session,
    this.global = false,
    this.embedded = false,
  });

  static void show(
    BuildContext context, {
    ChatSession? session,
    bool global = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UsageDashboard(session: session, global: global),
      ),
    );
  }

  @override
  State<UsageDashboard> createState() => _UsageDashboardState();
}

class _UsageDashboardState extends State<UsageDashboard> {
  String _granularity = 'hour';
  final _showTokens = ValueNotifier<bool>(true);
  List<UsageChartPoint> _chartData = [];
  bool _chartLoading = false;
  UsageStats? _stats;

  // 全局视图：真实用量（usage_rows）聚合，加载完成前回退到会话缓存求和
  UsageStats? _globalStats;
  final Map<String, _ModelUsage> _globalModelStats = {};
  final Map<String, UsageStats> _globalSessionStats = {};

  /// 时间区间（按粒度解释）：
  /// - 分/小时：仅取某一天，start=当天 00:00，end=当天 23:59:59.999
  /// - 天/月/年：start~end 的范围（为 null 表示不限该侧）
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    if (widget.global) {
      _loadGlobalData();
    } else if (widget.session != null) {
      _loadChartData();
    }
  }

  @override
  void dispose() {
    _showTokens.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    final session = widget.session;
    if (session == null) return;

    setState(() => _chartLoading = true);

    // 分/小时维度未选日期时，默认取「当天」（与默认粒度 hour 对应）
    DateTime? start = _rangeStart;
    DateTime? end = _rangeEnd;
    if (_isSingleDay && start == null) {
      final now = DateTime.now();
      final baseDay = DateTime(now.year, now.month, now.day);
      start = baseDay;
      end = DateTime(baseDay.year, baseDay.month, baseDay.day, 23, 59, 59, 999);
      if (mounted) {
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
        });
      }
    }

    try {
      final data = await UsageLoader.load(
        sessionId: session.sessionId,
        granularity: _granularity,
        start: start,
        end: end,
      );
      // 概览数字直接取自 usage_rows 真实累计用量，与曲线同源（同一时间区间）
      final stats = await UsageController.instance.getStats(
        sessionId: session.sessionId,
        start: start,
        end: end,
      );
      if (mounted) {
        setState(() {
          _chartData = data;
          _stats = stats;
          _chartLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chartLoading = false);
      }
    }
  }

  /// 加载全局视图的真实用量（usage_rows）：一次性拉取全部明细并按模型 / 会话聚合
  Future<void> _loadGlobalData() async {
    final sessionController = Get.find<SessionController>();
    final sessions = sessionController.sessions;

    try {
      // 全部明细（按 sessionId 查询，不按 modelId 过滤）
      final all = await UsageController.instance.loadDetails();

      final global = UsageStats.empty();
      final modelStats = <String, _ModelUsage>{};
      final sessionStats = <String, UsageStats>{};
      final modelMap = <String, ChatModel>{};
      for (final s in sessions) {
        final m = s.chatModel;
        if (m != null) modelMap[m.modelId] = m;
      }

      for (final d in all) {
        global.add(d);
        final ms = modelStats.putIfAbsent(d.modelId, () => _ModelUsage());
        ms.chatModel ??= modelMap[d.modelId];
        ms.promptTokens += d.promptTokens;
        ms.completionTokens += d.completionTokens;
        sessionStats.putIfAbsent(d.sessionId, () => UsageStats.empty()).add(d);
      }

      if (mounted) {
        setState(() {
          _globalStats = global;
          _globalModelStats
            ..clear()
            ..addAll(modelStats);
          _globalSessionStats
            ..clear()
            ..addAll(sessionStats);
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  /// 分/小时维度只需选「某一天」
  bool get _isSingleDay => _granularity == 'minute' || _granularity == 'hour';

  /// 切换粒度时重置区间（分/小时会由 _loadChartData 自动定位到有数据的一天）
  Future<void> _onGranularityChanged(String granularity) async {
    setState(() {
      _granularity = granularity;
      _rangeStart = null;
      _rangeEnd = null;
    });
    await _loadChartData();
  }

  @override
  Widget build(BuildContext context) {
    return widget.global ? _buildGlobalView() : _buildSessionView();
  }

  // ==================== 单会话视图 ====================

  Widget _buildSessionView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessionController = Get.find<SessionController>();
    final session = widget.session;
    final l10n = AppLocalizations.of(context)!;

    if (session == null) {
      final empty = Center(
        child: Text(
          l10n.noSessionData,
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
      if (widget.embedded) return empty;
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(l10n.usageDashboard),
        body: empty,
      );
    }

    final body = _buildSessionBody(
      theme,
      isDark,
      sessionController,
      session,
      l10n,
    );
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(l10n.sessionUsageTitle(session.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: body,
      ),
    );
  }

  /// 单会话用量内容（不含 Scaffold），供独立页面与嵌入 Tab 复用
  Widget _buildSessionBody(
    ThemeData theme,
    bool isDark,
    SessionController sessionController,
    ChatSession session,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 概览 (依赖 Obx 响应式数据) =====
        Obx(() {
          final sessions = sessionController.sessions;
          final currentSession =
              sessions.cast<ChatSession?>().firstWhere(
                (s) => s?.sessionId == session.sessionId,
                orElse: () => null,
              ) ??
              session;

          // 概览数字优先使用 usage_rows 真实累计用量，加载完成前回退到会话缓存值
          final promptTokens =
              _stats?.promptTokens ?? currentSession.promptTokens;
          final completionTokens =
              _stats?.completionTokens ?? currentSession.completionTokens;
          final totalTokens = promptTokens + completionTokens;
          final quotaEnabled = currentSession.quotaEnabled;
          final tokenLimit = currentSession.quotaTokenLimit;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(theme, l10n.overview),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: l10n.inputTokens,
                    value: _formatTokenCount(promptTokens),
                    accentColor: const Color(0xFF9CA3AF),
                  ),
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: l10n.outputTokens,
                    value: _formatTokenCount(completionTokens),
                    accentColor: const Color(0xFF059669),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, l10n.tokenDistribution),
              const SizedBox(height: 12),
              _buildTokenDistributionCard(
                theme,
                isDark,
                promptTokens,
                completionTokens,
                l10n,
              ),
              if (quotaEnabled) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(theme, l10n.quotaLimitSection),
                const SizedBox(height: 12),
                _buildQuotaCard(
                  theme,
                  isDark,
                  totalTokens,
                  tokenLimit,
                  l10n,
                ),
              ],
            ],
          );
        }),

        // ===== 用量曲线 (独立于 Obx，依赖 _chartData state) =====
        const SizedBox(height: 24),
        _buildSectionTitle(theme, l10n.usageCurve),
        const SizedBox(height: 12),
        _buildGranularitySelector(theme, isDark, l10n),
        const SizedBox(height: 12),
        _buildDateRangeSelector(theme, isDark, l10n),
        const SizedBox(height: 12),
        _buildChartToggle(theme, l10n),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child:
              _chartLoading
                  ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  )
                  : ValueListenableBuilder<bool>(
                    valueListenable: _showTokens,
                    builder:
                        (_, showToken, _) => UsageCurveChart(
                          data: _chartData,
                          showTokens: showToken,
                          granularity: _granularity,
                        ),
                  ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ==================== 全局视图 ====================

  Widget _buildGlobalView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessionController = Get.find<SessionController>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(l10n.globalUsageDashboard),
      body: Obx(() {
        final sessions = sessionController.sessions;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noUsageData,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        // 首次加载真实用量时显示 loading
        if (_globalStats == null) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          );
        }

        // 概览数字优先使用 usage_rows 真实累计用量，加载完成前回退到会话缓存求和
        final stats = _globalStats;
        final totalPrompt =
            stats?.promptTokens ??
            sessions.fold<int>(0, (s, session) => s + session.promptTokens);
        final totalCompletion =
            stats?.completionTokens ??
            sessions.fold<int>(0, (s, session) => s + session.completionTokens);
        // 按模型分组：真实用量（modelId 聚合），加载完成前回退到会话缓存分组
        final modelStats =
            stats == null ? _fallbackModelStats(sessions) : _globalModelStats;

        // 各会话真实用量排序（回退到会话缓存 token）
        final sortedWithTokens =
            sessions
                .where(
                  (s) =>
                      (_globalSessionStats[s.sessionId]?.totalTokens ??
                          s.promptTokens + s.completionTokens) >
                      0,
                )
                .toList()
              ..sort(
                (a, b) => (_globalSessionStats[b.sessionId]?.totalTokens ??
                        b.promptTokens + b.completionTokens)
                    .compareTo(
                      _globalSessionStats[a.sessionId]?.totalTokens ??
                          a.promptTokens + a.completionTokens,
                    ),
              );
        final emptyCount =
            sessions
                .where(
                  (s) =>
                      (_globalSessionStats[s.sessionId]?.totalTokens ??
                          s.promptTokens + s.completionTokens) ==
                      0,
                )
                .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(theme, l10n.overview),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: l10n.totalSessions,
                    value: '${sessions.length}',
                    accentColor: const Color(0xFF9CA3AF),
                  ),
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: l10n.totalTokens,
                    value: _formatTokenCount(totalPrompt + totalCompletion),
                    accentColor: const Color(0xFF059669),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, l10n.tokenDistribution),
              const SizedBox(height: 12),
              _buildTokenDistributionCard(
                theme,
                isDark,
                totalPrompt,
                totalCompletion,
                l10n,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, l10n.byModel),
              const SizedBox(height: 12),
              ...modelStats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildModelUsageRow(
                    theme,
                    isDark,
                    entry.key,
                    entry.value,
                    l10n,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, l10n.allSessions),
              const SizedBox(height: 12),
              if (sortedWithTokens.isEmpty)
                _buildEmptySessionsHint(theme, l10n)
              else ...[
                ...sortedWithTokens
                    .take(8)
                    .map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSessionUsageRow(
                          theme,
                          isDark,
                          session,
                          l10n,
                        ),
                      ),
                    ),
                if (emptyCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.moreSessionsNoData(emptyCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }

  /// 加载真实用量前的回退：用会话缓存累加按模型分组
  Map<String, _ModelUsage> _fallbackModelStats(List<ChatSession> sessions) {
    final map = <String, _ModelUsage>{};
    for (final session in sessions) {
      final modelName = session.chatModel?.name ?? 'Unknown';
      final stat = map.putIfAbsent(modelName, () => _ModelUsage());
      stat.chatModel ??= session.chatModel;
      stat.sessionCount++;
      stat.promptTokens += session.promptTokens;
      stat.completionTokens += session.completionTokens;
    }
    return map;
  }

  // ==================== 共用组件 ====================

  PreferredSizeWidget _buildAppBar(String title) {
    return StandardAppBar(title: title, showBottomDivider: true);
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required bool isDark,
    required String title,
    required String value,
    required Color accentColor,
    double? progress,
    String? progressSuffix,
  }) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23242A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              if (progressSuffix != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    progressSuffix,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor:
                      isDark
                          ? const Color(0xFF1A1B23)
                          : const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFFDC2626) : accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDistributionCard(
    ThemeData theme,
    bool isDark,
    int totalPrompt,
    int totalCompletion,
    AppLocalizations l10n,
  ) {
    final total = totalPrompt + totalCompletion;
    final promptRatio = total > 0 ? totalPrompt / total : 0.0;
    final completionRatio = total > 0 ? totalCompletion / total : 0.0;
    final accentBlue = const Color(0xFF9CA3AF);
    final accentPurple = const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(accentBlue),
              const SizedBox(width: 6),
              Text(
                '${l10n.inputLabel}: ${_formatTokenCount(totalPrompt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _legendDot(accentPurple),
              const SizedBox(width: 6),
              Text(
                '${l10n.outputLabel}: ${_formatTokenCount(totalCompletion)}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (promptRatio > 0)
                    Expanded(
                      flex: (promptRatio * 1000).round().clamp(1, 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentBlue,
                          borderRadius:
                              promptRatio >= 1
                                  ? BorderRadius.circular(6)
                                  : const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                  ),
                        ),
                      ),
                    ),
                  if (completionRatio > 0)
                    Expanded(
                      flex: (completionRatio * 1000).round().clamp(1, 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentPurple,
                          borderRadius:
                              completionRatio >= 1
                                  ? BorderRadius.circular(6)
                                  : const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildQuotaCard(
    ThemeData theme,
    bool isDark,
    int totalTokens,
    int? tokenLimit,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          if (tokenLimit != null && tokenLimit > 0) ...[
            Row(
              children: [
                Icon(
                  Icons.token_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.tokenUsage,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${_formatTokenCount(totalTokens)} / ${_formatTokenCount(tokenLimit)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:
                    tokenLimit > 0
                        ? (totalTokens / tokenLimit).clamp(0.0, 1.0)
                        : 0.0,
                minHeight: 6,
                backgroundColor:
                    isDark ? const Color(0xFF1A1B23) : const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalTokens > tokenLimit
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
          if (tokenLimit == null || tokenLimit <= 0)
            Text(
              l10n.noQuotaLimit,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModelUsageRow(
    ThemeData theme,
    bool isDark,
    String name,
    _ModelUsage usage,
    AppLocalizations l10n,
  ) {
    final modelTotal = usage.promptTokens + usage.completionTokens;
    final promptRatio = modelTotal > 0 ? usage.promptTokens / modelTotal : 0.0;
    final completionRatio =
        modelTotal > 0 ? usage.completionTokens / modelTotal : 0.0;
    final accentBlue = const Color(0xFF9CA3AF);
    final accentPurple = const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child:
                    usage.chatModel?.buildIconWidget(false) ??
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  usage.chatModel?.name ?? name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                _formatTokenCount(modelTotal),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.sessionsCountSuffix(usage.sessionCount),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          if (modelTotal > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(accentBlue),
                const SizedBox(width: 4),
                Text(
                  '${l10n.inputLabel} ${_formatTokenCount(usage.promptTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                _legendDot(accentPurple),
                const SizedBox(width: 4),
                Text(
                  '${l10n.outputLabel} ${_formatTokenCount(usage.completionTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (promptRatio > 0)
                      Expanded(
                        flex: (promptRatio * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentBlue,
                            borderRadius:
                                promptRatio >= 1
                                    ? BorderRadius.circular(3)
                                    : const BorderRadius.only(
                                      topLeft: Radius.circular(3),
                                      bottomLeft: Radius.circular(3),
                                    ),
                          ),
                        ),
                      ),
                    if (completionRatio > 0)
                      Expanded(
                        flex: (completionRatio * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentPurple,
                            borderRadius:
                                completionRatio >= 1
                                    ? BorderRadius.circular(3)
                                    : const BorderRadius.only(
                                      topRight: Radius.circular(3),
                                      bottomRight: Radius.circular(3),
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySessionsHint(ThemeData theme, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF23242A)
                : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D2F3A)
                  : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 24,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noUsageData,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionUsageRow(
    ThemeData theme,
    bool isDark,
    ChatSession session,
    AppLocalizations l10n,
  ) {
    final st = _globalSessionStats[session.sessionId];
    final promptTokens = st?.promptTokens ?? session.promptTokens;
    final completionTokens = st?.completionTokens ?? session.completionTokens;
    final total = promptTokens + completionTokens;
    final promptRatio = total > 0 ? promptTokens / total : 0.0;
    final completionRatio = total > 0 ? completionTokens / total : 0.0;
    final accentBlue = const Color(0xFF9CA3AF);
    final accentPurple = const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                _formatTokenCount(total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(accentBlue),
                const SizedBox(width: 4),
                Text(
                  '${l10n.inputLabel} ${_formatTokenCount(promptTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                _legendDot(accentPurple),
                const SizedBox(width: 4),
                Text(
                  '${l10n.outputLabel} ${_formatTokenCount(completionTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (promptRatio > 0)
                      Expanded(
                        flex: (promptRatio * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentBlue,
                            borderRadius:
                                promptRatio >= 1
                                    ? BorderRadius.circular(3)
                                    : const BorderRadius.only(
                                      topLeft: Radius.circular(3),
                                      bottomLeft: Radius.circular(3),
                                    ),
                          ),
                        ),
                      ),
                    if (completionRatio > 0)
                      Expanded(
                        flex: (completionRatio * 1000).round().clamp(1, 1000),
                        child: Container(
                          decoration: BoxDecoration(
                            color: accentPurple,
                            borderRadius:
                                completionRatio >= 1
                                    ? BorderRadius.circular(3)
                                    : const BorderRadius.only(
                                      topRight: Radius.circular(3),
                                      bottomRight: Radius.circular(3),
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTokenCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(2)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  // ==================== 用量曲线 ====================

  Widget _buildGranularitySelector(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final options = [
      (l10n.granMinute, 'minute'),
      (l10n.granHour, 'hour'),
      (l10n.granDay, 'day'),
      (l10n.granMonth, 'month'),
      (l10n.granYear, 'year'),
    ];

    return Row(
      children: [
        ...options.map((opt) {
          final selected = _granularity == opt.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onGranularityChanged(opt.$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? const Color(0xFF9CA3AF)
                          : (isDark
                              ? const Color(0xFF2D2F3A)
                              : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  opt.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color:
                        selected
                            ? Colors.white
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 时间区间选择器：根据粒度变化形态
  /// - 分/小时：选「某一天」
  /// - 天/月/年：选「开始 ~ 结束」范围
  Widget _buildDateRangeSelector(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final chipBg = isDark ? const Color(0xFF2D2F3A) : const Color(0xFFF3F4F6);
    final borderColor =
        isDark ? const Color(0xFF3A3D4A) : const Color(0xFFE5E7EB);

    if (_isSingleDay) {
      final day = _rangeStart;
      return Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 6),
          _dateChip(
            theme: theme,
            bg: chipBg,
            borderColor: borderColor,
            label: day == null ? l10n.selectDate : _fmtByGran(day),
            onTap: _pickDay,
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.date_range_outlined,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        _dateChip(
          theme: theme,
          bg: chipBg,
          borderColor: borderColor,
          label:
              _rangeStart == null ? l10n.rangeStart : _fmtByGran(_rangeStart!),
          onTap: () => _pickRange(isStart: true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        _dateChip(
          theme: theme,
          bg: chipBg,
          borderColor: borderColor,
          label: _rangeEnd == null ? l10n.rangeEnd : _fmtByGran(_rangeEnd!),
          onTap: () => _pickRange(isStart: false),
        ),
        if (_rangeStart != null || _rangeEnd != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                });
                _loadChartData();
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dateChip({
    required ThemeData theme,
    required Color bg,
    required Color borderColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  /// 分/小时：选择某一天
  Future<void> _pickDay() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: l10n.selectDate,
    );
    if (picked == null) return;
    setState(() {
      _rangeStart = DateTime(picked.year, picked.month, picked.day);
      _rangeEnd = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
        999,
      );
    });
    await _loadChartData();
  }

  /// 天/月/年：选择范围起点或终点
  Future<void> _pickRange({required bool isStart}) async {
    final l10n = AppLocalizations.of(context)!;
    final current =
        isStart ? _rangeStart ?? DateTime.now() : _rangeEnd ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: isStart ? l10n.startDateHelp : l10n.endDateHelp,
    );
    if (picked == null) return;

    DateTime start;
    DateTime end;
    switch (_granularity) {
      case 'month':
        start = DateTime(picked.year, picked.month);
        end = DateTime(picked.year, picked.month + 1, 0, 23, 59, 59, 999);
        break;
      case 'year':
        start = DateTime(picked.year);
        end = DateTime(picked.year, 12, 31, 23, 59, 59, 999);
        break;
      case 'day':
      default:
        start = DateTime(picked.year, picked.month, picked.day);
        end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
        break;
    }

    setState(() {
      if (isStart) {
        _rangeStart = start;
      } else {
        _rangeEnd = end;
      }
    });
    await _loadChartData();
  }

  /// 按粒度格式化时间区间标签
  String _fmtByGran(DateTime d) {
    switch (_granularity) {
      case 'minute':
      case 'hour':
        return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      case 'day':
        return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      case 'month':
        return '${d.year}/${d.month.toString().padLeft(2, '0')}';
      case 'year':
        return '${d.year}';
      default:
        return '${d.year}/${d.month}/${d.day}';
    }
  }

  Widget _buildChartToggle(ThemeData theme, AppLocalizations l10n) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTokens,
      builder:
          (_, showToken, _) => Row(
            children: [
              _toggleChip(
                theme: theme,
                label: l10n.tokenToggle,
                color: const Color(0xFF9CA3AF),
                selected: showToken,
                onTap: () => _showTokens.value = !_showTokens.value,
              ),
            ],
          ),
    );
  }

  Widget _toggleChip({
    required ThemeData theme,
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child:
                selected
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelUsage {
  int sessionCount = 0;
  int promptTokens = 0;
  int completionTokens = 0;
  ChatModel? chatModel;
}
