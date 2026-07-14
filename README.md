# LLMate

AI 驱动的智能工作助手 — 基于 Flutter 的多模式对话应用，支持合同管理、发票处理、创意写作、日程管理等场景。

## 功能特性

### 工作模式

| 模式 | 说明 |
|------|------|
| **对话** | 通用 AI 对话，支持文件读写、OCR、代码执行 |
| **合同** | 合同解析、要点提取、履约跟踪、争议记录 |
| **发票** | 发票识别、汇总统计、报销记录管理 |
| **创意** | 脑图生成、灵感笔记、草稿管理 |
| **日程** | 日程安排、工作日志、任务管理 |
| **聊天室** | 多角色对话，支持自定义角色 |

### 核心能力

- **MCP 协议支持** — 连接外部工具和服务
- **技能系统** — 可扩展的技能插件
- **文件操作** — 读写工作目录下的文件
- **OCR 识别** — 图片文字提取
- **深度思考** — 推理增强模式
- **多语言** — 中文、英文、泰语、越南语

### 平台支持

- macOS
- Linux
- Windows
- Web

## 快速开始

### 环境要求

- Flutter SDK >= 3.7.2
- Dart SDK >= 3.7.2

### 安装运行

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

### 配置模型

1. 启动应用后，进入设置页面
2. 添加 AI 模型供应商（OpenAI、DeepSeek 等）
3. 配置 API Key 和 Base URL
4. 选择模型开始对话

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── controllers/                 # 状态管理
├── core/                        # 核心功能
│   ├── llm/                     # LLM 集成
│   │   └── modes/               # 工作模式实现
│   ├── tools/                   # 系统工具
│   ├── mcp/                     # MCP 服务
│   ├── mcp_client/              # MCP 客户端
│   ├── skills/                  # 技能系统
│   └── config/                  # 配置管理
├── data/                        # 数据存储
├── features/                    # 功能模块
│   ├── chat/                    # 聊天界面
│   ├── settings/                # 设置页面
│   ├── mcp/                     # MCP 管理
│   ├── models/                  # 模型管理
│   └── skills/                  # 技能管理
├── models/                      # 数据模型
├── l10n/                        # 国际化
└── utils/                       # 工具类
```

## 内置工具

| 工具 | 说明 |
|------|------|
| `file_read` | 读取文件内容 |
| `file_write` | 写入文件 |
| `node_execute` | 执行 Node.js 脚本 |
| `python_execute` | 执行 Python 脚本 |
| `ocr_extract` | 图片 OCR 识别 |
| `word_modify` | 修改 Word 文档 |
| `contract_inspect` | 合同信息管理 |
| `session_rename` | 重命名会话 |

## 贡献指南

欢迎贡献代码！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

## 许可证

本项目采用 [GNU 通用公共许可证 v3.0](LICENSE) 发布。

## 致谢

- [Flutter](https://flutter.dev/) — 跨平台 UI 框架
- [GetX](https://pub.dev/packages/get) — 状态管理
- [OpenAI API](https://platform.openai.com/docs) — API 规范参考
