import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/features/models/view_models/model_connection_test_state.dart';

void main() {
  group('ModelConnectionTestState', () {
    test('tracks start, failure, and reset lifecycle', () {
      final state = ModelConnectionTestState();

      state.start();
      expect(state.isTesting, isTrue);
      expect(state.completed, isFalse);
      expect(state.passed, isFalse);
      expect(state.response, isEmpty);

      state.fail('bad config');
      expect(state.isTesting, isFalse);
      expect(state.completed, isTrue);
      expect(state.passed, isFalse);
      expect(state.response, 'bad config');

      state.resetIfCompleted();
      expect(state.completed, isFalse);
      expect(state.response, isEmpty);
    });

    test('finishes successful streamed response', () {
      final state = ModelConnectionTestState()..start();

      state.stream('hello');
      expect(state.completed, isFalse);
      expect(state.response, 'hello');

      state.finish(
        hasReceived: true,
        accumulatedResponse: 'hello',
        emptyResponseMessage: 'empty',
        noResponseMessage: 'none',
      );

      expect(state.isTesting, isFalse);
      expect(state.completed, isTrue);
      expect(state.passed, isTrue);
      expect(state.response, 'hello');
    });
  });
}
