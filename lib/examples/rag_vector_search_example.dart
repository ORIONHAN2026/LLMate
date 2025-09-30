import 'package:flutter/foundation.dart';
import '../framework/ragproviders/base_rag_provider.dart';
import '../models/rag/rag_document.dart';
import '../framework/services/vector_database_service.dart';

/// RAG 向量搜索使用示例
/// 展示如何使用新增的 saveChunkDocument 函数和向量搜索功能
class RagVectorSearchExample {
  final BaseRagProvider ragProvider;

  RagVectorSearchExample(this.ragProvider);

  /// 示例：处理文档并保存到向量数据库
  Future<void> processAndSaveDocument(RagDocument document) async {
    try {
      if (kDebugMode) {
        print('开始处理文档: ${document.fileName}');
      }

      // 1. 对文档进行分块处理（会自动保存到向量数据库）
      final chunks = await ragProvider.chunkDocument(document);
      
      if (chunks.isNotEmpty) {
        if (kDebugMode) {
          print('文档处理完成，生成 ${chunks.length} 个分块并已保存到向量数据库');
        }
      } else {
        if (kDebugMode) {
          print('文档处理失败或未生成分块');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('处理文档时发生错误: $e');
      }
    }
  }

  /// 示例：执行向量搜索
  Future<List<VectorSearchResult>> searchDocuments({
    required String query,
    int limit = 5,
    double similarityThreshold = 0.3,
    String? specificDocumentId,
  }) async {
    try {
      if (kDebugMode) {
        print('开始向量搜索，查询: "$query"');
      }

      // 执行向量搜索
      final results = await ragProvider.searchRagDocuments(
        query: 'Flutter 开发最佳实践',
      );

      if (kDebugMode) {
        print('搜索完成，找到 ${results.length} 个相关片段');
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          print('结果 ${i + 1}: 相似度 ${result.similarity.toStringAsFixed(3)} - ${result.chunk.content.substring(0, 100)}...');
        }
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('向量搜索时发生错误: $e');
      }
      return [];
    }
  }

  /// 示例：获取向量数据库统计信息
  Future<void> printDatabaseStats() async {
    try {
      final stats = await ragProvider.getVectorDatabaseStats();
      
      if (stats != null) {
        if (kDebugMode) {
          print('=== 向量数据库统计信息 ===');
          print('总分块数: ${stats.totalChunks}');
          print('总文档数: ${stats.totalDocuments}');
          print('平均每文档分块数: ${stats.averageChunksPerDocument.toStringAsFixed(1)}');
        }
      } else {
        if (kDebugMode) {
          print('无法获取向量数据库统计信息');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('获取统计信息时发生错误: $e');
      }
    }
  }

  /// 示例：在特定文档中搜索
  Future<List<VectorSearchResult>> searchInDocument({
    required String documentId,
    required String query,
    int limit = 3,
  }) async {
    try {
      if (kDebugMode) {
        print('在文档 $documentId 中搜索: "$query"');
      }

      final results = await ragProvider.searchRagDocuments(
        query: 'TypeScript 接口设计',
      );

      if (kDebugMode) {
        print('在文档内搜索完成，找到 ${results.length} 个相关片段');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('文档内搜索时发生错误: $e');
      }
      return [];
    }
  }

  /// 示例：删除文档的向量数据
  Future<void> deleteDocumentVectors(String documentId) async {
    try {
      if (kDebugMode) {
        print('删除文档 $documentId 的向量数据');
      }

      final success = await ragProvider.deleteDocumentVectorData(documentId);
      
      if (success) {
        if (kDebugMode) {
          print('文档向量数据删除成功');
        }
      } else {
        if (kDebugMode) {
          print('文档向量数据删除失败');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('删除文档向量数据时发生错误: $e');
      }
    }
  }

  /// 示例：批量处理多个文档
  Future<void> batchProcessDocuments(List<RagDocument> documents) async {
    try {
      if (kDebugMode) {
        print('开始批量处理 ${documents.length} 个文档');
      }

      for (int i = 0; i < documents.length; i++) {
        final document = documents[i];
        if (kDebugMode) {
          print('处理文档 ${i + 1}/${documents.length}: ${document.fileName}');
        }

        await processAndSaveDocument(document);
        
        // 可选：在处理完每个文档后暂停一下，避免过度占用资源
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (kDebugMode) {
        print('批量处理完成');
        await printDatabaseStats();
      }
    } catch (e) {
      if (kDebugMode) {
        print('批量处理文档时发生错误: $e');
      }
    }
  }

  /// 示例：智能问答 - 根据查询找到最相关的内容片段
  Future<String?> answerQuestion(String question) async {
    try {
      if (kDebugMode) {
        print('回答问题: "$question"');
      }

      // 搜索相关片段
      final results = await searchDocuments(
        query: question,
        limit: 3,
        similarityThreshold: 0.4,
      );

      if (results.isEmpty) {
        if (kDebugMode) {
          print('未找到相关内容');
        }
        return null;
      }

      // 组合最相关的片段作为答案基础
      final context = results
          .map((result) => result.chunk.content)
          .join('\n\n---\n\n');

      if (kDebugMode) {
        print('基于 ${results.length} 个相关片段构建答案上下文');
      }

      return context;
    } catch (e) {
      if (kDebugMode) {
        print('回答问题时发生错误: $e');
      }
      return null;
    }
  }
}

/// 使用示例函数
Future<void> demonstrateVectorSearch(BaseRagProvider ragProvider) async {
  final example = RagVectorSearchExample(ragProvider);

  // 假设有一些文档需要处理
  final sampleDocuments = <RagDocument>[
    // 这里应该是实际的 RagDocument 实例
  ];

  // 1. 批量处理文档
  await example.batchProcessDocuments(sampleDocuments);

  // 2. 执行搜索
  await example.searchDocuments(query: "如何实现向量搜索？");

  // 3. 智能问答
  final answer = await example.answerQuestion("什么是RAG？");
  if (answer != null) {
    if (kDebugMode) {
      print('问答结果: $answer');
    }
  }

  // 4. 查看统计信息
  await example.printDatabaseStats();
}
