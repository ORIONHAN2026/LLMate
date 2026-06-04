# 记忆系统测试指南

## 测试文件说明

| 文件 | 用途 |
|------|------|
| `memory_test.dart` | 单元测试，使用 flutter_test |
| `memory_demo.dart` | 演示程序，展示完整功能 |

## 运行单元测试

```bash
# 运行所有记忆系统测试
flutter test lib/memory/memory_test.dart

# 运行特定测试组
flutter test lib/memory/memory_test.dart --name "L0"
flutter test lib/memory/memory_test.dart --name "Recall"
```

## 在应用内运行演示

```dart
import 'memory/memory_demo.dart';

// 在任意位置调用
await MemoryDemo.run();
```

预期输出：
```
╔══════════════════════════════════════════╗
║      腾讯DB-Agent-Memory 记忆系统演示     ║
╚══════════════════════════════════════════╝

✅ 记忆系统初始化完成

📱 步骤1: 模拟多轮对话 (5轮)...
─────────────────────────────────────────
  对话 1: 你好，我想做一个Flutter...
  对话 2: 我喜欢使用GetX做状态...
  ...
✅ 对话捕获完成

⏳ 等待L1记忆提取 (约2秒)...

📊 步骤2: 记忆统计信息
─────────────────────────────────────────
  L0 (原始对话): 5 条
  L1 (原子记忆): X 条
  L2 (场景聚类): X 个
  L3 (用户画像): 未生成

🔍 步骤3: 测试记忆召回
...
```

## 测试覆盖范围

### 单元测试覆盖

- ✅ **L0 Conversation Capture**
  - 单轮对话捕获
  - 多轮对话捕获（触发L1）

- ✅ **L1 Memory Extraction**
  - 从对话提取原子记忆
  - 记忆类型分类

- ✅ **Memory Recall**
  - 关键词召回
  - 格式化上下文

- ✅ **Memory Stats**
  - 统计信息正确性
  - 状态变化跟踪

- ✅ **Memory Export**
  - 数据导出功能
  - JSON格式验证

### 演示程序覆盖

- 🎯 完整对话流程模拟
- 🎯 L0-L3全链路展示
- 🎯 实时统计信息
- 🎯 召回效果演示
- 🎯 数据导出示例

## 快速验证

最简单的方式是在应用启动时调用演示：

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化记忆系统
  await MemoryInitializer.initialize();
  
  // 运行演示（测试完成后注释掉）
  await MemoryDemo.run();
  
  runApp(MyApp());
}
```

## 预期行为

### 正常情况

1. **初始化**: 显示 "✅ 记忆系统初始化完成"
2. **L0捕获**: 每轮对话后计数增加
3. **L1提取**: 达到阈值后自动触发
4. **召回**: 根据关键词返回相关记忆

### 异常情况

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 初始化失败 | Isar权限问题 | 检查存储目录权限 |
| L1不提取 | 无LLM模型配置 | 配置extractionModel |
| 召回为空 | 无历史记忆 | 先进行多轮对话 |

## 调试技巧

1. **查看日志**: 关注 `debugPrint` 输出
2. **检查存储**: 查看 `~/Documents/memory/memory.isar`
3. **验证统计**: 调用 `memoryService.getStats(sessionKey)`

## 性能基准

在普通设备上的参考性能：

| 操作 | 耗时 |
|------|------|
| L0捕获 | < 10ms |
| L1提取 (5轮) | ~500ms |
| 记忆召回 | < 50ms |
| 数据导出 | < 100ms |
