# features/models/ - 模型管理模块

## 职责

LLM 模型的查看、编辑、添加和删除。

## 目录结构

```
models/
├── controllers/
│   └── model_controller.dart        # 模型列表全局控制器
├── pages/
│   └── add_online_model_dialog.dart # 在线模型添加向导（多步骤弹窗）
└── widgets/
    ├── model_detail_page.dart       # 模型详情/编辑页
    ├── model_config_tab.dart        # 模型配置编辑标签页
    └── chat_settings_tab.dart       # 聊天设置标签页（已废弃）
```

## 在线模型添加流程

```
选择供应商 → 选择模型 → 输入 API Key/URL → 连接测试 → 保存
```

## 支持的供应商

DeepSeek、OpenAI、Gemini、Claude、通义千问、智谱、ModelScope、Moonshot、百川等。
