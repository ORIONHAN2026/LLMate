import 'package:flutter_test/flutter_test.dart';
import 'package:llmate/features/models/services/model_endpoint_builder.dart';

void main() {
  group('ModelEndpointBuilder', () {
    test('appends OpenAI chat completions path once', () {
      expect(
        ModelEndpointBuilder.chatCompletionUrl(
          baseUrl: 'https://api.example.com/v1',
          protocol: 'openai',
          modelId: 'gpt-test',
          apiKey: 'key',
        ),
        'https://api.example.com/v1/chat/completions',
      );

      expect(
        ModelEndpointBuilder.chatCompletionUrl(
          baseUrl: 'https://api.example.com/v1/chat/completions',
          protocol: 'openai',
          modelId: 'gpt-test',
          apiKey: 'key',
        ),
        'https://api.example.com/v1/chat/completions',
      );
    });

    test('appends Anthropic messages path once', () {
      expect(
        ModelEndpointBuilder.chatCompletionUrl(
          baseUrl: 'https://api.anthropic.com/v1/',
          protocol: 'anthropic',
          modelId: 'claude-test',
          apiKey: 'key',
        ),
        'https://api.anthropic.com/v1/messages',
      );
    });

    test('builds Gemini model URL when base endpoint is provided', () {
      expect(
        ModelEndpointBuilder.chatCompletionUrl(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          protocol: 'gemini',
          modelId: 'gemini-test',
          apiKey: 'abc123',
        ),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-test:generateContent?key=abc123',
      );
    });
  });
}
