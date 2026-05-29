import 'package:chathub/models/bigmodel/chat_model.dart';
import 'package:chathub/models/rag/rag_document.dart';
import 'package:chathub/models/rag/rag_knowledge_base.dart';
import 'package:chathub/framework/llm_hub.dart';
import 'package:chathub/framework/services/vector_database_service.dart';
import 'package:chathub/services/file_processing_service.dart';
import 'package:chathub/utils/snackbar_utils.dart';
import 'package:chathub/widgets/common/confirm_delete_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class RagTab extends StatefulWidget {
  final ChatModel model;
  final Function(ChatModel) onModelUpdated;

  const RagTab({super.key, required this.model, required this.onModelUpdated});

  @override
  State<RagTab> createState() => _RagTabState();
}

class _RagTabState extends State<RagTab> {
  late ChatModel _currentModel;
  late TextEditingController _ragDocumentController;

  // RAG 功能相关状态
  String? _ragId; // 当前RAG知识库ID
  RagKnowledgeBase? _knowledgeBase;
  List<RagDocument> _documents = [];
  bool _isLoading = false;
  bool _isUploading = false;

  // 构建知识库进度状态
  bool _isBuildingKnowledgeBase = false;
  int _buildProgress = 0; // 当前处理的文档数量
  int _totalDocuments = 0; // 总文档数量
  String _currentProcessingFile = ''; // 当前正在处理的文件名

  // 文件夹结构相关状态
  final Map<String, List<RagDocument>> _folderStructure = {};
  List<String> _currentPath = [];

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _ragDocumentController = TextEditingController();

