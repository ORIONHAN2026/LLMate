# core/ - 核心业务逻辑层

## 职责

存放应用的核心业务逻辑，不包含 UI 代码。所有服务类按职责细分为子目录。

## 子目录

| 目录 | 职责 | 关键类 |
|------|------|--------|
| `llm/` | LLM 通信框架 | `LlmClient`, `OpenAiProvider` |
| `tools/` | 工具注册与执行 | `ToolRegistry`, `ToolExecutionService` |
| `mcp/` | MCP 协议客户端 | `McpService`, `McpJsonParser` |
| `skills/` | 技能管理 | `SkillService`, `SkillStorageService` |
| `memory/` | 对话记忆压缩 | `MemoryCompressor` |
| `scheduler/` | 定时任务 | `ScheduledTaskService` |
| `config/` | 功能开关 | `FeatureToggleService` |
| `utils/` | 工具函数 | `ModelIconUtils` |

## 依赖方向

```
features/ → core/ → data/
features/ → models/
core/ → models/
core/ → data/
```

`core/` 只依赖 `data/` 和 `models/`，不依赖 `features/`、`controllers/` 或 `widgets/`。
