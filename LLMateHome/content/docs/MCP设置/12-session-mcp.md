---
title: 会话 MCP 配置
type: docs
prev: docs/MCP设置/11-manage-mcp
next: docs/11-license
weight: 12
---

在 LLMate 中，MCP 工具按**会话**维度进行配置：你可以为不同的会话绑定不同的 MCP 工具，并为每个会话分配不同的访问权限，实现精细化的工具与权限管控。

### 按会话配置 MCP

1. 进入目标会话的 **设置** 页面

   {{< figure src="images/config-mcp/step1-session-settings.png" caption="进入目标会话的「设置」页面" >}}

2. 在 **MCP 工具** 区域勾选需要绑定的 MCP 工具

   {{< figure src="images/config-mcp/step2-bind.png" caption="勾选本会话需要使用的 MCP 工具" >}}

3. 为所选工具分配权限（如可访问的资源范围、是否允许写入等）

   {{< figure src="images/config-mcp/step3-permission.png" caption="为会话中的 MCP 工具分配访问权限" >}}

4. 保存设置，AI 即可在该会话中按配置调用相应的 MCP 工具

   {{< figure src="images/config-mcp/step4-save.png" caption="保存会话 MCP 配置" >}}

### 配置示例

#### Stdio 方式

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

#### SSE 方式

以配置企业内部 API MCP 服务为例：

```
服务名称：企业知识库
连接类型：SSE
服务地址：https://api.company.com/mcp/sse
认证方式：API Key
```

### 权限分配建议

- MCP 工具的访问权限应当**与会话绑定**，避免跨部门越权访问
- 敏感资源的 MCP 工具建议仅分配给特定岗位的会话
- 不同会话可配置不同的 MCP 工具组合与权限，互不影响
- 定期审计 MCP 工具的调用日志
- Stdio 方式的命令应使用绝对路径，避免路径注入风险
