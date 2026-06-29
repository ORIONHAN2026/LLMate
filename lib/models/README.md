# models/ - 数据模型定义

## 职责

定义所有跨模块共享的数据模型，按业务领域分为三个子目录。

## 子目录

| 目录 | 说明 |
|------|------|
| `chat/` | 聊天领域模型（会话、消息、附件、技能、MCP 配置等） |
| `bigmodel/` | LLM 模型配置和静态数据 |
| `responses/` | 各厂商 API 的 SSE 流式响应 DTO |

## barrel 导出

`models.dart` 统一导出常用模型类，方便外部引用：
```dart
import 'package:llmwork/models/models.dart';
```
