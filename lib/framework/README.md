# LLM Hub 框架迁移指南

## 概述

LLM Hub 是一个统一的大模型调用框架，旨在简化多种大模型提供商的集成和使用。该框架提供了一致的API接口，支持流式响应、工具调用等功能。

## 框架优势

1. **统一接口**: 所有大模型提供商使用相同的API接口
2. **插件化架构**: 易于扩展新的提供商
3. **类型安全**: 完整的 TypeScript 类型定义
4. **错误处理**: 统一的错误处理机制
5. **功能检测**: 自动检测和验证提供商功能
6. **资源管理**: 自动资源清理和连接管理

## 支持的提供商

- OpenAI (GPT-4, GPT-3.5 等)
- DeepSeek (DeepSeek-Chat, DeepSeek-Coder 等)
- Anthropic (Claude 系列)
- ModelScope (魔塔模型)
- Google Gemini
- 阿里通义千问 (Qwen)
- 智谱AI (GLM 系列)
- Ollama (本地模型)

## 快速开始

### 1. 基本使用

```dart
import 'package:chathub/framework/llm_framework.dart';

// 创建客户端
final client = LlmHub.instance.createClient('openai');

// 配置模型
final model = ChatModel.create(
  name: 'GPT-4',
  model: 'gpt-4',
  provider: 'openai',
  apiKey: 'your-api-key',
  apiUrl: 'https://api.openai.com/v1/chat/completions',
);

client.configure(model);

// 发送消息
await for (final chunk in client.sendMessageStream(
  message: '你好，世界！',
)) {
  print(chunk);
}

// 释放资源
client.dispose();
```

### 2. 从现有 ChatSession 创建客户端

```dart
// 假设你有一个配置好的 ChatSession
final client = LlmHub.instance.createClientFromSession(session);

// 直接使用
await for (final chunk in client.sendMessageStream(
  message: userMessage.content,
  session: session,
)) {
  // 处理响应
}
```

## 迁移步骤

### 第一步：替换 ApiService 调用

**原有代码：**
```dart
final apiService = ApiService(
  chatSession: session,
  userMessage: userMessage,
);
final responseStream = apiService.sendMessageToOnlineModelStream();
```

**新代码：**
```dart
final client = LlmHub.instance.createClientFromSession(session);
final responseStream = client.sendMessageStream(
  message: userMessage.content,
  session: session,
);
```

### 第二步：更新错误处理

**原有代码：**
```dart
try {
  final responseStream = apiService.sendMessageToOnlineModelStream();
  await for (final chunk in responseStream) {
    // 处理响应
  }
} catch (e) {
  // 错误处理
}
```

**新代码：**
```dart
try {
  final client = LlmHub.instance.createClientFromSession(session);
  
  // 验证配置
  final isValid = await client.validateConfiguration();
  if (!isValid) {
    throw Exception('模型配置无效');
  }
  
  await for (final chunk in client.sendMessageStream(
    message: userMessage.content,
    session: session,
  )) {
    // 处理响应
  }
  
  client.dispose();
} catch (e) {
  // 统一错误处理
}
```

### 第三步：利用框架特性

#### 功能检测
```dart
final client = LlmHub.instance.createClient('openai');

// 检查是否支持流式响应
if (client.supportsFeature(LlmFeatures.streaming)) {
  // 使用流式响应
}

// 检查是否支持工具调用
if (client.supportsFeature(LlmFeatures.toolCalling)) {
  // 启用工具调用
}
```

#### 模型信息获取
```dart
final modelInfo = await client.getModelInfo();
print('模型信息: $modelInfo');
```

#### 自定义请求选项
```dart
await for (final chunk in client.sendMessageStream(
  message: '请解释量子计算',
  options: {
    'max_tokens': 1000,
    'temperature': 0.7,
    'tool_choice': 'auto',
  },
)) {
  // 处理响应
}
```

## 在现有项目中的集成

