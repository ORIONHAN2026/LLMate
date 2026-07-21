import 'dart:convert';

import 'audit_types.dart';

/// 单条审计事件
///
/// 持久化于 DuckDB `audit.duckdb` 的 `audit_events` 表。采用 span 模型：
/// 每条事件归属一个 [traceId]，并以 [spanId] / [parentSpanId] 表达调用层级，
/// 便于对一次请求进行「链路追踪」与回放（[ReplayService]）。
class AuditEvent {
  final String id;
  final String traceId;
  final String spanId;
  final String? parentSpanId;

  final String sessionId;

  final AuditEventType type;
  final DateTime timestamp;

  final Map<String, dynamic> payload;

  AuditEvent({
    required this.id,
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    required this.sessionId,
    required this.type,
    required this.timestamp,
    required this.payload,
  });

  /// 由数据库行（列名 → 值）构造。列名统一以小写匹配，避免大小写差异。
  factory AuditEvent.fromRow(Map<String, dynamic> row) {
    final payloadStr = row['payload_json'];
    final payload =
        payloadStr is String
            ? (jsonDecode(payloadStr) as Map<String, dynamic>)
            : <String, dynamic>{};
    return AuditEvent(
      id: row['id'] as String? ?? '',
      traceId: row['trace_id'] as String? ?? '',
      spanId: row['span_id'] as String? ?? '',
      parentSpanId: row['parent_span_id'] as String?,
      sessionId: (row['session_id'] as String?) ?? '',
      type: AuditEventTypeX.fromName((row['event_type'] as String?) ?? 'request'),
      timestamp:
          DateTime.tryParse((row['timestamp'] as String?) ?? '') ??
          DateTime.now(),
      payload: payload,
    );
  }

  /// 用于对外 API / 序列化的通用 JSON 表达
  Map<String, dynamic> toJson() => {
    'id': id,
    'traceId': traceId,
    'spanId': spanId,
    if (parentSpanId != null) 'parentSpanId': parentSpanId,
    'sessionId': sessionId,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'payload': payload,
  };
}
