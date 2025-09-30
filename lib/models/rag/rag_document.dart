import 'dart:convert';

/// RAG 文档模型（简化版，只存储文件信息）
class RagDocument {
  final String id; // 文档唯一标识符
  final String filePath; // 文件存储路径
  final String fileName; // 文件名
  final String title; // 显示标题
  final String? fileExtension; // 文件扩展名
  final int? fileSize; // 文件大小（字节）
  final String status; // 文件状态：'uploaded', 'processing', 'ready', 'error'
  final DateTime uploadTime; // 上传时间
  final String? source; // 来源：'file_upload', 'folder_upload', 'git_import'
  final Map<String, dynamic>? metadata; // 额外元数据

  const RagDocument({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.title,
    this.fileExtension,
    this.fileSize,
    required this.status,
    required this.uploadTime,
    this.source,
    this.metadata,
  });

  /// 从 Map 创建 RagDocument
  factory RagDocument.fromMap(Map<String, dynamic> map) {
    return RagDocument(
      id: map['id'] ?? '',
      filePath: map['filePath'] ?? '',
      fileName: map['fileName'] ?? '',
      title: map['title'] ?? map['fileName'] ?? '',
      fileExtension: map['fileExtension'],
      fileSize: map['fileSize']?.toInt(),
      status: map['status'] ?? 'uploaded',
      uploadTime: map['uploadTime'] != null 
          ? DateTime.parse(map['uploadTime']) 
          : DateTime.now(),
      source: map['source'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'title': title,
      'status': status,
      'uploadTime': uploadTime.toIso8601String(),
    };

    if (fileExtension != null) result['fileExtension'] = fileExtension;
    if (fileSize != null) result['fileSize'] = fileSize;
    if (source != null) result['source'] = source;
    if (metadata != null) result['metadata'] = metadata;

    return result;
  }

  /// 从 JSON 字符串创建 RagDocument
  factory RagDocument.fromJson(String source) =>
      RagDocument.fromMap(json.decode(source));

  /// 转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 复制并修改部分字段
  RagDocument copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? title,
    String? fileExtension,
    int? fileSize,
    String? status,
    DateTime? uploadTime,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return RagDocument(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      title: title ?? this.title,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      uploadTime: uploadTime ?? this.uploadTime,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 获取格式化的文件大小
  String get formattedFileSize {
    if (fileSize == null) return '未知大小';
    
    if (fileSize! < 1024) {
      return '${fileSize}B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取显示标题
  String get displayTitle => title.isNotEmpty ? title : fileName;

  /// 检查是否是某种文件类型
  bool isFileType(String extension) {
    return fileExtension?.toLowerCase() == extension.toLowerCase();
  }

  /// 检查是否是代码文件
  bool get isCodeFile {
    if (fileExtension == null) return false;
    const codeExtensions = [
      'dart', 'js', 'ts', 'jsx', 'tsx', 'vue', 'py', 'java', 'kt', 'swift',
      'go', 'rs', 'cpp', 'c', 'h', 'hpp', 'cs', 'php', 'rb', 'scala', 'clj',
    ];
    return codeExtensions.contains(fileExtension!.toLowerCase());
  }

  /// 检查是否是文档文件
  bool get isDocumentFile {
    if (fileExtension == null) return false;
    const documentExtensions = [
      'txt', 'md', 'markdown', 'pdf', 'doc', 'docx', 'rtf', 'odt',
    ];
    return documentExtensions.contains(fileExtension!.toLowerCase());
  }

  /// 检查是否是配置文件
  bool get isConfigFile {
    if (fileExtension == null) return false;
    const configExtensions = [
      'json', 'yaml', 'yml', 'toml', 'ini', 'conf', 'cfg', 'xml',
    ];
    return configExtensions.contains(fileExtension!.toLowerCase());
  }

  /// 创建文件上传记录的工厂方法
  factory RagDocument.forFileUpload({
    required String filePath,
    String? customTitle,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    final file = filePath.split('/').last;
    final extension = file.contains('.') ? file.split('.').last : null;
    
    return RagDocument(
      id: 'file_${DateTime.now().millisecondsSinceEpoch}',
      filePath: filePath,
      fileName: file,
      title: customTitle ?? file,
      fileExtension: extension,
      status: 'uploaded',
      uploadTime: DateTime.now(),
      source: source ?? 'file_upload',
      metadata: {
        'original_path': filePath,
        ...?metadata,
      },
    );
  }

  @override
  String toString() {
    return 'RagDocument(id: $id, fileName: $fileName, status: $status, size: $formattedFileSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RagDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
