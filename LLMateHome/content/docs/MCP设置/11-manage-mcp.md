---
title: 管理 MCP
type: docs
prev: docs/用量设置/09-session-billing
next: docs/MCP设置/12-session-mcp
weight: 11
---

MCP（Model Context Protocol）是 AI 与外部工具交互的标准协议。在 LLMate 中，你可以统一添加和管理企业所需的 MCP 工具，供后续按会话灵活配置使用。

### MCP 连接方式

LLMate 支持四种 MCP 连接方式：

| 方式 | 说明 | 适用场景 |
|------|------|----------|
| **Stdio** | 本地进程通信，启动命令行程序 | 本地工具、脚本、数据库连接 |
| **SSE** | 远程服务发现，通过 URL 长连接 | 企业内部 API、微服务 |
| **HTTP** | 标准 HTTP 请求方式 | 普通远程 MCP 服务 |
| **Streamable HTTP** | 基于 HTTP 的可流式传输协议 | 现代 MCP 服务（SSE 不可用时自动回退尝试） |

### 添加 MCP 工具

1. 进入 **MCP 管理** 页面

   {{< figure src="images/manage-mcp/step1-open-mcp.png" caption="进入「MCP 管理」页面" >}}

2. 点击 **添加 MCP** 按钮

   {{< figure src="images/manage-mcp/step2-add.png" caption="点击「添加 MCP」按钮" >}}

3. 选择连接方式（Stdio / SSE / HTTP / Streamable HTTP）

   {{< figure src="images/manage-mcp/step3-select-type.png" caption="选择 MCP 连接方式" >}}

4. 配置服务参数：
   - **服务名称**：如"内部知识库"、"文件系统"
   - **连接配置**：命令行（Stdio）或服务 URL（SSE / HTTP）
   - **环境变量**：服务运行所需的环境变量（仅 Stdio）

   {{< figure src="images/manage-mcp/step4-config.png" caption="填写 MCP 服务名称、连接配置与环境变量" >}}

5. 保存配置

   {{< figure src="images/manage-mcp/step5-save.png" caption="保存 MCP 工具配置" >}}

### 管理 MCP 工具

添加完成后，你可以在 **MCP 管理** 页面中统一管理所有 MCP 工具：

- **编辑**：修改名称、连接方式或连接参数
- **启停**：临时禁用某个 MCP 工具，而不必删除
- **删除**：移除不再使用的 MCP 工具

{{< figure src="images/manage-mcp/step-manage.png" caption="在 MCP 管理页面对工具进行编辑、启停或删除" >}}

> 管理 MCP 仅完成工具的接入与维护；具体要将哪些工具开放给哪些会话、分配何种权限，请在 [会话 MCP 配置](/docs/MCP设置/12-session-mcp/) 中按会话进行设置。
