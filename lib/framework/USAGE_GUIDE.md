# LLM Hub 框架使用指南

## 项目结构

```
lib/framework/
├── llm_hub.dart                    # 核心框架类
├── llm_framework.dart              # 框架导出文件
├── llm_migration_service.dart      # 迁移服务
├── providers/                      # 提供商实现（按协议标准）
│   ├── base_provider.dart          # 基础抽象类
│   ├── openai_provider.dart        # OpenAI 兼容协议（OpenAI/DeepSeek/阿里云百炼/智谱AI/ModelScope/Ollama）
│   ├── anthropic_provider.dart     # Anthropic 协议
│   └── gemini_provider.dart        # Gemini 协议
├── examples/                       # 示例代码
│   └── llm_hub_examples.dart       # 完整示例
└── README.md                       # 详细文档
```

## 核心概念

### 1. LlmHub (单例)
- 框架的入口点
- 管理所有提供商实例
- 提供客户端创建方法

### 2. LlmClient
- 具体的模型调用客户端
- 支持流式和非流式响应
- 提供配置验证和功能检测

### 3. BaseLlmProvider
- 所有提供商的基类
- 定义统一的接口
- 提供通用功能实现

## 快速开始

### 1. 添加依赖

在 `pubspec.yaml` 中确保有以下依赖：

```yaml
dependencies:
  dio: ^5.0.0
  http: ^1.0.0
  flutter:
    sdk: flutter
```

### 2. 导入框架

```dart
import 'package:chathub/framework/llm_framework.dart';
```

### 3. 基本使用

```dart
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
  message: '你好！',
)) {
  print(chunk);
}

client.dispose();
```

## 完整的项目集成示例

### 1. 在现有项目中使用

