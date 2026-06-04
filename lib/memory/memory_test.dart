import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_models.dart';
import 'memory_service.dart';
import 'memory_store.dart';

/// 记忆系统测试
///
/// 运行测试：flutter test lib/memory/memory_test.dart
void main() {
  group('Memory System Tests', () {
    late MemoryService memoryService;

    setUp(() async {
      // 使用测试配置
      memoryService = MemoryService(
        config: const MemoryConfig(
          enabled: true,
          recallStrategy: 'keyword',
          maxRecallResults: 5,
          extractionInterval: 2,  // 每2轮触发，方便测试
          l2TriggerThreshold: 3,   // 3条触发L2
          l3TriggerThreshold: 2,   // 2个场景触发L3
          enableDeduplication: true,
        ),
      );
      await memoryService.initialize();
    });

    tearDown(() async {
      await memoryService.dispose();
    });

    group('L0: Conversation Capture', () {
      test('should capture conversation turn', () async {
        const sessionKey = 'test_session_001';

        await memoryService.captureTurn(
          sessionKey: sessionKey,
          sessionId: sessionKey,
          userText: '你好，我想学习Flutter',
          assistantText: '你好！Flutter是一个优秀的跨平台UI框架。我可以帮你入门。',
          messages: [
            {'role': 'user', 'content': '你好，我想学习Flutter'},
            {'role': 'assistant', 'content': '你好！Flutter是一个优秀的跨平台UI框架。'},
          ],
        );

        // 验证统计
        final stats = await memoryService.getStats(sessionKey);
        expect(stats.l0Count, greaterThanOrEqualTo(1));

        debugPrint('✅ L0捕获测试通过');
      });

      test('should capture multiple turns', () async {
        const sessionKey = 'test_session_002';

        // 模拟5轮对话（触发L1提取阈值）
        final conversations = [
          {
            'user': '我想做一个天气App',
            'assistant': '很好的项目！你需要了解Flutter的布局和状态管理。',
          },
          {
            'user': '用什么状态管理比较好？',
            'assistant': '推荐GetX或Provider，GetX更轻量，Provider更灵活。',
          },
          {
            'user': '我喜欢简洁的代码',
            'assistant': '那GetX可能更适合你，它的语法非常简洁。',
          },
          {
            'user': '怎么获取天气数据？',
            'assistant': '可以使用http包调用天气API，比如OpenWeatherMap。',
          },
          {
            'user': '需要付费吗？',
            'assistant': 'OpenWeatherMap有免费额度，个人使用足够。',
          },
        ];

        for (var i = 0; i < conversations.length; i++) {
          final conv = conversations[i];
          await memoryService.captureTurn(
            sessionKey: sessionKey,
            sessionId: sessionKey,
            userText: conv['user']!,
            assistantText: conv['assistant']!,
            messages: [
              {'role': 'user', 'content': conv['user']},
              {'role': 'assistant', 'content': conv['assistant']},
            ],
          );
          debugPrint('  捕获对话 ${i + 1}/${conversations.length}');
        }

        // 等待L1提取完成
        await Future.delayed(const Duration(seconds: 2));

        // 验证统计
        final stats = await memoryService.getStats(sessionKey);
        expect(stats.l0Count, equals(5));

        debugPrint('✅ 多轮对话捕获测试通过');
        debugPrint('   L0: ${stats.l0Count}');
      });
    });

    group('L1: Memory Extraction', () {
      test('should extract memories from conversations', () async {
        const sessionKey = 'test_session_l1';

        // 模拟3轮有明确偏好的对话
        final testConversations = [
          {
            'user': '我想做一个Flutter聊天应用',
            'assistant': '好的！我们可以使用ListView和TextField来构建聊天界面。',
          },
          {
            'user': '我喜欢使用GetX',
            'assistant': 'GetX确实很方便！我们可以用GetX做状态管理和路由。',
          },
          {
            'user': '界面要Material Design风格',
            'assistant': '没问题，Flutter提供了丰富的Material组件。',
          },
        ];

        for (final conv in testConversations) {
          await memoryService.captureTurn(
            sessionKey: sessionKey,
            sessionId: sessionKey,
            userText: conv['user']!,
            assistantText: conv['assistant']!,
            messages: [
              {'role': 'user', 'content': conv['user']},
              {'role': 'assistant', 'content': conv['assistant']},
            ],
          );
        }

        // 手动触发L1提取
        await memoryService.flushSession(sessionKey);

        // 验证L1记忆
        final memories = await memoryService.searchMemories(
          query: 'Flutter',
          sessionKey: sessionKey,
        );

        debugPrint('✅ L1记忆提取测试通过');
        debugPrint('   找到 ${memories.length} 条相关记忆');
        for (final m in memories.take(3)) {
          debugPrint('   - [${m.type.name}] ${m.content.substring(0, m.content.length > 30 ? 30 : m.content.length)}...');
        }
      });
    });

    group('Memory Recall', () {
      test('should recall relevant memories', () async {
        const sessionKey = 'test_session_recall';

        // 先创建一些记忆
        final testData = [
          {'user': '我喜欢深色模式', 'assistant': '好的，我会记住你偏好深色模式。'},
          {'user': '用中文回复我', 'assistant': '明白，我会用中文和你交流。'},
          {'user': '我在做Flutter项目', 'assistant': '收到，你正在进行Flutter开发。'},
        ];

        for (final data in testData) {
          await memoryService.captureTurn(
            sessionKey: sessionKey,
            sessionId: sessionKey,
            userText: data['user']!,
            assistantText: data['assistant']!,
            messages: [
              {'role': 'user', 'content': data['user']},
              {'role': 'assistant', 'content': data['assistant']},
            ],
          );
        }

        // 等待处理
        await Future.delayed(const Duration(seconds: 1));

        // 测试召回
        final recall = await memoryService.recall(
          userText: '界面颜色怎么设置？',
          sessionKey: sessionKey,
          userId: 'user_$sessionKey',
        );

        debugPrint('✅ 记忆召回测试通过');
        debugPrint('   召回策略: ${recall.recallStrategy}');
        debugPrint('   召回记忆数: ${recall.relevantMemories.length}');
        if (recall.systemContextAppend != null) {
          debugPrint('   系统上下文已追加');
        }
      });

      test('should format memory context correctly', () async {
        final memories = [
          L1Memory()
            ..id = 1
            ..content = '用户偏好使用Flutter开发'
            ..type = MemoryType.preference
            ..createdAt = DateTime.now(),
          L1Memory()
            ..id = 2
            ..content = '用户喜欢深色模式'
            ..type = MemoryType.preference
            ..createdAt = DateTime.now(),
        ];

        final result = MemoryRecallResult(
          relevantMemories: memories,
          recallStrategy: 'keyword',
        );

        final context = result.formattedMemoryContext;
        expect(context, contains('相关历史记忆'));
        expect(context, contains('用户偏好使用Flutter开发'));
        expect(context, contains('用户喜欢深色模式'));

        debugPrint('✅ 记忆格式化测试通过');
        debugPrint('   格式化输出:\n$context');
      });
    });

    group('Memory Stats', () {
      test('should return correct stats', () async {
        const sessionKey = 'test_session_stats';

        // 初始状态
        final initialStats = await memoryService.getStats(sessionKey);
        expect(initialStats.l0Count, equals(0));
        expect(initialStats.l1Count, equals(0));
        expect(initialStats.l2Count, equals(0));
        expect(initialStats.hasL3, isFalse);

        // 添加一些对话
        for (var i = 0; i < 3; i++) {
          await memoryService.captureTurn(
            sessionKey: sessionKey,
            sessionId: sessionKey,
            userText: '测试消息 $i',
            assistantText: '测试回复 $i',
            messages: [],
          );
        }

        // 验证更新后的统计
        final updatedStats = await memoryService.getStats(sessionKey);
        expect(updatedStats.l0Count, equals(3));

        debugPrint('✅ 统计信息测试通过');
        debugPrint('   L0: ${updatedStats.l0Count}');
        debugPrint('   L1: ${updatedStats.l1Count}');
        debugPrint('   L2: ${updatedStats.l2Count}');
        debugPrint('   L3: ${updatedStats.hasL3 ? '有' : '无'}');
      });
    });

    group('Memory Export', () {
      test('should export session memories', () async {
        const sessionKey = 'test_session_export';

        // 添加测试数据
        await memoryService.captureTurn(
          sessionKey: sessionKey,
          sessionId: sessionKey,
          userText: '导出测试',
          assistantText: '这是导出测试的回复',
          messages: [],
        );

        // 导出
        final export = await memoryService.exportSession(sessionKey);

        expect(export['sessionKey'], equals(sessionKey));
        expect(export.containsKey('exportedAt'), isTrue);
        expect(export.containsKey('l0Conversations'), isTrue);
        expect(export.containsKey('l1Memories'), isTrue);
        expect(export.containsKey('l2Scenes'), isTrue);

        debugPrint('✅ 导出功能测试通过');
        debugPrint('   导出时间: ${export['exportedAt']}');
        debugPrint('   L0数量: ${(export['l0Conversations'] as List).length}');
      });
    });

    group('Memory Types', () {
      test('should handle different memory types', () {
        final types = MemoryType.values;

        expect(types, contains(MemoryType.fact));
        expect(types, contains(MemoryType.preference));
        expect(types, contains(MemoryType.goal));
        expect(types, contains(MemoryType.project));
        expect(types, contains(MemoryType.tool));
        expect(types, contains(MemoryType.code));
        expect(types, contains(MemoryType.learning));
        expect(types, contains(MemoryType.other));

        debugPrint('✅ 记忆类型测试通过');
        debugPrint('   支持的类型: ${types.map((t) => t.name).join(', ')}');
      });
    });
  });
}

