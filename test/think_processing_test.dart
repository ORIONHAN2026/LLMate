import 'package:flutter_test/flutter_test.dart';
import '../lib/framework/llmproviders/base_provider.dart';

/// 测试用的Provider实现
class TestProvider extends BaseLlmProvider {
  @override
  Stream<Map<String, String?>> sendMessageStream({
    required userMessage,
    session,
  }) async* {
    // 测试用的空实现
    yield {'content': 'test', 'think': null};
  }
}

void main() {
  group('Think Content Processing Tests', () {
    late TestProvider provider;

    setUp(() {
      provider = TestProvider();
    });

    test('基础think标签处理', () {
      const content = '这是正文内容<think>这是思考内容</think>更多正文内容';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], equals('这是正文内容更多正文内容'));
      expect(result['think'], equals('这是思考内容'));
      expect(result['insideThinkTag'], equals(false));
    });

    test('跨chunk的think标签处理 - 开始', () {
      const content = '正文内容<think>思考开始';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], equals('正文内容'));
      expect(result['think'], equals('思考开始'));
      expect(result['insideThinkTag'], equals(true));
    });

    test('跨chunk的think标签处理 - 中间', () {
      const content = '思考继续中';
      final result = provider.processContentWithThink(content, true);
      
      expect(result['content'], isNull);
      expect(result['think'], equals('思考继续中'));
      expect(result['insideThinkTag'], equals(true));
    });

    test('跨chunk的think标签处理 - 结束', () {
      const content = '思考结束</think>后续正文内容';
      final result = provider.processContentWithThink(content, true);
      
      expect(result['content'], equals('后续正文内容'));
      expect(result['think'], equals('思考结束'));
      expect(result['insideThinkTag'], equals(false));
    });

    test('没有think标签的内容', () {
      const content = '纯正文内容';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], equals('纯正文内容'));
      expect(result['think'], isNull);
      expect(result['insideThinkTag'], equals(false));
    });

    test('多个think标签处理', () {
      const content = '开始<think>第一个思考</think>中间<think>第二个思考</think>结束';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], equals('开始中间结束'));
      expect(result['think'], equals('第一个思考第二个思考'));
      expect(result['insideThinkTag'], equals(false));
    });

    test('空内容处理', () {
      const content = '';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], isNull);
      expect(result['think'], isNull);
      expect(result['insideThinkTag'], equals(false));
    });

    test('只有think标签内容', () {
      const content = '<think>只有思考内容</think>';
      final result = provider.processContentWithThink(content, false);
      
      expect(result['content'], isNull);
      expect(result['think'], equals('只有思考内容'));
      expect(result['insideThinkTag'], equals(false));
    });
  });
}
