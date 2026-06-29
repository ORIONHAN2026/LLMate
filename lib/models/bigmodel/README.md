# models/bigmodel/ - 模型配置

## 文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `chat_model.dart` | 381 | **LLM 模型配置**：模型 ID、名称、平台、协议、API 凭证、聊天设置、图标渲染 |
| `model_data.dart` | 241 | **静态数据目录**：业务类型列表（代码分析/法律/金融等）、在线供应商定义（DeepSeek/OpenAI/Gemini 等） |

## ChatModel 字段

```dart
class ChatModel {
  String modelId;           // 模型唯一 ID
  String name;              // 显示名称
  String platform;          // 平台（deepseek/openai/zhipu 等）
  String protocol;          // 协议（openai/deepseek/zhipu/qwen 等）
  String apiKey;            // API 密钥
  String baseUrl;           // API 地址
  String modelName;         // 实际模型名称
  ChatSettings settings;    // 聊天参数
  // ...
}
```
