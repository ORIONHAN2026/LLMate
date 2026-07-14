---
title: 开始使用
type: docs
prev: /docs
next: docs/02-features
weight: 1
---

LLMate 为企业提供可视化的大模型接口管理与代理服务，帮助您按部门、按岗位精细化分配 AI 资源。以下是完整的入门指南。

### 1. 安装包下载

访问 [下载页面](/docs/07-download/) 获取最新版本的安装包。

| 平台 | 格式 | 版本 | 状态 |
|------|------|------|------|
| macOS | DMG (~120 MB) | v1.1.0 | 已发布，支持 Apple Silicon / Intel |
| Windows | MSIX | 开发中 | 即将发布 |
| Linux | AppImage / deb / rpm | 开发中 | 即将发布 |

<br>
下载后双击安装包，按照可视化安装向导完成安装，无需任何技术背景即可完成部署。

### 2. 源码下载安装

企业用户可根据自身需求，下载源码进行定制化修改和二次开发。

#### 环境要求

- Flutter SDK >= 3.7.2
- Dart SDK >= 3.7.2
- Git

#### 安装步骤

```bash
# 克隆仓库
git clone https://cnb.cool/llmhub.cc/llmchat.git

# 进入项目目录
cd llmchat

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

#### 打包发布

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

源码采用 GPL v3.0 开源协议，企业可自由修改和分发，但需遵守协议条款。

---

### 3. 配置大模型

LLMate 支持接入主流大模型供应商，统一管理企业的所有 AI 模型资源。

#### 添加模型供应商

1. 打开 LLMate，点击左侧菜单中的 **模型管理**
2. 点击 **添加模型** 按钮
3. 填写以下配置项：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 模型名称 | 自定义名称，便于识别 | 公司 GPT-4o |
| 供应商 | 选择模型供应商 | OpenAI / DeepSeek / Gemini |
| API 地址 | 模型 API 端点 URL | `https://api.openai.com/v1` |
| API 密钥 | 供应商提供的安全密钥 | `sk-xxxxxxxx` |
| 模型标识 | 具体模型名称 | `gpt-4o` / `deepseek-chat` |
| Temperature | 生成随机性 (0-2) | `0.7` |
| 最大 Token | 单次回复最大长度 | `4096` |

#### 支持的供应商

目前支持以下主流大模型供应商：

- **OpenAI** — GPT-4o, GPT-4 Turbo, GPT-3.5 Turbo
- **DeepSeek** — DeepSeek-V3, DeepSeek-R1
- **Google Gemini** — Gemini 2.0 Flash, Gemini 1.5 Pro
- **阿里云百炼** — 通义千问系列
- **腾讯云 TokenHub** — 混元大模型
- **小米 Mimo** — MiMo 系列

---

### 4. 创建会话

会话是 LLMate 的核心管理单元，每个会话对应一个独立的工作场景和资源配置。

#### 创建步骤

1. 在左侧会话列表中点击 **+** 按钮
2. 填写会话基本信息：
   - **会话名称**：如"技术部-后端开发"、"市场部-文案创作"
   - **会话头像**：自动随机分配 emoji，可自定义
   - **所属分组**：如"技术部"、"市场部"、"财务部"
3. 选择绑定的 AI 模型
4. 配置会话级参数（详见下文）
5. 点击 **创建** 完成

#### 会话配置项

| 配置项 | 说明 |
|--------|------|
| API 密钥 | 会话独立的请求密钥，可与模型全局密钥不同 |
| 系统提示词 | 该会话的行为约束和角色设定 |
| 深度思考 | 启用后模型会展示推理过程 |
| 工作目录 | AI 可读写文件的工作目录路径 |
| 免授权模式 | 开启后无需密钥即可使用 |

> **设计理念**：每个部门、每个岗位可拥有独立的会话，各自配置不同的模型、密钥和用量配额，实现精细化管理。

---

### 5. 会话服务地址

LLMate 内置本地 HTTP/HTTPS 代理服务，将配置好的大模型接口透传为 OpenAI 兼容 API。

