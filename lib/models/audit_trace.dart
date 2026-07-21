/// 审计链路（Trace）
///
/// 一次完整业务交互（如一次 Chat Completion 请求）对应一条 Trace，
/// 之下挂载多个 [AuditEvent]（prompt / llmRequest / toolStart ...）。
class AuditTrace {
  final String traceId;
  final String sessionId;
  final String userId;

  AuditTrace({
    required this.traceId,
    required this.sessionId,
    required this.userId,
  });
}
