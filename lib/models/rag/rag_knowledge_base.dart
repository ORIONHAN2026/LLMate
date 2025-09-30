import 'dart:convert';
import '../rag/rag_document.dart';

/// RAG 知识库数据结构
class RagKnowledgeBase {
  final String ragId;
  final List<RagDocument> documents;
  final Map<String, dynamic> stats;
  final DateTime lastUpdated;

  const RagKnowledgeBase({
    required this.ragId,
    required this.documents,
    required this.stats,
    required this.lastUpdated,
  });

  /// 从 Map 创建 RagKnowledgeBase
  factory RagKnowledgeBase.fromMap(Map<String, dynamic> map) {
    final documentsList = map['documents'] as List<dynamic>? ?? [];

    return RagKnowledgeBase(
      ragId: map['ragId'] ?? '',
      documents:
          documentsList
              .map(
                (docMap) => RagDocument.fromMap(docMap as Map<String, dynamic>),
              )
              .toList(),
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
      lastUpdated:
          map['lastUpdated'] != null
              ? DateTime.parse(map['lastUpdated'])
              : DateTime.now(),
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'ragId': ragId,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'stats': stats,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 从 JSON 字符串创建
  factory RagKnowledgeBase.fromJson(String source) =>
      RagKnowledgeBase.fromMap(json.decode(source));

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 复制并修改部分字段
  RagKnowledgeBase copyWith({
    String? ragId,
    List<RagDocument>? documents,
    Map<String, dynamic>? stats,
    DateTime? lastUpdated,
  }) {
    return RagKnowledgeBase(
      ragId: ragId ?? this.ragId,
      documents: documents ?? this.documents,
      stats: stats ?? this.stats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 添加文档
  RagKnowledgeBase addDocument(RagDocument document) {
    final newDocuments = List<RagDocument>.from(documents);

    // 检查是否已存在，如果存在则替换
    final existingIndex = newDocuments.indexWhere((d) => d.id == document.id);
    if (existingIndex != -1) {
      newDocuments[existingIndex] = document;
    } else {
      newDocuments.add(document);
    }

    return copyWith(
      documents: newDocuments,
      stats: _updateStats(),
      lastUpdated: DateTime.now(),
    );
  }

  /// 批量添加文档
  RagKnowledgeBase addDocuments(List<RagDocument> newDocuments) {
    final updatedDocuments = List<RagDocument>.from(documents);

    for (final doc in newDocuments) {
      final existingIndex = updatedDocuments.indexWhere((d) => d.id == doc.id);
      if (existingIndex != -1) {
        updatedDocuments[existingIndex] = doc;
      } else {
        updatedDocuments.add(doc);
      }
    }

    return copyWith(
      documents: updatedDocuments,
      stats: _updateStats(updatedDocuments),
      lastUpdated: DateTime.now(),
    );
  }

  /// 删除文档
  RagKnowledgeBase removeDocument(String documentId) {
    final newDocuments = documents.where((d) => d.id != documentId).toList();

    return copyWith(
      documents: newDocuments,
      stats: _updateStats(newDocuments),
      lastUpdated: DateTime.now(),
    );
  }

  /// 清空所有文档
  RagKnowledgeBase clearDocuments() {
    return copyWith(
      documents: [],
      stats: _updateStats([]),
      lastUpdated: DateTime.now(),
    );
  }

  /// 更新统计信息
  Map<String, dynamic> _updateStats([List<RagDocument>? docs]) {
    final docList = docs ?? documents;

    // 统计文件类型
    final fileTypes = <String, int>{};
    final chunkTypes = <String, int>{};
    final originalFiles = <String>{};

    for (final doc in docList) {
      // 文件扩展名统计
      if (doc.fileExtension != null) {
        fileTypes[doc.fileExtension!] =
            (fileTypes[doc.fileExtension!] ?? 0) + 1;
      }

   
      // 原始文件统计
      if (doc.filePath != null) {
        originalFiles.add(doc.filePath!);
      }
    }

    return {
      'total_documents': docList.length,
      'original_files_count': originalFiles.length,
      'file_types': fileTypes,
      'chunk_types': chunkTypes,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
 

  /// 获取文档数量
  int get documentCount => documents.length;

  /// 获取原始文件数量
  int get originalFilesCount {
    final files = <String>{};
    for (final doc in documents) {
      if (doc.filePath != null) {
        files.add(doc.filePath!);
      }
    }
    return files.length;
  }

  /// 是否为空
  bool get isEmpty => documents.isEmpty;

  /// 是否非空
  bool get isNotEmpty => documents.isNotEmpty;

  @override
  String toString() {
    return 'RagKnowledgeBase(ragId: $ragId, documents: ${documents.length}, files: $originalFilesCount)';
  }
}
