import 'dart:convert';
import 'dart:math' as math;

// 引入 ObjectBox 生成的代码
import '../../objectbox.g.dart';

/// RAG 文档切片模型
@Entity()
class RagChunk {
  @Id()
  int obxId = 0;

  String id; // 切片唯一标识符

  @Index()
  String modelId; // 所属模型ID

  @Index()
  String documentId; // 所属文档ID
  String content; // 切片内容
  int startPosition; // 在源文件中的起始位置
  int endPosition; // 在源文件中的结束位置
  int chunkIndex; // 切片在文档中的序号（从0开始）
  String sourceFilePath; // 源文件路径
  String? relativePath; // 相对路径（保持目录结构）
  String? folderName; // 文件夹名称

  @Property(type: PropertyType.date)
  DateTime createdTime; // 创建时间

  @Transient()
  Map<String, dynamic>? _metadata; // 额外元数据（内存中）

  String? _metadataJson; // 元数据的 JSON 存储

  Map<String, dynamic>? get metadata => _metadata;

  set metadata(Map<String, dynamic>? value) {
    _metadata = value;
    _metadataJson = value != null ? json.encode(value) : null;
  }

  List<double>? embeddings; // 向量化内容
  String? comment; // 注释

  RagChunk({
    this.obxId = 0,
    required this.id,
    required this.modelId,
    required this.documentId,
    required this.content,
    required this.startPosition,
    required this.endPosition,
    required this.chunkIndex,
    required this.sourceFilePath,
    this.relativePath,
    this.folderName,
    required this.createdTime,
    Map<String, dynamic>? metadata,
    this.embeddings,
    this.comment,
  }) {
    this.metadata = metadata;
  }

  /// 从 Map 创建 RagChunk
  factory RagChunk.fromMap(Map<String, dynamic> map) {
    return RagChunk(
      id: map['id'] ?? '',
      modelId: map['modelId'] ?? '',
      documentId: map['documentId'] ?? '',
      content: map['content'] ?? '',
      startPosition: map['startPosition']?.toInt() ?? 0,
      endPosition: map['endPosition']?.toInt() ?? 0,
      chunkIndex: map['chunkIndex']?.toInt() ?? 0,
      sourceFilePath: map['sourceFilePath'] ?? '',
      relativePath: map['relativePath'],
      folderName: map['folderName'],
      createdTime:
          map['createdTime'] != null
              ? DateTime.parse(map['createdTime'])
              : DateTime.now(),
      metadata:
          map['metadata'] != null
              ? (map['metadata'] is String
                  ? json.decode(map['metadata'])
                  : Map<String, dynamic>.from(map['metadata']))
              : null,
      embeddings:
          map['embeddings'] != null
              ? List<double>.from(map['embeddings'])
              : null,
      comment: map['comment'],
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'id': id,
      'modelId': modelId,
      'documentId': documentId,
      'content': content,
      'startPosition': startPosition,
      'endPosition': endPosition,
      'chunkIndex': chunkIndex,
      'sourceFilePath': sourceFilePath,
      'createdTime': createdTime.toIso8601String(),
    };

    if (relativePath != null) result['relativePath'] = relativePath;
    if (folderName != null) result['folderName'] = folderName;
    if (_metadataJson != null) result['metadata'] = _metadataJson;
    if (embeddings != null) result['embeddings'] = embeddings;
    if (comment != null) result['comment'] = comment;

    return result;
  }

  /// 从 JSON 字符串创建 RagChunk
  factory RagChunk.fromJson(String source) =>
      RagChunk.fromMap(json.decode(source));

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 复制并修改部分字段
  RagChunk copyWith({
    String? id,
    String? modelId,
    String? documentId,
    String? content,
    int? startPosition,
    int? endPosition,
    int? chunkIndex,
    String? sourceFilePath,
    String? relativePath,
    String? folderName,
    DateTime? createdTime,
    Map<String, dynamic>? metadata,
    List<double>? embeddings,
    String? comment,
  }) {
    return RagChunk(
      id: id ?? this.id,
      modelId: modelId ?? this.modelId,
      documentId: documentId ?? this.documentId,
      content: content ?? this.content,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      relativePath: relativePath ?? this.relativePath,
      folderName: folderName ?? this.folderName,
      createdTime: createdTime ?? this.createdTime,
      metadata: metadata ?? this.metadata,
      embeddings: embeddings ?? this.embeddings,
      comment: comment ?? this.comment,
    );
  }

  /// 获取切片内容长度
  int get contentLength => content.length;

  /// 获取切片在源文件中的位置范围
  String get positionRange => '$startPosition-$endPosition';

  /// 获取切片预览（前50个字符）
  String get preview {
    if (content.length <= 50) return content;
    return '${content.substring(0, 50)}...';
  }

  /// 检查切片是否包含特定文本
  bool contains(String text, {bool caseSensitive = false}) {
    if (caseSensitive) {
      return content.contains(text);
    } else {
      return content.toLowerCase().contains(text.toLowerCase());
    }
  }

  /// 创建文档切片的工厂方法
  factory RagChunk.create({
    required String modelId,
    required String documentId,
    required String content,
    required int startPosition,
    required int endPosition,
    required int chunkIndex,
    required String sourceFilePath,
    String? relativePath,
    String? folderName,
    Map<String, dynamic>? metadata,
    List<double>? embeddings,
    String? comment,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return RagChunk(
      id: 'chunk_${timestamp}_$chunkIndex',
      modelId: modelId,
      documentId: documentId,
      content: content,
      startPosition: startPosition,
      endPosition: endPosition,
      chunkIndex: chunkIndex,
      sourceFilePath: sourceFilePath,
      relativePath: relativePath,
      folderName: folderName,
      createdTime: DateTime.now(),
      metadata: {
        'content_length': content.length,
        'position_range': '$startPosition-$endPosition',
        ...?metadata,
      },
      embeddings: embeddings,
      comment: comment,
    );
  }

  @override
  String toString() {
    return 'RagChunk(id: $id, documentId: $documentId, index: $chunkIndex, length: $contentLength, position: $positionRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RagChunk && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// 在保存之前清除相同 modelId 和 documentId 的内容
  static void clearExistingDocument(
    Box<RagChunk> box,
    String modelId,
    String documentId,
  ) {
    final existing =
        box
            .query(
              RagChunk_.modelId
                  .equals(modelId)
                  .and(RagChunk_.documentId.equals(documentId)),
            )
            .build()
            .find();
    if (existing.isNotEmpty) {
      box.removeMany(existing.map((e) => e.obxId).toList());
    }
  }

  /// 计算与另一个向量的余弦相似度
  double? cosineSimilarity(List<double> otherEmbeddings) {
    if (embeddings == null) return null;

    if (embeddings!.length != otherEmbeddings.length) return null;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < embeddings!.length; i++) {
      dotProduct += embeddings![i] * otherEmbeddings[i];
      normA += embeddings![i] * embeddings![i];
      normB += otherEmbeddings[i] * otherEmbeddings[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
}
