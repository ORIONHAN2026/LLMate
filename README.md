# LLMate

<p align="center">
  <strong>面向企业的大模型代理、治理与审计工作台</strong>
</p>

<p align="center">
  <img alt="License" src="https://img.shields.io/badge/License-GPLv3-blue.svg" />
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%3E%3D3.7.2-blue.svg?logo=flutter" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%3E%3D3.7.2-blue.svg?logo=dart" />
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-orange.svg" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg" />
</p>

LLMate 是一个本地优先的大模型代理服务与桌面管理工具。它把不同模型供应商、会话 API Key、MCP 工具、配额、用量统计、审计追踪和风险控制收敛到一个统一入口中，让团队可以用 OpenAI 兼容接口接入模型，同时保留企业侧需要的治理能力。

> 简单说：客户端只访问 LLMate，本地服务再按会话配置、安全策略和模型路由转发到真实大模型接口。

---

## 预览

下方图片为占位路径，你可以后续把截图放到 `docs/images/` 目录中替换。

### 主聊天窗口

![主聊天窗口](docs/images/1.jpg)

### 会话设置

![会话设置](docs/images/2.jpg)

### 模型管理

![模型管理](docs/images/3.jpg)

### MCP 管理

![MCP 管理](docs/images/4.jpg)

### 用量统计与审计

![用量统计](docs/images/5.jpg)

![审计查看](docs/images/6.jpg)

---

## 核心能力

- **OpenAI 兼容代理服务**：提供 `/v1/chat/completions` 和 `/v1/models`，支持普通路径和会话路径 `/{sessionId}/v1/chat/completions`。
- **会话级 API Key**：每个会话拥有独立 `lm-` API Key，可按会话隔离模型、MCP、提示词、配额和审计。
- **模型统一管理**：集中配置 DeepSeek、OpenAI、Gemini、Qwen、Claude、OpenRouter、Ollama 等模型供应商与模型列表。
- **自动模型路由**：支持自动选择轻量模型或高能力模型，也可以按会话固定指定模型。
- **MCP 服务端执行**：会话绑定的 MCP 工具会注入到模型请求中，由 LLMate 服务端执行完成；客户端自带工具则保留给客户端处理。
- **流式响应代理**：普通请求尽量保持上游 SSE 原样转发，减少代理层对模型输出节奏的影响。
- **用量统计**：记录请求数、输入 Token、输出 Token、缓存写入 Token、缓存命中 Token，并提供趋势图。
- **审计追踪**：基于 DuckDB 记录请求、模型决策、工具调用、响应和错误，方便排查与合规留痕。
- **配额控制**：支持会话级请求次数与 Token 上限，配额周期可自动重置。
- **风险控制**：支持手机号、身份证号等敏感信息脱敏后再转发给模型。
- **本地优先存储**：默认数据存储在 `~/.llmate/`，方便备份、迁移和排查。

---

## 工作方式

```text
┌────────────────────┐
│ 外部客户端 / 聊天 UI │
│ OpenAI Compatible  │
└─────────┬──────────┘
          │ /v1/chat/completions
          ▼
┌──────────────────────────────┐
│ LLMate 本地 HTTP 服务          │
│ - API Key / 会话鉴权           │
│ - 模型路由与提示词注入          │
│ - MCP 工具注入与服务端执行      │
│ - 风控脱敏 / 配额检查           │
│ - 审计与用量统计                │
└─────────┬────────────────────┘
          │ OpenAI / Anthropic / Ollama / ...
          ▼
┌────────────────────┐
│ 真实大模型供应商 API │
└────────────────────┘
```

LLMate 的核心不是单纯聊天，而是把模型访问放进一个可治理的代理层中。客户端无需知道真实模型 API Key，也无需自己处理会话 MCP、审计、配额和脱敏策略。

---

## 适用场景

- 给企业内部工具提供统一大模型出口。
- 为不同团队、项目或业务系统分配独立会话 API Key。
- 在不暴露真实模型密钥的情况下接入 Cursor、OpenAI SDK、HTTP 客户端或内部系统。
- 统一管理 MCP 工具，让模型可以调用企业内部能力。
- 对模型调用过程做审计、回放和故障排查。
- 按会话观察请求量、Token 用量和缓存命中情况。

---

## 快速开始

### 环境要求

- Flutter SDK >= 3.7.2
- Dart SDK >= 3.7.2
- macOS、Windows 或 Linux

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

启动后，应用会初始化本地 HTTP 服务。默认端口可在应用内的服务设置中调整。

---

## 基础使用

### 1. 添加模型

