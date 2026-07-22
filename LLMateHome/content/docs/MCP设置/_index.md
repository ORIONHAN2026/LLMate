---
title: MCP设置
type: docs
prev: docs/用量设置/09-session-billing
next: docs/MCP设置/11-manage-mcp
weight: 11
---

MCP（Model Context Protocol）是 AI 与外部工具交互的标准协议。LLMate 通过 MCP 实现工具的接入与按会话的精细化授权，包含以下模块：

- **[管理 MCP](/docs/MCP设置/11-manage-mcp/)**：统一添加、维护企业所需的 MCP 工具（连接方式、参数配置、启停与删除）
- **[会话 MCP 配置](/docs/MCP设置/12-session-mcp/)**：为不同会话绑定 MCP 工具并分配访问权限，实现工具与权限的会话级管控

> 管理 MCP 负责工具的接入与维护，会话 MCP 配置负责将工具按会话开放并授权，两者配合完成"接入工具 → 按会话授权"的完整链路。
