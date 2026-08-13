import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../controllers/audit_controller.dart';
import '../../../data/database.dart';
import '../../../models/audit.dart';
import '../../../models/chat/session.dart';
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
  final Set<AuditEventType> _selectedTypes = {};
  DateTime? _startDate;
  DateTime? _endDate;
  static const int _limit = 50;

  List<_TraceGroup> _groups = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 开始 / 结束时间默认取当日 00:00:00 ~ 23:59:59
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _load();
  }

  @override
  void dispose() {
    _traceCtrl.dispose();
    super.dispose();
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
      limit: _limit,
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
      final events = await AuditController.instance.storage.search(
        _buildFilter(),
      );
      // 按 traceId 聚合：一次请求 = 一条链路，列表只展示一条
      final grouped = <String, List<AuditEvent>>{};
      for (final e in events) {
        (grouped[e.traceId] ??= []).add(e);
      }
      final groups =
          grouped.entries.map((e) => _TraceGroup(e.key, e.value)).toList();
      // 链路按时间倒序排列（最新链路在前）；事件本身为时间升序，取末位即最新
      groups.sort(
        (a, b) => b.events.last.timestamp.compareTo(a.events.last.timestamp),
      );
      if (mounted) {
        setState(() {
          _groups = groups;
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
    final cs = Theme.of(context).colorScheme;
    final content = Column(
      children: [_buildSearchPanel(), Expanded(child: _buildResultList())],
    );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const StandardAppBar(title: '审计查看', showBottomDivider: true),
      body: content,
    );
  }

  Widget _buildSearchPanel() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(1),
      color: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 400,
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _traceCtrl,
                      onSubmitted: (_) => _load(),
                      style: TextStyle(fontSize: 13),
                      decoration: _inputDecoration('链路 ID (traceId)'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _dateButton(true)),
                const SizedBox(width: 8),
                Expanded(child: _dateButton(false)),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('搜索', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: _reset,
                    child: const Text('重置'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text(
                    '事件类型',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        AuditEventType.values.map((t) {
                          final selected = _selectedTypes.contains(t);
                          return FilterChip(
                            label: Text(t.name),
                            selected: selected,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            labelStyle: const TextStyle(fontSize: 11),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
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
      ),
    );
  }

  /// 日期选择按钮（开始 / 结束）
  Widget _dateButton(bool isStart) {
    final d = isStart ? _startDate : _endDate;
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  /// 统一的输入框装饰：对齐「添加模型」弹窗风格
  /// （圆角 6、浅灰边框、深色聚焦、紧凑内边距）
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF1F2937)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          '加载失败: $_error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (_groups.isEmpty) {
      return const Center(child: Text('无审计记录'));
    }
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SectionTitle('审计链路 (${_groups.length})'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _groups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = _groups[i];
              final first = g.events.first;
              return Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    foregroundColor: cs.primary,
                    child: Text('${g.events.length}'),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          g.traceId,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: '复制 traceId',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _copyTraceId(g.traceId),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${g.events.length} 个事件  ·  ${_fmt(first.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => AuditReplayPage.show(context, g.traceId),
                ),
              );
            },
          ),
        ),
      ],
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
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
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
    final json = const JsonEncoder.withIndent('  ').convert(e.payload);
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
                child: SelectableText(
                  json,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
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
    case AuditEventType.prompt:
      return Colors.indigo;
    case AuditEventType.policy:
      return Colors.purple;
    case AuditEventType.memoryRead:
      return Colors.teal;
    case AuditEventType.memoryWrite:
      return Colors.cyan;
    case AuditEventType.toolStart:
      return Colors.orange;
    case AuditEventType.toolFinish:
      return Colors.deepOrange;
    case AuditEventType.llmRequest:
      return Colors.green;
    case AuditEventType.llmResponse:
      return Colors.lightGreen;
    case AuditEventType.response:
      return Colors.green.shade700;
    case AuditEventType.error:
      return Colors.red;
    case AuditEventType.cost:
      return Colors.amber;
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
