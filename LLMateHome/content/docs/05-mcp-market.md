---
title: MCP 市场
type: docs
prev: docs/04-workmodes
next: docs/06-changelog
weight: 12
---

## 无限扩展 AI 能力边界

MCP (Model Context Protocol) 让 AI 连接外部工具与数据源。LLMate 原生支持 MCP，既可接入官方提供的专属服务，也能通过粘贴标准 `mcpServers` JSON 接入社区中**任意兼容的第三方 MCP 服务**，从搜索到开发、从文件操作到云端协作，让 AI 成为真正的全能助手。

> 添加方式：在 **MCP 管理** 中粘贴 JSON 或填写命令 / URL 即可，无需等待应用内市场。详见 [增加 MCP](/docs/07-add-mcp/)。

---

### LLMate 专属 MCP 服务

#### 💬 微信公众号 Token 管理

LLMate 专属 MCP 服务，实现微信服务号的 AccessToken 自动获取与刷新，用于在 LLMate 上操作微信服务号接口。

- **传输协议**：HTTP
- **版本**：v1.0.0
- **添加方式**：在 MCP 管理中粘贴上方 JSON 即可

```json
{
  "mcpServers": {
    "wechatpublic": {
      "headers": {
        "Authorization": "请联系LLMate获取授权码",
        "X-Appid": "您的微信服务号的AppID",
        "X-Secret": "您的微信服务号的AppSecret"
      },
      "url": "https://mcp-wchatpublic-261458-4-1402725619.sh.run.tcloudbase.com/mcp"
    }
  }
}
```

> ⚠️ 此 MCP 服务为 LLMate 专属服务，需要联系 LLMate 团队获取使用权限。

---

### 第三方 MCP 服务生态

LLMate 兼容所有标准 MCP 协议服务，以下为常用分类：

| 分类 | 典型服务 | 说明 |
|------|---------|------|
| 🔍 搜索与知识 | Brave Search, Tavily | 网页搜索、知识检索 |
| 📁 文件与文档 | Filesystem, Markdown | 文件读写、文档处理 |
| 🛠️ 开发工具 | GitHub, Git | 代码仓库操作 |
| 📊 数据与可视化 | PostgreSQL, SQLite | 数据库查询与分析 |
| ☁️ 云端服务 | CloudBase, AWS | 云资源管理 |
| 🌐 浏览器自动化 | Puppeteer, Playwright | 网页抓取与测试 |

社区中已有大量成熟的 MCP 服务可供接入，可按需选用。

> 浏览社区 MCP 服务列表：[GitHub MCP Servers](https://github.com/modelcontextprotocol/servers)
