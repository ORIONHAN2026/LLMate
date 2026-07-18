---
title: 功能特性
type: docs
prev: docs/08-mcp-config
next: docs/03-feature-guide
weight: 9
---

## 为什么选择 LLMate？

不只是聊天客户端，更是你的 AI 生产力工作台。从多模型管理到 MCP 扩展，从工作模式到用量管控，一站式满足企业 AI 落地需求。

### 🖥️ 多模型统一管理

一个界面管理 **OpenAI、Anthropic Claude、Google Gemini、DeepSeek、阿里云百炼（通义千问）、智谱 AI、Ollama（本地）、腾讯云 TokenHub、Kimi、小米 Mimo** 等主流模型。未列出的供应商还可通过「自定义」填写 Base URL 接入。

- 单个模型独立配置 API Key、Temperature、System Prompt，互不干扰
- 支持云端 API + 本地 Ollama 模型
- 模型选择器一键切换，无需重启对话

### 🔌 MCP 协议原生支持

完整支持 **Model Context Protocol (MCP)**，让 AI 连接外部工具与数据源（文件系统、数据库、内部 API、搜索引擎等）。

- 支持 **Stdio、SSE、HTTP、Streamable HTTP** 四种连接协议
- 本地进程 + 远程服务两种方式
- 会话级与模型级 MCP 自动合并、去重
- 搜索、文件管理、数据库、浏览器自动化等能力即接即用

### 🗂️ 场景化工作模式

针对不同业务内置专属工作模式，右侧导航栏随模式自动切换为结构化面板：

- **合同模式** — 合约要点、履约、争议、备忘录
- **发票模式** — 发票汇总、明细、报销记录
- **聊天室模式** — 多角色群聊、多角度讨论
- **创作模式** — 灵感、脑图、草稿

### 📊 用量统计与配额管控

每个会话实时统计 Token 与费用，并支持设置配额上限：

- 输入 / 输出 Token、总 Token、累计费用、请求次数
- Token 上限、费用预算、请求次数上限、重置周期
- 超额自动拦截，可视化用量曲线

### 🌐 本地 HTTP / HTTPS 代理

内置本地代理，把配置好的模型接口透传为 **OpenAI 兼容 API**，企业系统可一键接入：

- 可配置 HTTP / HTTPS 端口与 API Key 认证
- 内置配额、审计、越权拦截等中间件
- 每个会话有独立服务地址，便于分发

### 🔓 免授权便捷访问

支持免授权模式，内部用户无需配置密钥即可使用 AI 服务（建议仅在可信内网开启，并配合配额与审计）。

### 🌏 多语言与主题

- **8 种界面语言**：中文、English、日本語、ไทย、Tiếng Việt、한국어、Français、Deutsch
- 支持跟随系统 / 深色 / 浅色主题

---

## 支持的模型平台

| 平台 | 类型 | 说明 |
|------|------|------|
| OpenAI | 云端 API | GPT-4o / GPT-4 系列 |
| Anthropic | 云端 API | Claude 系列 |
| Google | 云端 API | Gemini 系列 |
| DeepSeek | 云端 API | DeepSeek-V3 / R1 |
| 阿里云百炼 | 云端 API | 通义千问（Qwen）系列 |
| 智谱 AI | 云端 API | GLM 系列 |
| Ollama | 本地部署 | 本地运行开源模型 |
| 腾讯云 TokenHub | 云端 API | 混元等 |
| Kimi（Moonshot） | 云端 API | Moonshot 系列 |
| 小米 Mimo | 云端 API | MiMo 系列 |

> 其他兼容 OpenAI / Anthropic / Gemini 协议的供应商，可通过「自定义」接入。

---

> 想看完整功能清单？前往 [功能说明](/docs/03-feature-guide/)。
