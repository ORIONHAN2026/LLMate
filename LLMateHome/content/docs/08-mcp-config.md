---
title: 配置 MCP
type: docs
prev: docs/07-add-mcp
next: docs/02-features
weight: 8
---

### Stdio 方式配置示例

以配置一个本地文件管理 MCP 服务为例：

```json
{
  "name": "文件管理器",
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-server-filesystem", "/path/to/workspace"],
  "env": {
    "HOME": "/Users/username"
  }
}
```

### SSE 方式配置示例

以配置企业内部 API MCP 服务为例：

```
服务名称：企业知识库
连接类型：SSE
服务地址：https://api.company.com/mcp/sse
认证方式：API Key
```

### 安全建议

- MCP 服务的访问权限应当与会话绑定，避免跨部门越权访问
- 敏感资源的 MCP 服务建议仅分配给特定岗位的会话
- 定期审计 MCP 服务的调用日志
- Stdio 方式的命令应使用绝对路径，避免路径注入风险

---

> **下一步**：阅读 [功能说明](/docs/03-feature-guide/) 了解 LLMate 的完整功能列表。
