# 腾讯DB-Agent-Memory 记忆系统

本项目集成了腾讯开源的DB-Agent-Memory记忆系统，实现了分层记忆架构。

## 架构概览

```
L0 Conversation (原始对话)
    ↓ 提取
L1 Atom (原子记忆) - 关键事实、偏好、目标
    ↓ 聚类
L2 Scenario (场景块) - 相关记忆的集合
    ↓ 聚合
L3 Persona (用户画像) - 长期偏好和特征
```

## 核心组件

| 组件 | 说明 |
|------|------|
| `MemoryService` | 主入口，整合所有记忆功能 |
| `MemoryStore` | 数据存储层（Isar数据库） |
| `MemoryExtractor` | 使用LLM提取记忆 |
| `MemoryRecall` | 记忆检索服务 |
| `MemoryModels` | 数据模型定义 |

## 快速开始

### 1. 初始化

在 `main.dart` 中初始化记忆系统：

```dart
import 'memory/memory_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化记忆系统
  await MemoryInitializer.initialize();
  
  runApp(MyApp());
}
```

### 2. 捕获对话

在AI回复完成后调用：

```dart
final memoryService = MemoryInitializer.service;

await memoryService?.captureTurn(
  sessionKey: session.sessionId,
  sessionId: session.sessionId,
  userText: userMessage.content,
  assistantText: assistantResponse,
  messages: messages,
);
```

### 3. 召回记忆

在发送消息前调用：

```dart
final recall = await memoryService?.recall(
  userText: userMessage.content,
  sessionKey: session.sessionId,
  userId: 'user_${session.sessionId}',
);

// 将召回的记忆注入到提示词中
if (recall?.relevantMemories.isNotEmpty == true) {
  // 注入到用户消息前
}
```

## 配置选项

```dart
MemoryConfig(
  enabled: true,                    // 是否启用
  recallStrategy: 'hybrid',         // 召回策略: keyword/embedding/hybrid
  maxRecallResults: 5,              // 最大召回记忆数
  extractionInterval: 5,            // 每N轮触发L1提取
  l2TriggerThreshold: 10,           // 触发L2的最小记忆数
  l3TriggerThreshold: 5,            // 触发L3的最小场景数
  l1IdleTimeoutSeconds: 600,        // 空闲超时触发L1
  enableDeduplication: true,        // 启用去重
);
```

## API 参考

### MemoryService

| 方法 | 说明 |
|------|------|
| `initialize()` | 初始化服务 |
| `captureTurn()` | 捕获对话回合 |
| `recall()` | 执行记忆召回 |
| `quickRecall()` | 快速召回 |
| `flushSession()` | 强制处理所有层级 |
| `getStats()` | 获取统计信息 |
| `searchMemories()` | 搜索L1记忆 |
| `searchConversations()` | 搜索L0对话 |
| `exportSession()` | 导出会话记忆 |

### 记忆召回结果

```dart
MemoryRecallResult {
  List<L1Memory> relevantMemories;  // 相关记忆列表
  String? systemContextAppend;       // 系统提示词追加内容
  L3Persona? persona;                // L3人物画像
  String recallStrategy;             // 使用的召回策略
}
```

## 集成到LLM流程

记忆系统已经集成到 `LlmHub` 和 `LlmClient` 中，自动处理：

1. **发送消息前**: 自动召回相关记忆并注入提示词
2. **AI回复后**: 自动捕获对话到L0层
3. **后台处理**: 定时触发L1-L3的提取和聚合

## 调试

当前使用 **Isar数据库存储**，存储位置：

```
~/Documents/memory/
├── memory.isar          # 主数据库文件
├── memory.isar.lock     # 锁文件
└── *.isar.compact       # 压缩备份
```

如需查看数据，使用记忆API：
```dart
// 获取统计
final stats = await memoryService.getStats(sessionKey);

// 导出会话
final export = await memoryService.exportSession(sessionKey);
```

## 存储状态

✅ **Isar存储已启用** - 使用高性能Isar数据库

如需重新生成代码（修改了memory_models.dart）：

```bash
# 一次性生成
dart run build_runner build --delete-conflicting-outputs

# 持续监听文件变化
dart run build_runner watch
```

## 性能考虑

- L0层使用频繁写入优化（JSONL追加模式）
- L1提取是异步的，不影响对话响应
- 召回操作有超时保护
- 支持配置最大记忆字符数限制

## 文件清单

```
lib/memory/
├── README.md                  # 本文档
├── EXAMPLE.md                 # 使用示例
├── memory_models.dart         # 数据模型（需代码生成）
├── memory_store.dart          # Isar存储（需代码生成）
├── memory_store_simple.dart   # JSON存储（无需代码生成）
├── memory_extractor.dart      # 记忆提取（LLM调用）
├── memory_recall.dart         # 记忆召回
├── memory_service.dart        # 主服务
├── memory_initializer.dart    # 初始化器
├── memory_integration.dart    # 导出文件
└── memory_provider_mixin.dart # Provider Mixin
```

## 测试

提供了两种测试方式：

### 1. 单元测试

```bash
flutter test lib/memory/memory_test.dart
```

### 2. 演示程序

```dart
import 'memory/memory_demo.dart';
await MemoryDemo.run();
```

详见 [TEST_README.md](TEST_README.md)

## 参考

- [腾讯DB-Agent-Memory](https://github.com/Tencent/TencentDB-Agent-Memory)
