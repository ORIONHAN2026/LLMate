import '../../../widgets/standard_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/session_controller.dart';
import '../../../models/model.dart';
import '../../../models/chat/session.dart';
import '../services/usage_loader.dart';
import 'usage_curve_chart.dart';

/// 使用量仪表盘
/// - global=true: 全局统计（所有会话汇总）
/// - global=false + session: 单会话统计
class UsageDashboard extends StatefulWidget {
  final ChatSession? session;
  final bool global;

  const UsageDashboard({super.key, this.session, this.global = false});

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
  final _showCost = ValueNotifier<bool>(true);
  List<UsageChartPoint> _chartData = [];
  bool _chartLoading = false;

  /// 时间区间（按粒度解释）：
  /// - 分/小时：仅取某一天，start=当天 00:00，end=当天 23:59:59.999
  /// - 天/月/年：start~end 的范围（为 null 表示不限该侧）
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    if (!widget.global && widget.session != null) {
      _loadChartData();
    }
  }

  @override
  void dispose() {
    _showTokens.dispose();
    _showCost.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    final session = widget.session;
    if (session == null) return;

    setState(() => _chartLoading = true);

    final modelId = session.chatModel?.modelId ?? 'unknown';

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
        modelId: modelId,
        granularity: _granularity,
        start: start,
        end: end,
      );
      if (mounted) {
        setState(() {
          _chartData = data;
          _chartLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chartLoading = false);
      }
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

    if (session == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar('使用量仪表盘'),
        body: Center(
          child: Text(
            '暂无会话数据',
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar('${session.name} 使用量'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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

              final promptTokens = currentSession.promptTokens;
              final completionTokens = currentSession.completionTokens;
              final totalTokens = promptTokens + completionTokens;
              final totalCost = currentSession.totalCost;
              final messageCount = currentSession.messages.length;
              final modelName = currentSession.chatModel?.name ?? 'Unknown';
              final quotaEnabled = currentSession.quotaEnabled;
              final tokenLimit = currentSession.quotaTokenLimit;
              final costLimit = currentSession.quotaCostLimit;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, '概览'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatCard(
                        theme,
                        isDark: isDark,
                        title: '消息数',
                        value: '$messageCount',
                        icon: Icons.message_outlined,
                        accentColor: const Color(0xFF7C3AED),
                      ),
                      _buildStatCard(
                        theme,
                        isDark: isDark,
                        title: '输入 Token',
                        value: _formatTokenCount(promptTokens),
                        icon: Icons.arrow_upward,
                        accentColor: const Color(0xFF2563EB),
                      ),
                      _buildStatCard(
                        theme,
                        isDark: isDark,
                        title: '输出 Token',
                        value: _formatTokenCount(completionTokens),
                        icon: Icons.arrow_downward,
                        accentColor: const Color(0xFF059669),
                      ),
                      _buildStatCard(
                        theme,
                        isDark: isDark,
                        title: '总费用',
                        value:
                            '${_getCurrencySymbol(currentSession.chatModel)}${totalCost.toStringAsFixed(4)}',
                        icon: Icons.attach_money,
                        accentColor: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(theme, 'Token 分布'),
                  const SizedBox(height: 12),
                  _buildTokenDistributionCard(
                    theme,
                    isDark,
                    promptTokens,
                    completionTokens,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(theme, '模型信息'),
                  const SizedBox(height: 12),
                  _buildSessionModelInfoCard(
                    theme,
                    isDark,
                    currentSession.chatModel,
                    modelName,
                    promptTokens,
                    completionTokens,
                    totalCost,
                  ),
                  if (quotaEnabled) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, '配额限制'),
                    const SizedBox(height: 12),
                    _buildQuotaCard(
                      theme,
                      isDark,
                      totalTokens,
                      totalCost,
                      tokenLimit,
                      costLimit,
                      currentSession.chatModel,
                    ),
                  ],
                ],
              );
            }),

            // ===== 用量曲线 (独立于 Obx，依赖 _chartData state) =====
            const SizedBox(height: 24),
            _buildSectionTitle(theme, '用量曲线'),
            const SizedBox(height: 12),
            _buildGranularitySelector(theme, isDark),
            const SizedBox(height: 12),
            _buildDateRangeSelector(theme, isDark),
            const SizedBox(height: 12),
            _buildChartToggle(theme),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      )
                      : ValueListenableBuilder<bool>(
                        valueListenable: _showTokens,
                        builder:
                            (_, showToken, _1) => ValueListenableBuilder<bool>(
                              valueListenable: _showCost,
                              builder:
                                  (_, showCost, _2) => UsageCurveChart(
                                    data: _chartData,
                                    showTokens: showToken,
                                    showCost: showCost,
                                    currencySymbol: _getCurrencySymbol(
                                      session.chatModel,
                                    ),
                                    granularity: _granularity,
                                  ),
                            ),
                      ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ==================== 全局视图 ====================

  Widget _buildGlobalView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessionController = Get.find<SessionController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar('全局使用量仪表盘'),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无使用数据',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        final totalPrompt = sessions.fold<int>(
          0,
          (s, session) => s + session.promptTokens,
        );
        final totalCompletion = sessions.fold<int>(
          0,
          (s, session) => s + session.completionTokens,
        );
        final totalCost = sessions.fold<double>(
          0,
          (s, session) => s + session.totalCost,
        );
        final totalMessages = sessions.fold<int>(
          0,
          (s, session) => s + session.messages.length,
        );

        // 按模型分组
        final modelStats = <String, _ModelUsage>{};
        for (final session in sessions) {
          final modelName = session.chatModel?.name ?? 'Unknown';
          modelStats.putIfAbsent(modelName, () => _ModelUsage());
          final stat = modelStats[modelName]!;
          stat.chatModel ??= session.chatModel;
          stat.sessionCount++;
          stat.promptTokens += session.promptTokens;
          stat.completionTokens += session.completionTokens;
          stat.totalCost += session.totalCost;
        }

        final sortedWithTokens =
            sessions
                .where((s) => s.promptTokens + s.completionTokens > 0)
                .toList()
              ..sort(
                (a, b) => (b.promptTokens + b.completionTokens).compareTo(
                  a.promptTokens + a.completionTokens,
                ),
              );
        final emptyCount =
            sessions
                .where((s) => s.promptTokens + s.completionTokens == 0)
                .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(theme, '概览'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: '总会话数',
                    value: '${sessions.length}',
                    icon: Icons.chat_bubble_outline,
                    accentColor: const Color(0xFF2563EB),
                  ),
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: '总消息数',
                    value: '$totalMessages',
                    icon: Icons.message_outlined,
                    accentColor: const Color(0xFF7C3AED),
                  ),
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: '总 Token',
                    value: _formatTokenCount(totalPrompt + totalCompletion),
                    icon: Icons.token_outlined,
                    accentColor: const Color(0xFF059669),
                  ),
                  _buildStatCard(
                    theme,
                    isDark: isDark,
                    title: '总费用',
                    value: '\$${totalCost.toStringAsFixed(4)}',
                    icon: Icons.attach_money,
                    accentColor: const Color(0xFFDC2626),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, 'Token 分布'),
              const SizedBox(height: 12),
              _buildTokenDistributionCard(
                theme,
                isDark,
                totalPrompt,
                totalCompletion,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, '按模型统计'),
              const SizedBox(height: 12),
              ...modelStats.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildModelUsageRow(
                    theme,
                    isDark,
                    entry.key,
                    entry.value,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(theme, '所有会话'),
              const SizedBox(height: 12),
              if (sortedWithTokens.isEmpty)
                _buildEmptySessionsHint(theme)
              else ...[
                ...sortedWithTokens
                    .take(8)
                    .map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildSessionUsageRow(theme, isDark, session),
                      ),
                    ),
                if (emptyCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '另有 $emptyCount 个会话暂无使用数据',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
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
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme, {
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(height: 12),
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
                color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
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
  ) {
    final total = totalPrompt + totalCompletion;
    final promptRatio = total > 0 ? totalPrompt / total : 0.0;
    final completionRatio = total > 0 ? totalCompletion / total : 0.0;
    final accentBlue = const Color(0xFF2563EB);
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
                '输入: ${_formatTokenCount(totalPrompt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _legendDot(accentPurple),
              const SizedBox(width: 6),
              Text(
                '输出: ${_formatTokenCount(totalCompletion)}',
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

  Widget _buildSessionModelInfoCard(
    ThemeData theme,
    bool isDark,
    ChatModel? chatModel,
    String modelName,
    int promptTokens,
    int completionTokens,
    double totalCost,
  ) {
    final total = promptTokens + completionTokens;
    final promptRatio = total > 0 ? promptTokens / total : 0.0;
    final completionRatio = total > 0 ? completionTokens / total : 0.0;
    final accentBlue = const Color(0xFF2563EB);
    final accentPurple = const Color(0xFF7C3AED);

    return Container(
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
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child:
                    chatModel?.buildIconWidget(false) ??
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  modelName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${_formatTokenCount(total)} · ${_getCurrencySymbol(chatModel)}${totalCost.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _legendDot(accentBlue),
                const SizedBox(width: 4),
                Text(
                  '输入 ${_formatTokenCount(promptTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                _legendDot(accentPurple),
                const SizedBox(width: 4),
                Text(
                  '输出 ${_formatTokenCount(completionTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
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

  Widget _buildQuotaCard(
    ThemeData theme,
    bool isDark,
    int totalTokens,
    double totalCost,
    int? tokenLimit,
    double? costLimit,
    ChatModel? chatModel,
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
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Token 用量',
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
                    color: Color(0xFF2563EB),
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
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
          if (costLimit != null && costLimit > 0) ...[
            if (tokenLimit != null && tokenLimit > 0)
              const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '费用用量',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${_getCurrencySymbol(chatModel)}${totalCost.toStringAsFixed(4)} / ${_getCurrencySymbol(chatModel)}${costLimit.toStringAsFixed(4)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value:
                    costLimit > 0
                        ? (totalCost / costLimit).clamp(0.0, 1.0)
                        : 0.0,
                minHeight: 6,
                backgroundColor:
                    isDark ? const Color(0xFF1A1B23) : const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalCost > costLimit
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
          if ((tokenLimit == null || tokenLimit <= 0) &&
              (costLimit == null || costLimit <= 0))
            Text(
              '未设置配额限制',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
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
  ) {
    final modelTotal = usage.promptTokens + usage.completionTokens;
    final promptRatio = modelTotal > 0 ? usage.promptTokens / modelTotal : 0.0;
    final completionRatio =
        modelTotal > 0 ? usage.completionTokens / modelTotal : 0.0;
    final accentBlue = const Color(0xFF2563EB);
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
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                '${_formatTokenCount(modelTotal)} · ${_getCurrencySymbol(usage.chatModel)}${usage.totalCost.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${usage.sessionCount}个会话',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
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
                  '输入 ${_formatTokenCount(usage.promptTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                _legendDot(accentPurple),
                const SizedBox(width: 4),
                Text(
                  '输出 ${_formatTokenCount(usage.completionTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
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

  Widget _buildEmptySessionsHint(ThemeData theme) {
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
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无使用数据',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
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
  ) {
    final total = session.promptTokens + session.completionTokens;
    final promptRatio = total > 0 ? session.promptTokens / total : 0.0;
    final completionRatio = total > 0 ? session.completionTokens / total : 0.0;
    final accentBlue = const Color(0xFF2563EB);
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
                '${_formatTokenCount(total)} · ${_getCurrencySymbol(session.chatModel)}${session.totalCost.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
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
                  '输入 ${_formatTokenCount(session.promptTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const Spacer(),
                _legendDot(accentPurple),
                const SizedBox(width: 4),
                Text(
                  '输出 ${_formatTokenCount(session.completionTokens)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
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

  /// 获取模型对应的货币符号
  String _getCurrencySymbol(ChatModel? model) {
    return model?.currency == 'CNY' ? '¥' : '\$';
  }

  // ==================== 用量曲线 ====================

  Widget _buildGranularitySelector(ThemeData theme, bool isDark) {
    const options = [
      ('分', 'minute'),
      ('小时', 'hour'),
      ('天', 'day'),
      ('月', 'month'),
      ('年', 'year'),
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
                          ? const Color(0xFF2563EB)
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
                            : theme.colorScheme.onSurface.withOpacity(0.6),
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
  Widget _buildDateRangeSelector(ThemeData theme, bool isDark) {
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
            color: theme.colorScheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(width: 6),
          _dateChip(
            theme: theme,
            bg: chipBg,
            borderColor: borderColor,
            label: day == null ? '选择日期' : _fmtByGran(day),
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
          color: theme.colorScheme.onSurface.withOpacity(0.45),
        ),
        const SizedBox(width: 6),
        _dateChip(
          theme: theme,
          bg: chipBg,
          borderColor: borderColor,
          label: _rangeStart == null ? '开始' : _fmtByGran(_rangeStart!),
          onTap: () => _pickRange(isStart: true),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
        _dateChip(
          theme: theme,
          bg: chipBg,
          borderColor: borderColor,
          label: _rangeEnd == null ? '结束' : _fmtByGran(_rangeEnd!),
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
                color: theme.colorScheme.onSurface.withOpacity(0.4),
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
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  /// 分/小时：选择某一天
  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: '选择日期',
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
    final current =
        isStart ? _rangeStart ?? DateTime.now() : _rangeEnd ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: isStart ? '开始日期' : '结束日期',
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

  Widget _buildChartToggle(ThemeData theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showTokens,
      builder:
          (_, showToken, _1) => ValueListenableBuilder<bool>(
            valueListenable: _showCost,
            builder:
                (_, showCost, _2) => Row(
                  children: [
                    _toggleChip(
                      theme: theme,
                      label: 'Token',
                      color: const Color(0xFF2563EB),
                      selected: showToken,
                      onTap: () => _showTokens.value = !_showTokens.value,
                    ),
                    const SizedBox(width: 8),
                    _toggleChip(
                      theme: theme,
                      label: '费用',
                      color: const Color(0xFFDC2626),
                      selected: showCost,
                      onTap: () => _showCost.value = !_showCost.value,
                    ),
                  ],
                ),
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
                color: selected ? color : color.withOpacity(0.4),
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
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
  double totalCost = 0.0;
  ChatModel? chatModel;
}