进入「模型管理」页面，选择模型供应商和模型列表，填写 API Key 与接口地址。LLMate 会把模型配置保存到本地数据库中。

### 2. 创建或配置会话

每个会话可以独立设置：

- 会话名称与组织名称
- 会话 API Key
- 绑定模型或自动选模策略
- 系统提示词
- 回复语言
- MCP 工具
- 请求次数与 Token 配额
- 敏感信息脱敏策略

### 3. 通过 HTTP 接入

外部客户端可以按 OpenAI 兼容方式访问：

```bash
curl http://127.0.0.1:80/v1/chat/completions \
  -H "Authorization: Bearer lm-your-session-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "auto",
    "stream": true,
    "messages": [
      {"role": "user", "content": "你好，介绍一下你自己"}
    ]
  }'
```

也可以使用兼容会话路径：

```text
/{sessionId}/v1/chat/completions
```

### 4. 查看用量与审计

在会话页面可以打开：

- 用量统计：请求数、Token、缓存 Token 和趋势图。
- 审计查看：按 traceId、时间范围和关键字查询请求链路。

---

## MCP 工作流

LLMate 支持把会话绑定的 MCP 工具注入到模型请求中。

```text
模型返回 tool_calls
        │
        ▼
LLMate 判断工具来源
        │
        ├─ 会话 MCP 工具：服务端执行，并把结果回填给模型
        │
        └─ 客户端自带工具：透传给客户端处理
```

这意味着企业内部工具可以统一由 LLMate 管理和执行，外部客户端无需直接持有 MCP 连接配置。

---

## 数据存储

默认数据位于：

```text
~/.llmate/
├── llmate.sqlite     # 应用主数据库
├── audit.duckdb      # 审计数据库
├── ssl/              # HTTPS 证书
└── log/              # 最近请求与路由日志
```

项目目前主要使用：

- SQLite / Drift：模型、会话、消息、用量等结构化数据。
- DuckDB：审计事件与链路查询。

---

## 项目结构

```text
lib/
├── main.dart                         # 应用入口与窗口初始化
├── controllers/                      # GetX 控制器
├── core/
│   ├── http/                         # 本地 HTTP 代理服务
│   │   ├── local_http_service.dart    # /v1/models 与 /v1/chat/completions
│   │   ├── stream_round.dart          # SSE 转发、工具调用分类、usage 提取
│   │   ├── middleware/                # 会话、模型、语言、风控等中间件
│   │   └── sensitive_masker.dart      # 敏感信息脱敏
│   ├── router/                       # 自动模型路由
│   ├── llm/                          # LLM 客户端与消息构建
│   ├── mcp/                          # MCP 客户端实现
│   └── services/                     # 存储路径、地址检测等服务
├── data/                             # Drift 数据库
├── features/
│   ├── chat/                         # 聊天页、会话设置、用量、审计
│   ├── models/                       # 添加模型与模型详情
│   ├── mcp/                          # MCP 管理页面
│   ├── settings/                     # 设置模块
│   └── widgets/                      # 通用组件
├── models/                           # 业务模型
├── theme/                            # 应用主题
└── l10n/                             # 多语言资源
```

---

## 技术栈

| 模块 | 技术 |
| --- | --- |
| 桌面应用 | Flutter |
| 状态管理 | GetX |
| 本地 HTTP 服务 | Shelf、shelf_router |
| 数据库 | Drift / SQLite、DuckDB |
| 网络请求 | dart:io HttpClient、http、dio |
| 国际化 | flutter_localizations、intl、ARB |
| MCP | 项目内置 MCP 客户端实现 |
| 桌面窗口 | window_manager |

---

## 开发命令

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze

# 运行测试
flutter test

# 生成 Drift / l10n 等代码
dart run build_runner build --delete-conflicting-outputs
```

---

## 设计原则

- **统一入口**：所有模型访问都先进入 LLMate。
- **会话隔离**：不同会话拥有独立 API Key、模型、工具和治理策略。
- **服务端治理**：鉴权、配额、脱敏、审计、MCP 执行都在服务端完成。
- **兼容生态**：尽量保持 OpenAI 兼容接口，方便接入现有 SDK 和工具。
- **本地可控**：核心数据默认落在本机，便于开发、排查和私有部署。

---

## 许可证

本项目基于 [GNU General Public License v3.0](LICENSE) 发布。

---

## 致谢

- [Flutter](https://flutter.dev/)
- [GetX](https://pub.dev/packages/get)
- [Shelf](https://pub.dev/packages/shelf)
- [Drift](https://drift.simonbinder.eu/)
- [DuckDB](https://duckdb.org/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
