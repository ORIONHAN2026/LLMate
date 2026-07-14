# lib/ - LLMate 项目源码根目录

## 目录结构

```
lib/
├── main.dart              # 应用入口：窗口管理、GetX 初始化、主题/语言配置、路由
├── controllers/           # 全局状态管理（GetX Controller）
├── core/                  # 核心业务逻辑层
│   ├── llm/               # LLM 通信框架（客户端、传输、模式策略）
│   ├── tools/             # 工具系统（注册表、执行器、文档工具）
│   ├── mcp/               # MCP 协议客户端服务
│   ├── memory/            # 对话记忆压缩
│   ├── scheduler/         # 定时任务调度
│   ├── cloud/             # 云服务（OSS、CloudBase）
│   ├── config/            # 功能开关配置
│   └── utils/             # 工具函数
├── data/                  # 数据持久化层
├── models/                # 数据模型定义
├── features/              # 按功能模块划分的 UI 和业务逻辑
│   ├── chat/              # 聊天功能
│   ├── mcp/               # MCP 管理
│   ├── models/            # 模型管理
│   └── settings/          # 设置页
├── pages/                 # 独立页面（加载页）
├── widgets/               # 跨功能共享组件
├── utils/                 # 通用工具函数
└── l10n/                  # 国际化资源
```

## 架构设计

采用**分层 + 功能模块化**架构：

- **data/** — 持久化层：文件存储、路径管理
- **core/** — 业务逻辑层：LLM 通信、工具执行、MCP 协议
- **features/** — 功能模块层：按业务领域组织 UI 和控制器
- **models/** — 数据层：跨模块共享的数据模型
- **controllers/** — 全局状态层：主题、语言、会话管理

## 技术栈

- **状态管理**: GetX
- **网络**: Dio (HTTP/SSE)
- **存储**: JSON 文件持久化（~/.llmate/）
- **UI**: Material Design 3
- **国际化**: flutter_localizations + ARB
