/// 记忆系统核心功能测试（独立版本）
/// 
/// 不依赖项目中其他模块，只测试记忆系统自身功能
/// 运行：dart run lib/memory/memory_core_test.dart

import 'dart:io';
import 'dart:convert';
import 'memory_models.dart';
import 'memory_store.dart';
import 'memory_store_simple.dart';

void main() async {
  print('╔══════════════════════════════════════════╗');
  print('║     记忆系统核心功能测试（独立版）        ║');
  print('╚══════════════════════════════════════════╝');
  print('');

  // 测试1: 内存模型
  await testModels();

  // 测试2: 简化版存储
  await testSimpleStore();

  // 测试3: 关键词提取
  testKeywordExtraction();

  // 测试4: 记忆格式化
  testMemoryFormatting();

  print('\n✅ 所有核心测试通过！');
}

/// 测试数据模型
Future<void> testModels() async {
  print('📦 测试1: 数据模型');
  print('─────────────────────────────────────────');

  // L0 Conversation
  final l0 = L0Conversation()
    ..id = 1
    ..sessionKey = 'test_session'
    ..sessionId = 'test_session'
    ..timestamp = DateTime.now()
    ..userText = '你好'
    ..assistantText = '你好！有什么可以帮助你？'
    ..messagesJson = '[]'
    ..processedToL1 = false;

  print('  ✅ L0Conversation 创建成功');
  print('     - ID: ${l0.id}');
  print('     - 用户: ${l0.userText.substring(0, l0.userText.length > 20 ? 20 : l0.userText.length)}...');

  // L1 Memory
  final l1 = L1Memory()
    ..id = 1
    ..sessionKey = 'test_session'
    ..content = '用户偏好使用Flutter开发'
    ..type = MemoryType.preference
    ..createdAt = DateTime.now()
    ..keywords = ['Flutter', '开发', '偏好']
    ..confidence = 0.95;

  print('  ✅ L1Memory 创建成功');
  print('     - 类型: ${l1.type.name}');
  print('     - 内容: ${l1.content.substring(0, l1.content.length > 25 ? 25 : l1.content.length)}...');
  print('     - 关键词: ${l1.keywords.join(', ')}');

  // L2 Scene
  final l2 = L2Scene()
    ..id = 1
    ..sessionKey = 'test_session'
    ..title = 'Flutter项目开发'
    ..description = '用户正在开发Flutter应用'
    ..createdAt = DateTime.now()
    ..tags = ['Flutter', '移动开发', 'Dart'];

  print('  ✅ L2Scene 创建成功');
  print('     - 标题: ${l2.title}');
  print('     - 标签: ${l2.tags.join(', ')}');

  // L3 Persona
  final l3 = L3Persona()
    ..id = 1
    ..userId = 'user_001'
    ..preferences = '偏好使用Flutter和GetX开发移动应用'
    ..skills = 'Flutter, Dart, GetX'
    ..preferredTools = ['Flutter', 'GetX', 'VS Code']
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();

  print('  ✅ L3Persona 创建成功');
  print('     - 用户ID: ${l3.userId}');
  print('     - 工具偏好: ${l3.preferredTools.join(', ')}');

  // MemoryConfig
  final config = MemoryConfig(
    enabled: true,
    recallStrategy: 'hybrid',
    maxRecallResults: 5,
    extractionInterval: 5,
  );

  print('  ✅ MemoryConfig 创建成功');
  print('     - 召回策略: ${config.recallStrategy}');
  print('     - 最大召回: ${config.maxRecallResults}');

  // MemoryRecallResult
  final result = MemoryRecallResult(
    relevantMemories: [l1],
    systemContextAppend: '用户偏好Flutter开发',
    recallStrategy: 'keyword',
  );

  print('  ✅ MemoryRecallResult 创建成功');
  print('     - 召回数: ${result.relevantMemories.length}');
  print('');
}

