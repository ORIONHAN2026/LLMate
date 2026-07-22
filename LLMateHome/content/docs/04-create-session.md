---
title: 创建会话
type: docs
prev: docs/03-model-config
next: docs/会话设置/05-session-basic-info
weight: 4
---

会话是 LLMate 的核心管理单元，每个会话对应一个独立的工作场景和资源配置。会话既可以按**员工**维度配置（如为每位同事建立专属会话），也可以按**组织**维度配置（如按部门、团队、岗位划分会话）；具体采用哪种方式，请结合企业实际的管理与协作情况进行规划。

### 创建步骤

1. 在左侧会话列表中点击 **+** 按钮

   {{< figure src="images/create-session/step1-new-session.png" caption="点击左侧会话列表顶部的「+」按钮新建会话" >}}

2. 填写会话基本信息：

   {{< figure src="images/create-session/step2-basic-info.png" caption="填写会话名称、头像与所属分组" >}}

   - **会话名称**：如"技术部-后端开发"、"市场部-文案创作"
   - **会话头像**：自动随机分配 emoji，可自定义
   - **所属分组**：如"技术部"、"市场部"、"财务部"
3. 选择绑定的 AI 模型

   {{< figure src="images/create-session/step3-select-model.png" caption="选择本会话绑定的 AI 模型" >}}

4. 配置会话级参数（详见下文）

   {{< figure src="images/create-session/step4-session-config.png" caption="配置 API 密钥、系统提示词、深度思考、工作目录等会话级参数" >}}

5. 点击 **创建** 完成

   {{< figure src="images/create-session/step5-create.png" caption="点击「创建」按钮完成会话创建" >}}

### 会话配置项

| 配置项 | 说明 |
|--------|------|
| API 密钥 | 会话独立的请求密钥，可与模型全局密钥不同 |
| 系统提示词 | 该会话的行为约束和角色设定 |
| 深度思考 | 启用后模型会展示推理过程 |
| 工作目录 | AI 可读写文件的工作目录路径 |
| 免授权模式 | 开启后无需密钥即可使用 |

> **设计理念**：每个部门、每个岗位可拥有独立的会话，各自配置不同的模型、密钥和用量配额，实现精细化管理。
