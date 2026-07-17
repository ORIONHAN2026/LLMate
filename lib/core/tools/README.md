# core/tools/ - 工具执行

> 注意：内置文档/代码工具（`document_tools/`、`executors/`）已移除。统一工具执行器已整合进 `McpController`（`../../controllers/mcp_controller.dart`），本目录不再保留单独实现文件。

## 工具调用流程

```
LLM 返回 tool_call
  → McpController.instance.executeToolCalls(...)
    → 还原工具名 → 路由到 MCP 客户端执行（连接失败自动重连重试）
```
