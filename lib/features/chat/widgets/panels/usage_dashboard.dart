import 'package:llmate/features/widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:llmate/l10n/app_localizations.dart';
import '../../../../controllers/session_controller.dart';
import '../../../../controllers/usage_controller.dart';
import '../../../../models/model.dart';
import '../../../../models/chat/session.dart';
import '../../../../models/chat/usage.dart';
import '../../services/usage_loader.dart';
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
  int _rangePresetDays = 0;
  final _showTokens = ValueNotifier<bool>(true);
  List<UsageChartPoint> _chartData = [];
  bool _chartLoading = false;
  UsageStats? _stats;

  // 全局视图：真实用量（usage_rows）聚合，加载完成前回退到会话缓存求和
  UsageStats? _globalStats;
  final Map<String, _ModelUsage> _globalModelStats = {};
  final Map<String, UsageStats> _globalSessionStats = {};

  // 会话视图：按实际使用模型聚合的用量（用于分别展示智能选模命中的模型）
  final Map<String, _ModelUsage> _sessionModelStats = {};

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

    DateTime? start = _rangeStart;
    DateTime? end = _rangeEnd;
    if (start == null) {
      final range = _rangeForPreset(_rangePresetDays);
      start = range.$1;
      end = range.$2;
      if (mounted) {
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
          _granularity = _rangePresetDays <= 1 ? 'hour' : 'day';
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
      // 按模型聚合：单会话下分别统计各「实际使用模型」的用量（含智能选模命中的轻量模型）
      final details = await UsageController.instance.loadDetails(
        sessionId: session.sessionId,
        start: start,
        end: end,
      );
      final modelStats = <String, _ModelUsage>{};
      final modelMap = <String, ChatModel>{};
      final configuredModel = session.chatModel;
      if (configuredModel != null) {
        _indexModelAliases(modelMap, configuredModel);
      }
      for (final d in details) {
        // UsageDetail.modelId 即「实际调用模型」的 API 模型名（如 deepseek-v4-flash），直接作为分组键
        final key = d.modelId.isEmpty ? 'unknown' : d.modelId;
        final ms = modelStats.putIfAbsent(key, () => _ModelUsage());
        ms.chatModel ??= modelMap[key];
        ms.model = d.modelId;
        ms.sessionCount++;
        ms.promptTokens += d.promptTokens;
        ms.completionTokens += d.completionTokens;
      }
      if (mounted) {
        setState(() {
          _chartData = data;
          _stats = stats;
          _sessionModelStats
            ..clear()
            ..addAll(modelStats);
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
        if (m != null) _indexModelAliases(modelMap, m);
      }

      for (final d in all) {
        global.add(d);
        // UsageDetail.modelId 即「实际调用模型」的 API 模型名（如 deepseek-v4-flash），直接作为分组键
        final key = d.modelId.isEmpty ? 'unknown' : d.modelId;
        final ms = modelStats.putIfAbsent(key, () => _ModelUsage());
        ms.chatModel ??= modelMap[key];
        ms.model = d.modelId;
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

  /// 将某个模型配置「可能实际调用」的所有 API 模型名（主模型 + 智能选模候选 + 候选池）索引到该配置，
  /// 供按实际调用模型名（如 deepseek-v4-flash）分组时关联显示名与图标。
  void _indexModelAliases(Map<String, ChatModel> map, ChatModel m) {
    final names = <String>{
      if (m.model.isNotEmpty) m.model,
      if (m.lightweightModel != null && m.lightweightModel!.isNotEmpty)
        m.lightweightModel!,
      if (m.capableModel != null && m.capableModel!.isNotEmpty) m.capableModel!,
      ...m.availableModels,
    };
    for (final n in names) {
      final existing = map[n];
      // 已存在时优先保留 name 非空（更可读）的配置
      if (existing == null || existing.name.isEmpty) map[n] = m;
    }
  }

  (DateTime, DateTime) _rangeForPreset(int days) {
    final now = DateTime.now();
    if (days == 0) {
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(start.year, start.month, start.day, 23, 59, 59, 999);
      return (start, end);
    }
    final end = now;
    final start = now.subtract(Duration(days: days));
    return (start, end);
  }

  Future<void> _onRangePresetChanged(int days) async {
    final range = _rangeForPreset(days);
    setState(() {
      _rangePresetDays = days;
      _granularity = days <= 1 ? 'hour' : 'day';
      _rangeStart = range.$1;
      _rangeEnd = range.$2;
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
        Obx(() {
          final sessions = sessionController.sessions;
          final currentSession =
              sessions.cast<ChatSession?>().firstWhere(
                (s) => s?.sessionId == session.sessionId,
                orElse: () => null,
              ) ??
              session;

          final promptTokens =
              _stats?.promptTokens ?? currentSession.promptTokens;
          final completionTokens =
              _stats?.completionTokens ?? currentSession.completionTokens;
          final totalTokens = promptTokens + completionTokens;
          final cacheWriteTokens = _stats?.cacheWriteTokens ?? 0;
          final cacheReadTokens = _stats?.cacheReadTokens ?? 0;
          final requestCount =
              (_stats?.requests ?? 0) > 0
                  ? _stats!.requests
                  : currentSession.messages
                      .where((m) => m.role.name == 'bot' && !m.isError)
                      .length;
          final costText =
              _stats != null && _stats!.costsByCurrency.isNotEmpty
                  ? _formatCost(_stats!.costsByCurrency)
                  : _formatSessionCost(currentSession);
          final quotaEnabled = currentSession.quotaEnabled;
          final tokenLimit = currentSession.quotaTokenLimit;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUsageHeader(theme, isDark),
              const SizedBox(height: 28),
              _buildUsageMetricGrid(
                theme,
                isDark,
                requestCount: requestCount,
                costText: costText,
                totalTokens: totalTokens,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                cacheWriteTokens: cacheWriteTokens,
                cacheReadTokens: cacheReadTokens,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 360,
                child:
                    _chartLoading
                        ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                        )
                        : UsageCurveChart(
                          data: _chartData,
                          showTokens: _showTokens.value,
                          granularity: _granularity,
                          rangeLabel: _rangePresetLabel(_rangePresetDays),
                        ),
              ),
              if (_sessionModelStats.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildSectionTitle(theme, l10n.byModel),
                const SizedBox(height: 12),
                _buildSessionModelUsage(theme, isDark, l10n),
              ],
              if (quotaEnabled) ...[
                const SizedBox(height: 28),
                _buildSectionTitle(theme, l10n.quotaLimitSection),
                const SizedBox(height: 12),
                _buildQuotaCard(theme, isDark, totalTokens, tokenLimit, l10n),
              ],
            ],
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  /// 会话视图：按实际使用模型分组的用量明细（token 降序）
  Widget _buildSessionModelUsage(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final entries =
        _sessionModelStats.entries.toList()..sort(
          (a, b) => (b.value.promptTokens + b.value.completionTokens).compareTo(
            a.value.promptTokens + a.value.completionTokens,
          ),
        );
    return Column(
      children: [
        for (final entry in entries) ...[
          _buildModelUsageRow(
            theme,
            isDark,
            entry.key,
            entry.value,
            l10n,
            showAsRequests: true,
          ),
          const SizedBox(height: 8),
        ],
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
              _buildModelDistributionCard(
                theme,
                isDark,
                _modelDistributionEntries(modelStats),
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
      final m = session.chatModel;
      // 与真实用量聚合一致：以 API 模型名（model）分组，而非配置记录 id / 显示名
      final modelKey = m != null && m.model.isNotEmpty ? m.model : 'Unknown';
      final stat = map.putIfAbsent(modelKey, () => _ModelUsage());
      stat.chatModel ??= m;
      stat.model = modelKey;
      stat.sessionCount++;
      stat.promptTokens += session.promptTokens;
      stat.completionTokens += session.completionTokens;
    }
    return map;
  }

  // ==================== 共用组件 ====================

  Widget _buildUsageHeader(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '使用统计',
              style: TextStyle(
                fontSize: compact ? 28 : 32,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '按日期范围查看请求、Token、缓存和成本',
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        );

        final selector = _buildRangeSegmentedControl(theme, isDark);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: selector,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 20),
            selector,
          ],
        );
      },
    );
  }

  Widget _buildRangeSegmentedControl(ThemeData theme, bool isDark) {
    final options = [(0, '今天'), (1, '1天'), (7, '7天'), (14, '14天'), (30, '30天')];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            options.map((option) {
              final selected = _rangePresetDays == option.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => _onRangePresetChanged(option.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? (isDark
                                  ? const Color(0xFF111827)
                                  : Colors.white)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow:
                          selected && !isDark
                              ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            selected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.55,
                                ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildUsageMetricGrid(
    ThemeData theme,
    bool isDark, {
    required int requestCount,
    required String costText,
    required int totalTokens,
    required int promptTokens,
    required int completionTokens,
    required int cacheWriteTokens,
    required int cacheReadTokens,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns =
            width >= 840
                ? 4
                : width >= 720
                ? 2
                : 1;
        final spacing = 16.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildMetricCard(
              theme,
              isDark,
              width: itemWidth,
              compact: columns == 4 && itemWidth < 220,
              title: '总请求数',
              value: _formatInteger(requestCount),
              icon: Icons.monitor_heart_outlined,
              accent: const Color(0xFF3B82F6),
              accentBackground: const Color(0xFFDBEAFE),
            ),
            _buildMetricCard(
              theme,
              isDark,
              width: itemWidth,
              compact: columns == 4 && itemWidth < 220,
              title: '总成本',
              value: costText,
              icon: Icons.attach_money_rounded,
              accent: const Color(0xFFA855F7),
              accentBackground: const Color(0xFFF3E8FF),
            ),
            _buildMetricCard(
              theme,
              isDark,
              width: itemWidth,
              compact: columns == 4 && itemWidth < 220,
              title: '总 Token 数',
              value: _formatTokenCount(totalTokens),
              icon: Icons.layers_outlined,
              accent: const Color(0xFF10B981),
              accentBackground: const Color(0xFFD1FAE5),
              footer:
                  '输入 ${_formatTokenCount(promptTokens)}    输出 ${_formatTokenCount(completionTokens)}',
            ),
            _buildMetricCard(
              theme,
              isDark,
              width: itemWidth,
              compact: columns == 4 && itemWidth < 220,
              title: '缓存 Token',
              value: _formatTokenCount(cacheWriteTokens + cacheReadTokens),
              icon: Icons.storage_rounded,
              accent: const Color(0xFFF97316),
              accentBackground: const Color(0xFFFFEDD5),
              footer:
                  '写入 ${_formatTokenCount(cacheWriteTokens)}    命中 ${_formatTokenCount(cacheReadTokens)}',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    bool isDark, {
    required double width,
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required Color accentBackground,
    bool compact = false,
    String? footer,
  }) {
    return SizedBox(
      width: width,
      height: 154,
      child: Container(
        padding:
            compact
                ? const EdgeInsets.fromLTRB(16, 18, 16, 16)
                : const EdgeInsets.fromLTRB(22, 20, 22, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE1E4E8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? accent.withValues(alpha: 0.16)
                            : accentBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: compact ? 21 : 23),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 24 : 28,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  height: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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

  /// 按模型总用量降序排列，供「模型总用量分布」卡片使用
  List<MapEntry<String, _ModelUsage>> _modelDistributionEntries(
    Map<String, _ModelUsage> stats,
  ) {
    final entries = stats.entries.toList();
    entries.sort(
      (a, b) => (b.value.promptTokens + b.value.completionTokens).compareTo(
        a.value.promptTokens + a.value.completionTokens,
      ),
    );
    return entries;
  }

  Color _distributionColor(int index) {
    const palette = [
      Color(0xFF3B82F6),
      Color(0xFF7C3AED),
      Color(0xFF059669),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF84CC16),
      Color(0xFFF97316),
    ];
    return palette[index % palette.length];
  }

  Widget _modelShareLegendItem(
    ThemeData theme,
    Color color,
    String name,
    int tokens,
    int total,
    AppLocalizations l10n,
  ) {
    final pct = total > 0 ? (tokens / total * 100) : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(color),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${pct.toStringAsFixed(1)}% · ${_formatTokenCount(tokens)}',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildModelDistributionCard(
    ThemeData theme,
    bool isDark,
    List<MapEntry<String, _ModelUsage>> entries,
    AppLocalizations l10n,
  ) {
    final total = entries.fold<int>(
      0,
      (sum, e) => sum + e.value.promptTokens + e.value.completionTokens,
    );
    final hasData = entries.isNotEmpty && total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child:
          !hasData
              ? Text(
                l10n.noUsageData,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
                      width: double.infinity,
                      child: Row(
                        children: [
                          for (var i = 0; i < entries.length; i++)
                            Expanded(
                              flex: ((entries[i].value.promptTokens +
                                          entries[i].value.completionTokens) /
                                      total *
                                      1000)
                                  .round()
                                  .clamp(1, 1000),
                              child: Container(color: _distributionColor(i)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        _modelShareLegendItem(
                          theme,
                          _distributionColor(i),
                          _modelDisplayName(entries[i].value, entries[i].key),
                          entries[i].value.promptTokens +
                              entries[i].value.completionTokens,
                          total,
                          l10n,
                        ),
                    ],
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
    AppLocalizations l10n, {
    bool showAsRequests = false,
  }) {
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
                  _modelDisplayName(usage, name),

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
                showAsRequests
                    ? l10n.requestsCountSuffix(usage.sessionCount)
                    : l10n.sessionsCountSuffix(usage.sessionCount),
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

  /// 模型行显示名：优先显示用量记录里实际调用的 API 模型名（usage.model，如 deepseek-v4-flash），
  /// 其次取配置模型名，最后把分组键美化为可读名兜底
  String _modelDisplayName(_ModelUsage usage, String name) {
    final model = usage.model;
    if (model != null && model.isNotEmpty) return model;
    final apiModel = usage.chatModel?.model;
    if (apiModel != null && apiModel.isNotEmpty) return apiModel;
    return _friendlyModelName(name);
  }

  /// 把裸模型 id（如 deepseek-v4-flash）美化为可读名称（chatModel 缺失时兜底）。
  /// 配置记录 id（`model<uuid>`）无法还原为可读名时返回 Unknown Model。
  static String _friendlyModelName(String id) {
    if (id.isEmpty ||
        id == 'unknown' ||
        RegExp(r'^model[0-9a-f-]{20,}$').hasMatch(id)) {
      return 'Unknown Model';
    }
    final parts = id.split(RegExp(r'[-_]'));
    final buf = StringBuffer();
    var first = true;
    for (final p in parts) {
      if (p.isEmpty) continue;
      if (!first) buf.write(' ');
      first = false;
      buf.write(p[0].toUpperCase());
      buf.write(p.substring(1));
    }
    return buf.isEmpty ? id : buf.toString();
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

  String _formatInteger(int count) {
    final text = count.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  String _formatCost(Map<String, double>? costsByCurrency) {
    if (costsByCurrency == null || costsByCurrency.isEmpty) return '\$0.00';
    final entries =
        costsByCurrency.entries.where((e) => e.value != 0).toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return '\$0.00';
    if (entries.length == 1) {
      final entry = entries.first;
      final symbol = entry.key.toUpperCase() == 'CNY' ? '¥' : '\$';
      return '$symbol${entry.value.toStringAsFixed(2)}';
    }
    return entries
        .map((e) => '${e.key.toUpperCase()} ${e.value.toStringAsFixed(2)}')
        .join(' / ');
  }

  String _formatSessionCost(ChatSession session) {
    final cost = session.totalCost;
    if (cost <= 0) return '\$0.00';
    final currency = session.chatModel?.currency?.toUpperCase() ?? 'USD';
    final symbol = currency == 'CNY' ? '¥' : '\$';
    return '$symbol${cost.toStringAsFixed(2)}';
  }

  String _rangePresetLabel(int days) {
    if (days == 0) return '今天';
    return '$days天';
  }
}

class _ModelUsage {
  int sessionCount = 0;
  int promptTokens = 0;
  int completionTokens = 0;

  ChatModel? chatModel;

  /// 每条用量记录对应的实际调用模型（直接取自 UsageDetail.modelId，如 deepseek-v4-flash）
  String? model;
}
