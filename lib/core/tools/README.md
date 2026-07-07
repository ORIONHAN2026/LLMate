# core/tools/ - 工具执行

> 注意：内置文档/代码工具（`document_tools/`、`executors/`）已移除。当前仅保留通过 MCP 执行工具的统一入口。

## 文件说明

| 文件 | 说明 |
|------|------|
| `tool_execution_service.dart` | 统一执行器：将 LLM 解析出的工具调用路由到 MCP 客户端执行 |

## 工具调用流程

```
LLM 返回 tool_call
  → ToolExecutionService.execute()
    → 还原工具名 → 路由到 MCP 客户端执行
```
