# widgets/ - 跨功能共享组件

## 职责

存放不属于特定功能模块的通用 UI 组件。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `chat_message_widget.dart` | 42 | 消息操作的共享类型定义：回调函数类型、操作枚举 |
| `common/confirm_delete_dialog.dart` | 178 | 通用删除确认弹窗：自定义标题/描述/警告/图标/回调 |

## 使用方式

```dart
// 删除确认弹窗
showDialog(
  context: context,
  builder: (_) => ConfirmDeleteDialog(
    title: '删除会话',
    itemName: '会话名称',
    onDelete: () => handleDelete(),
  ),
);
```
