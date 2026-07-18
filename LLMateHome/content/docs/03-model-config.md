---
title: 大模型配置
type: docs
prev: docs/02-source-build
next: docs/04-create-session
weight: 3
---

LLMate 支持接入主流大模型供应商，统一管理企业的所有 AI 模型资源。

### 添加模型供应商

1. 打开 LLMate，点击左侧菜单中的 **模型管理**
2. 点击 **添加模型** 按钮
3. 填写以下配置项：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 模型名称 | 自定义名称，便于识别 | 公司 GPT-4o |
| 供应商 | 选择模型供应商 | OpenAI / DeepSeek / Gemini |
| API 地址 | 模型 API 端点 URL | `https://api.openai.com/v1` |
| API 密钥 | 供应商提供的安全密钥 | `lm-xxxxxxxx` |
| 模型标识 | 具体模型名称 | `gpt-4o` / `deepseek-chat` |
| Temperature | 生成随机性 (0-2) | `0.7` |
| 最大 Token | 单次回复最大长度 | `4096` |

### 支持的供应商

目前内置预设以下主流大模型供应商：

- **OpenAI** — GPT-4o, GPT-4 Turbo, GPT-3.5 Turbo
- **Anthropic Claude** — Claude 系列
- **Google Gemini** — Gemini 2.0 Flash, Gemini 1.5 Pro
- **DeepSeek** — DeepSeek-V3, DeepSeek-R1
- **阿里云百炼** — 通义千问（Qwen）系列
- **智谱 AI** — GLM 系列
- **Ollama** — 本地运行开源模型（默认 `127.0.0.1:11434`）
- **腾讯云 TokenHub** — 混元大模型
- **Kimi（Moonshot）** — Moonshot 系列
- **小米 Mimo** — MiMo 系列

> 未列出的供应商，可在添加时选择 **自定义**，填写 Base URL 并选择协议（OpenAI / Anthropic / Gemini 兼容格式）接入。
