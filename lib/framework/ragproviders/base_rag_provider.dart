import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../../models/bigmodel/chat_model.dart';
import '../../models/rag/rag_document.dart';
import '../../models/rag/rag_knowledge_base.dart';
import '../../models/rag/rag_chunk.dart';
import '../../services/ollama_embedding_service.dart';
import '../services/vector_database_service.dart';

/// 基础RAG提供商抽象类
/// 定义了所有RAG提供商必须实现的接口
abstract class BaseRagProvider {
  /// 当前配置的模型
  ChatModel? _model;

  /// 向量化服务实例
  late final OllamaEmbeddingService _embeddingService;

  /// 向量数据库服务实例
  VectorDatabaseService? _vectorDbService;

  // 已移除代码描述相关回调字段 _codeDescriptionCallback（功能暂未启用）

  /// RAG支持的文件类型
  static const Set<String> supportedRagExtensions = {
    // 文本文件
    '.txt', '.md', '.markdown', '.rst', '.tex',
    // 文档文件
    '.pdf', '.doc', '.docx',
    // 代码文件
    '.dart', '.js', '.ts', '.py', '.java', '.cpp', '.c', '.h', '.hpp',
    '.go', '.mod', '.sum', '.rs', '.rb', '.php', '.swift', '.kt', '.scala',
    '.html', '.css', '.json', '.xml', '.yaml', '.yml', '.toml', '.ini',
    '.sh', '.bash', '.zsh', '.fish', '.ps1', '.bat', '.cmd',
    '.sql', '.r', '.m', '.mm', '.pl', '.lua', '.vim', '.asm',
    // 配置文件
    '.conf', '.config', '.cfg', '.env', '.properties',
    '.dockerfile', '.gitignore', '.gitattributes',
    // 数据文件
    '.csv', '.tsv', '.log',
    // 其他
    '.rtf', '.odt', '.makefile', '.cmake', '.gradle'
  };

  /// 构造函数
  BaseRagProvider() {
    _embeddingService = OllamaEmbeddingService();
  }

  /// 获取当前配置的模型
  ChatModel? get model => _model;

  /// 获取当前RAG知识库ID（使用modelId）
  String? get ragId => _model?.modelId;

  /// 配置模型
  void configure(ChatModel model) {
    _model = model;
    onConfigure(model);
  }

  // setCodeDescriptionCallback 已移除（代码描述功能暂未启用）

  /// 子类可以重写此方法来处理配置
  void onConfigure(ChatModel model) {}

  // ============ RAG 功能 ============

  /// 创建RAG知识库（使用modelId）
  Future<String> createRagKnowledgeBase() async {
    if (_model?.modelId == null) {
      throw RagException('模型未配置或modelId为空');
    }
    final ragId = _model!.modelId;
    final ragDir = path.join('assets/RAG', ragId);
    final documentsDir = path.join(ragDir, 'documents');
    
    try {
      // 创建目录结构
      await Directory(documentsDir).create(recursive: true);
      
      // 创建空的知识库元数据
      final knowledgeBase = RagKnowledgeBase(
        ragId: ragId,
        documents: [],
        stats: {'totalDocuments': 0, 'totalSize': 0},
        lastUpdated: DateTime.now(),
      );

      await _saveKnowledgeBase(knowledgeBase);
      
      if (kDebugMode) {
        print('RAG知识库创建成功: $ragId');
      }
      
      return ragId;
    } catch (e) {
      if (kDebugMode) {
        print('创建RAG知识库失败: $e');
      }
      throw RagException('创建RAG知识库失败: $e');
    }
  }

  /// 导入单个文件到RAG知识库（使用modelId）
  Future<RagDocument> importFileToRag({
    required String sourceFilePath,
    String? customTitle,
    String? relativePath,
    String? folderName,
  }) async {
    if (_model?.modelId == null) {
      throw RagException('模型未配置或modelId为空');
    }
    
    try {
      // 验证文件和类型
      await _validateSourceFile(sourceFilePath);
      
      // 准备目标路径和目录
      final targetPath = await _prepareTargetPath(
        sourceFilePath: sourceFilePath,
        relativePath: relativePath,
        folderName: folderName,
      );
      
      // 复制文件到目标路径
      final finalPath = await _copyFileToTarget(sourceFilePath, targetPath);
      
      // 创建文档记录
      final document = await _createDocumentRecord(
        sourceFilePath: sourceFilePath,
        finalPath: finalPath,
        customTitle: customTitle,
        relativePath: relativePath,
        folderName: folderName,
      );

      // 更新知识库
      await _addDocumentToKnowledgeBase(document);

      if (kDebugMode) {
        print('文件导入成功: ${document.fileName} -> $finalPath');
      }

      return document;
    } catch (e) {
      if (kDebugMode) {
        print('文件导入失败: $e');
      }
      rethrow;
    }
  }

  /// 导入文件夹到RAG知识库（使用modelId）
  Future<List<RagDocument>> importFolderToRag({
    required String sourceFolderPath,
    bool recursive = true,
  }) async {
    if (_model?.modelId == null) {
      throw RagException('模型未配置或modelId为空');
    }
    
    try {
      final sourceDir = Directory(sourceFolderPath);
      await _validateSourceDirectory(sourceDir);

      final importContext = await _createImportContext(sourceDir, recursive);
      final documents = await _importFilesFromContext(importContext);
      
      _logImportResults(importContext, documents);
      return documents;
    } catch (e) {
      if (kDebugMode) {
        print('文件夹导入失败: $e');
      }
      rethrow;
    }
  }

  /// 获取RAG知识库
  Future<RagKnowledgeBase?> getRagKnowledgeBase() async {
    if (_model?.modelId == null) {
      return null;
    }
    final ragId = _model!.modelId;
    
    try {
      final ragDir = path.join('assets/RAG', ragId);
      final metadataPath = path.join(ragDir, 'metadata.json');
      final metadataFile = File(metadataPath);
      
      if (!await metadataFile.exists()) {
        return null;
      }
      
      final jsonContent = await metadataFile.readAsString();
      return RagKnowledgeBase.fromJson(jsonContent);
    } catch (e) {
      if (kDebugMode) {
        print('加载知识库失败: $e');
      }
      return null;
    }
  }


