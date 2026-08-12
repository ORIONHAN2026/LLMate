import 'dart:convert';

/// 单条审计日志条目
///
/// 持久化于 Drift / SQLite 数据库 `~/.llmate/llmate.sqlite` 的 `audit_rows` 表中。
class AuditLog {
  final String? requestId;
  final DateTime timestamp;
  final String sessionId;
  final String modelId;

  /// 第三方客户端发送的原始请求体（已按风控开关脱敏）
  final dynamic originRequest;

  /// 中间件处理后最终发送给 LLM 的请求体（已按风控开关脱敏）
  final dynamic middleRequest;

  /// 累计回复给第三方客户端的完整内容（已按风控开关脱敏）
  final String response;

  /// 若请求处理出错，记录错误信息
  final String? error;

  AuditLog({
    this.requestId,
    required this.timestamp,
    required this.sessionId,
    required this.modelId,
    this.originRequest,
    this.middleRequest,
    required this.response,
    this.error,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      requestId: json['requestId'] as String?,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      sessionId: json['sessionId'] as String? ?? '',
      modelId: json['modelId'] as String? ?? '',
      originRequest: json['originRequest'],
      middleRequest: json['middleRequest'],
      response: json['response'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (requestId != null) 'requestId': requestId,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'modelId': modelId,
      'originRequest': originRequest,
      'middleRequest': middleRequest,
      'response': response,
      if (error != null) 'error': error,
    };
  }
}

/// 审计事件类型
///
/// 对应 DuckDB `audit_events` 表中的 `event_type` 列。
enum AuditEventType {
  request,
  prompt,
  policy,
  memoryRead,
  memoryWrite,
  toolStart,
  toolFinish,
  llmRequest,
  llmResponse,
  response,
  error,
  cost,
}

/// [AuditEventType] 的便捷扩展
extension AuditEventTypeX on AuditEventType {
  /// 枚举名（与数据库存储值一致，如 `llmRequest`）
  String get name => toString().split('.').last;

  /// 由字符串解析回枚举，未知值回退到 [AuditEventType.request]
  static AuditEventType fromName(String name) =>
      AuditEventType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AuditEventType.request,
      );
}

/// 审计检索过滤器
///
/// 所有字段均为可选，提供即作为 `WHERE` 条件参与检索。
class AuditFilter {
  final String? traceId;
  final String? sessionId;
  final Set<AuditEventType>? eventTypes;
  final DateTime? start;
  final DateTime? end;
  final int? limit;

  const AuditFilter({
    this.traceId,
    this.sessionId,
    this.eventTypes,
    this.start,
    this.end,
    this.limit,
  });
}

/// 审计链路（Trace）
///
/// 一次完整业务交互（如一次 Chat Completion 请求）对应一条 Trace，
/// 之下挂载多个 [AuditEvent]（prompt / llmRequest / toolStart ...）。
class AuditTrace {
  final String traceId;
  final String sessionId;

  AuditTrace({required this.traceId, required this.sessionId});
}

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
