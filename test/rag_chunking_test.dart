import 'package:flutter_test/flutter_test.dart';
import 'package:chathub/framework/ragproviders/base_rag_provider.dart';
import 'package:chathub/models/rag/rag_document.dart';
import 'package:chathub/models/bigmodel/chat_model.dart';

// 测试用的具体实现
class TestRagProvider extends BaseRagProvider {
  @override
  Future<bool> addDocumentToKnowledgeBase(String knowledgeBaseId, String documentId) async {
    return true;
  }

  @override
  Future<bool> removeDocumentFromKnowledgeBase(String knowledgeBaseId, String documentId) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> searchDocuments(String knowledgeBaseId, String query, {int limit = 10}) async {
    return [];
  }

  @override
  Future<bool> updateDocumentInKnowledgeBase(String knowledgeBaseId, String documentId, Map<String, dynamic> updates) async {
    return true;
  }
}

void main() {
  group('RAG Provider Tests', () {
    late TestRagProvider ragProvider;
    late ChatModel testModel;

    setUp(() {
      ragProvider = TestRagProvider();
      testModel = ChatModel(
        modelId: 'test-model',
        displayName: 'Test Model',
        provider: 'test',
        modelName: 'test-model',
        inputTokenPrice: 0.001,
        outputTokenPrice: 0.002,
        supportFileType: ['txt', 'md', 'dart'],
        maxTokens: 4096,
        isVisible: true,
      );
      
      // 配置模型
      ragProvider.configureModel(testModel);
    });

    test('should initialize correctly', () {
      expect(ragProvider.model, equals(testModel));
    });

    test('should create chunks for Dart code', () async {
      // 测试文档
      final document = RagDocument.create(
        fileName: 'test.dart',
        filePath: '/test/test.dart',
        fileExtension: '.dart',
        fileSize: 1024,
        content: '''
class TestClass {
  String name;
  
  TestClass(this.name);
  
  void greet() {
    print('Hello, \$name!');
  }
}

void main() {
  final test = TestClass('World');
  test.greet();
}
''',
        metadata: {
          'relativePath': 'test.dart',
          'folderName': 'test',
        },
      );

      // 测试分块功能
      final chunks = await ragProvider.chunkDocument(document);
      
      // 验证分块结果
      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThan(0));
      
      // 验证分块内容
      for (final chunk in chunks) {
        expect(chunk.documentId, equals(document.id));
        expect(chunk.sourceFilePath, equals(document.filePath));
        expect(chunk.content, isNotEmpty);
      }
    });

    test('should create chunks for Go code', () async {
      final document = RagDocument.create(
        fileName: 'test.go',
        filePath: '/test/test.go',
        fileExtension: '.go',
        fileSize: 512,
        content: '''
package main

import "fmt"

type Person struct {
    Name string
    Age  int
}

func (p Person) Greet() {
    fmt.Printf("Hello, I'm %s and I'm %d years old\\n", p.Name, p.Age)
}

func main() {
    person := Person{Name: "Alice", Age: 30}
    person.Greet()
}
''',
        metadata: {
          'relativePath': 'test.go',
          'folderName': 'test',
        },
      );

      final chunks = await ragProvider.chunkDocument(document);
      
      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThan(0));
    });

    test('should create chunks for markdown file', () async {
      final document = RagDocument.create(
        fileName: 'test.md',
        filePath: '/test/test.md',
        fileExtension: '.md',
        fileSize: 256,
        content: '''
# Title

This is a test markdown file.

## Section 1

Some content here.

## Section 2

More content here.

### Subsection

Even more content.
''',
        metadata: {
          'relativePath': 'test.md',
          'folderName': 'test',
        },
      );

      final chunks = await ragProvider.chunkDocument(document);
      
      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThan(0));
    });

    test('should handle empty document', () async {
      final document = RagDocument.create(
        fileName: 'empty.txt',
        filePath: '/test/empty.txt',
        fileExtension: '.txt',
        fileSize: 0,
        content: '',
        metadata: {
          'relativePath': 'empty.txt',
          'folderName': 'test',
        },
      );

      final chunks = await ragProvider.chunkDocument(document);
      
      expect(chunks, isEmpty);
    });

    test('should create chunks for JSON file', () async {
      final document = RagDocument.create(
        fileName: 'test.json',
        filePath: '/test/test.json',
        fileExtension: '.json',
        fileSize: 128,
        content: '''
{
  "name": "John Doe",
  "age": 30,
  "email": "john@example.com",
  "address": {
    "street": "123 Main St",
    "city": "Anytown",
    "zip": "12345"
  },
  "hobbies": ["reading", "swimming", "coding"]
}
''',
        metadata: {
          'relativePath': 'test.json',
          'folderName': 'test',
        },
      );

      final chunks = await ragProvider.chunkDocument(document);
      
      expect(chunks, isNotEmpty);
      expect(chunks.length, greaterThan(0));
    });
  });
}
