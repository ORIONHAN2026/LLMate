import 'dart:io';
import 'package:flutter/foundation.dart';
import 'memory_models.dart';
import 'memory_service.dart';

/// 记忆系统演示程序
///
/// 运行方式：flutter run -d <device_id> lib/memory/memory_demo.dart
/// 或直接在应用内调用：MemoryDemo.run();
class MemoryDemo {
  static Future<void> run() async {
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║      腾讯DB-Agent-Memory 记忆系统演示     ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('');

    // 初始化
    final service = MemoryService(
      config: const MemoryConfig(
        enabled: true,
        recallStrategy: 'keyword',
        maxRecallResults: 5,
        extractionInterval: 2,
        l2TriggerThreshold: 3,
        l3TriggerThreshold: 2,
        enableDeduplication: true,
      ),
    );

    try {
      await service.initialize();
      debugPrint('✅ 记忆系统初始化完成\n');

      const sessionKey = 'demo_session_001';

      // 步骤1: 模拟对话
      await _simulateConversation(service, sessionKey);

      // 步骤2: 展示统计
      await _showStats(service, sessionKey);

      // 步骤3: 测试召回
      await _testRecall(service, sessionKey);

      // 步骤4: 导出数据
      await _exportData(service, sessionKey);

      debugPrint('\n✅ 演示完成！');
    } catch (e, stack) {
      debugPrint('❌ 错误: $e');
      debugPrint(stack.toString());
    } finally {
      await service.dispose();
    }
  }

  /// 模拟多轮对话
  static Future<void> _simulateConversation(
    MemoryService service,
    String sessionKey,
  ) async {
    debugPrint('📱 步骤1: 模拟多轮对话 (5轮)...');
    debugPrint('─────────────────────────────────────────');

    final conversations = [
      {
        'user': '你好，我想做一个Flutter聊天应用',
        'assistant': '你好！Flutter非常适合做聊天应用。我们可以使用ListView.builder来展示消息列表。',
      },
      {
        'user': '我喜欢使用GetX做状态管理',
        'assistant': 'GetX是个不错的选择！它轻量且功能强大。我们可以用GetXController来管理聊天状态。',
      },
      {
        'user': '界面要用深色模式',
        'assistant': '没问题，Flutter的ThemeData可以轻松实现深色模式。我会记住你的偏好。',
      },
      {
        'user': '需要支持图片发送',
        'assistant': '可以！我们可以用image_picker选择图片，然后base64编码发送。',
      },
      {
        'user': '用DeepSeek模型做AI回复',
        'assistant': '好的，DeepSeek-V3是优秀的开源模型。我们需要配置API密钥和基础URL。',
      },
    ];

    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      debugPrint('  对话 ${i + 1}: ${conv['user']!.substring(0, conv['user']!.length > 20 ? 20 : conv['user']!.length)}...');

      await service.captureTurn(
        sessionKey: sessionKey,
        sessionId: sessionKey,
        userText: conv['user']!,
        assistantText: conv['assistant']!,
        messages: [
          {'role': 'user', 'content': conv['user']},
          {'role': 'assistant', 'content': conv['assistant']},
        ],
      );

      // 模拟真实对话间隔
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('✅ 对话捕获完成\n');

    // 等待L1提取
    debugPrint('⏳ 等待L1记忆提取 (约2秒)...');
    await Future.delayed(const Duration(seconds: 2));
  }

