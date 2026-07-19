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
  final String? userId;
  final String? tenantId;
  final String? agentId;
  final Set<AuditEventType>? eventTypes;
  final DateTime? start;
  final DateTime? end;
  final int? limit;

  const AuditFilter({
    this.traceId,
    this.sessionId,
    this.userId,
    this.tenantId,
    this.agentId,
    this.eventTypes,
    this.start,
    this.end,
    this.limit,
  });
}
