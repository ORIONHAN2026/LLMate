# core/llm/modes/ - 工作模式策略

## 设计模式

采用**策略模式 (Strategy Pattern)**：通过工厂函数根据模式名称创建对应的策略实例。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `work_mode_strategy.dart` | 24 | 抽象策略接口：定义 `buildMessages()` 和 `buildTools()` 契约 |
| `work_mode_factory.dart` | 26 | 工厂函数：根据模式字符串创建对应策略 |
| `work_mode_sidebar.dart` | 15 | 右侧面板抽象接口 |
| `mode_sidebars.dart` | 84 | 各模式的具体侧边栏实现 |
| `mode_utils.dart` | 403 | 共享工具函数：记忆上下文构建、工具名解析、历史消息组装、附件映射 |

## 模式实现

| 模式 | 文件 | 行数 | 用途 |
|------|------|------|------|
| `conversation` | `conversation_mode.dart` | 71 | 默认对话模式 |
| `contract` | `contract_mode.dart` | 166 | 合同审查模式 |
| `invoice` | `invoice_mode.dart` | 135 | 发票管理模式 |
| `chatroom` | `chatroom_mode.dart` | 146 | 多角色聊天室模式 |
| `creative` | `creative_mode.dart` | 450 | 创意写作模式（含脑图、笔记、草稿） |
| `task` | `task_mode.dart` | 215 | 任务/日程管理模式 |

## 扩展新模式

1. 实现 `WorkModeStrategy` 接口
2. 在 `work_mode_factory.dart` 中注册
3. 可选：实现 `WorkModeSidebar` 提供右侧面板