#### 启动服务

1. 在应用设置中找到 **本地 HTTP 服务**
2. 配置服务参数：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 监听端口 | HTTP 服务端口号 | `80` |
| 启用 HTTPS | 是否启用加密传输 | 否 |
| 允许外部访问 | 是否允许局域网内其他设备调用 | 是 |
| API Key 认证 | 是否要求调用方提供密钥 | 可选 |

#### 使用方式

服务启动后，企业内部系统可通过标准 OpenAI API 格式调用：

```bash
curl http://localhost:80/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "你好"}]
  }'
```

每个会话的服务地址可在会话设置中查看和复制，方便分发给对应部门使用。

---

### 6. 会话用量管理

LLMate 提供完善的用量统计与配额管理功能，帮助企业精确控制 AI 资源消耗。

#### 配额设置

在会话设置页面，可配置以下用量限制：

| 配额项 | 说明 |
|--------|------|
| Token 上限 | 限制会话累计使用的 Token 数量 |
| 费用上限 | 限制会话累计产生的 API 调用费用 |
| 请求次数上限 | 限制会话的总请求次数 |
| 重置周期 | 配额重置时间（每日/每月） |

#### 用量统计

每个会话实时显示：

- **Prompt Tokens** — 输入消耗的 Token 量
- **Completion Tokens** — 输出消耗的 Token 量
- **总 Token 数** — 累计 Token 消耗
- **总费用** — 按模型定价自动计算的费用
- **请求次数** — API 调用总次数

#### 企业管理视角

管理员可在全局视图中查看：

- 各部门、各岗位的 Token 消耗排行
- 费用趋势图表
- 异常用量告警

> 用量的精细化管控让 AI 资源使用透明、可控，每一笔消耗都有据可查。

---

### 7. 增加 MCP

MCP（Model Context Protocol）是 AI 与外部工具交互的标准协议。通过配置 MCP 服务，可以让 AI 访问企业内部资源。

#### MCP 连接方式

LLMate 支持两种 MCP 连接方式：

| 方式 | 说明 | 适用场景 |
|------|------|----------|
| **Stdio** | 本地进程通信，启动命令行程序 | 本地工具、脚本、数据库连接 |
| **SSE** | 远程服务发现，通过 URL 连接 | 企业内部 API、微服务 |

#### 添加 MCP 服务

1. 进入 **MCP 管理** 页面
2. 点击 **添加 MCP** 按钮
3. 选择连接方式（Stdio 或 SSE）
4. 配置服务参数：
   - **服务名称**：如"内部知识库"、"文件系统"
   - **连接配置**：命令行（Stdio）或服务 URL（SSE）
   - **环境变量**：服务运行所需的环境变量（仅 Stdio）
5. 保存配置

#### 绑定到会话

MCP 服务配置完成后，需要在会话设置中绑定：

1. 进入目标会话的 **设置** 页面
2. 在 **MCP 工具** 区域勾选需要绑定的 MCP 服务
3. 保存后，AI 即可在该会话中调用相应的 MCP 工具

---

### 8. 配置 MCP

#### Stdio 方式配置示例

以配置一个本地文件管理 MCP 服务为例：

```json
{
  "name": "文件管理器",
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@anthropic/mcp-server-filesystem", "/path/to/workspace"],
  "env": {
    "HOME": "/Users/username"
  }
}
```

#### SSE 方式配置示例

以配置企业内部 API MCP 服务为例：

```
服务名称：企业知识库
连接类型：SSE
服务地址：https://api.company.com/mcp/sse
认证方式：API Key
```

#### 安全建议

- MCP 服务的访问权限应当与会话绑定，避免跨部门越权访问
- 敏感资源的 MCP 服务建议仅分配给特定岗位的会话
- 定期审计 MCP 服务的调用日志
- Stdio 方式的命令应使用绝对路径，避免路径注入风险

---

> **下一步**：阅读 [功能说明](/docs/03-feature-guide/) 了解 LLMate 的完整功能列表。