#### 替换 chat_input_widget.dart 中的 ApiService

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
final llmService = LlmApiService(
  chatSession: currentSession,
  userMessage: userMessage,
);
final responseStream = llmService.sendMessageToOnlineModelStream();
```

#### 完整的消息发送逻辑

```dart
Future<void> _sendMessage() async {
  if (currentSession?.chatModel == null) {
    // 显示错误提示
    return;
  }
  
  try {
    // 1. 创建用户消息
    final userMessage = ChatMessage(
      msgId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: _inputController.text,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    
    // 2. 创建AI消息占位符
    final botMessageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
    final botMessage = ChatMessage(
      msgId: botMessageId,
      content: '',
      role: MessageRole.bot,
      timestamp: DateTime.now(),
    );
    
    // 3. 更新会话
    final updatedMessages = [...currentSession!.messages, userMessage, botMessage];
    final updatedSession = currentSession!.copyWith(
      messages: updatedMessages,
      isSending: true,
      shouldStopResponse: false,
    );
    
    sessionController.updateSession(updatedSession);
    setState(() {});
    
    // 4. 使用新框架发送消息
    final client = LlmHub.instance.createClientFromSession(updatedSession);
    
    // 5. 验证配置
    final isValid = await client.validateConfiguration();
    if (!isValid) {
      throw Exception('模型配置验证失败');
    }
    
    // 6. 处理流式响应
    String accumulatedContent = '';
    await for (final chunk in client.sendMessageStream(
      message: userMessage.content,
      session: updatedSession,
    )) {
      // 检查是否被停止
      final latestSession = sessionController.sessions.firstWhere(
        (s) => s.sessionId == updatedSession.sessionId,
        orElse: () => updatedSession,
      );
      
      if (latestSession.shouldStopResponse) {
        break;
      }
      
      accumulatedContent += chunk;
      
      // 更新AI消息内容
      final messageIndex = latestSession.messages.indexWhere(
        (msg) => msg.msgId == botMessageId,
      );
      
      if (messageIndex != -1) {
        final updatedBotMessage = latestSession.messages[messageIndex].copyWith(
          content: accumulatedContent,
        );
        
        final newMessages = [...latestSession.messages];
        newMessages[messageIndex] = updatedBotMessage;
        
        final newSession = latestSession.copyWith(
          messages: newMessages,
          isSending: true,
        );
        
        sessionController.updateSession(newSession);
      }
    }
    
    // 7. 完成发送
    final finalSession = sessionController.sessions.firstWhere(
      (s) => s.sessionId == updatedSession.sessionId,
      orElse: () => updatedSession,
    );
    
    final completedSession = finalSession.copyWith(isSending: false);
    sessionController.updateSession(completedSession);
    
    // 8. 释放资源
    client.dispose();
    
    // 9. 清空输入框
    _inputController.clear();
    
  } catch (e) {
    // 错误处理
    debugPrint('发送消息失败: $e');
    
    // 更新会话状态
    if (currentSession != null) {
      final errorSession = currentSession!.copyWith(isSending: false);
      sessionController.updateSession(errorSession);
    }
    
    // 显示错误提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('发送失败: $e')),
    );
  }
}
```

### 2. 模型配置验证

在模型设置页面添加配置验证：

```dart
Future<void> _validateModelConfiguration(ChatModel model) async {
  setState(() {
    _isValidating = true;
  });
  
  try {
    final isValid = await LlmMigrationHelper.validateModelConfiguration(model);
    
    setState(() {
      _isValidating = false;
      _validationResult = isValid;
    });
    
    if (isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模型配置验证成功')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模型配置验证失败，请检查设置')),
      );
    }
  } catch (e) {
    setState(() {
      _isValidating = false;
      _validationResult = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('验证过程出错: $e')),
    );
  }
}
```

### 3. 批量操作示例

```dart
Future<void> _batchValidateModels() async {
  final results = await LlmMigrationHelper.validateMultipleModels(
    _availableModels,
  );
  
  final validModels = results.entries.where((e) => e.value).length;
  final totalModels = results.length;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('批量验证结果'),
      content: Text('共 $totalModels 个模型，其中 $validModels 个配置有效'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
```

## 高级特性

### 1. 自定义提供商

```dart
class CustomProvider extends BaseLlmProvider {
  @override
  List<String> getSupportedFeatures() {
    return [
      LlmFeatures.textGeneration,
      LlmFeatures.streaming,
      // 其他支持的功能
    ];
  }
  
  @override
  Stream<String> sendMessageStream({
    required String message,
    List<ChatMessage>? messages,
    ChatSession? session,
    Map<String, dynamic>? options,
  }) async* {
    // 实现自定义逻辑
    final requestData = _buildRequestData(message, messages, session, options);
    
    final response = await dio.post(
      model!.apiUrl!,
      data: requestData,
      options: Options(responseType: ResponseType.stream),
    );
    
    yield* processStreamResponse(response.data!.stream);
  }
  
  @override
  Future<bool> validateConfiguration() async {
    // 实现配置验证逻辑
    return true;
  }
}
```

### 2. 工具调用集成

```dart
// 在会话中启用工具调用
final session = ChatSession(
  // ... 其他配置
  mcpConfig: const McpSessionConfig(isEnabled: true),
);

// 框架会自动处理工具调用
final client = LlmHub.instance.createClientFromSession(session);
await for (final chunk in client.sendMessageStream(
  message: '帮我搜索最新的技术新闻',
  session: session,
)) {
  // 处理响应，可能包含工具调用结果
}
```

### 3. 性能监控

```dart
void _sendMessageWithMonitoring() async {
  final requestId = 'request_${DateTime.now().millisecondsSinceEpoch}';
  
  // 开始监控
  LlmPerformanceMonitor.startRequest(requestId);
  
  try {
    // 发送消息
    final client = LlmHub.instance.createClientFromSession(session);
    await for (final chunk in client.sendMessageStream(message: message)) {
      // 处理响应
    }
  } finally {
    // 结束监控
    LlmPerformanceMonitor.endRequest(requestId);
  }
}
```

## 最佳实践

### 1. 资源管理

```dart
class ChatService {
  LlmClient? _client;
  
  Future<void> initialize(ChatSession session) async {
    _client = LlmHub.instance.createClientFromSession(session);
    final isValid = await _client!.validateConfiguration();
    if (!isValid) {
      throw Exception('配置验证失败');
    }
  }
  
  Stream<String> sendMessage(String message) async* {
    if (_client == null) {
      throw StateError('服务未初始化');
    }
    
    yield* _client!.sendMessageStream(message: message);
  }
  
  void dispose() {
    _client?.dispose();
    _client = null;
  }
}
```

### 2. 错误处理

```dart
Future<void> _handleLlmRequest() async {
  try {
    final client = LlmHub.instance.createClientFromSession(session);
    
    // 验证配置
    final isValid = await client.validateConfiguration();
    if (!isValid) {
      _showError('模型配置无效');
      return;
    }
    
    // 发送消息
    await for (final chunk in client.sendMessageStream(message: message)) {
      _handleChunk(chunk);
    }
    
  } on UnsupportedError catch (e) {
    _showError('不支持的提供商: ${e.message}');
  } on ArgumentError catch (e) {
    _showError('参数错误: ${e.message}');
  } on StateError catch (e) {
    _showError('状态错误: ${e.message}');
  } catch (e) {
    _showError('未知错误: $e');
  }
}
```

### 3. 配置管理

```dart
class LlmConfigManager {
  static const String _configKey = 'llm_configs';
  
  static Future<void> saveConfig(ChatModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getConfigs();
    configs[model.modelId] = model.toJson();
    await prefs.setString(_configKey, jsonEncode(configs));
  }
  
  static Future<Map<String, dynamic>> getConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getString(_configKey);
    if (configsJson != null) {
      return jsonDecode(configsJson);
    }
    return {};
  }
  
  static Future<bool> validateAllConfigs() async {
    final configs = await getConfigs();
    for (final config in configs.values) {
      final model = ChatModel.fromJson(jsonEncode(config));
      final isValid = await LlmMigrationHelper.validateModelConfiguration(model);
      if (!isValid) {
        return false;
      }
    }
    return true;
  }
}
```

## 故障排除

### 常见问题及解决方案

1. **配置验证失败**
   - 检查 API Key 是否正确
   - 验证 API URL 格式
   - 确认网络连接

2. **提供商不支持**
   - 使用 `LlmHub.instance.getSupportedProviders()` 查看支持的提供商
   - 检查提供商名称拼写

3. **工具调用失败**
   - 确认会话启用了 `mcpConfig.isEnabled`
   - 检查 MCP 服务配置

4. **内存泄漏**
   - 确保调用 `client.dispose()`
   - 避免创建过多客户端实例

### 调试技巧

```dart
// 启用调试模式
import 'package:flutter/foundation.dart';

void debugLlmRequest(String provider, ChatModel model) {
  if (kDebugMode) {
    print('提供商: $provider');
    print('模型: ${model.model}');
    print('API URL: ${model.apiUrl}');
    print('支持的功能: ${LlmMigrationHelper.getProviderFeatures(provider)}');
  }
}
```

## 总结

LLM Hub 框架提供了一个统一、灵活的大模型调用接口，通过合理的架构设计和丰富的功能支持，可以显著简化大模型集成的复杂性。建议按照本指南逐步迁移现有代码，充分利用框架的各种特性。
