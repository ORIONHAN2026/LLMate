# features/chat/widgets/message_widgets/ - 消息气泡组件

## 职责

渲染不同角色的消息气泡，提供交互操作。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `ai_message_widget.dart` | 2215 | AI 消息气泡：Markdown 渲染、流式光标动画、悬浮操作（复制/重新生成/截图） |
| `user_message_widget.dart` | 1523 | 用户消息气泡：Markdown 渲染、悬浮操作（复制/编辑/删除/截图/从此消息创建新会话） |
| `tool_message_widget.dart` | 153 | 工具调用结果：橙色主题卡片、工具名称头部、Markdown 内容体 |
| `chat_message_widget.dart` | 42 | 共享类型：`RegenerateActionType`、`MessageActionType` 枚举和回调函数类型定义 |

## 操作回调

```dart
typedef RegenerateCallback = void Function(RegenerateActionType type);
typedef EditAiMessageCallback = void Function(String messageId, String newContent);
typedef DeleteMessageCallback = void Function(String messageId);
typedef ScreenshotCallback = void Function(String messageId);
```