  /// 删除RAG文档（使用modelId）
  Future<bool> deleteRagDocument({
    required String documentId,
  }) async {
    if (_model?.modelId == null) {
      return false;
    }
    
    try {
      // 加载知识库
      final knowledgeBase = await getRagKnowledgeBase();
      if (knowledgeBase == null) {
        return false;
      }

      // 查找要删除的文档
      final document = knowledgeBase.documents
          .where((doc) => doc.id == documentId)
          .firstOrNull;
      
      if (document == null) {
        return false;
      }

      // 删除物理文件
      final file = File(document.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 删除文档对应的分块文件
      try {
        await deleteDocumentChunks(document);
        if (kDebugMode) {
          print('删除文档分块文件成功: ${document.fileName}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('删除文档分块文件失败: ${document.fileName}, 错误: $e');
        }
        // 即使分块删除失败，也继续删除文档记录
      }

      // 更新知识库元数据
      final updatedDocuments = knowledgeBase.documents
          .where((doc) => doc.id != documentId)
          .toList();
      
      final updatedKnowledgeBase = RagKnowledgeBase(
        ragId: _model!.modelId,
        documents: updatedDocuments,
        stats: _calculateRagStats(updatedDocuments),
        lastUpdated: DateTime.now(),
      );

      await _saveKnowledgeBase(updatedKnowledgeBase);

      if (kDebugMode) {
        print('RAG文档删除成功: $documentId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('删除RAG文档失败: $e');
      }
      return false;
    }
  }

  /// 删除整个RAG知识库（使用modelId）
  Future<bool> deleteRagKnowledgeBase() async {
    if (_model?.modelId == null) {
      return false;
    }
    
    try {
      final ragDir = Directory(path.join('assets/RAG', _model!.modelId));
      if (!ragDir.existsSync()) {
        return false;
      }

      // 递归删除整个知识库目录（包括文档和切片）
      await ragDir.delete(recursive: true);

      if (kDebugMode) {
        print('RAG知识库删除成功: ${_model!.modelId}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('删除RAG知识库失败: $e');
      }
      return false;
    }
  }


  // ============ 私有辅助方法 ============

  /// 验证源文件
  Future<void> _validateSourceFile(String sourceFilePath) async {
    final sourceFile = File(sourceFilePath);
    
    if (!await sourceFile.exists()) {
      throw RagException('源文件不存在: $sourceFilePath');
    }

    final fileExtension = path.extension(sourceFilePath).toLowerCase();
    if (!supportedRagExtensions.contains(fileExtension)) {
      throw RagException('不支持的文件类型: $fileExtension');
    }
  }

  /// 准备目标文件路径
  Future<String> _prepareTargetPath({
    required String sourceFilePath,
    String? relativePath,
    String? folderName,
  }) async {
    final ragDir = path.join('assets/RAG', _model!.modelId);
    final documentsDir = path.join(ragDir, 'documents');
    await Directory(documentsDir).create(recursive: true);

    final fileName = path.basename(sourceFilePath);
    
    if (relativePath != null && relativePath.isNotEmpty) {
      return _buildRelativeTargetPath(documentsDir, relativePath, folderName, fileName);
    } else {
      return _buildDirectTargetPath(documentsDir, folderName, fileName);
    }
  }

  /// 构建相对路径的目标路径
  Future<String> _buildRelativeTargetPath(
    String documentsDir,
    String relativePath,
    String? folderName,
    String fileName,
  ) async {
    String basePath = documentsDir;
    if (folderName != null && folderName.isNotEmpty) {
      basePath = path.join(documentsDir, folderName);
    }
    
    final relativeDir = path.dirname(relativePath);
    final targetDir = relativeDir == '.' 
        ? basePath 
        : path.join(basePath, relativeDir);
    
    await Directory(targetDir).create(recursive: true);
    return path.join(targetDir, fileName);
  }

  /// 构建直接目标路径
  Future<String> _buildDirectTargetPath(
    String documentsDir,
    String? folderName,
    String fileName,
  ) async {
    if (folderName != null && folderName.isNotEmpty) {
      final targetDir = path.join(documentsDir, folderName);
      await Directory(targetDir).create(recursive: true);
      return path.join(targetDir, fileName);
    } else {
      return path.join(documentsDir, fileName);
    }
  }

  /// 复制文件到目标位置
  Future<String> _copyFileToTarget(String sourceFilePath, String targetFilePath) async {
    String finalTargetPath = targetFilePath;
    if (await File(targetFilePath).exists()) {
      finalTargetPath = await _getUniqueFilePath(targetFilePath);
    }
    
    await File(sourceFilePath).copy(finalTargetPath);
    return finalTargetPath;
  }

  /// 创建文档记录
  Future<RagDocument> _createDocumentRecord({
    required String sourceFilePath,
    required String finalPath,
    String? customTitle,
    String? relativePath,
    String? folderName,
  }) async {
    final sourceFile = File(sourceFilePath);
    final stat = await sourceFile.stat();
    final fileName = path.basename(sourceFilePath);
    final documentId = _generateDocumentId(fileName);
    final fileExtension = path.extension(sourceFilePath).toLowerCase();

    return RagDocument(
      id: documentId,
      filePath: finalPath,
      fileName: fileName,
      title: customTitle ?? fileName,
      fileExtension: fileExtension,
      fileSize: stat.size,
      status: 'uploaded',
      uploadTime: DateTime.now(),
      source: 'file_upload',
      metadata: {
        'originalPath': sourceFilePath,
        'relativePath': relativePath,
        'folderName': folderName,
        'importTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 验证源目录
  Future<void> _validateSourceDirectory(Directory sourceDir) async {
    if (!await sourceDir.exists()) {
      throw RagException('源文件夹不存在: ${sourceDir.path}');
    }
  }

  /// 创建导入上下文
  Future<_ImportContext> _createImportContext(Directory sourceDir, bool recursive) async {
    final files = await _getFilesFromDirectory(sourceDir, recursive);
    final folderName = path.basename(sourceDir.path);
    final sourceDirPath = sourceDir.absolute.path;
    
    if (kDebugMode) {
      print('准备导入文件夹: $folderName');
      print('找到 ${files.length} 个支持的文件');
    }

    return _ImportContext(
      files: files,
      folderName: folderName,
      sourceDirPath: sourceDirPath,
      sourceDir: sourceDir,
      recursive: recursive,
    );
  }

  /// 从导入上下文中导入文件
  Future<List<RagDocument>> _importFilesFromContext(_ImportContext context) async {
    final documents = <RagDocument>[];
    final errors = <String>[];

    for (final file in context.files) {
      try {
        final document = await _importSingleFile(file, context);
        documents.add(document);
        
        if (kDebugMode) {
          final relativePath = path.relative(file.absolute.path, from: context.sourceDirPath);
          print('文件导入成功: ${context.folderName}/$relativePath');
        }
      } catch (e) {
        final fileName = path.basename(file.path);
        errors.add('$fileName: $e');
        
        if (kDebugMode) {
          print('跳过文件 ${file.path}: $e');
        }
      }
    }

    context.errors = errors;
    return documents;
  }

  /// 导入单个文件
  Future<RagDocument> _importSingleFile(File file, _ImportContext context) async {
    final filePath = file.absolute.path;
    final relativePath = path.relative(filePath, from: context.sourceDirPath);
    
    return await importFileToRag(
      sourceFilePath: file.path,
      relativePath: relativePath,
      folderName: context.folderName,
    );
  }

  /// 记录导入结果
  void _logImportResults(_ImportContext context, List<RagDocument> documents) async {
    if (!kDebugMode) return;
    
    final skippedFiles = <String>[];
    await _collectSkippedFiles(context.sourceDir, context.recursive, skippedFiles);

    print('文件夹 "${context.folderName}" 导入完成:');
    print('  - 成功导入: ${documents.length} 个文件');
    print('  - 跳过文件: ${skippedFiles.length} 个');
    print('  - 错误文件: ${context.errors.length} 个');
    
    if (skippedFiles.isNotEmpty) {
      print('跳过的文件 (不支持的类型):');
      skippedFiles.take(5).forEach((file) => print('  - $file'));
      if (skippedFiles.length > 5) {
        print('  - 还有 ${skippedFiles.length - 5} 个文件...');
      }
    }
    
    if (context.errors.isNotEmpty) {
      print('错误的文件:');
      context.errors.take(5).forEach((error) => print('  - $error'));
      if (context.errors.length > 5) {
        print('  - 还有 ${context.errors.length - 5} 个错误...');
      }
    }
  }

  /// 生成文档ID
  String _generateDocumentId(String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanName = fileName.replaceAll(RegExp(r'[^\w\-_.]'), '_');
    return '${timestamp}_${cleanName.hashCode.abs()}';
  }

  /// 保存知识库元数据
  Future<void> _saveKnowledgeBase(RagKnowledgeBase knowledgeBase) async {
    try {
      final ragDir = path.join('assets/RAG', knowledgeBase.ragId);
      final metadataPath = path.join(ragDir, 'metadata.json');
      
      // 确保目录存在
      await Directory(ragDir).create(recursive: true);
      
      // 保存元数据
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(knowledgeBase.toJson());
      
      if (kDebugMode) {
        print('知识库元数据保存成功: $metadataPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存知识库元数据失败: $e');
      }
      throw RagException('保存知识库元数据失败: $e');
    }
  }

  /// 添加文档到知识库
  Future<void> _addDocumentToKnowledgeBase(RagDocument document) async {
    final ragId = _model!.modelId;
    // 获取现有知识库
    var knowledgeBase = await getRagKnowledgeBase();
    
    knowledgeBase ??= RagKnowledgeBase(
      ragId: ragId,
      documents: [],
      stats: {},
      lastUpdated: DateTime.now(),
    );

    // 添加新文档
    final allDocuments = [...knowledgeBase.documents, document];
    
    // 计算统计信息
    final stats = _calculateRagStats(allDocuments);
    
    // 创建更新后的知识库
    final updatedKnowledgeBase = RagKnowledgeBase(
      ragId: ragId,
      documents: allDocuments,
      stats: stats,
      lastUpdated: DateTime.now(),
    );

    // 保存到文件
    await _saveKnowledgeBase(updatedKnowledgeBase);
  }

  /// 获取目录下的所有支持的文件
  Future<List<File>> _getFilesFromDirectory(
    Directory directory,
    bool recursive,
  ) async {
    final files = <File>[];
    
    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (supportedRagExtensions.contains(extension)) {
          files.add(entity);
        }
      }
    }
    
    return files;
  }

  /// 收集被跳过的文件信息（不支持的文件类型）
  Future<void> _collectSkippedFiles(
    Directory directory,
    bool recursive,
    List<String> skippedFiles,
  ) async {
    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (!supportedRagExtensions.contains(extension)) {
          final relativeName = path.basename(entity.path);
          skippedFiles.add('$relativeName ($extension - 不支持的类型)');
        }
      }
    }
  }

  /// 获取唯一的文件路径（如果文件已存在，添加序号）
  Future<String> _getUniqueFilePath(String originalPath) async {
    if (!await File(originalPath).exists()) {
      return originalPath;
    }

    final dir = path.dirname(originalPath);
    final fileName = path.basenameWithoutExtension(originalPath);
    final extension = path.extension(originalPath);

    int counter = 1;
    String newPath;
    
    do {
      newPath = path.join(dir, '${fileName}_$counter$extension');
      counter++;
    } while (await File(newPath).exists());

    return newPath;
  }

  /// 获取文档内容
  Future<String?> _getDocumentContent(RagDocument document) async {
    try {
      final file = File(document.filePath);
      if (!await file.exists()) {
        return null;
      }

      // 根据文件类型处理内容
      final extension = document.fileExtension?.toLowerCase();
      
      switch (extension) {
        case '.txt':
        case '.md':
        case '.markdown':
        case '.rst':
        case '.tex':
        case '.dart':
        case '.js':
        case '.ts':
        case '.py':
        case '.java':
        case '.cpp':
        case '.c':
        case '.h':
        case '.hpp':
        case '.go':
        case '.mod':
        case '.sum':
        case '.rs':
        case '.rb':
        case '.php':
        case '.swift':
        case '.kt':
        case '.scala':
        case '.html':
        case '.css':
        case '.json':
        case '.xml':
        case '.yaml':
        case '.yml':
        case '.toml':
        case '.ini':
        case '.sh':
        case '.bash':
        case '.zsh':
        case '.fish':
        case '.ps1':
        case '.bat':
        case '.cmd':
        case '.sql':
        case '.r':
        case '.m':
        case '.mm':
        case '.pl':
        case '.lua':
        case '.vim':
        case '.asm':
        case '.conf':
        case '.config':
        case '.cfg':
        case '.env':
        case '.properties':
        case '.dockerfile':
        case '.gitignore':
        case '.gitattributes':
        case '.csv':
        case '.tsv':
        case '.log':
        case '.makefile':
        case '.cmake':
        case '.gradle':
          // 文本文件直接读取
          return await file.readAsString();
        
        case '.pdf':
        case '.doc':
        case '.docx':
        case '.rtf':
        case '.odt':
          // 对于二进制文档文件，返回文件信息
          return '文档文件: ${document.fileName}\n'
                 '大小: ${document.fileSize} 字节\n'
                 '上传时间: ${document.uploadTime}\n'
                 '路径: ${document.filePath}';
        
        default:
          return '不支持的文件类型: $extension';
      }
    } catch (e) {
      if (kDebugMode) {
        print('读取文档内容失败: $e');
      }
      return null;
    }
  }

  /// 计算知识库统计信息
  Map<String, dynamic> _calculateRagStats(List<RagDocument> documents) {
    final stats = <String, dynamic>{
      'totalDocuments': documents.length,
      'totalSize': 0,
      'fileTypes': <String, int>{},
      'statusCounts': <String, int>{},
    };

    for (final document in documents) {
      // 计算总大小
      if (document.fileSize != null) {
        stats['totalSize'] += document.fileSize!;
      }

      // 统计文件类型
      if (document.fileExtension != null) {
        final ext = document.fileExtension!;
        stats['fileTypes'][ext] = (stats['fileTypes'][ext] ?? 0) + 1;
      }

      // 统计状态
      final status = document.status;
      stats['statusCounts'][status] = (stats['statusCounts'][status] ?? 0) + 1;
    }

    return stats;
  }


  //增加切片功能
  
  /// 分块配置常量
  static const int defaultChunkSize = 1000; // 默认分块大小
  static const int defaultChunkOverlap = 200; // 默认重叠大小
  
  /// 为文档创建分块
  Future<List<RagChunk>> chunkDocument(RagDocument document) async {
    try {
      final content = await _getDocumentContent(document);
      if (content == null || content.isEmpty) {
        if (kDebugMode) {
          print('文档内容为空，跳过分块: ${document.fileName}');
        }
        return [];
      }

      final chunks = await _createChunksForDocument(document, content);
      
      // 为分块添加向量化
      final chunksWithEmbeddings = await _addEmbeddingsToChunks(chunks);
      
      // 保存分块到文件系统
      await _saveChunksToFile(document, chunksWithEmbeddings);
      
      // 保存分块到向量数据库
      await _saveChunkToObjectBox(chunksWithEmbeddings);
      
      if (kDebugMode) {
        print('文档分块完成: ${document.fileName}, 共生成 ${chunksWithEmbeddings.length} 个分块');
      }
      
      return chunksWithEmbeddings;
    } catch (e) {
      if (kDebugMode) {
        print('文档分块失败: ${document.fileName}, 错误: $e');
      }
      return [];
    }
  }

  /// 保存分块文档到ObjectBox向量数据库
  /// 这个函数将生成的分块内容存储到向量数据库中，支持后续的向量搜索
  Future<bool> _saveChunkToObjectBox(List<RagChunk> chunks) async {
    try {
      // 确保向量数据库服务已初始化
      await _ensureVectorDbService();
      
      if (_vectorDbService == null) {
        if (kDebugMode) {
          print('向量数据库服务未初始化');
        }
        return false;
      }

      // 保存分块到向量数据库
      await _vectorDbService!.saveChunks(chunks);
      
      if (kDebugMode) {
        print('成功保存 ${chunks.length} 个分块到向量数据库');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('保存分块到向量数据库失败: $e');
      }
      return false;
    }
  }

  /// 确保向量数据库服务已初始化
  Future<void> _ensureVectorDbService() async {
    if (_vectorDbService == null && _model != null) {
      // 如果已经有一个实例，先释放它
      if (_vectorDbService != null) {
        _vectorDbService!.dispose();
      }
      
      final ragId = _model!.ragId.isNotEmpty ? _model!.ragId : _model!.modelId;
      _vectorDbService = VectorDatabaseService(ragId);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    _vectorDbService?.dispose();
    _vectorDbService = null;
  }

  /// 基于向量数据库的语义搜索
  /// 使用向量相似度进行智能搜索，返回最相关的文档片段
  Future<List<VectorSearchResult>> searchRagDocuments({
    required String query,
    int limit = 3,
    double similarityThreshold = 0.5,
    String? documentId,
  }) async {
    try {
      // 确保向量数据库服务已初始化
      await _ensureVectorDbService();
      
      if (_vectorDbService == null) {
        if (kDebugMode) {
          print('向量数据库服务未初始化');
        }
        return [];
      }

      // 生成查询向量
      final queryEmbeddings = await _embeddingService.getEmbedding(query);
      if (queryEmbeddings == null || queryEmbeddings.isEmpty) {
        if (kDebugMode) {
          print('无法生成查询向量');
        }
        return [];
      }
        print("查询向量: $queryEmbeddings" ); 

      // 执行向量搜索
      final results = await _vectorDbService!.vectorSearch(
        queryEmbeddings: queryEmbeddings,
        limit: limit,
        similarityThreshold: similarityThreshold,
        modelId: _model!.modelId,
      );

      if (kDebugMode) {
        print('向量搜索完成，查询: "$query"，返回 ${results.length} 个结果');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('向量搜索失败: $e');
      }
      return [];
    }
  }

  /// 获取向量数据库统计信息
  Future<VectorDatabaseStats?> getVectorDatabaseStats() async {
    try {
      await _ensureVectorDbService();
      return await _vectorDbService?.getStats();
    } catch (e) {
      if (kDebugMode) {
        print('获取向量数据库统计信息失败: $e');
      }
      return null;
    }
  }

  /// 删除文档的向量数据
  Future<bool> deleteDocumentVectorData(String documentId) async {
    try {
      await _ensureVectorDbService();
      
      if (_vectorDbService == null) {
        return false;
      }

      await _vectorDbService!.deleteChunksByDocumentId(documentId);
      
      if (kDebugMode) {
        print('已删除文档 $documentId 的向量数据');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('删除文档向量数据失败: $e');
      }
      return false;
    }
  }

     

  /// 为特定文档创建分块
  Future<List<RagChunk>> _createChunksForDocument(RagDocument document, String content) async {
    final extension = document.fileExtension?.toLowerCase();
    
    switch (extension) {
      // 代码文件分块
      case '.dart':
      case '.js':
      case '.ts':
      case '.py':
      case '.java':
      case '.cpp':
      case '.c':
      case '.h':
      case '.hpp':
      case '.go':
      case '.rs':
      case '.rb':
      case '.php':
      case '.swift':
      case '.kt':
      case '.scala':
        return _chunkCodeFile(document, content, extension!);
        
      // Go 相关配置文件
      case '.mod':
      case '.sum':
        return _chunkGoConfigFile(document, content);
        
      // 标记文档分块
      case '.md':
      case '.markdown':
        return _chunkMarkdownFile(document, content);
        
      // 文本文档分块
      case '.txt':
      case '.log':
        return _chunkTextFile(document, content);
        
      // 结构化文档分块
      case '.json':
        return _chunkJsonFile(document, content);
        
      case '.xml':
      case '.html':
        return _chunkXmlFile(document, content);
        
      case '.yaml':
      case '.yml':
        return _chunkYamlFile(document, content);
        
      // 配置文件分块
      case '.conf':
      case '.config':
      case '.ini':
      case '.env':
      case '.properties':
        return _chunkConfigFile(document, content);
        
      // 文档文件（PDF、Word等）使用段落分块
      case '.pdf':
      case '.doc':
      case '.docx':
      case '.rtf':
      case '.odt':
        return _chunkDocumentFile(document, content);
        
      // 默认使用固定大小分块
      default:
        return _chunkByFixedSize(document, content);
    }
  }

  /// 代码文件分块（按函数、类、方法）
  Future<List<RagChunk>> _chunkCodeFile(RagDocument document, String content, String extension) async {
    final lines = content.split('\n');
    
    List<RagChunk> chunks;
    switch (extension) {
      case '.dart':
        chunks = await _chunkDartCode(document, content, lines);
        break;
      case '.go':
        chunks = await _chunkGoCode(document, content, lines);
        break;
      case '.py':
        chunks = await _chunkPythonCode(document, content, lines);
        break;
      case '.js':
      case '.ts':
        chunks = await _chunkJavaScriptCode(document, content, lines);
        break;
      case '.java':
        chunks = await _chunkJavaCode(document, content, lines);
        break;
      default:
        chunks = await _chunkGenericCode(document, content, lines);
        break;
    }
    
    // 为代码分块生成功能描述
    // 暂时去掉对代码的描述，直接返回分块
    return chunks;
  }

  /// Dart代码分块
  Future<List<RagChunk>> _chunkDartCode(RagDocument document, String content, List<String> lines) async {
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测类定义
      if (line.startsWith('class ') || line.startsWith('abstract class ') || 
          line.startsWith('mixin ') || line.startsWith('enum ')) {
        
        if (i > currentStart) {
          // 保存之前的内容
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        // 找到类的结束位置
        final classEnd = _findBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, classEnd, chunkIndex++);
        currentStart = classEnd + 1;
        i = classEnd;
      }
      // 检测顶级函数
      else if (_isTopLevelFunction(line) && !_isInsideClass(lines, i)) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final funcEnd = _findFunctionEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, funcEnd, chunkIndex++);
        currentStart = funcEnd + 1;
        i = funcEnd;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// 查找代码块相关的注释起始位置
  int _findCommentStart(List<String> lines, int currentLine) {
    var line = currentLine;
    // 向上查找注释，直到遇到空行或非注释行
    while (line > 0) {
      final prevLine = lines[line - 1].trim();
      if (prevLine.isEmpty || (!prevLine.startsWith('//') && !prevLine.startsWith('/*'))) {
        break;
      }
      line--;
    }
    return line;
  }

  /// Go代码分块
  /// 按照Go语言特定的语法结构进行智能分块：
  /// - 包声明和导入语句作为单独的块
  /// - 类型定义（struct、interface等）作为单独的块
  /// - 函数和方法定义作为单独的块
  /// - 保持代码块的完整性和上下文
  Future<List<RagChunk>> _chunkGoCode(RagDocument document, String content, List<String> lines) async {
    final List<RagChunk> chunks = [];
    int chunkIndex = 0;

    // 记录包和导入信息，用于函数块的上下文
    List<String> imports = [];
    
    // 当前代码块的状态
    int blockStartLine = 0;
    bool inImportBlock = false;
    bool inTypeBlock = false;
    bool inFuncBlock = false;
    String currentBlockType = '';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 处理包声明
      if (line.startsWith('package ')) {
        if (i > blockStartLine && currentBlockType.isNotEmpty) {
          _addGoChunk(chunks, document, lines, blockStartLine, i - 1, chunkIndex++, currentBlockType);
        }
        blockStartLine = i;
        currentBlockType = 'go_package';
        continue;
      }

      // 处理导入块
      if (line.startsWith('import')) {
        if (line.contains('(')) {
          if (i > blockStartLine && currentBlockType.isNotEmpty) {
            _addGoChunk(chunks, document, lines, blockStartLine, i - 1, chunkIndex++, currentBlockType);
          }
          inImportBlock = true;
          blockStartLine = i;
          currentBlockType = 'go_imports';
          continue;
        } else {
          imports.add(line);
        }
      }
      
      // 导入块结束
      if (inImportBlock && line == ')') {
        inImportBlock = false;
        _addGoChunk(chunks, document, lines, blockStartLine, i, chunkIndex++, 'go_imports');
        currentBlockType = '';
        continue;
      }

      // 处理类型定义
      if (line.startsWith('type ')) {
        if (i > blockStartLine && currentBlockType.isNotEmpty) {
          _addGoChunk(chunks, document, lines, blockStartLine, i - 1, chunkIndex++, currentBlockType);
        }
        // 向上查找关联的注释
        blockStartLine = _findCommentStart(lines, i);
        currentBlockType = 'go_type';
        inTypeBlock = true;
        continue;
      }

      // 处理函数定义
      if (line.startsWith('func ')) {
        if (i > blockStartLine && currentBlockType.isNotEmpty) {
          _addGoChunk(chunks, document, lines, blockStartLine, i - 1, chunkIndex++, currentBlockType);
        }
        // 向上查找关联的注释
        blockStartLine = _findCommentStart(lines, i);
        currentBlockType = 'go_function';
        inFuncBlock = true;
        continue;
      }

      // 检测类型块或函数块的结束
      if ((inTypeBlock || inFuncBlock) && line == '}') {
        if (_isBlockEnd(lines, i)) {
          _addGoChunk(chunks, document, lines, blockStartLine, i, chunkIndex++, currentBlockType);
          inTypeBlock = false;
          inFuncBlock = false;
          currentBlockType = '';
          continue;
        }
      }
    }

    // 处理最后一个块
    if (blockStartLine < lines.length - 1 && currentBlockType.isNotEmpty) {
      _addGoChunk(chunks, document, lines, blockStartLine, lines.length - 1, chunkIndex, currentBlockType);
    }

    if (kDebugMode) {
      print('Go文件 ${document.fileName} 分块完成，共${chunks.length}个块');
    }
    return chunks;
  }

  /// 添加Go代码块，同时添加必要的上下文信息
  void _addGoChunk(
    List<RagChunk> chunks,
    RagDocument document,
    List<String> lines,
    int startLine,
    int endLine,
    int chunkIndex,
    String blockType,
  ) {
    final content = lines.sublist(startLine, endLine + 1).join('\n');
    final startPos = _getStartPosition(lines, startLine);
    final endPos = _getStartPosition(lines, endLine) + lines[endLine].length;

    chunks.add(RagChunk.create(
      documentId: document.id,
      modelId: _model!.modelId,
      content: content,
      startPosition: startPos,
      endPosition: endPos,
      chunkIndex: chunkIndex,
      sourceFilePath: document.filePath,
      relativePath: document.metadata?['relativePath'],
      folderName: document.metadata?['folderName'],
      metadata: {
        'type': blockType,
        'start_line': startLine + 1,
        'end_line': endLine + 1,
        'line_count': endLine - startLine + 1,
      },
    ));
  }

  /// 检测代码块是否结束
  bool _isBlockEnd(List<String> lines, int currentLine) {
    int braceCount = 0;
    bool foundStart = false;

    // 向上搜索直到找到块的开始
    for (int i = currentLine; i >= 0; i--) {
      final line = lines[i].trim();
      
      if (line.startsWith('type ') || line.startsWith('func ')) {
        foundStart = true;
        break;
      }

      braceCount += line.split('{').length - 1;
      braceCount -= line.split('}').length - 1;
    }

    return foundStart && braceCount == 0;
  }

  /// 计算行的起始位置
  int _getStartPosition(List<String> lines, int lineNumber) {
    int position = 0;
    for (int i = 0; i < lineNumber; i++) {
      position += lines[i].length + 1; // +1 for newline
    }
    return position;
  }

  /// Python代码分块
  Future<List<RagChunk>> _chunkPythonCode(RagDocument document, String content, List<String> lines) async {
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测类定义
      if (line.startsWith('class ')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final classEnd = _findPythonBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, classEnd, chunkIndex++);
        currentStart = classEnd + 1;
        i = classEnd;
      }
      // 检测函数定义
      else if (line.startsWith('def ')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final funcEnd = _findPythonBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, funcEnd, chunkIndex++);
        currentStart = funcEnd + 1;
        i = funcEnd;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// JavaScript/TypeScript代码分块
  Future<List<RagChunk>> _chunkJavaScriptCode(RagDocument document, String content, List<String> lines) async {
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测函数定义
      if (line.contains('function ') || line.contains(') => {') || 
          RegExp(r'^\w+\s*\([^)]*\)\s*{').hasMatch(line)) {
        
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final funcEnd = _findBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, funcEnd, chunkIndex++);
        currentStart = funcEnd + 1;
        i = funcEnd;
      }
      // 检测类定义
      else if (line.startsWith('class ')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final classEnd = _findBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, classEnd, chunkIndex++);
        currentStart = classEnd + 1;
        i = classEnd;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// Java代码分块
  Future<List<RagChunk>> _chunkJavaCode(RagDocument document, String content, List<String> lines) async {
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测类定义
      if (line.contains('class ') || line.contains('interface ') || line.contains('enum ')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        
        final classEnd = _findBlockEnd(lines, i);
        await _addCodeChunk(chunks, document, lines, i, classEnd, chunkIndex++);
        currentStart = classEnd + 1;
        i = classEnd;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// 通用代码分块
  Future<List<RagChunk>> _chunkGenericCode(RagDocument document, String content, List<String> lines) async {
    return _chunkByLines(document, content, lines, 50); // 按50行分块
  }

  /// Markdown文件分块（按标题）
  Future<List<RagChunk>> _chunkMarkdownFile(RagDocument document, String content) async {
    final chunks = <RagChunk>[];
    final lines = content.split('\n');
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测标题
      if (line.startsWith('#')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        currentStart = i;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// 文本文件分块（按段落）
  Future<List<RagChunk>> _chunkTextFile(RagDocument document, String content) async {
    final paragraphs = content.split(RegExp(r'\n\s*\n'));
    final chunks = <RagChunk>[];
    int position = 0;
    
    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i].trim();
      if (paragraph.isNotEmpty) {
        final chunk = RagChunk.create(
          documentId: document.id,
          modelId: _model!.modelId,
          content: paragraph,
          startPosition: position,
          endPosition: position + paragraph.length,
          chunkIndex: i,
          sourceFilePath: document.filePath,
          relativePath: document.metadata?['relativePath'],
          folderName: document.metadata?['folderName'],
          metadata: {'type': 'paragraph'},
        );
        chunks.add(chunk);
      }
      position += paragraph.length + 2; // +2 for \n\n
    }
    
    return chunks;
  }

  /// JSON文件分块
  Future<List<RagChunk>> _chunkJsonFile(RagDocument document, String content) async {
    try {
      final jsonData = json.decode(content);
      return _chunkJsonData(document, jsonData, content);
    } catch (e) {
      // 如果JSON解析失败，按固定大小分块
      return _chunkByFixedSize(document, content);
    }
  }

  /// XML/HTML文件分块
  Future<List<RagChunk>> _chunkXmlFile(RagDocument document, String content) async {
    final lines = content.split('\n');
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测XML标签开始
      if (line.startsWith('<') && !line.startsWith('</') && line.contains('>')) {
        final tagName = _extractTagName(line);
        if (tagName.isNotEmpty) {
          if (i > currentStart) {
            await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
          }
          
          final tagEnd = _findXmlTagEnd(lines, i, tagName);
          await _addCodeChunk(chunks, document, lines, i, tagEnd, chunkIndex++);
          currentStart = tagEnd + 1;
          i = tagEnd;
        }
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// YAML文件分块
  Future<List<RagChunk>> _chunkYamlFile(RagDocument document, String content) async {
    final lines = content.split('\n');
    return _chunkByLines(document, content, lines, 30); // 按30行分块
  }

  /// 配置文件分块
  Future<List<RagChunk>> _chunkConfigFile(RagDocument document, String content) async {
    final lines = content.split('\n');
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测配置节
      if (line.startsWith('[') && line.endsWith(']')) {
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        currentStart = i;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// Go配置文件分块（go.mod, go.sum）
  Future<List<RagChunk>> _chunkGoConfigFile(RagDocument document, String content) async {
    final lines = content.split('\n');
    final extension = document.fileExtension?.toLowerCase();
    
    if (extension == '.mod') {
      // go.mod 文件按模块声明分块
      return _chunkGoModFile(document, content, lines);
    } else if (extension == '.sum') {
      // go.sum 文件按固定行数分块（每50行一个分块）
      return _chunkBySmallerLines(document, content, lines, 50);
    } else {
      // 其他情况按固定大小分块
      return _chunkByFixedSize(document, content);
    }
  }

  /// 分块 go.mod 文件
  Future<List<RagChunk>> _chunkGoModFile(RagDocument document, String content, List<String> lines) async {
    final chunks = <RagChunk>[];
    int chunkIndex = 0;
    int currentStart = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 检测主要的go.mod指令
      if (line.startsWith('module ') || 
          line.startsWith('go ') ||
          line.startsWith('require ') ||
          line.startsWith('replace ') ||
          line.startsWith('exclude ')) {
        
        if (i > currentStart) {
          await _addCodeChunk(chunks, document, lines, currentStart, i - 1, chunkIndex++);
        }
        currentStart = i;
      }
    }
    
    // 处理剩余内容
    if (currentStart < lines.length) {
      await _addCodeChunk(chunks, document, lines, currentStart, lines.length - 1, chunkIndex);
    }
    
    return chunks;
  }

  /// 按较小的行数分块（专门用于处理大型列表文件如go.sum）
  Future<List<RagChunk>> _chunkBySmallerLines(RagDocument document, String content, List<String> lines, int linesPerChunk) async {
    final chunks = <RagChunk>[];
    
    for (int i = 0; i < lines.length; i += linesPerChunk) {
      final endIndex = math.min(i + linesPerChunk, lines.length);
      await _addCodeChunk(chunks, document, lines, i, endIndex - 1, chunks.length);
    }
    
    return chunks;
  }

  /// 文档文件分块（Word、PDF等）
  Future<List<RagChunk>> _chunkDocumentFile(RagDocument document, String content) async {
    // 按段落分块，段落之间用双换行分隔
    return _chunkTextFile(document, content);
  }

  /// 按固定大小分块
  Future<List<RagChunk>> _chunkByFixedSize(RagDocument document, String content) async {
    final chunks = <RagChunk>[];
    const chunkSize = defaultChunkSize;
    const overlap = defaultChunkOverlap;
    
    int start = 0;
    int chunkIndex = 0;
    
    while (start < content.length) {
      int end = math.min(start + chunkSize, content.length);
      
      // 尝试在单词边界处断开
      if (end < content.length) {
        final lastSpace = content.lastIndexOf(' ', end);
        if (lastSpace > start + chunkSize ~/ 2) {
          end = lastSpace;
        }
      }
      
      final chunkContent = content.substring(start, end);
      final chunk = RagChunk.create(
                  modelId: _model!.modelId,

        documentId: document.id,
        content: chunkContent,
        startPosition: start,
        endPosition: end,
        chunkIndex: chunkIndex++,
        sourceFilePath: document.filePath,
        relativePath: document.metadata?['relativePath'],
        folderName: document.metadata?['folderName'],
        metadata: {'type': 'fixed_size', 'chunk_size': chunkSize},
      );
      chunks.add(chunk);
      
      // 确保下一个开始位置向前推进，避免无限循环
      final nextStart = math.max(start + 1, end - overlap);
      if (nextStart >= content.length) break;
      start = nextStart;
    }
    
    return chunks;
  }

  /// 为分块添加向量化
  Future<List<RagChunk>> _addEmbeddingsToChunks(List<RagChunk> chunks) async {
    if (chunks.isEmpty) return chunks;
    
    try {
      // 检查向量化服务是否可用
      final isAvailable = await _embeddingService.isServiceAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          print('Ollama 向量化服务不可用，跳过向量化');
        }
        return chunks;
      }
      
      final chunksWithEmbeddings = <RagChunk>[];
      
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        
        if (kDebugMode) {
          print('正在向量化分块 ${i + 1}/${chunks.length}: ${chunk.preview}');
        }
        
        // 构建用于向量化的文本：合并内容和注释
        String textForEmbedding = chunk.content;
        if (chunk.comment != null && chunk.comment!.isNotEmpty) {
          textForEmbedding = '${chunk.content}\n\n功能描述: ${chunk.comment}';
        }
        
        // 获取分块内容的向量化表示
        final embedding = await _embeddingService.getEmbedding(textForEmbedding);
        
        // 创建包含向量化数据的新分块
        final chunkWithEmbedding = chunk.copyWith(embeddings: embedding);
        chunksWithEmbeddings.add(chunkWithEmbedding);
        
        // 添加小延迟避免过于频繁的请求
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      if (kDebugMode) {
        final successCount = chunksWithEmbeddings.where((c) => c.embeddings != null).length;
        print('向量化完成: 成功 $successCount/${chunks.length} 个分块');
      }
      
      return chunksWithEmbeddings;
    } catch (e) {
      if (kDebugMode) {
        print('向量化过程出错: $e，返回原始分块');
      }
      return chunks;
    }
  }

  // 已移除未使用的 _addCodeDescriptionsToChunks 方法（保留的相关辅助方法可供未来功能启用）

  // 已移除未使用的与代码描述相关的辅助方法：_buildCodeDescriptionPrompt / _getLanguageName / _getCodeDescription

  // 已移除请求代码描述的辅助方法 _requestCodeDescription / _requestCodeDescriptionViaHttp

  /// 按行数分块
  Future<List<RagChunk>> _chunkByLines(RagDocument document, String content, List<String> lines, int linesPerChunk) async {
    final chunks = <RagChunk>[];
    
    for (int i = 0; i < lines.length; i += linesPerChunk) {
      final endIndex = math.min(i + linesPerChunk, lines.length);
      await _addCodeChunk(chunks, document, lines, i, endIndex - 1, i ~/ linesPerChunk);
    }
    
    return chunks;
  }

  /// 保存分块到文件
  Future<void> _saveChunksToFile(RagDocument document, List<RagChunk> chunks) async {
    if (chunks.isEmpty) return;
    
    try {
      final ragDir = path.join('assets/RAG', _model!.modelId);
      final chunksDir = path.join(ragDir, 'chunks');
      
      // 创建chunks目录结构，保持与documents相同的目录结构
      String targetChunkDir = chunksDir;
      
      // 根据文档的metadata重建目录结构
      if (document.metadata != null) {
        final relativePath = document.metadata!['relativePath'] as String?;
        final folderName = document.metadata!['folderName'] as String?;
        
        if (folderName != null && folderName.isNotEmpty) {
          // 如果有文件夹名称，先添加文件夹名称
          targetChunkDir = path.join(chunksDir, folderName);
          
          // 如果有相对路径，进一步构建子目录
          if (relativePath != null && relativePath.isNotEmpty) {
            final relativeDir = path.dirname(relativePath);
            if (relativeDir != '.' && relativeDir.isNotEmpty) {
              targetChunkDir = path.join(targetChunkDir, relativeDir);
            }
          }
        } else if (relativePath != null && relativePath.isNotEmpty) {
          // 只有相对路径，没有文件夹名称
          final relativeDir = path.dirname(relativePath);
          if (relativeDir != '.' && relativeDir.isNotEmpty) {
            targetChunkDir = path.join(chunksDir, relativeDir);
          }
        }
      }
      
      // 确保目标目录存在
      await Directory(targetChunkDir).create(recursive: true);
      
      // 为每个分块保存JSON文件，使用有意义的文件名
      final baseFileName = path.basenameWithoutExtension(document.fileName);
      final fileExtension = document.fileExtension ?? '';
      
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        final chunkFileName = '${baseFileName}_chunk_${i.toString().padLeft(3, '0')}${fileExtension}.json';
        final chunkFilePath = path.join(targetChunkDir, chunkFileName);
        
        final chunkFile = File(chunkFilePath);
        await chunkFile.writeAsString(chunk.toJson());
      }
      
      if (kDebugMode) {
        print('分块文件保存成功:');
        print('  原文件: ${document.filePath}');
        print('  分块目录: $targetChunkDir');
        print('  分块数量: ${chunks.length}');
        print('  目录结构: ${targetChunkDir.replaceFirst(ragDir, 'RAG')}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('保存分块文件失败: $e');
      }
      throw RagException('保存分块文件失败: $e');
    }
  }

  /// 添加代码分块的辅助方法
  Future<void> _addCodeChunk(List<RagChunk> chunks, RagDocument document, List<String> lines, int startLine, int endLine, int chunkIndex) async {
    if (startLine > endLine || startLine >= lines.length) return;
    
    final actualEndLine = math.min(endLine, lines.length - 1);
    final chunkLines = lines.sublist(startLine, actualEndLine + 1);
    final content = chunkLines.join('\n');
    
    if (content.trim().isEmpty) return;
    
    // 计算在原始内容中的位置
    int startPosition = 0;
    for (int i = 0; i < startLine; i++) {
      startPosition += lines[i].length + 1; // +1 for \n
    }
    
    int endPosition = startPosition + content.length;
    
    final chunk = RagChunk.create(

                  modelId: _model!.modelId,
      documentId: document.id,
      content: content,
      startPosition: startPosition,
      endPosition: endPosition,
      chunkIndex: chunkIndex,
      sourceFilePath: document.filePath,
      relativePath: document.metadata?['relativePath'],
      folderName: document.metadata?['folderName'],
      metadata: {
        'type': 'code_block',
        'start_line': startLine + 1,
        'end_line': actualEndLine + 1,
        'line_count': actualEndLine - startLine + 1,
      },
    );
    
    chunks.add(chunk);
  }

  // ============ 代码分析辅助方法 ============

  // 已移除未使用的 _findGoFunctionEnd 方法（未来如需更精确的 Go 函数边界检测，可在版本控制历史中恢复）

  /// 查找代码块结束位置（通过花括号匹配）
  int _findBlockEnd(List<String> lines, int startLine) {
    int braceCount = 0;
    bool foundOpenBrace = false;
    
    for (int i = startLine; i < lines.length; i++) {
      final line = lines[i];
      for (int j = 0; j < line.length; j++) {
        if (line[j] == '{') {
          braceCount++;
          foundOpenBrace = true;
        } else if (line[j] == '}') {
          braceCount--;
          if (foundOpenBrace && braceCount == 0) {
            return i;
          }
        }
      }
    }
    
    return lines.length - 1;
  }

  /// 查找Python代码块结束位置（通过缩进）
  int _findPythonBlockEnd(List<String> lines, int startLine) {
    if (startLine >= lines.length) return startLine;
    
    final startIndent = _getIndentLevel(lines[startLine]);
    
    for (int i = startLine + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final currentIndent = _getIndentLevel(lines[i]);
      if (currentIndent <= startIndent) {
        return i - 1;
      }
    }
    
    return lines.length - 1;
  }

  /// 获取缩进级别
  int _getIndentLevel(String line) {
    int indent = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        indent++;
      } else if (line[i] == '\t') {
        indent += 4; // 制表符算4个空格
      } else {
        break;
      }
    }
    return indent;
  }

  /// 查找函数结束位置
  int _findFunctionEnd(List<String> lines, int startLine) {
    // 对于简单函数，查找下一个空行或者下一个相同缩进级别的代码
    final startIndent = _getIndentLevel(lines[startLine]);
    
    for (int i = startLine + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final currentIndent = _getIndentLevel(lines[i]);
      if (currentIndent <= startIndent && !line.startsWith('//') && !line.startsWith('*')) {
        return i - 1;
      }
    }
    
    return lines.length - 1;
  }

  /// 检测是否是顶级函数
  bool _isTopLevelFunction(String line) {
    return (line.contains('(') && line.contains(')') && 
            !line.startsWith('//') && !line.startsWith('*') &&
            (line.contains('func ') || line.contains('function ') || 
             RegExp(r'^\w+\s*\(').hasMatch(line)));
  }

  /// 检测是否在类内部
  bool _isInsideClass(List<String> lines, int currentLine) {
    int braceCount = 0;
    for (int i = currentLine - 1; i >= 0; i--) {
      final line = lines[i];
      if (line.contains('class ')) {
        return braceCount > 0;
      }
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;
    }
    return false;
  }

  /// 提取XML标签名
  String _extractTagName(String line) {
    final match = RegExp(r'<(\w+)').firstMatch(line);
    return match?.group(1) ?? '';
  }

  /// 查找XML标签结束位置
  int _findXmlTagEnd(List<String> lines, int startLine, String tagName) {
    final closeTag = '</$tagName>';
    
    for (int i = startLine; i < lines.length; i++) {
      if (lines[i].contains(closeTag)) {
        return i;
      }
    }
    
    return lines.length - 1;
  }

  /// 分块JSON数据
  List<RagChunk> _chunkJsonData(RagDocument document, dynamic jsonData, String content) {
    final chunks = <RagChunk>[];
    
    if (jsonData is Map) {
      int chunkIndex = 0;
      int position = 0;
      
      for (final entry in jsonData.entries) {
        final keyValue = '"${entry.key}": ${json.encode(entry.value)}';
        final chunk = RagChunk.create(
          documentId: document.id,
          modelId: _model!.modelId,
          content: keyValue,
          startPosition: position,
          endPosition: position + keyValue.length,
          chunkIndex: chunkIndex++,
          sourceFilePath: document.filePath,
          relativePath: document.metadata?['relativePath'],
          folderName: document.metadata?['folderName'],
          metadata: {'type': 'json_key_value', 'key': entry.key},
        );
        chunks.add(chunk);
        position += keyValue.length + 1;
      }
    } else if (jsonData is List) {
      for (int i = 0; i < jsonData.length; i++) {
        final itemContent = json.encode(jsonData[i]);
        final chunk = RagChunk.create(
                    modelId: _model!.modelId,

          documentId: document.id,
          content: itemContent,
          startPosition: i * 100, // 简化位置计算
          endPosition: (i + 1) * 100,
          chunkIndex: i,
          sourceFilePath: document.filePath,
          relativePath: document.metadata?['relativePath'],
          folderName: document.metadata?['folderName'],
          metadata: {'type': 'json_array_item', 'index': i},
        );
        chunks.add(chunk);
      }
    }
    
    return chunks;
  }

  /// 获取文档的所有分块文件
  Future<List<RagChunk>> getDocumentChunks(RagDocument document) async {
    if (_model?.modelId == null) {
      return [];
    }
    
    try {
      final ragDir = path.join('assets/RAG', _model!.modelId);
      final chunksDir = path.join(ragDir, 'chunks');
      
      // 重建目标目录路径
      String targetChunkDir = chunksDir;
      
      if (document.metadata != null) {
        final relativePath = document.metadata!['relativePath'] as String?;
        final folderName = document.metadata!['folderName'] as String?;
        
        if (folderName != null && folderName.isNotEmpty) {
          targetChunkDir = path.join(chunksDir, folderName);
          
          if (relativePath != null && relativePath.isNotEmpty) {
            final relativeDir = path.dirname(relativePath);
            if (relativeDir != '.' && relativeDir.isNotEmpty) {
              targetChunkDir = path.join(targetChunkDir, relativeDir);
            }
          }
        } else if (relativePath != null && relativePath.isNotEmpty) {
          final relativeDir = path.dirname(relativePath);
          if (relativeDir != '.' && relativeDir.isNotEmpty) {
            targetChunkDir = path.join(chunksDir, relativeDir);
          }
        }
      }
      
      final chunkDirectory = Directory(targetChunkDir);
      if (!await chunkDirectory.exists()) {
        return [];
      }
      
      final baseFileName = path.basenameWithoutExtension(document.fileName);
      final chunks = <RagChunk>[];
      
      // 查找所有相关的分块文件
      await for (final entity in chunkDirectory.list()) {
        if (entity is File && entity.path.contains('${baseFileName}_chunk_')) {
          try {
            final jsonContent = await entity.readAsString();
            final chunk = RagChunk.fromJson(jsonContent);
            chunks.add(chunk);
          } catch (e) {
            if (kDebugMode) {
              print('读取分块文件失败: ${entity.path}, 错误: $e');
            }
          }
        }
      }
      
      // 按分块索引排序
      chunks.sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
      
      if (kDebugMode) {
        print('找到文档 ${document.fileName} 的 ${chunks.length} 个分块');
      }
      
      return chunks;
    } catch (e) {
      if (kDebugMode) {
        print('获取文档分块失败: $e');
      }
      return [];
    }
  }

  /// 删除文档的所有分块文件
  Future<bool> deleteDocumentChunks(RagDocument document) async {
    if (_model?.modelId == null) {
      return false;
    }
    
    try {
      final ragDir = path.join('assets/RAG', _model!.modelId);
      final chunksDir = path.join(ragDir, 'chunks');
      
      // 重建目标目录路径
      String targetChunkDir = chunksDir;
      
      if (document.metadata != null) {
        final relativePath = document.metadata!['relativePath'] as String?;
        final folderName = document.metadata!['folderName'] as String?;
        
        if (folderName != null && folderName.isNotEmpty) {
          targetChunkDir = path.join(chunksDir, folderName);
          
          if (relativePath != null && relativePath.isNotEmpty) {
            final relativeDir = path.dirname(relativePath);
            if (relativeDir != '.' && relativeDir.isNotEmpty) {
              targetChunkDir = path.join(targetChunkDir, relativeDir);
            }
          }
        } else if (relativePath != null && relativePath.isNotEmpty) {
          final relativeDir = path.dirname(relativePath);
          if (relativeDir != '.' && relativeDir.isNotEmpty) {
            targetChunkDir = path.join(chunksDir, relativeDir);
          }
        }
      }
      
      final chunkDirectory = Directory(targetChunkDir);
      if (!await chunkDirectory.exists()) {
        return true; // 目录不存在，认为删除成功
      }
      
      final baseFileName = path.basenameWithoutExtension(document.fileName);
      int deletedCount = 0;
      
      // 删除所有相关的分块文件
      await for (final entity in chunkDirectory.list()) {
        if (entity is File && entity.path.contains('${baseFileName}_chunk_')) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            if (kDebugMode) {
              print('删除分块文件失败: ${entity.path}, 错误: $e');
            }
          }
        }
      }
      
      if (kDebugMode) {
        print('删除文档 ${document.fileName} 的 $deletedCount 个分块文件');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('删除文档分块失败: $e');
      }
      return false;
    }
  }

  /// 清空所有分块文件
  Future<void> clearAllChunks() async {
    if (_model?.modelId == null) {
      return;
    }
    
    try {
      final ragDir = path.join('assets/RAG', _model!.modelId);
      final chunksDir = Directory(path.join(ragDir, 'chunks'));
      
      if (await chunksDir.exists()) {
        await chunksDir.delete(recursive: true);
        if (kDebugMode) {
          print('清空所有分块文件成功');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('清空分块文件失败: $e');
      }
      rethrow;
    }
  }
}

/// RAG异常
class RagException implements Exception {
  final String message;
  
  const RagException(this.message);
  
  @override
  String toString() => 'RagException: $message';
}

/// 导入上下文类
class _ImportContext {
  final List<File> files;
  final String folderName;
  final String sourceDirPath;
  final Directory sourceDir;
  final bool recursive;
  List<String> errors = [];

  _ImportContext({
    required this.files,
    required this.folderName,
    required this.sourceDirPath,
    required this.sourceDir,
    required this.recursive,
  });
}
