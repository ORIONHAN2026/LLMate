# features/chat/ - 聊天功能模块

## 职责

应用的核心功能：完整的聊天交互体验，包括会话管理、消息渲染、输入处理、侧边栏。

## 目录结构

```
chat/
├── pages/
│   └── home.dart                    # 主页：三栏布局（左会话列表 + 聊天区 + 右面板）
└── widgets/
    ├── chat_input_widget.dart       # 输入框：文本/附件/技能/MCP/文件处理
    ├── chat_conversation_area.dart  # 消息列表：滚动管理、截图、消息分组
    ├── model_selector.dart          # 模型选择下拉框
    ├── scheduled_task_dialog.dart   # 定时任务设置弹窗
    ├── message_widgets/             # 消息气泡组件
    │   ├── ai_message_widget.dart   # AI 消息：Markdown 渲染、流式光标、操作按钮
    │   ├── user_message_widget.dart # 用户消息：编辑/删除/截图操作
    │   ├── tool_message_widget.dart # 工具调用结果展示
    │   └── chat_message_widget.dart # 共享类型定义和回调
    ├── sidebars/                    # 侧边栏组件
    │   ├── chat_left_sidebar.dart   # 左侧：会话列表、搜索、收藏
    │   ├── chat_right_sidebar.dart  # 右侧：记忆/文件/模式面板
    │   ├── contract_sidebar.dart    # 合同模式面板
    │   ├── invoice_sidebar.dart     # 发票模式面板
    │   ├── chatroom_sidebar.dart    # 聊天室模式面板
    │   └── mindmap_widget.dart      # 脑图渲染组件
    └── attachment/                   # 附件组件
        ├── attachment_chip_widget.dart   # 单个附件卡片
        └── attachment_list_widget.dart   # 附件列表（带动画）
```
