import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/core/router/model_router.dart';
import 'package:llmate/models/chat/session.dart';
import 'package:llmate/models/model.dart';

void main() {
  group('ModelRouter.decideForSessionDetailed', () {
    test(
      'keeps manually selected session model when auto select is disabled',
      () {
        final session = _session(autoSelect: false, selectedModel: 'gpt-5');

        final decision = ModelRouter.decideForSessionDetailed(
          session: session,
          body: _body('你好'),
        );

        expect(decision.modelId, 'gpt-5');
        expect(decision.usedCapable, isFalse);
      },
    );

    test('uses configured model when routing is disabled', () {
      final session = _session(autoSelect: true, routingEnabled: false);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('请帮我深入分析这个架构问题'),
      );

      expect(decision.modelId, 'gpt-5-mini');
      expect(decision.usedCapable, isFalse);
    });

    test('uses lightweight model for simple chat', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('你好'),
      );

      expect(decision.modelId, 'gpt-5-mini');
      expect(decision.simpleIntentHit, isTrue);
      expect(decision.usedCapable, isFalse);
    });

    test('uses capable model for coding intent', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('请帮我重构这个函数，并补充测试'),
      );

      expect(decision.modelId, 'gpt-5');
      expect(decision.intentHit, isTrue);
      expect(decision.usedCapable, isTrue);
    });

    test('does not treat tool_choice none as tool usage', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: {
          ..._body('你好'),
          'tools': [
            {'type': 'function'},
          ],
          'tool_choice': 'none',
        },
      );

      expect(decision.hasTools, isFalse);
      expect(decision.modelId, 'gpt-5-mini');
    });

    test('uses capable model when tools are available', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: {
          ..._body('查一下数据库里的订单状态'),
          'tools': [
            {'type': 'function'},
          ],
          'tool_choice': 'auto',
        },
      );

      expect(decision.hasTools, isTrue);
      expect(decision.modelId, 'gpt-5');
    });

    test('uses capable model for multimodal input', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: {
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': '看一下这张图'},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'https://example.com/a.png'},
                },
              ],
            },
          ],
        },
      );

      expect(decision.hasMultimodal, isTrue);
      expect(decision.modelId, 'gpt-5');
    });

    test('uses capable model for strict structured output', () {
      final session = _session(autoSelect: true);

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: {
          ..._body('提取这段文本的信息'),
          'response_format': {'type': 'json_schema'},
        },
      );

      expect(decision.structuredOutputHit, isTrue);
      expect(decision.modelId, 'gpt-5');
    });

    test('does not upgrade only because medium context is present', () {
      final session = _session(autoSelect: true);
      final longHistory = List.generate(80, (index) => '普通聊天内容$index').join();

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: {
          'messages': [
            {'role': 'user', 'content': longHistory},
            {'role': 'user', 'content': '好的'},
          ],
        },
      );

      expect(decision.modelId, 'gpt-5-mini');
      expect(decision.usedCapable, isFalse);
    });

    test('fallback to capable model is only active in auto select mode', () {
      final manualSession = _session(autoSelect: false);
      final autoSession = _session(autoSelect: true);

      expect(ModelRouter.fallbackModelFor(manualSession, 'gpt-5-mini'), isNull);
      expect(ModelRouter.fallbackModelFor(autoSession, 'gpt-5-mini'), 'gpt-5');
    });

    test('repairs reversed configured lightweight and capable models', () {
      final session = _session(
        autoSelect: true,
        lightweightModel: 'gpt-5',
        capableModel: 'gpt-5-mini',
      );

      final simple = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('你好'),
      );
      final complex = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('请帮我重构这个函数'),
      );

      expect(simple.lightweightModel, 'gpt-5-mini');
      expect(simple.capableModel, 'gpt-5');
      expect(simple.modelId, 'gpt-5-mini');
      expect(complex.modelId, 'gpt-5');
    });

    test('ignores stale configured model ids that are not available', () {
      final session = _session(
        autoSelect: true,
        lightweightModel: 'removed-mini',
        capableModel: 'removed-pro',
      );

      final decision = ModelRouter.decideForSessionDetailed(
        session: session,
        body: _body('请帮我深入分析这个问题'),
      );

      expect(decision.lightweightModel, 'gpt-5-mini');
      expect(decision.capableModel, 'gpt-5');
      expect(decision.modelId, 'gpt-5');
    });

    test(
      'repairs identical configured lightweight and capable models when possible',
      () {
        final session = _session(
          autoSelect: true,
          lightweightModel: 'gpt-5-mini',
          capableModel: 'gpt-5-mini',
        );

        final decision = ModelRouter.decideForSessionDetailed(
          session: session,
          body: _body('请帮我规划一个复杂方案'),
        );

        expect(decision.lightweightModel, 'gpt-5-mini');
        expect(decision.capableModel, 'gpt-5');
        expect(decision.modelId, 'gpt-5');
      },
    );
  });
}

Map<String, dynamic> _body(String text) {
  return {
    'messages': [
      {'role': 'user', 'content': text},
    ],
  };
}

ChatSession _session({
  required bool autoSelect,
  bool routingEnabled = true,
  String? selectedModel,
  String lightweightModel = 'gpt-5-mini',
  String capableModel = 'gpt-5',
}) {
  return ChatSession(
    sessionId: 'session-1',
    name: 'Session',
    createdAt: DateTime(2026),
    messages: const [],
    model: selectedModel,
    autoSelectModel: autoSelect,
    chatModel: ChatModel(
      modelId: 'model-1',
      name: 'OpenAI',
      model: 'gpt-5-mini',
      availableModels: const ['gpt-5-mini', 'gpt-5'],
      lightweightModel: lightweightModel,
      capableModel: capableModel,
      routingEnabled: routingEnabled,
    ),
  );
}