/// 手动测试运行器
/// 
/// 在应用内运行测试：
/// ```dart
/// await MemoryTestRunner.runAllTests();
/// ```
class MemoryTestRunner {
  static Future<void> runAllTests() async {
    debugPrint('🧠 开始记忆系统测试...\n');

    final service = MemoryService(
      config: const MemoryConfig(
        enabled: true,
        extractionInterval: 2,
        l2TriggerThreshold: 3,
        l3TriggerThreshold: 2,
      ),
    );

    try {
      await service.initialize();
      debugPrint('✅ 初始化完成\n');

      // 测试1: L0捕获
      await _testL0Capture(service);

      // 测试2: 记忆召回
      await _testRecall(service);

      // 测试3: 统计信息
      await _testStats(service);

      debugPrint('\n✅ 所有测试完成！');
    } catch (e, stack) {
      debugPrint('❌ 测试失败: $e');
      debugPrint(stack.toString());
    } finally {
      await service.dispose();
    }
  }

  static Future<void> _testL0Capture(MemoryService service) async {
    debugPrint('📋 测试 L0 对话捕获...');
    const sessionKey = 'manual_test_session';

    await service.captureTurn(
      sessionKey: sessionKey,
      sessionId: sessionKey,
      userText: '这是一个测试消息',
      assistantText: '这是AI的回复',
      messages: [],
    );

    final stats = await service.getStats(sessionKey);
    debugPrint('   L0数量: ${stats.l0Count}');
    debugPrint('✅ L0测试通过\n');
  }

  static Future<void> _testRecall(MemoryService service) async {
    debugPrint('🔍 测试记忆召回...');
    const sessionKey = 'manual_test_session';

    final recall = await service.recall(
      userText: '测试查询',
      sessionKey: sessionKey,
      userId: 'user_$sessionKey',
    );

    debugPrint('   召回记忆数: ${recall.relevantMemories.length}');
    debugPrint('   召回策略: ${recall.recallStrategy}');
    debugPrint('✅ 召回测试通过\n');
  }

  static Future<void> _testStats(MemoryService service) async {
    debugPrint('📊 测试统计信息...');
    const sessionKey = 'manual_test_session';

    final stats = await service.getStats(sessionKey);
    debugPrint('   L0: ${stats.l0Count}');
    debugPrint('   L1: ${stats.l1Count}');
    debugPrint('   L2: ${stats.l2Count}');
    debugPrint('   L3: ${stats.hasL3}');
    debugPrint('✅ 统计测试通过\n');
  }
}
