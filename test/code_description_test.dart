import 'package:flutter_test/flutter_test.dart';
import 'package:chathub/models/rag/rag_document.dart';
import 'package:chathub/models/rag/rag_chunk.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/framework/ragproviders/base_rag_provider.dart';

// 创建一个测试用的RAG提供商实现
class TestRagProvider extends BaseRagProvider {
  @override
  Future<List<String>> search(String query, {int limit = 10}) async {
    return [];
  }

  @override
  Future<bool> deleteDocument(String documentId) async {
    return true;
  }

  @override
  Future<bool> deleteKnowledgeBase() async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    return [];
  }

  @override
  Future<bool> addKnowledgeBase(String name, String description) async {
    return true;
  }

  @override
  Future<bool> addDocument(RagDocument document) async {
    return true;
  }
}

void main() {
  group('Code Description Generation Tests', () {
    late TestRagProvider ragProvider;
    late ChatModel testModel;

    setUp(() {
      ragProvider = TestRagProvider();
      
      // 创建一个测试用的模型配置
      testModel = const ChatModel(
        modelId: 'test-model',
        name: 'Test Model',
        model: 'gpt-3.5-turbo',
        status: 'active',
        provider: 'openai',
        apiUrl: 'https://api.openai.com/v1',
        apiKey: 'test-api-key',
      );
      
      ragProvider.configure(testModel);
    });

    test('should identify Go language from extension', () {
      // 测试语言识别功能
      expect(ragProvider._getLanguageName('.go'), equals('Go'));
      expect(ragProvider._getLanguageName('.dart'), equals('Dart'));
      expect(ragProvider._getLanguageName('.py'), equals('Python'));
      expect(ragProvider._getLanguageName('.js'), equals('JavaScript'));
    });

    test('should build appropriate code description prompt', () {
      const goCode = '''
func calculateSum(a, b int) int {
    return a + b
}''';
      
      final prompt = ragProvider._buildCodeDescriptionPrompt(goCode, '.go');
      
      expect(prompt, contains('Go代码片段'));
      expect(prompt, contains('calculateSum'));
      expect(prompt, contains('简要说明这个代码片段的功能'));
    });

    test('should chunk Go code with function extraction', () async {
      const goFileContent = '''
package main

import "fmt"

// calculateSum 计算两个整数的和
func calculateSum(a, b int) int {
    return a + b
}

// printMessage 打印消息
func printMessage(msg string) {
    fmt.Println(msg)
}

func main() {
    result := calculateSum(1, 2)
    printMessage("Hello World")
}''';

      final document = RagDocument.create(
        filePath: '/test/main.go',
        fileName: 'main.go',
        fileExtension: '.go',
        fileSize: goFileContent.length,
      );

      // 测试Go代码分块
      final chunks = await ragProvider._chunkGoCode(document, goFileContent, goFileContent.split('\n'));
      
      // 应该提取出3个函数
      expect(chunks.length, equals(3));
      
      // 检查函数名是否正确提取
      expect(chunks.any((chunk) => chunk.content.contains('calculateSum')), isTrue);
      expect(chunks.any((chunk) => chunk.content.contains('printMessage')), isTrue);
      expect(chunks.any((chunk) => chunk.content.contains('main()')), isTrue);
    });

    test('should handle embedding with comment and content', () async {
      final chunk = RagChunk.create(
        documentId: 'test-doc',
        content: 'func test() { return }',
        startPosition: 0,
        endPosition: 20,
        chunkIndex: 0,
        sourceFilePath: '/test.go',
        comment: '这是一个测试函数',
      );

      final chunks = [chunk];
      
      // 模拟向量化过程中的文本合并
      String textForEmbedding = chunk.content;
      if (chunk.comment != null && chunk.comment!.isNotEmpty) {
        textForEmbedding = '${chunk.content}\n\n功能描述: ${chunk.comment}';
      }
      
      expect(textForEmbedding, contains('func test()'));
      expect(textForEmbedding, contains('功能描述: 这是一个测试函数'));
    });
  });
}
