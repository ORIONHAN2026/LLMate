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
