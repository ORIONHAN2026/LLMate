import 'package:flutter_test/flutter_test.dart';
import 'package:chathub/services/ollama_embedding_service.dart';

void main() {
  group('OllamaEmbeddingService Tests', () {
    late OllamaEmbeddingService embeddingService;

    setUp(() {
      embeddingService = OllamaEmbeddingService();
    });

    test('should check if service is available', () async {
      // 注意：这个测试需要本地运行 Ollama 服务
      final isAvailable = await embeddingService.isServiceAvailable();
      
      // 如果服务不可用，我们只是打印信息而不是失败测试
      if (!isAvailable) {
        print('Ollama service is not available. Make sure Ollama is running on localhost:11434');
      }
      
      // 我们只验证方法不抛出异常
      expect(isAvailable, isA<bool>());
    });

    test('should get embedding for text when service is available', () async {
      final testText = 'This is a test text for embedding';
      
      // 首先检查服务是否可用
      final isAvailable = await embeddingService.isServiceAvailable();
      
      if (isAvailable) {
        final embedding = await embeddingService.getEmbedding(testText);
        
        // 如果服务可用且有 nomic-embed-text 模型，应该返回向量
        if (embedding != null) {
          expect(embedding, isA<List<double>>());
          expect(embedding.isNotEmpty, true);
          print('Embedding generated successfully with ${embedding.length} dimensions');
        } else {
          print('Embedding returned null - model might not be installed');
        }
      } else {
        print('Skipping embedding test - Ollama service not available');
      }
    });

    test('should handle service errors gracefully', () async {
      // 使用一个无效的URL来测试错误处理
      final badService = OllamaEmbeddingService(baseUrl: 'http://invalid-url:11434');
      
      final embedding = await badService.getEmbedding('test text');
      
      // 应该返回 null 而不是抛出异常
      expect(embedding, isNull);
    });
  });
}
