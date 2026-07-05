# models/chat/ - 聊天领域模型

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `chat_session.dart` | 439 | **会话模型**：消息列表、模型绑定、工作模式、技能/MCP 绑定、记忆数据、附件、定时任务 |
| `chat_message.dart` | 229 | **消息模型**：角色(user/bot/tool)、内容、思考块、工具调用、性能统计(令牌/耗时/速度) |
| `chat_setting.dart` | 199 | 聊天设置：系统提示词、温度、回复语言；快捷命令数据类 |
| `chat_attachment.dart` | 104 | 附件模型：图片/文档/代码/链接/文件夹，支持 base64 和 OSS 上传 |
| `content_block.dart` | 26 | 内容块：按顺序渲染思考/工具/文本内容的轻量模型 |
| `skill.dart` | 190 | 技能模型：从 SKILL.md 解析，含 frontmatter、MCP 工具定义 |
| `mcp_config.dart` | 340 | MCP 配置：传输类型(Stdio/URL)、工具信息、服务器配置 |
| `scheduled_task.dart` | 110 | 定时任务：Cron 表达式 + 预设消息 |
| `contract_info.dart` | 241 | 合同信息：当事人、条款、违约、日期范围 |
| `mindmap_node.dart` | 28 | 脑图节点：递归树结构 |
