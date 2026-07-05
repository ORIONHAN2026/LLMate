# core/tools/ - 工具系统

## 职责

管理所有内置工具的注册、定义和执行调度。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `tool_execution_service.dart` | 306 | **统一执行器**：根据工具类型分发到 Shell、系统工具或 MCP 后端 |

## 子目录

| 目录 | 说明 |
|------|------|
| `document_tools/` | 文档处理工具（Word/PDF/Excel/PPT/图片/OCR/URL） |
| `executors/` | 脚本执行器（Python/Node.js） |

## 工具调用流程

```
LLM 返回 tool_call
  → ToolExecutionService.execute()
    → 判断工具类型
      → Shell 工具 → 子进程执行
      → 系统工具 → ToolRegistry 路由到对应 Service
      → MCP 工具 → McpService 调用远程服务器
```
