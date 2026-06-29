# core/scheduler/ - 定时任务调度

## 职责

基于 Cron 表达式的定时任务调度器，周期性检查会话绑定的任务并在匹配时自动发送消息。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `scheduled_task_service.dart` | 225 | 定时任务服务：每分钟检查 Cron 表达式，匹配时自动向会话发送预设消息 |

## 任务模型

```dart
class ScheduledTask {
  String cronExpression;  // Cron 表达式
  String message;         // 自动发送的消息内容
  bool enabled;           // 是否启用
}
```

## Cron 表达式格式

```
分 时 日 月 周
*  *  *  *  *
```

示例：
- `0 9 * * *` — 每天 9:00
- `*/30 * * * *` — 每 30 分钟
- `0 9 * * 1-5` — 工作日 9:00
