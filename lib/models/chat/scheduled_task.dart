/// 定时任务模型
///
/// 使用 cron 表达式定义触发规则，到时间自动发送预设消息。
class ScheduledTask {
  /// 任务唯一ID
  final String id;

  /// cron 表达式（5字段：分 时 日 月 周）
  /// 例："0 9 * * *" 每天9点，"*/30 * * * *" 每30分钟
  final String cronExpression;

  /// 定时发送的消息内容
  final String message;

  /// 是否启用
  final bool enabled;

  /// 上次触发时间
  final DateTime? lastTriggeredAt;

  /// 创建时间
  final DateTime createdAt;

  ScheduledTask({
    required this.id,
    required this.cronExpression,
    required this.message,
    this.enabled = true,
    this.lastTriggeredAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ScheduledTask copyWith({
    String? id,
    String? cronExpression,
    String? message,
    bool? enabled,
    DateTime? lastTriggeredAt,
    bool clearLastTriggered = false,
  }) {
    return ScheduledTask(
      id: id ?? this.id,
      cronExpression: cronExpression ?? this.cronExpression,
      message: message ?? this.message,
      enabled: enabled ?? this.enabled,
      lastTriggeredAt:
          clearLastTriggered ? null : (lastTriggeredAt ?? this.lastTriggeredAt),
      createdAt: createdAt,
    );
  }

  /// 人性化描述 cron 表达式
  String get humanReadable {
    try {
      final parts = cronExpression.trim().split(RegExp(r'\s+'));
      if (parts.length != 5) return cronExpression;
      final minute = parts[0];
      final hour = parts[1];
      final dayOfMonth = parts[2];
      final month = parts[3];
      final dayOfWeek = parts[4];

      // 每天固定时间
      if (dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
        if (minute.contains('/')) {
          final interval = minute.split('/').last;
          return '每隔${interval}分钟';
        }
        if (hour == '*' && minute == '*') return '每分钟';
        return '每天${hour}:${minute.padLeft(2, '0')}';
      }

      // 每周
      if (dayOfMonth == '*' && month == '*' && dayOfWeek != '*') {
        final weekNames = {'0': '周日', '1': '周一', '2': '周二', '3': '周三', '4': '周四', '5': '周五', '6': '周六'};
        return '每${weekNames[dayOfWeek] ?? dayOfWeek} ${hour}:${minute.padLeft(2, '0')}';
      }

      return cronExpression;
    } catch (_) {
      return cronExpression;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cronExpression': cronExpression,
    'message': message,
    'enabled': enabled,
    'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    return ScheduledTask(
      id: json['id'] ?? '',
      cronExpression: json['cronExpression'] ?? '',
      message: json['message'] ?? '',
      enabled: json['enabled'] ?? true,
      lastTriggeredAt:
          json['lastTriggeredAt'] != null
              ? DateTime.tryParse(json['lastTriggeredAt'])
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}
