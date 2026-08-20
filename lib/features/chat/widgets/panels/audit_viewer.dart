import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../controllers/audit_controller.dart';
import '../../../../data/database.dart';
import '../../../../models/audit.dart';
import '../../../../models/chat/session.dart';
import 'package:llmate/features/widgets/json_view.dart';
import 'package:llmate/features/widgets/section_title.dart';
import 'package:llmate/features/widgets/standard_app_bar.dart';

/// 审计查看器
///
/// 提供审计事件的检索（按 trace / session / user / tenant / agent / 事件类型 /
/// 时间范围）与链路回放入口。底层数据来自 [AuditController] 的 DuckDB 存储。
class AuditViewer extends StatefulWidget {
  final ChatSession? session;

  /// 嵌入模式：为 true 时不包裹 Scaffold / AppBar，用于嵌入到会话设置 Tab 中
  final bool embedded;

  const AuditViewer({super.key, this.session, this.embedded = false});

  static void show(BuildContext context, {ChatSession? session}) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AuditViewer(session: session)));
  }

  @override
  State<AuditViewer> createState() => _AuditViewerState();
}

class _AuditViewerState extends State<AuditViewer> {
  final _traceCtrl = TextEditingController();
  final _traceFocusNode = FocusNode();
  final _scrollCtrl = ScrollController();
  final Set<AuditEventType> _selectedTypes = {};
  DateTime? _startDate;
  DateTime? _endDate;

  static const double _filterControlHeight = 40;

  /// 每页加载的链路（trace）数量
  static const int _pageSize = 20;