### 1. 更新 chat_input_widget.dart

**原有代码：**
```dart
final apiService = ApiService(
  chatSession: currentSession,
  userMessage: userMessage,
);
final responseStream = apiService.sendMessageToOnlineModelStream();
```

**新代码：**
```dart
final client = LlmHub.instance.createClientFromSession(currentSession);
final responseStream = client.sendMessageStream(
  message: userMessage.content,
  session: currentSession,
);
```

### 2. 更新 ai_message_widget.dart

**原有代码：**
```dart
final apiService = ApiService(
  chatSession: currentSession,
  userMessage: userMessage,
);
final responseStream = apiService.sendMessageToOnlineModelStream();
```

**新代码：**
```dart
final client = LlmHub.instance.createClientFromSession(currentSession);
final responseStream = client.sendMessageStream(
  message: userMessage.content,
  session: currentSession,
);
```

### 3. 添加配置验证

在模型配置页面添加验证功能：

```dart
Future<bool> validateModelConfiguration(ChatModel model) async {
  try {
    final client = LlmHub.instance.createClientFromModel(model);
    return await client.validateConfiguration();
  } catch (e) {
    return false;
  }
}
```

## 高级特性

### 1. 自定义提供商

如果需要添加新的提供商，可以继承 `BaseLlmProvider`:

```dart
class CustomProvider extends BaseLlmProvider {
  @override
  Stream<String> sendMessageStream({
    required String message,
    List<ChatMessage>? messages,
    ChatSession? session,
    Map<String, dynamic>? options,
  }) async* {
    // 实现自定义逻辑
  }
  
  @override
  Future<bool> validateConfiguration() async {
    // 实现配置验证
  }
}
```

### 2. 批量操作

```dart
// 批量测试多个提供商
final hub = LlmHub.instance;
final providers = hub.getSupportedProviders();

for (final provider in providers) {
  final client = hub.createClient(provider);
  // 配置和测试
}
```

### 3. 工具调用集成

框架自动集成了 MCP 工具调用功能：

```dart
// 启用工具调用的会话
final session = ChatSession(
  // ... 其他配置
  mcpConfig: const McpSessionConfig(isEnabled: true),
);

final client = LlmHub.instance.createClientFromSession(session);
await for (final chunk in client.sendMessageStream(
  message: '帮我搜索最新的技术新闻',
  session: session,
)) {
  // 自动处理工具调用
}
```

## 注意事项

1. **API Key 安全**: 确保 API Key 的安全存储和传输
2. **资源管理**: 使用完毕后调用 `client.dispose()` 释放资源
3. **错误处理**: 框架提供了统一的错误处理，但仍需在应用层处理特定错误
4. **配置验证**: 在使用前验证模型配置，避免运行时错误
5. **并发控制**: 避免同时创建过多客户端实例

## 性能优化建议

1. **复用客户端**: 对于相同配置的模型，可以复用客户端实例
2. **连接池**: 框架内部使用连接池管理 HTTP 连接
3. **流式处理**: 优先使用流式响应，提高用户体验
4. **异步处理**: 所有 API 调用都是异步的，避免阻塞主线程

## 故障排除

### 常见问题

1. **配置验证失败**: 检查 API Key 和 URL 是否正确
2. **网络连接错误**: 检查网络设置和防火墙配置
3. **模型不支持**: 检查提供商是否支持指定的模型
4. **工具调用失败**: 确保 MCP 服务已正确配置

### 调试技巧

```dart
// 启用详细日志
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  // 框架会自动输出调试信息
}
```

## 完整示例

参见 `lib/framework/examples/llm_hub_examples.dart` 文件中的完整示例代码。

## 总结

LLM Hub 框架提供了一个统一、灵活、易于扩展的大模型调用接口。通过逐步迁移，可以显著简化现有代码的维护和新功能的开发。建议先从简单的场景开始迁移，逐步替换所有的 ApiService 调用。