    // 异步初始化RAG知识库
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRagKnowledgeBase();
    });
  }

  /// 上传文件夹，保存到 assets/rag/$ragId/documents, 保留目录结构
  void _uploadFolder() async {
    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        // 使用新的框架功能导入文件夹
        setState(() {
          _isUploading = true;
        });

        final documents = await LlmClient.fromModel(
          _currentModel,
        ).importFolderToRag(folderPath: selectedDirectory, recursive: true);

        if (mounted) {
          SnackBarUtils.showSuccess(context, '成功导入 ${documents.length} 个文件');

          // 重新加载文档列表
          await _loadDocuments();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '文件夹上传失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 导入单个文件
  void _importFiles() async {
    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });

        final List<RagDocument> allDocuments = [];

        for (final file in result.files) {
          if (file.path != null) {
            try {
              final document = await LlmClient.fromModel(
                _currentModel,
              ).importFileToRag(filePath: file.path!, customTitle: file.name);

              allDocuments.add(document);
            } catch (e) {
              print('导入文件 ${file.name} 失败: $e');
            }
          }
        }

        if (mounted) {
          SnackBarUtils.showSuccess(context, '成功导入 ${allDocuments.length} 个文件');

          await _loadDocuments();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '文件导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 导入代码库
  void _importCodebase() async {
    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          _isUploading = true;
        });

        // 使用LlmClient导入文件夹
        final documents = await LlmClient.fromModel(
          _currentModel,
        ).importFolderToRag(folderPath: selectedDirectory, recursive: true);

        if (mounted) {
          SnackBarUtils.showSuccess(context, '代码库导入完成：${documents.length} 个文件');

          await _loadDocuments();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, '代码库导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 格式化字节大小

  /// 显示代码库导入选项对话框

  /// 初始化RAG知识库
  Future<void> _initializeRagKnowledgeBase() async {
    // 确保模型有RAG ID，如果没有则创建
    if (_currentModel.ragId.isEmpty) {
      print('创建新的RAG知识库...');
      // 创建RAG知识库目录结构（现在使用modelId）
      await LlmClient.fromModel(_currentModel).createRagKnowledgeBase();

      // RAG系统现在直接使用modelId，不需要单独存储知识库对象

      widget.onModelUpdated(_currentModel);
    }

    _ragId = _currentModel.ragId;
    print('开始初始化RAG知识库，RAG ID: $_ragId');

    setState(() {
      _isLoading = true;
    });

    try {
      // 加载知识库信息
      _knowledgeBase =
          await LlmClient.fromModel(_currentModel).getRagKnowledgeBase();

      if (_knowledgeBase != null) {
        print('知识库加载成功，文档数量: ${_knowledgeBase!.documents.length}');
        _documents = _knowledgeBase!.documents;
        _buildFolderStructure(_documents);
      } else {
        print('知识库不存在或为空');
        _documents = [];
      }

      print('RAG知识库初始化完成');
    } catch (e) {
      print('RAG知识库初始化失败: $e');
      _documents = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 加载文档列表
  Future<void> _loadDocuments() async {
    if (_ragId == null) {
      print('RAG ID未设置，无法加载文档');
      return;
    }

    try {
      print('开始加载已有文档，RAG ID: $_ragId');

      // 从LlmClient加载文档
      final docs =
          await LlmClient.fromModel(_currentModel).getAllRagDocuments();
      print('获取到 ${docs.length} 个文档');

      print('文档加载完成，找到 ${docs.length} 个文档');
      if (docs.isNotEmpty) {
        print('文档详情:');
        for (int i = 0; i < docs.length && i < 3; i++) {
          print(
            '  文档${i + 1}: ${docs[i].title} (${docs[i].formattedFileSize})',
          );
        }
      }

      setState(() {
        _documents = docs;
        _buildFolderStructure(docs);
      });
    } catch (e, stackTrace) {
      print('加载文档列表失败: $e');
      print('详细错误信息: ${e.toString()}');
      print('错误堆栈: $stackTrace');

      // 即使加载失败，也要确保UI状态正确
      setState(() {
        _documents = [];
      });
    }
  }

  /// 验证和清理文档列表（移除不存在的文件）

  /// 构建文件夹结构
  void _buildFolderStructure(List<RagDocument> docs) {
    _folderStructure.clear();

    for (final doc in docs) {
      final metadata = doc.metadata;
      if (metadata == null) {
        // 没有元数据的文档放在根目录
        _folderStructure.putIfAbsent('', () => []).add(doc);
        continue;
      }

      final relativePath = metadata['relativePath'] as String?;
      final folderName = metadata['folderName'] as String?;

      if (relativePath == null || relativePath.isEmpty) {
        // 没有相对路径的文档，检查是否有文件夹名称
        if (folderName != null && folderName.isNotEmpty) {
          _folderStructure.putIfAbsent(folderName, () => []).add(doc);
        } else {
          // 放在根目录
          _folderStructure.putIfAbsent('', () => []).add(doc);
        }
        continue;
      }

      // 解析完整路径
      String fullPath = '';
      if (folderName != null && folderName.isNotEmpty) {
        // 如果有文件夹名称，将其作为根路径
        final pathParts = relativePath.split('/');
        if (pathParts.length > 1) {
          // 文件在子目录中，构建完整路径：folderName/subdir1/subdir2/...
          final dirParts = pathParts.sublist(0, pathParts.length - 1);
          fullPath = '$folderName/${dirParts.join('/')}';
        } else {
          // 文件在根文件夹中
          fullPath = folderName;
        }
      } else {
        // 没有文件夹名称，直接使用相对路径
        final pathParts = relativePath.split('/');
        if (pathParts.length > 1) {
          final dirParts = pathParts.sublist(0, pathParts.length - 1);
          fullPath = dirParts.join('/');
        } else {
          // 文件在根目录
          fullPath = '';
        }
      }

      _folderStructure.putIfAbsent(fullPath, () => []).add(doc);
    }

    print('文件夹结构构建完成：');
    _folderStructure.forEach((path, files) {
      print('  路径 "$path": ${files.length} 个文件');
    });
  }

  /// 获取当前目录的内容（文件夹和文件）
  List<dynamic> _getCurrentDirectoryItems() {
    final currentPathStr = _currentPath.join('/');
    List<dynamic> items = [];

    // 收集子文件夹
    Set<String> subFolders = {};

    // 遍历所有已知的文件夹路径
    for (final folderPath in _folderStructure.keys) {
      if (currentPathStr.isEmpty) {
        // 在根目录，查找顶级文件夹
        if (folderPath.isNotEmpty) {
          final parts = folderPath.split('/');
          final topFolder = parts[0];
          subFolders.add(topFolder);
        }
      } else {
        // 在子目录中，查找下一级文件夹
        if (folderPath.startsWith('$currentPathStr/')) {
          // 获取当前路径后的剩余部分
          final remainingPath = folderPath.substring(currentPathStr.length + 1);

          if (remainingPath.contains('/')) {
            // 如果剩余路径还包含斜杠，说明还有更深层的目录
            final nextFolder = remainingPath.split('/')[0];
            subFolders.add(nextFolder);
          } else {
            // 如果剩余路径不包含斜杠，说明这是下一级的直接子文件夹
            subFolders.add(remainingPath);
          }
        }
      }
    }

    // 添加文件夹项
    for (final folder in subFolders) {
      final folderPath =
          currentPathStr.isEmpty ? folder : '$currentPathStr/$folder';
      items.add({'type': 'folder', 'name': folder, 'path': folderPath});
    }

    // 添加当前目录的文件
    final currentFiles = _folderStructure[currentPathStr] ?? [];
    items.addAll(currentFiles);

    return items;
  }

  /// 进入文件夹
  void _enterFolder(String folderName) {
    setState(() {
      _currentPath.add(folderName);
    });
  }

  /// 返回上级目录
  void _goBack() {
    if (_currentPath.isNotEmpty) {
      setState(() {
        _currentPath.removeLast();
      });
    }
  }

  /// 返回根目录
  void _goToRoot() {
    setState(() {
      _currentPath.clear();
    });
  }

  /// 刷新文档列表（带用户反馈）
  Future<void> _refreshDocuments() async {
    print('用户手动刷新文档列表');
    await _loadDocuments();

    if (mounted) {
      SnackBarUtils.showSuccess(context, '已刷新，找到 ${_documents.length} 个文档');
    }
  }

  /// 构建知识库 - 后台异步执行切片任务
  Future<void> _buildKnowledgeBase() async {
    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    if (_documents.isEmpty) {
      SnackBarUtils.showError(context, '请先上传文档再构建知识库');
      return;
    }

    // 设置初始状态
    setState(() {
      _isBuildingKnowledgeBase = true;
      _buildProgress = 0;
      _totalDocuments = _documents.length;
      _currentProcessingFile = '';
    });

    // 后台异步执行切片任务，不阻塞UI
    _performChunkingInBackground();
  }

  /// 后台执行文档切片任务
  void _performChunkingInBackground() async {
    int processedCount = 0;
    int totalChunks = 0;
    final List<String> processedFiles = [];
    final List<String> failedFiles = [];

    try {
      if (kDebugMode) {
        print('开始执行文档切片任务，共 ${_documents.length} 个文档');
      }

      // 获取RAG客户端
      final ragClient = LlmClient.fromModel(_currentModel);

      // 逐个处理文档进行分块
      for (final document in _documents) {
        try {
          if (mounted) {
            setState(() {
              _currentProcessingFile = document.fileName;
            });
          }

          if (kDebugMode) {
            print('正在处理文档: ${document.fileName}');
          }

          // 为文档创建分块
          final chunks = await ragClient.chunkDocument(document);

          if (chunks.isNotEmpty) {
            totalChunks += chunks.length;
            processedFiles.add(document.fileName);

            if (kDebugMode) {
              print('文档 ${document.fileName} 分块完成，生成 ${chunks.length} 个分块');
            }
          } else {
            if (kDebugMode) {
              print('文档 ${document.fileName} 内容为空或无法分块');
            }
          }

          processedCount++;

          // 更新进度状态
          if (mounted) {
            setState(() {
              _buildProgress = processedCount;
            });
          }
        } catch (e) {
          failedFiles.add(document.fileName);
          if (kDebugMode) {
            print('处理文档 ${document.fileName} 失败: $e');
          }

          processedCount++;
          if (mounted) {
            setState(() {
              _buildProgress = processedCount;
            });
          }
        }
      }

      if (kDebugMode) {
        print('文档分块任务完成：');
        print('- 处理成功: $processedCount/${_documents.length} 个文档');
        print('- 生成分块: $totalChunks 个');
        print('- 失败文件: ${failedFiles.length} 个');
      }

      // 显示完成提示
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (failedFiles.isEmpty) {
          final message =
              '知识库构建完成！\n'
              '成功处理 ${processedFiles.length} 个文档\n'
              '生成 $totalChunks 个智能分块\n'
              '支持代码语法感知和语义搜索';
          SnackBarUtils.showSuccess(context, message);
        } else {
          final message =
              '知识库构建部分完成\n'
              '成功处理: ${processedFiles.length} 个文档\n'
              '生成分块: $totalChunks 个\n'
              '失败文件: ${failedFiles.length} 个';
          SnackBarUtils.showWarning(context, message);
        }

        // 重置构建状态
        setState(() {
          _isBuildingKnowledgeBase = false;
          _buildProgress = 0;
          _totalDocuments = 0;
          _currentProcessingFile = '';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('后台切片任务失败: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        SnackBarUtils.showError(context, '知识库构建失败: $e');

        // 重置构建状态（即使失败也要重置）
        setState(() {
          _isBuildingKnowledgeBase = false;
          _buildProgress = 0;
          _totalDocuments = 0;
          _currentProcessingFile = '';
        });
      }
    }
  }

  /// 调试RAG存储状态

  @override
  void dispose() {
    _ragDocumentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // 文档管理卡片
        Expanded(child: _buildDocumentUploadSection()),
      ],
    );
  }

  /// 显示测试查询对话框
  void _showTestDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _RagQueryTestDialog(
          ragId: _ragId,
          documents: _documents,
          model: _currentModel,
        );
      },
    );
  }

  Widget _buildDocumentUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _refreshDocuments,
                  icon: const Icon(CupertinoIcons.refresh, size: 12),
                  tooltip: '刷新文档列表',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showTestDialog,
                  icon: const Icon(CupertinoIcons.search, size: 10),
                  label: const Text('测试查询'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: const Size(60, 24),
                    textStyle: const TextStyle(fontSize: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected:
                      _isUploading
                          ? null
                          : (value) {
                            switch (value) {
                              case 'file':
                                _importFiles();
                                break;
                              case 'folder':
                                _uploadFolder();
                                break;
                              case 'codebase':
                                _importCodebase();
                                break;
                              case 'git':
                                _importFromGit();
                                break;
                            }
                          },
                  itemBuilder:
                      (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'file',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.doc, size: 14),
                              SizedBox(width: 8),
                              Text('导入文件', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'folder',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.folder, size: 14),
                              SizedBox(width: 8),
                              Text('导入文件夹', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'codebase',
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.square_stack_3d_down_right,
                                size: 14,
                              ),
                              SizedBox(width: 8),
                              Text('导入代码库', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'git',
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.link, size: 14),
                              SizedBox(width: 8),
                              Text('从Git导入', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isUploading ? Colors.grey : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isUploading) ...[
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '处理中',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ] else ...[
                          const Icon(
                            CupertinoIcons.plus,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '上传',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            CupertinoIcons.chevron_down,
                            size: 8,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      (_isUploading || _isBuildingKnowledgeBase)
                          ? null
                          : _buildKnowledgeBase,
                  icon: const Icon(CupertinoIcons.gear_alt, size: 10),
                  label: const Text('构建知识库'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: const Size(60, 24),
                    textStyle: const TextStyle(fontSize: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // 构建知识库进度指示器
                if (_isBuildingKnowledgeBase) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 16, // 与构建按钮高度一致
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 将进度数字和文件名显示在同一行，避免高度跳动
                        Flexible(
                          child: Text(
                            _currentProcessingFile.isNotEmpty
                                ? '处理中 $_buildProgress/$_totalDocuments - $_currentProcessingFile'
                                : '处理中 $_buildProgress/$_totalDocuments',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 路径导航栏
        if (_currentPath.isNotEmpty) _buildPathNavigation(),
        if (_currentPath.isNotEmpty) const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child:
                _isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '正在加载文档...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                    : _getCurrentDirectoryItems().isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentPath.isEmpty
                                ? CupertinoIcons.doc_text
                                : CupertinoIcons.folder,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentPath.isEmpty ? '暂无文档' : '文件夹为空',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_currentPath.isEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '支持单个文件、文件夹和Git仓库导入\n文档格式：TXT、MD、JSON、CSV、DOC、DOCX等\n代码格式：Dart、JS、TS、Python、Java、Go等',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _getCurrentDirectoryItems().length,
                      itemBuilder: (context, index) {
                        final item = _getCurrentDirectoryItems()[index];

                        if (item is Map<String, dynamic> &&
                            item['type'] == 'folder') {
                          // 文件夹项
                          return _buildFolderItem(item);
                        } else {
                          // 文件项
                          final doc = item as RagDocument;
                          return _buildDocumentItem(doc);
                        }
                      },
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '已上传 ${_documents.length} 个文档到知识库',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            if (_currentPath.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '(当前目录: ${_getCurrentDirectoryItems().whereType<RagDocument>().length} 个文件)',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
            if (_isUploading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 构建路径导航栏
  Widget _buildPathNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 根目录按钮
          GestureDetector(
            onTap: _goToRoot,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    _currentPath.isEmpty
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.home,
                    size: 12,
                    color:
                        _currentPath.isEmpty
                            ? Colors.blue[600]
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '根目录',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          _currentPath.isEmpty
                              ? Colors.blue[600]
                              : Colors.grey[600],
                      fontWeight:
                          _currentPath.isEmpty
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 路径分隔符和路径项
          for (int i = 0; i < _currentPath.length; i++) ...[
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 10,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  // 安全地创建新的路径，避免并发修改问题
                  if (i < _currentPath.length) {
                    _currentPath = _currentPath.sublist(0, i + 1);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      i == _currentPath.length - 1
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _currentPath[i],
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        i == _currentPath.length - 1
                            ? Colors.blue[600]
                            : Colors.grey[600],
                    fontWeight:
                        i == _currentPath.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          // 返回按钮
          if (_currentPath.isNotEmpty)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Icon(
                  CupertinoIcons.back,
                  size: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建文件夹项
  Widget _buildFolderItem(Map<String, dynamic> folderItem) {
    final folderName = folderItem['name'] as String;
    final folderPath = folderItem['path'] as String;

    // 统计文件夹中的文件数量、总大小和最新上传时间
    int fileCount = 0;
    int totalSize = 0;
    DateTime? latestUploadTime;

    _folderStructure.forEach((path, files) {
      if (path.startsWith(folderPath)) {
        fileCount += files.length;
        for (final file in files) {
          totalSize += file.fileSize ?? 0;
          if (latestUploadTime == null ||
              file.uploadTime.isAfter(latestUploadTime!)) {
            latestUploadTime = file.uploadTime;
          }
        }
      }
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _enterFolder(folderName),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // 文件夹图标
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    CupertinoIcons.folder_fill,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                ),
                const SizedBox(width: 12),
                // 文件夹信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      Text(
                        '$fileCount 个文件',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),

                      // 文件夹大小和上传时间
                      Row(
                        children: [
                          // 文件夹大小
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              _formatFileSize(totalSize),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 上传时间
                          if (latestUploadTime != null) ...[
                            Icon(
                              CupertinoIcons.time,
                              size: 9,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatUploadTime(latestUploadTime),
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 删除按钮
                Tooltip(
                  message: '删除文件夹',
                  child: GestureDetector(
                    onTap: () => _deleteFolder(folderPath, folderName),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 进入箭头
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: Colors.blue[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建文档项
  Widget _buildDocumentItem(RagDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _showFileContentDialog(doc), // 单击查看内容
          onDoubleTap: () => _openFileWithSystem(doc), // 双击用系统程序打开
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 文件类型图标
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getDocumentIconColor(doc).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getDocumentIcon(doc),
                    size: 16,
                    color: _getDocumentIconColor(doc),
                  ),
                ),
                const SizedBox(width: 12),
                // 文档信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 文档标题
                      Text(
                        _getDocumentDisplayTitle(doc),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // 显示相对路径信息
                      if (doc.metadata != null &&
                          doc.metadata!['relativePath'] != null) ...[
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.folder,
                              size: 9,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                doc.metadata!['relativePath'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // 文件大小和上传时间
                      Row(
                        children: [
                          // 文件大小
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              doc.formattedFileSize,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 上传时间
                          Icon(
                            CupertinoIcons.time,
                            size: 9,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatUploadTime(doc.uploadTime),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                          // 文件扩展名标签
                          if (doc.fileExtension != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                doc.fileExtension!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // 操作提示
                      Text(
                        '单击预览 • 双击打开',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 删除按钮
                Tooltip(
                  message: '删除文档',
                  child: GestureDetector(
                    onTap: () => _deleteDocument(doc),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        size: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示文件内容对话框
  void _showFileContentDialog(RagDocument doc) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _FileContentDialog(document: doc);
      },
    );
  }

  /// 用系统默认程序打开文件
  Future<void> _openFileWithSystem(RagDocument doc) async {
    try {
      final file = File(doc.filePath);

      if (!await file.exists()) {
        if (mounted) {
          SnackBarUtils.showError(context, '文件不存在: ${doc.fileName}');
        }
        return;
      }

      // 根据平台使用不同的命令打开文件
      ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', [doc.filePath]);
      } else if (Platform.isWindows) {
        result = await Process.run('start', [
          '',
          doc.filePath,
        ], runInShell: true);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [doc.filePath]);
      } else {
        throw UnsupportedError('当前平台不支持打开文件');
      }

      if (result.exitCode != 0) {
        throw Exception('打开文件失败: ${result.stderr}');
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已用系统默认程序打开: ${doc.fileName}');
      }
    } catch (e) {
      print('打开文件失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, '打开文件失败: $e');
      }
    }
  }

  /// 从Git仓库导入代码
  void _importFromGit() async {
    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    // 显示Git URL输入对话框
    final gitUrl = await _showGitUrlDialog();
    if (gitUrl == null || gitUrl.trim().isEmpty) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 解析git地址后面的目录名
      final uri = Uri.parse(gitUrl.trim());
      String repoName =
          uri.pathSegments.isNotEmpty
              ? uri.pathSegments.last.replaceAll('.git', '')
              : 'git_repo';
      final tempDir = Directory.systemTemp.createTempSync(repoName);
      final repoPath = tempDir.path;

      SnackBarUtils.showInfo(context, '正在克隆仓库: $gitUrl');

      // 使用git命令克隆仓库
      final result = await Process.run('git', [
        'clone',
        '--depth',
        '1',
        gitUrl.trim(),
        repoPath,
      ], workingDirectory: Directory.systemTemp.path);

      if (result.exitCode != 0) {
        throw Exception('Git克隆失败: ${result.stderr}');
      }

      // 使用LlmClient导入文件夹
      final documents = await LlmClient.fromModel(
        _currentModel,
      ).importFolderToRag(folderPath: repoPath, recursive: true);

      if (documents.isEmpty) {
        throw Exception('仓库中未找到有效的代码文件');
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Git仓库导入完成：${documents.length} 个文件');

        await _loadDocuments();
      }

      // 清理临时目录
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        print('清理临时目录失败: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        SnackBarUtils.showError(context, 'Git导入失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// 显示Git URL输入对话框
  Future<String?> _showGitUrlDialog() async {
    final TextEditingController urlController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,

      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Row(
            children: [
              Icon(CupertinoIcons.link, size: 20),
              SizedBox(width: 8),
              Text('从Git仓库导入', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请输入Git仓库URL：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://github.com/user/repo.git',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.of(context).pop(value.trim());
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                '支持的仓库类型：\n• GitHub: https://github.com/user/repo.git\n• GitLab: https://gitlab.com/user/repo.git\n• 其他Git仓库的公开URL',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.of(context).pop(url);
                }
              },
              child: const Text('导入'),
            ),
          ],
        );
      },
    );
  }

  /// 扫描代码库（智能过滤）

  /// 检查是否应该忽略某个路径

  /// 检查文件扩展名是否有效

  /// 创建RAG目录结构

  /// 保存文件到RAG目录（保留目录结构）

  /// 处理选中的文件列表（优化版本）

  /// 获取文档显示标题
  String _getDocumentDisplayTitle(RagDocument doc) {
    if (doc.title.isNotEmpty) {
      // 如果标题包含路径分隔符，提取文件名部分作为主标题
      if (doc.title.contains('/') || doc.title.contains('\\')) {
        return doc.title.split(RegExp(r'[/\\]')).last;
      }
      return doc.title;
    }
    return '未知文档';
  }

  /// 格式化上传时间
  String _formatUploadTime(DateTime? uploadTime) {
    if (uploadTime == null) return '未知时间';

    final now = DateTime.now();
    final diff = now.difference(uploadTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';

    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '${size.toInt()} ${units[unitIndex]}';
    } else {
      return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
    }
  }

  /// 根据文件类型获取图标
  IconData _getDocumentIcon(RagDocument doc) {
    final metadata = doc.metadata;
    if (metadata == null) return CupertinoIcons.doc_text;

    final extension = metadata['file_extension'] as String?;
    if (extension == null) return CupertinoIcons.doc_text;

    switch (extension.toLowerCase()) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
      case 'vue':
      case 'py':
      case 'java':
      case 'kt':
      case 'swift':
      case 'go':
      case 'rs':
      case 'cpp':
      case 'c':
      case 'cs':
      case 'php':
      case 'rb':
        return CupertinoIcons.cube_box; // 代码文件
      case 'md':
      case 'markdown':
        return CupertinoIcons.doc_richtext; // Markdown文件
      case 'json':
      case 'yaml':
      case 'yml':
      case 'xml':
        return CupertinoIcons.doc_chart; // 配置文件
      case 'html':
      case 'css':
      case 'scss':
        return CupertinoIcons.globe; // Web文件
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return CupertinoIcons.photo; // 图片文件
      case 'pdf':
        return CupertinoIcons.doc_text_fill; // PDF文件
      case 'doc':
      case 'docx':
        return CupertinoIcons.doc_richtext; // Word文档
      case 'rtf':
      case 'odt':
        return CupertinoIcons.doc_text_fill; // 其他文档格式
      default:
        return CupertinoIcons.doc_text; // 默认文档图标
    }
  }

  /// 根据文件类型获取图标颜色
  Color _getDocumentIconColor(RagDocument doc) {
    final metadata = doc.metadata;
    if (metadata == null) return Colors.blue[600]!;

    final extension = metadata['file_extension'] as String?;
    if (extension == null) return Colors.blue[600]!;

    switch (extension.toLowerCase()) {
      case 'dart':
        return Colors.blue[700]!; // Dart蓝色
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Colors.yellow[700]!; // JavaScript黄色
      case 'vue':
        return Colors.green[600]!; // Vue绿色
      case 'py':
        return Colors.blue[800]!; // Python蓝色
      case 'java':
      case 'kt':
        return Colors.orange[700]!; // Java橙色
      case 'swift':
        return Colors.orange[600]!; // Swift橙色
      case 'go':
        return Colors.cyan[600]!; // Go青色
      case 'rs':
        return Colors.brown[600]!; // Rust棕色
      case 'cpp':
      case 'c':
        return Colors.indigo[600]!; // C/C++靛蓝色
      case 'cs':
        return Colors.purple[600]!; // C#紫色
      case 'php':
        return Colors.indigo[700]!; // PHP靛蓝色
      case 'rb':
        return Colors.red[600]!; // Ruby红色
      case 'md':
      case 'markdown':
        return Colors.grey[700]!; // Markdown灰色
      case 'json':
      case 'yaml':
      case 'yml':
        return Colors.teal[600]!; // 配置文件青色
      case 'html':
        return Colors.orange[600]!; // HTML橙色
      case 'css':
      case 'scss':
        return Colors.blue[500]!; // CSS蓝色
      case 'xml':
        return Colors.green[700]!; // XML绿色
      case 'doc':
      case 'docx':
        return Colors.blue[600]!; // Word文档蓝色
      case 'pdf':
        return Colors.red[600]!; // PDF红色
      case 'rtf':
      case 'odt':
        return Colors.purple[600]!; // 其他文档格式紫色
      default:
        return Colors.blue[600]!; // 默认蓝色
    }
  }

  /// 删除文档
  void _deleteDocument(RagDocument document) async {
    // 显示确认对话框
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '删除文档',
      itemName: document.title,
      description: '确定要删除文档',
      warningMessage: '此操作不可撤销',
      icon: CupertinoIcons.doc_text,
      iconColor: Colors.red,
    );

    if (shouldDelete != true) return;

    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 先删除assets目录中的本地文件
      try {
        final file = File(document.filePath);
        if (await file.exists()) {
          await file.delete();
          print('已删除本地文件: ${document.filePath}');
        } else {
          print('本地文件不存在或已被删除: ${document.filePath}');
        }
      } catch (e) {
        print('删除本地文件失败: $e');
        // 即使本地文件删除失败，仍然继续删除文档记录
      }

      // 删除文档记录
      await LlmClient.fromModel(
        _currentModel,
      ).deleteRagDocument(documentId: document.id);

      // 重新加载文档列表
      await _loadDocuments();

      if (mounted) {
        SnackBarUtils.showSuccess(context, '已删除文档 "${document.title}"');
      }
    } catch (e) {
      print('删除文档失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, '删除失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 删除文件夹及其所有文件
  void _deleteFolder(String folderPath, String folderName) async {
    // 获取文件夹中的所有文档
    final List<RagDocument> folderDocuments = [];
    _folderStructure.forEach((path, documents) {
      if (path.startsWith(folderPath)) {
        folderDocuments.addAll(documents);
      }
    });

    if (folderDocuments.isEmpty) {
      SnackBarUtils.showInfo(context, '文件夹中没有文档可删除');
      return;
    }

    // 显示确认对话框
    final bool? shouldDelete = await ConfirmDeleteDialog.show(
      context: context,
      title: '删除文件夹',
      itemName: folderName,
      description: '确定要删除文件夹及其所有文件',
      warningMessage: '将删除 ${folderDocuments.length} 个文件，此操作不可撤销',
      icon: CupertinoIcons.folder,
      iconColor: Colors.red,
    );

    if (shouldDelete != true) return;

    if (_ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      int deletedCount = 0;
      List<String> errors = [];

      // 删除文件夹中的所有文档
      for (final document in folderDocuments) {
        try {
          // 删除本地文件
          try {
            final file = File(document.filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('删除本地文件失败: $e');
          }

          // 删除文档记录
          await LlmClient.fromModel(
            _currentModel,
          ).deleteRagDocument(documentId: document.id);

          deletedCount++;
        } catch (e) {
          errors.add('删除文档 "${document.title}" 失败: $e');
        }
      }

      // 重新加载文档列表
      await _loadDocuments();

      if (mounted) {
        if (errors.isEmpty) {
          SnackBarUtils.showSuccess(
            context,
            '已删除文件夹 "$folderName" 及其 $deletedCount 个文件',
          );
        } else {
          SnackBarUtils.showWarning(
            context,
            '文件夹删除完成，成功删除 $deletedCount 个文件，${errors.length} 个失败',
          );
        }
      }
    } catch (e) {
      print('删除文件夹失败: $e');
      if (mounted) {
        SnackBarUtils.showError(context, '删除文件夹失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// 独立的RAG查询测试弹窗
class _RagQueryTestDialog extends StatefulWidget {
  final String? ragId;
  final List<RagDocument> documents;
  final ChatModel model;

  const _RagQueryTestDialog({
    required this.ragId,
    required this.documents,
    required this.model,
  });

  @override
  State<_RagQueryTestDialog> createState() => _RagQueryTestDialogState();
}

class _RagQueryTestDialogState extends State<_RagQueryTestDialog> {
  late TextEditingController _queryController;
  List<VectorSearchResult> _searchResults = [];
  bool _isSearching = false;

  /// 格式化上传时间
  String _formatUploadTime(DateTime? uploadTime) {
    if (uploadTime == null) return '未知时间';

    final now = DateTime.now();
    final diff = now.difference(uploadTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 弹窗标题栏
            Row(
              children: [
                Icon(
                  CupertinoIcons.search_circle,
                  size: 20,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                const Text(
                  '查询测试',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 知识库状态
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '知识库状态: ${widget.documents.length} 篇文档',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.ragId != null
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.ragId != null ? '已初始化' : '未初始化',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            widget.ragId != null
                                ? Colors.green[700]
                                : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 测试区域
            Expanded(child: _buildQueryTestSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测试查询',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            hintText: '输入测试查询...',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: const EdgeInsets.all(10),
            suffixIcon: IconButton(
              icon: const Icon(CupertinoIcons.search, size: 16),
              onPressed: _testRagQuery,
              tooltip: '测试查询',
            ),
          ),
          style: const TextStyle(fontSize: 12),
          onSubmitted: (_) => _testRagQuery(),
        ),
        const SizedBox(height: 8),
        if (_isSearching)
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '搜索结果',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final chunk = result.chunk;
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: Text('内容预览'),
                            content: SingleChildScrollView(
                              child: SelectableText(chunk.content),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('关闭'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chunk.sourceFilePath.split('/').last,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(result.similarity * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 显示切片信息
                          Row(
                            children: [
                              Text(
                                'Chunk ${chunk.chunkIndex}: ${chunk.contentLength} chars',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Position: ${chunk.positionRange}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chunk.preview,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${_formatUploadTime(chunk.createdTime)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ] else if (!_isSearching) ...[
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.search,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchResults.isEmpty && _queryController.text.isNotEmpty
                        ? '未找到相关内容'
                        : '输入查询内容并点击搜索',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  if (_searchResults.isEmpty &&
                      _queryController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '尝试使用不同的关键词或短语',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          '测试RAG知识库的查询功能，验证相关文档检索效果。',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _testRagQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      SnackBarUtils.showWarning(context, '请输入测试查询内容');
      return;
    }

    if (widget.ragId == null) {
      SnackBarUtils.showError(context, 'RAG知识库未初始化');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      print('=== 搜索调试信息 ===');
      print('查询内容: "$query"');
      print('当前文档总数: ${widget.documents.length}');

      // 使用LlmClient进行搜索
      print('使用LlmClient搜索...');
      final results = await LlmClient.fromModel(
        widget.model,
      ).searchRagDocuments(query: query);

      print('搜索结果: 找到 ${results.length} 个相关文档');
      for (int i = 0; i < results.length && i < 3; i++) {
        final result = results[i];
        final chunk = result.chunk;
        print(
          '  结果${i + 1}: ${chunk.sourceFilePath} (相似度: ${result.similarity.toStringAsFixed(3)})',
        );
        print('    内容预览: ${chunk.preview}');
      }
      print('==================');

      setState(() {
        _searchResults = results;
      });

      if (results.isNotEmpty) {
        SnackBarUtils.showSuccess(context, '找到 ${results.length} 个搜索结果');
      } else {
        SnackBarUtils.showInfo(context, '未找到任何搜索结果');
      }
    } catch (e) {
      print('查询失败: $e');
      SnackBarUtils.showError(context, '查询失败: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
}

/// 文件内容显示对话框
class _FileContentDialog extends StatefulWidget {
  final RagDocument document;

  const _FileContentDialog({required this.document});

  @override
  State<_FileContentDialog> createState() => _FileContentDialogState();
}

class _FileContentDialogState extends State<_FileContentDialog> {
  String _content = '';
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  /// 加载文件内容
  Future<void> _loadFileContent() async {
    try {
      final file = File(widget.document.filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        final extension = widget.document.fileExtension?.toLowerCase();

        // 根据文件类型选择不同的读取方式
        if (extension == 'docx') {
          // 读取DOCX文件
          _content = await _readDocxFile(file);
        } else if (extension == 'doc') {
          // DOC文件暂时显示提示信息，因为需要更复杂的解析
          _content =
              '抱歉，暂不支持直接预览.doc格式文件，请转换为.docx格式后重新上传。\n\n文件信息：\n文件名：${widget.document.fileName}\n文件大小：${widget.document.formattedFileSize}\n文件路径：${widget.document.filePath}';
        } else {
          // 普通文本文件
          if (fileSize > 1024 * 1024) {
            // 如果文件太大（超过1MB），只读取前1MB
            final bytes = await file.openRead(0, 1024 * 1024).toList();
            final allBytes = <int>[];
            for (final chunk in bytes) {
              allBytes.addAll(chunk);
            }
            _content = String.fromCharCodes(allBytes);
            _content += '\n\n... (文件太大，仅显示前1MB内容)';
          } else {
            _content = await file.readAsString();
          }
        }
      } else {
        _error = '文件不存在: ${widget.document.filePath}';
      }
    } catch (e) {
      _error = '读取文件失败: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 读取DOCX文件内容
  Future<String> _readDocxFile(File file) async {
    try {
      final text = await FileProcessingService.extractDocxText(file);

      if (text.isEmpty) {
        return '文档内容为空或无法读取文本内容。\n\n文件信息：\n文件名：${widget.document.fileName}\n文件大小：${widget.document.formattedFileSize}';
      }

      return text;
    } catch (e) {
      return '读取DOCX文件失败: $e\n\n可能原因：\n1. 文件损坏或格式不正确\n2. 文档包含复杂格式或加密\n3. 文件正在被其他程序使用\n\n文件信息：\n文件名：${widget.document.fileName}\n文件大小：${widget.document.formattedFileSize}';
    }
  }

  /// 获取文件类型对应的语言标识（用于语法高亮）
  String _getLanguageFromExtension(String? extension) {
    if (extension == null) return 'text';

    switch (extension.toLowerCase()) {
      case 'dart':
        return 'dart';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'py':
        return 'python';
      case 'java':
        return 'java';
      case 'kt':
        return 'kotlin';
      case 'swift':
        return 'swift';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'cpp':
      case 'c':
      case 'h':
      case 'hpp':
        return 'cpp';
      case 'cs':
        return 'csharp';
      case 'php':
        return 'php';
      case 'rb':
        return 'ruby';
      case 'html':
        return 'html';
      case 'css':
      case 'scss':
      case 'sass':
        return 'css';
      case 'json':
        return 'json';
      case 'xml':
        return 'xml';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
      case 'markdown':
        return 'markdown';
      case 'sql':
        return 'sql';
      case 'sh':
      case 'bash':
        return 'bash';
      default:
        return 'text';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  // 文件图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      CupertinoIcons.doc_text,
                      size: 20,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 文件信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.document.formattedFileSize,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (widget.document.fileExtension != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.document.fileExtension!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 关闭按钮
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CupertinoIcons.xmark),
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '正在加载文件内容...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _error.isNotEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 48,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载失败',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : Container(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: SelectableText(
                              _content,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Monaco, Consolas, monospace',
                                height: 1.4,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
            // 底部操作栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '文件路径: ${widget.document.filePath}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '语言: ${_getLanguageFromExtension(widget.document.fileExtension)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