  /// 展示统计信息
  static Future<void> _showStats(MemoryService service, String sessionKey) async {
    debugPrint('📊 步骤2: 记忆统计信息');
    debugPrint('─────────────────────────────────────────');

    final stats = await service.getStats(sessionKey);

    debugPrint('  L0 (原始对话): ${stats.l0Count} 条');
    debugPrint('  L1 (原子记忆): ${stats.l1Count} 条');
    debugPrint('  L2 (场景聚类): ${stats.l2Count} 个');
    debugPrint('  L3 (用户画像): ${stats.hasL3 ? '已生成' : '未生成'}');

    if (stats.l1Count > 0) {
      debugPrint('');
      debugPrint('  📝 L1记忆示例:');
      final memories = await service.searchMemories(
        query: 'Flutter',
        sessionKey: sessionKey,
        limit: 3,
      );
      for (var i = 0; i < memories.length && i < 3; i++) {
        final m = memories[i];
        debugPrint('    ${i + 1}. [${m.type.name}] ${m.content.substring(0, m.content.length > 35 ? 35 : m.content.length)}...');
      }
    }

    debugPrint('');
  }

  /// 测试记忆召回
  static Future<void> _testRecall(MemoryService service, String sessionKey) async {
    debugPrint('🔍 步骤3: 测试记忆召回');
    debugPrint('─────────────────────────────────────────');

    // 测试查询1
    final query1 = '界面颜色怎么设置？';
    debugPrint('  查询: "$query1"');
    final recall1 = await service.recall(
      userText: query1,
      sessionKey: sessionKey,
      userId: 'user_$sessionKey',
    );
    debugPrint('  召回 ${recall1.relevantMemories.length} 条记忆');
    if (recall1.relevantMemories.isNotEmpty) {
      for (final m in recall1.relevantMemories.take(2)) {
        debugPrint('    - ${m.content.substring(0, m.content.length > 30 ? 30 : m.content.length)}...');
      }
    }
    debugPrint('');

    // 测试查询2
    final query2 = '用什么状态管理？';
    debugPrint('  查询: "$query2"');
    final recall2 = await service.recall(
      userText: query2,
      sessionKey: sessionKey,
      userId: 'user_$sessionKey',
    );
    debugPrint('  召回 ${recall2.relevantMemories.length} 条记忆');
    if (recall2.relevantMemories.isNotEmpty) {
      for (final m in recall2.relevantMemories.take(2)) {
        debugPrint('    - ${m.content.substring(0, m.content.length > 30 ? 30 : m.content.length)}...');
      }
    }
    debugPrint('');

    // 展示格式化后的记忆上下文
    if (recall1.relevantMemories.isNotEmpty) {
      debugPrint('  📝 格式化后的记忆上下文:');
      debugPrint(recall1.formattedMemoryContext.split('\n').map((l) => '    $l').join('\n'));
    }

    debugPrint('');
  }

  /// 导出数据
  static Future<void> _exportData(MemoryService service, String sessionKey) async {
    debugPrint('📤 步骤4: 导出会话记忆');
    debugPrint('─────────────────────────────────────────');

    final export = await service.exportSession(sessionKey);

    debugPrint('  导出时间: ${export['exportedAt']}');
    debugPrint('  L0对话: ${(export['l0Conversations'] as List).length} 条');
    debugPrint('  L1记忆: ${(export['l1Memories'] as List).length} 条');
    debugPrint('  L2场景: ${(export['l2Scenes'] as List).length} 个');

    // 展示L0对话示例
    if ((export['l0Conversations'] as List).isNotEmpty) {
      debugPrint('');
      debugPrint('  📝 L0对话示例:');
      final l0List = export['l0Conversations'] as List;
      for (var i = 0; i < l0List.length && i < 2; i++) {
        final conv = l0List[i] as Map<String, dynamic>;
        debugPrint('    ${i + 1}. 用户: ${conv['userText'].toString().substring(0, conv['userText'].toString().length > 25 ? 25 : conv['userText'].toString().length)}...');
      }
    }

    debugPrint('');
  }
}

/// 快速测试入口
///
/// 在应用内调用：
/// ```dart
/// import 'memory/memory_demo.dart';
/// 
/// // 在某处调用
/// MemoryDemo.run();
/// ```
void main() {
  // 这是一个占位main函数
  // 实际运行时请使用：flutter run lib/memory/memory_demo.dart
  debugPrint('请在应用内调用 MemoryDemo.run() 运行演示');
}
