import 'package:flutter/foundation.dart';
import '../../models/rag/rag_chunk.dart';
import 'store_manager.dart';
import '../../../objectbox.g.dart';

/// 向量数据库服务
/// 基于文件系统的简单实现，用于存储和检索RAG文档切片
class VectorDatabaseService {
  final String _ragId;
  late final Store _store;
  late final Box<RagChunk> _chunkBox;

  VectorDatabaseService(String ragId, {Store? store}) : _ragId = ragId {
    _store = store ?? StoreManager.getStore(ragId);
    _chunkBox = _store.box<RagChunk>();
    _chunkBox.removeAllAsync();
  }

  /// 释放资源
  void dispose() {
    StoreManager.closeStore(_ragId);
  }

  /// 保存文档切片
  Future<void> saveChunks(List<RagChunk> chunks) async {
    await Future(() => _chunkBox.putMany(chunks));
    if (kDebugMode) {
      print('ObjectBox: 保存 ${chunks.length} 个切片');
    }
  }

  /// 根据文档ID获取所有切片
  Future<List<RagChunk>> getChunksByDocumentId(String documentId) async {
    final qBuilder = _chunkBox.query(RagChunk_.documentId.equals(documentId));
    final query = qBuilder.build();
    final result = query.find();
    query.close();
    return result;
  }

  /// 向量搜索
  Future<List<VectorSearchResult>> vectorSearch({
    required List<double> queryEmbeddings,
    required String modelId,
    int limit = 10,
    double similarityThreshold = 0.3,
  }) async {
    // 使用索引直接查询指定 modelId 的文档
    final qBuilder = _chunkBox.query(RagChunk_.modelId.equals(modelId));

    final query = qBuilder.build();
    final allChunks = query.find();
    query.close();

    final results = <VectorSearchResult>[];
    for (final chunk in allChunks) {
      final similarity = chunk.cosineSimilarity(queryEmbeddings);
      if (similarity != null && similarity >= similarityThreshold) {
        results.add(VectorSearchResult(chunk: chunk, similarity: similarity));
      }
    }
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results.take(limit).toList();
  }

  /// 删除文档的所有切片
  Future<void> deleteChunksByDocumentId(String documentId) async {
    final qBuilder = _chunkBox.query(RagChunk_.documentId.equals(documentId));
    final query = qBuilder.build();
    final chunks = query.find();
    query.close();
    if (chunks.isNotEmpty) {
      _chunkBox.removeMany(chunks.map((c) => c.obxId).toList());
      if (kDebugMode) {
        print('ObjectBox: 删除文档 $documentId 的 ${chunks.length} 个切片');
      }
    }
  }

  /// 获取数据库统计信息
  Future<VectorDatabaseStats> getStats() async {
    final totalChunks = _chunkBox.count();

    // 获取所有不重复的文档ID
    final query = _chunkBox.query().build();
    final allChunks = query.find();
    query.close();

    final uniqueDocIds = allChunks.map((c) => c.documentId).toSet();
    final totalDocuments = uniqueDocIds.length;
    final averageChunksPerDocument =
        totalDocuments > 0 ? (totalChunks / totalDocuments).toDouble() : 0.0;

    return VectorDatabaseStats(
      totalChunks: totalChunks,
      totalDocuments: totalDocuments,
      averageChunksPerDocument: averageChunksPerDocument,
    );
  }

  /// 清空数据库
  Future<void> clear() async {
    await Future(() => _chunkBox.removeAll());
    if (kDebugMode) {
      print('ObjectBox: 向量数据库已清空');
    }
  }
}

/// 向量搜索结果
class VectorSearchResult {
  final RagChunk chunk;
  final double similarity;

  VectorSearchResult({required this.chunk, required this.similarity});
}

/// 向量数据库统计信息
class VectorDatabaseStats {
  final int totalChunks;
  final int totalDocuments;
  final double averageChunksPerDocument;

  VectorDatabaseStats({
    required this.totalChunks,
    required this.totalDocuments,
    required this.averageChunksPerDocument,
  });
}