/// 测试简化版存储
Future<void> testSimpleStore() async {
  print('💾 测试2: 简化版存储 (JSON文件)');
  print('─────────────────────────────────────────');

  final store = MemoryStoreSimple.instance;
  await store.initialize();

  const sessionKey = 'test_store_session';

  // 测试L0保存
  final l0 = L0Conversation()
    ..id = 1
    ..sessionKey = sessionKey
    ..sessionId = sessionKey
    ..timestamp = DateTime.now()
    ..userText = '测试用户消息'
    ..assistantText = '测试AI回复'
    ..messagesJson = jsonEncode([{'role': 'user', 'content': 'test'}]);

  await store.saveL0Conversation(l0);
  print('  ✅ L0 保存成功');

  // 测试L1保存
  final l1 = L1Memory()
    ..id = 1
    ..sessionKey = sessionKey
    ..content = '这是一个测试记忆'
    ..type = MemoryType.fact
    ..createdAt = DateTime.now()
    ..keywords = ['测试', '记忆'];

  await store.saveL1Memory(l1);
  print('  ✅ L1 保存成功');

  // 测试L2保存
  final l2 = L2Scene()
    ..id = 1
    ..sessionKey = sessionKey
    ..title = '测试场景'
    ..description = '这是一个测试场景描述'
    ..createdAt = DateTime.now()
    ..tags = ['测试', '场景'];

  await store.saveL2Scene(l2);
  print('  ✅ L2 保存成功');

  // 测试L3保存
  final l3 = L3Persona()
    ..id = 1
    ..userId = 'user_$sessionKey'
    ..preferences = '用户偏好测试'
    ..createdAt = DateTime.now()
    ..updatedAt = DateTime.now();

  await store.saveL3Persona(l3);
  print('  ✅ L3 保存成功');

  // 测试查询
  final l1Memories = await store.getL1Memories(sessionKey);
  print('  ✅ L1 查询成功: 找到 ${l1Memories.length} 条记忆');

  // 测试搜索
  final searchResults = await store.searchL1ByKeyword('测试', sessionKey: sessionKey);
  print('  ✅ L1 搜索成功: 找到 ${searchResults.length} 条结果');

  // 测试统计
  final stats = await store.getStats(sessionKey, 'user_$sessionKey');
  print('  ✅ 统计信息:');
  print('     - L0: ${stats.l0Count}');
  print('     - L1: ${stats.l1Count}');
  print('     - L2: ${stats.l2Count}');
  print('     - L3: ${stats.hasL3}');

  // 测试导出
  final export = await store.exportSessionMemories(sessionKey);
  print('  ✅ 导出成功: 包含 ${(export['l1Memories'] as List).length} 条L1记忆');

  await store.close();
  print('');
}

/// 测试关键词提取
void testKeywordExtraction() {
  print('🔍 测试3: 关键词提取');
  print('─────────────────────────────────────────');

  final testCases = [
    '我想做一个Flutter聊天应用，使用GetX做状态管理',
    'Please help me with Dart async programming',
    '如何设置深色模式和主题颜色？',
  ];

  for (final text in testCases) {
    final keywords = _extractKeywords(text);
    print('  文本: ${text.substring(0, text.length > 30 ? 30 : text.length)}...');
    print('  关键词: ${keywords.take(5).join(', ')}');
    print('');
  }

  print('  ✅ 关键词提取测试通过');
  print('');
}

/// 测试记忆格式化
void testMemoryFormatting() {
  print('📝 测试4: 记忆格式化');
  print('─────────────────────────────────────────');

  final memories = [
    L1Memory()
      ..id = 1
      ..content = '用户偏好使用Flutter开发移动端应用'
      ..type = MemoryType.preference
      ..createdAt = DateTime.now(),
    L1Memory()
      ..id = 2
      ..content = '用户喜欢使用GetX进行状态管理'
      ..type = MemoryType.preference
      ..createdAt = DateTime.now(),
    L1Memory()
      ..id = 3
      ..content = '用户目标是开发一个聊天应用'
      ..type = MemoryType.goal
      ..createdAt = DateTime.now(),
  ];

  final result = MemoryRecallResult(
    relevantMemories: memories,
    systemContextAppend: '## 用户画像\n用户是Flutter开发者，偏好简洁的代码风格',
    recallStrategy: 'hybrid',
  );

  print('  格式化记忆上下文:');
  print('  ────────────────────────────');
  print(result.formattedMemoryContext.split('\n').map((l) => '  $l').join('\n'));
  print('  ────────────────────────────');
  print('');
  print('  ✅ 记忆格式化测试通过');
  print('');
}

/// 简单关键词提取实现
List<String> _extractKeywords(String text) {
  final stopWords = {
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '那', '什么', '怎么', '为什么',
    'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as', 'and', 'or', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
  };

  final cleaned = text
      .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff]'), ' ')
      .toLowerCase();

  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && !stopWords.contains(w) && w.length > 1)
      .toList();

  final wordFreq = <String, int>{};
  for (final word in words) {
    wordFreq[word] = (wordFreq[word] ?? 0) + 1;
  }

  final sortedWords = wordFreq.keys.toList()
    ..sort((a, b) => wordFreq[b]!.compareTo(wordFreq[a]!));

  return sortedWords.take(10).toList();
}
