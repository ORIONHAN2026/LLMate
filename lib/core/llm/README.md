# core/llm/ - LLM 通信框架

## 职责

封装与大语言模型的完整通信链路：请求构建、SSE 流式传输、工具调用循环、记忆管理。

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `llm_framework.dart` | 24 | Barrel 导出文件，统一导出整个 LLM 框架 |
| `llm_client.dart` | ~ | **核心编排器**：协调 OpenAiProvider（网络）→ 消息/工具组装 → 工具执行 |
| `openai_provider.dart` | 300 | HTTP 传输层：实现 OpenAI 兼容的 Chat Completions 协议，处理 SSE 流解析和错误重试 |

## 子目录

| 目录 | 说明 |
|------|------|
| `common/` | 系统提示词常量 + 消息构建器 |
| `modes/` | 模式工具函数（`mode_utils.dart`） |

## 请求流程

```
用户输入
  → LlmClient.sendMessage()
    → _buildMessages()  // 组装系统提示词 + 历史消息
    → _buildTools()     // 注册可用工具
    → OpenAiProvider.sendChat()         // 发送 HTTP/SSE 请求
    → 解析流式响应 → 工具调用循环
```
