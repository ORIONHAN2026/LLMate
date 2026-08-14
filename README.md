# LLMate

<p align="center">
  <strong>AI 驱动的智能工作助手 — 基于 Flutter 的多模式对话应用</strong>
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/badge/License-GPLv3-blue.svg" />
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%3E%3D3.7.2-blue.svg?logo=flutter" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%3E%3D3.7.2-blue.svg?logo=dart" />
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-orange.svg" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey.svg" />
</p>

LLMate 是一款 AI 驱动的智能工作助手，采用 **「聊天窗口 → 本机 HTTP 服务 → 真实模型 API」** 三层架构，将鉴权、配额、工具注入、审计与用量统计统一收敛在本机服务层，实现安全、可控、可审计的 AI 工作流。

---

## 目录

- [特性](#特性)
- [架构](#架构)
- [快速开始](#快速开始)
- [使用指南](#使用指南)
- [项目结构](#项目结构)
- [技术栈](#技术栈)
- [数据存储](#数据存储)
- [贡献指南](#贡献指南)
- [许可证](#许可证)
- [致谢](#致谢)

---

## 特性

### 会话模式

| 模式 | 说明 |
|------|------|
| **会话模式** | 常规对话。消息经本机服务转发，绑定会话 MCP 工具，计入审计与用量统计 |
| **管理模式** | 管理操作。注入审计/用量/配额管理工具，用量不计入统计、绕过脱敏与配额检查 |

### 工作模式

| 模式 | 说明 |
|------|------|
| **对话** | 通用 AI 对话 |
| **合同** | 合同解析、要点提取、履约跟踪、争议记录 |
| **发票** | 发票识别与汇总管理 |
| **创意** | 灵感笔记与草稿管理 |
| **日程** | 日程安排、任务管理 |
| **聊天室** | 多角色对话，支持自定义角色（`roles/` 目录加载角色上下文） |

### 核心能力

- **本机服务网关** — 所有会话请求经本机 Shelf HTTP 服务转发，服务层统一完成 API Key 鉴权、配额检查、风险控制、工具执行、审计与用量统计
- **MCP 协议支持** — 内置完整 MCP 客户端 SDK（auth / client / protocol / transport），可接入外部 MCP 服务并注入其工具
- **工具调用** — 会话工具（MCP）与第三方工具分类执行，支持流式工具调用
- **审计系统** — 基于 DuckDB 的链路审计（request / prompt / model / usage / toolStart / toolFinish / response / error），可追溯每次请求的模型、用量与工具调用
- **用量统计** — 按会话记录 token 用量，支持用量看板与曲线展示
- **额度管理** — 会话级配额查询 / 设置 / 重置
- **管理模式工具** — `audit_search` / `audit_get` / `audit_add` / `audit_update` / `audit_delete`、`usage_query`、`quota_get` / `quota_set` / `quota_reset`、`session_config_get`
- **服务安全中间件** — API Key 守卫、审计守卫、禁用守卫、模型工具守卫、配额守卫、风控守卫、会话守卫
- **模型管理** — 添加在线模型供应商（OpenAI、DeepSeek 等），配置 API Key、Base URL 与系统提示词
- **会话管理** — 多会话、随机表情图标、会话级 API Key（`lm-` 前缀）、会话系统提示词
- **多语言** — 中文、英文、日文、泰语、越南语、韩语、法语、德语

### 平台支持

- macOS
- Linux
- Windows

---

## 架构

```
┌─────────────────┐   HTTP/SSE    ┌──────────────────┐   HTTP/SSE   ┌──────────────┐
│  Flutter 聊天窗口 │ ────────────▶ │ 本机 Shelf 服务    │ ───────────▶ │ 真实模型 API   │
│  (GetX 状态管理) │ ◀──────────── │  (localhost)      │ ◀─────────── │ (OpenAI 等)  │
└─────────────────┘               └──────────────────┘              └──────────────┘
                                     │  ├─ 鉴权 / 配额 / 风控
                                     │  ├─ MCP 工具注入与执行
                                     │  ├─ 审计（DuckDB）
                                     │  └─ 用量统计（SQLite）
```

- 所有会话请求经本机 HTTP 服务转发，服务层统一完成 **API Key 鉴权、配额检查、风险控制、工具执行、审计与用量统计**。
- 状态管理使用 **GetX**。
- 数据持久化于 `~/.llmate/`（会话数据、SQLite 用量库、DuckDB 审计库）。

---

## 快速开始

### 环境要求

- Flutter SDK >= 3.7.2
- Dart SDK >= 3.7.2

### 安装运行

```bash
# 克隆仓库
git clone <仓库地址>

# 进入项目目录
cd LLMate

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 配置模型

1. 启动应用后，进入设置页面
2. 添加 AI 模型供应商（OpenAI、DeepSeek 等）
3. 配置 API Key 和 Base URL
4. 选择模型开始对话

---

## 使用指南

### 开始对话

选择会话模式，在输入框中输入消息即可开始对话。消息经本机服务转发至真实模型 API，所有交互都会写入审计与用量统计。

### 使用管理工具

切换到管理模式后，系统自动注入审计查询、用量统计、配额管理等管理工具，可通过自然语言执行管理操作，如：

- "查询最近 10 条审计记录"
- "查看今天的 token 用量"
- "设置会话配额为 10000 tokens"

### 接入 MCP 服务

在 MCP 服务管理页面添加外部 MCP 服务地址，系统将通过内置 MCP 客户端建立连接并将其工具注入会话。

---

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── controllers/                 # 状态管理（会话/审计/用量/MCP/模型/设置）
├── core/                        # 核心功能
│   ├── http/                    # 本机 Shelf HTTP 服务
│   │   ├── local_http_service.dart  # 服务入口：鉴权/配额/审计/用量
│   │   ├── stream_round.dart        # 单轮流式请求（SSE 解析、工具调用分类）
│   │   ├── sensitive_masker.dart    # 敏感信息脱敏
│   │   └── middleware/              # API Key/审计/配额/风控等守卫
│   ├── llm/                     # LLM 集成
│   │   ├── llm_client.dart          # LLM 客户端
│   │   ├── common/                  # 分块解析/消息构建/OpenAI Provider/系统提示词
│   │   ├── modes/                   # 工作模式工具函数
│   │   └── tools/                   # 管理模式工具定义
│   ├── mcp/                     # MCP 客户端 SDK（auth/client/protocol/transport）
│   ├── router/                  # 路由
│   └── services/                # DuckDB 存储/存储路径/地址检测等服务
├── data/                        # 数据存储（SQLite / DuckDB）
├── features/                    # 功能模块
│   ├── chat/                    # 聊天界面（输入框/消息/审计查看器/用量面板）
│   ├── settings/                # 设置页面（主题/语言/服务）
│   ├── mcp/                     # MCP 服务管理
│   ├── models/                  # 模型管理
│   ├── utils/                   # 通用工具
│   └── widgets/                 # 通用组件
├── models/                      # 数据模型（会话/消息/审计/模型/系统设置）
└── l10n/                        # 国际化（8 种语言）
```

---

## 技术栈

| 类别 | 技术 |
|------|------|
| UI 框架 | Flutter |
| 状态管理 | GetX |
| 本机服务 | Shelf / shelf_router |
| 数据库 | DuckDB（审计）、SQLite（Drift，用量统计） |
| 网络 | dio / http |
| 文档处理 | syncfusion_flutter_pdf / docx_to_text / excel / flutter_quill |
| 国际化 | flutter_localizations / intl / ARB |

---

## 数据存储

所有数据保存在 `~/.llmate/`：

```
~/.llmate/
├── chats/{sessionId}/    # 会话数据（session.json / messages.json / memory.md）
├── ssl/                  # HTTPS 证书
├── *.sqlite              # 用量统计数据库
└── audit.duckdb          # 审计数据库
```

---

## 贡献指南

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

---

## 许可证

本项目采用 [GNU 通用公共许可证 v3.0](LICENSE) 发布。

---

## 致谢

- [Flutter](https://flutter.dev/) — 跨平台 UI 框架
- [GetX](https://pub.dev/packages/get) — 状态管理
- [Shelf](https://pub.dev/packages/shelf) — Dart HTTP 服务框架
- [OpenAI API](https://platform.openai.com/docs) — API 规范参考