  List<_TraceGroup> _groups = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 开始 / 结束时间默认取当日 00:00:00 ~ 23:59:59
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _scrollCtrl.addListener(_onScroll);
    _traceFocusNode.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _traceFocusNode.dispose();
    _traceCtrl.dispose();
    super.dispose();
  }

  /// 滚动接近底部时自动加载下一页
  void _onScroll() {
    if (_scrollCtrl.hasClients && _scrollCtrl.position.extentAfter < 200) {
      _loadMore();
    }
  }

  AuditFilter _buildFilter() {
    DateTime? end;
    if (_endDate != null) {
      // 若结束时间仍是当日 00:00:00（未选择具体时分秒），则视为当日结束，
      // 否则使用用户选定的精确时间。
      final e = _endDate!;
      if (e.hour == 0 && e.minute == 0 && e.second == 0 && e.microsecond == 0) {
        end = DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
      } else {
        end = e;
      }
    }
    return AuditFilter(
      traceId: _blank(_traceCtrl.text),
      sessionId: widget.session?.sessionId,
      eventTypes: _selectedTypes.isEmpty ? null : _selectedTypes,
      start: _startDate,
      end: end,
      // 展示「最新链路」：链路按最新事件时间倒序，配合 searchTraces 分页
      orderDesc: true,
    );
  }

  String? _blank(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuditController.instance.ensureInitialized();
      final page = await AuditController.instance.storage.searchTraces(
        _buildFilter(),
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _groups = _toGroups(page.traces);
          _hasMore = page.hasMore;
          _total = page.totalTraces;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  /// 追加加载下一页链路
  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      await AuditController.instance.ensureInitialized();
      final page = await AuditController.instance.storage.searchTraces(
        _buildFilter(),
        limit: _pageSize,
        offset: _groups.length,
      );
      if (mounted) {
        setState(() {
          _groups.addAll(_toGroups(page.traces));
          _hasMore = page.hasMore;
          _total = page.totalTraces;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  /// 将分页返回的链路事件列表转换为 [_TraceGroup]（事件已按时间升序）
  List<_TraceGroup> _toGroups(List<List<AuditEvent>> traces) =>
      traces
          .where((events) => events.isNotEmpty)
          .map((events) => _TraceGroup(events.first.traceId, events))
          .toList();

  void _reset() {
    _traceCtrl.clear();
    setState(() {
      _selectedTypes.clear();
      _startDate = null;
      _endDate = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditHeader(theme),
          const SizedBox(height: 24),
          _buildSearchPanel(),
          const SizedBox(height: 20),
          Expanded(child: _buildResultList()),
        ],
      ),
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const StandardAppBar(title: '审计查看', showBottomDivider: true),
      body: content,
    );
  }

  Widget _buildAuditHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '审计查看',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '按链路、时间和事件类型追踪代理请求、模型调用、工具执行和风险事件',
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Text(
            '筛选条件',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final fields = [
                SizedBox(
                  width: compact ? double.infinity : 360,
                  child: _traceInputField(),
                ),
                SizedBox(
                  width: compact ? double.infinity : 180,
                  child: _dateButton(true),
                ),
                SizedBox(
                  width: compact ? double.infinity : 180,
                  child: _dateButton(false),
                ),
                SizedBox(
                  height: _filterControlHeight,
                  child: ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('搜索', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      fixedSize: const Size.fromHeight(_filterControlHeight),
                      minimumSize: const Size(0, _filterControlHeight),
                      maximumSize: const Size(
                        double.infinity,
                        _filterControlHeight,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: _filterControlHeight,
                  child: TextButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重置'),
                    style: TextButton.styleFrom(
                      fixedSize: const Size.fromHeight(_filterControlHeight),
                      minimumSize: const Size(0, _filterControlHeight),
                      maximumSize: const Size(
                        double.infinity,
                        _filterControlHeight,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ];
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      if (i != fields.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    fields[i],
                    if (i != fields.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Text(
                  '事件类型',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      AuditEventType.values.map((t) {
                        final selected = _selectedTypes.contains(t);
                        final color = _typeColor(t);
                        return FilterChip(
                          label: Text(t.name),
                          selected: selected,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                selected
                                    ? color
                                    : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.62,
                                    ),
                          ),
                          backgroundColor:
                              isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF4F4F5),
                          selectedColor: color.withValues(alpha: 0.12),
                          checkmarkColor: color,
                          side: BorderSide(
                            color:
                                selected
                                    ? color.withValues(alpha: 0.45)
                                    : Colors.transparent,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected:
                              (v) => setState(() {
                                if (v) {
                                  _selectedTypes.add(t);
                                } else {
                                  _selectedTypes.remove(t);
                                }
                              }),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 日期选择按钮（开始 / 结束）
  Widget _dateButton(bool isStart) {
    final d = isStart ? _startDate : _endDate;
    return SizedBox(
      height: _filterControlHeight,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          fixedSize: const Size.fromHeight(_filterControlHeight),
          minimumSize: const Size(0, _filterControlHeight),
          maximumSize: const Size(double.infinity, _filterControlHeight),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: Color(0xFFE1E4E8)),
        ),
        onPressed: () => _pickDateTime(isStart),
        child: Text(
          d == null
              ? (isStart ? '开始日期' : '结束日期')
              : (isStart ? '起: ' : '止: ') + _fmtShort(d),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _traceInputField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final focused = _traceFocusNode.hasFocus;
    return GestureDetector(
      onTap: () => _traceFocusNode.requestFocus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: _filterControlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: focused ? const Color(0xFF2563EB) : const Color(0xFFE1E4E8),
            width: focused ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _traceCtrl,
          builder: (context, value, _) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (value.text.isEmpty)
                  Text(
                    '链路 ID (traceId)',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      height: 1.2,
                    ),
                  ),
                EditableText(
                  controller: _traceCtrl,
                  focusNode: _traceFocusNode,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                  cursorColor: const Color(0xFF2563EB),
                  backgroundCursorColor: const Color(0xFF9CA3AF),
                  maxLines: 1,
                  onSubmitted: (_) => _load(),
                  textInputAction: TextInputAction.search,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 先选日期，再选精确到秒的时间
  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await _pickTime(initial ?? DateTime.now());
    if (time == null || !mounted) return;
    setState(() {
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.$1,
        time.$2,
        time.$3,
      );
      if (isStart) {
        _startDate = dt;
      } else {
        _endDate = dt;
      }
    });
  }

  /// 自定义「时:分:秒」选择弹窗，返回 (时, 分, 秒)
  Future<(int, int, int)?> _pickTime(DateTime initial) async {
    int h = initial.hour;
    int m = initial.minute;
    int s = initial.second;
    return showDialog<(int, int, int)>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSt) => AlertDialog(
                  title: const Text('选择时间'),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _timeColumn('时', 24, h, setSt, (v) => h = v),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(':'),
                      ),
                      _timeColumn('分', 60, m, setSt, (v) => m = v),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(':'),
                      ),
                      _timeColumn('秒', 60, s, setSt, (v) => s = v),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, (h, m, s)),
                      child: const Text('确定'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _timeColumn(
    String label,
    int max,
    int value,
    void Function(void Function()) setSt,
    void Function(int) onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        DropdownButton<int>(
          value: value,
          items: [
            for (int i = 0; i < max; i++)
              DropdownMenuItem(
                value: i,
                child: Text(i.toString().padLeft(2, '0')),
              ),
          ],
          onChanged: (v) {
            onChanged(v!);
            setSt(() {});
          },
        ),
      ],
    );
  }

  /// 复制链路 traceId 到剪贴板，并给出轻量提示
  void _copyTraceId(String traceId) {
    Clipboard.setData(ClipboardData(text: traceId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制 traceId: ${_shortId(traceId)}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildResultList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (_loading) {
      return _buildListShell(
        theme,
        isDark,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _buildListShell(
        theme,
        isDark,
        child: Text(
          '加载失败: $_error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    if (_groups.isEmpty) {
      return _buildListShell(
        theme,
        isDark,
        child: Text(
          '无审计记录',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '审计链路',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  _total > 0
                      ? '已加载 ${_groups.length} / $_total'
                      : '已加载 ${_groups.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _groups.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == _groups.length) return _buildFooter();
                return _buildTraceCard(_groups[i], theme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListShell(
    ThemeData theme,
    bool isDark, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE1E4E8),
        ),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildTraceCard(_TraceGroup g, ThemeData theme, bool isDark) {
    final first = g.events.first;
    final last = g.events.last;
    final errorCount =
        g.events.where((e) => e.type == AuditEventType.error).length;
    final modelEvent = g.events.where((e) => e.type == AuditEventType.model);
    final modelText =
        modelEvent.isEmpty
            ? '未记录模型'
            : (modelEvent.last.payload['model']?.toString() ?? '未知模型');
    final statusColor =
        errorCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => AuditReplayPage.show(context, g.traceId),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                errorCount > 0
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          g.traceId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: '复制 traceId',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _copyTraceId(g.traceId),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _traceMeta(
                        theme,
                        Icons.event_note_outlined,
                        '${g.events.length} 个事件',
                      ),
                      _traceMeta(theme, Icons.memory_outlined, modelText),
                      _traceMeta(
                        theme,
                        Icons.schedule_outlined,
                        _fmt(last.timestamp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _typeChip(first.type),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _traceMeta(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  /// 列表底部：加载中 / 上滑加载更多 / 已全部加载 提示
  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontSize: 12,
      color: cs.onSurface.withValues(alpha: 0.5),
    );
    Widget content;
    if (_loadingMore) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('加载中…', style: style),
        ],
      );
    } else if (_hasMore) {
      content = Text('上滑加载更多', style: style);
    } else {
      content = Text('已全部加载', style: style);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: content),
    );
  }
}

/// 审计链路回放页
///
/// 按 [traceId] 还原一次完整业务交互的事件序列（时间轴），展示每个事件的
/// 类型、发生时间与完整 payload，用于审计回溯 / 调试。
class AuditReplayPage extends StatelessWidget {
  final String traceId;

  const AuditReplayPage({super.key, required this.traceId});

  static void show(BuildContext context, String traceId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuditReplayPage(traceId: traceId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: '审计回放', showBottomDivider: true),
      body: FutureBuilder<(List<AuditEvent>, String?)>(
        future: () async {
          final events = await AuditController.instance.storage.loadTrace(
            traceId,
          );
          String? sessionName;
          if (events.isNotEmpty) {
            final s = await appDatabase.getSession(events.first.sessionId);
            sessionName = s?.name;
          }
          return (events, sessionName);
        }(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                '加载失败: ${snap.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          final (events, sessionName) = snap.data ?? (<AuditEvent>[], null);
          if (events.isEmpty) {
            return const Center(child: Text('该链路无事件'));
          }
          final first = events.first;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTraceHeader(first, sessionName, theme),
              const SizedBox(height: 12),
              SectionTitle('事件时间轴 (${events.length})'),
              const SizedBox(height: 4),
              ...events.asMap().entries.map(
                (e) => _buildEventTile(e.value, e.key, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTraceHeader(AuditEvent e, String? sessionName, ThemeData theme) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('链路信息'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.traceId,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '会话: ${sessionName ?? e.sessionId}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventTile(AuditEvent e, int index, ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            foregroundColor: cs.primary,
            child: Text('${index + 1}'),
          ),
          title: Row(
            children: [
              _typeChip(e.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _fmt(e.timestamp),
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'span: ${e.spanId}',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: JsonView(e.payload),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ── 共享工具 ──

Widget _typeChip(AuditEventType type) {
  final color = _typeColor(type);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(type.name, style: TextStyle(fontSize: 11, color: color)),
  );
}

Color _typeColor(AuditEventType type) {
  switch (type) {
    case AuditEventType.request:
      return Colors.blue;
    case AuditEventType.body:
      return Colors.brown;
    case AuditEventType.prompt:
      return Colors.indigo;
    case AuditEventType.policy:
      return Colors.purple;
    case AuditEventType.toolStart:
      return Colors.orange;
    case AuditEventType.toolFinish:
      return Colors.deepOrange;
    case AuditEventType.model:
      return Colors.green;
    case AuditEventType.usage:
      return Colors.lightGreen;
    case AuditEventType.response:
      return Colors.green.shade700;
    case AuditEventType.error:
      return Colors.red;
  }
}

String _fmt(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
}

/// 精简显示：MM-DD HH:MM:SS，用于搜索面板的日期按钮
String _fmtShort(DateTime d) {
  String p(int n) => n.toString().padLeft(2, '0');
  return '${p(d.month)}-${p(d.day)} ${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
}

String _shortId(String id) => id.length > 10 ? '${id.substring(0, 10)}…' : id;

/// 按 traceId 聚合的「一次请求 = 一条链路」分组
class _TraceGroup {
  final String traceId;
  final List<AuditEvent> events;
  _TraceGroup(this.traceId, this.events);
}
