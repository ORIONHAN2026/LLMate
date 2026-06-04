# 记忆系统使用示例

## 1. 在 main.dart 中初始化

```dart
import 'package:flutter/material.dart';
import 'memory/memory_initializer.dart';
import 'memory/memory_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化记忆系统（使用默认配置）
  await MemoryInitializer.initialize();

  runApp(const MyApp());
}
```

## 2. 在聊天页面中集成

```dart
import 'memory/memory_service.dart';
import 'memory/memory_models.dart';

class ChatController {
  final MemoryService _memoryService = MemoryService();

  /// 发送消息时召回记忆
  Future<void> sendMessage(String content) async {
    // 1. 召回相关记忆
    final recallResult = await _memoryService.recall(
      userText: content,
      sessionKey: currentSession.id,
      userId: 'user_${currentSession.id}',
    );

    // 2. 构建带记忆的提示词
    String enhancedPrompt = content;
    if (recallResult.relevantMemories.isNotEmpty) {
      enhancedPrompt = '${recallResult.formattedMemoryContext}\n\n当前问题: $content';
    }

    // 3. 发送给LLM
    final response = await llmClient.sendMessage(enhancedPrompt);

    // 4. 捕获对话到记忆系统
    await _memoryService.captureTurn(
      sessionKey: currentSession.id,
      sessionId: currentSession.id,
      userText: content,
      assistantText: response,
      messages: messages,
    );
  }
}
```

## 3. 在 LlmHub 中自动集成（已完成）

`llm_hub.dart` 已自动集成记忆功能：

```dart
// 发送消息前自动召回记忆
_lastRecallResult = await _performMemoryRecall(userMessage.content);

// 注入记忆上下文到消息列表
messages = _injectMemoryContext(messages, _lastRecallResult!, userMessage.content);

// 对话结束后自动捕获
await _captureToMemory(userText, responseBuffer.toString(), messages);
```

## 4. 配置记忆系统

```dart
// 自定义配置
final config = MemoryConfig(
  enabled: true,
  recallStrategy: 'hybrid',      // keyword | embedding | hybrid
  maxRecallResults: 5,           // 每次召回5条记忆
  extractionInterval: 5,         // 每5轮对话提取一次
  l2TriggerThreshold: 10,        // 10条记忆触发场景聚合
  l3TriggerThreshold: 5,         // 5个场景触发画像更新
  enableDeduplication: true,     // 启用去重
);

await MemoryInitializer.initialize(
  extractionModel: myModel,  // 用于记忆提取的模型
  config: config,
);
```

## 5. 查看记忆统计

```dart
final stats = await memoryService.getStats(sessionKey);
print('''
记忆统计:
- L0对话记录: ${stats.l0Count}
- L1原子记忆: ${stats.l1Count}
- L2场景: ${stats.l2Count}
- L3画像: ${stats.hasL3 ? '已创建' : '未创建'}
''');
```

## 6. 手动触发处理

```dart
// 强制处理所有层级
await memoryService.flushSession(sessionKey);

// 搜索记忆
final memories = await memoryService.searchMemories(
  query: 'Flutter',
  sessionKey: sessionKey,
);

// 导出会话记忆
final export = await memoryService.exportSession(sessionKey);
```

## 7. 会话结束时清理

```dart
@override
void onSessionClose(String sessionKey) {
  // 刷新所有待处理的记忆
  memoryService.flushSession(sessionKey);
}
```

## 运行代码生成（可选）

如果要使用Isar存储（性能更好）：

```bash
# 生成Isar代码
flutter pub run build_runner build --delete-conflicting-outputs

# 持续监听文件变化
flutter pub run build_runner watch
```

> 注意：如果不运行代码生成，系统将自动回退到JSON文件存储模式。
