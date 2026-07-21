import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../controllers/audit_controller.dart';
import '../../../data/database.dart';
import '../../../models/audit_event.dart';
import '../../../models/audit_types.dart';
import '../../../models/chat/session.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/standard_app_bar.dart';

/// 审计查看器
///
/// 提供审计事件的检索（按 trace / session / user / tenant / agent / 事件类型 /
/// 时间范围）与链路回放入口。底层数据来自 [AuditController] 的 DuckDB 存储。
class AuditViewer extends StatefulWidget {
  final ChatSession? session;

  const AuditViewer({super.key, this.session});

  static void show(BuildContext context, {ChatSession? session}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuditViewer(session: session)),
    );
  }

  @override
  State<AuditViewer> createState() => _AuditViewerState();
}

class _AuditViewerState extends State<AuditViewer> {
  final _traceCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final Set<AuditEventType> _selectedTypes = {};
  DateTime? _startDate;
  DateTime? _endDate;
  int _limit = 200;

  List<_TraceGroup> _groups = [];
  /// sessionId → 会话名称 缓存，避免重复查库
  final Map<String, String> _sessionNames = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _sessionCtrl.text = widget.session!.sessionId;
    }
    _load();
  }

  @override
  void dispose() {
    _traceCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  AuditFilter _buildFilter() {
    DateTime? end;
    if (_endDate != null) {
      end = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
        999,
      );
    }
    return AuditFilter(
      traceId: _blank(_traceCtrl.text),
      sessionId: _blank(_sessionCtrl.text),
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
      final events =
          await AuditController.instance.storage.search(_buildFilter());
      // 按 traceId 聚合：一次请求 = 一条链路，列表只展示一条
      final grouped = <String, List<AuditEvent>>{};
      for (final e in events) {
        (grouped[e.traceId] ??= []).add(e);
      }
      final groups = grouped.entries
          .map((e) => _TraceGroup(e.key, e.value))
          .toList();
      // 预取所有不重复 sessionId 的会话名称
      await _populateSessionNames(events);
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

  /// 按 [events] 中不重复的 sessionId，批量查找会话名称缓存在 [_sessionNames]
  Future<void> _populateSessionNames(List<AuditEvent> events) async {
    final ids = events.map((e) => e.sessionId).toSet();
    for (final id in ids) {
      if (_sessionNames.containsKey(id)) continue;
      try {
        final s = await appDatabase.getSession(id);
        if (s != null) {
          _sessionNames[id] = s.name;
        }
      } catch (_) {
        // 查不到不阻塞
      }
    }
  }

  void _reset() {
    _traceCtrl.clear();
    _sessionCtrl.clear();
    setState(() {
      _selectedTypes.clear();
      _startDate = null;
      _endDate = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: '审计查看', showBottomDivider: true),
      body: Column(
        children: [
          _buildSearchPanel(),
          const Divider(height: 1),
          Expanded(child: _buildResultList()),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _field(_traceCtrl, '链路 ID (traceId)')),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_sessionCtrl, '会话 ID (sessionId)'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _limit,
                    decoration: const InputDecoration(
                      labelText: '返回上限',
                      isDense: true,
                    ),
                    items: const [50, 100, 200, 500]
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n 条'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _limit = v ?? 200),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
            const SectionTitle('事件类型'),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: AuditEventType.values.map((t) {
                final selected = _selectedTypes.contains(t);
                return FilterChip(
                  label: Text(t.name),
                  selected: selected,
                  visualDensity: VisualDensity.compact,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedTypes.add(t);
                    } else {
                      _selectedTypes.remove(t);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(true),
                    child: Text(_startDate == null
                        ? '开始日期'
                        : '起: ${_fmt(_startDate!)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(false),
                    child: Text(_endDate == null
                        ? '结束日期'
                        : '止: ${_fmt(_endDate!)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('搜索'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _reset,
                  child: const Text('重置'),
                ),
                const Spacer(),
                Text('共 ${_groups.length} 条链路',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      onSubmitted: (_) => _load(),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }

  Widget _buildResultList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('加载失败: $_error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            )),
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = _groups[i];
              final first = g.events.first;
              final sessionName = _sessionNames[first.sessionId];
              return Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primary.withOpacity(0.12),
                    foregroundColor: cs.primary,
                    child: Text('${g.events.length}'),
                  ),
                  title: Text(
                    sessionName ?? first.sessionId,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${_shortId(g.traceId)}  ·  ${g.events.length} 个事件  ·  ${_fmt(first.timestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
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
      MaterialPageRoute(
        builder: (_) => AuditReplayPage(traceId: traceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(title: '审计回放', showBottomDivider: true),
      body: FutureBuilder<(List<AuditEvent>, String?)>(
        future: () async {
          final events =
              await AuditController.instance.storage.loadTrace(traceId);
          String? sessionName;
          if (events.isNotEmpty) {
            final s =
                await appDatabase.getSession(events.first.sessionId);
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
              child: Text('加载失败: ${snap.error}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  )),
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
            color: cs.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
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
                  color: cs.onSurface.withOpacity(0.5),
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
        color: cs.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: cs.primary.withOpacity(0.12),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'span: ${e.spanId}',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(
                  json,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
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
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      type.name,
      style: TextStyle(fontSize: 11, color: color),
    ),
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

String _shortId(String id) =>
    id.length > 10 ? '${id.substring(0, 10)}…' : id;

/// 按 traceId 聚合的「一次请求 = 一条链路」分组
class _TraceGroup {
  final String traceId;
  final List<AuditEvent> events;
  _TraceGroup(this.traceId, this.events);
}
