import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart';
import '../models/chat/chat_attachment.dart';

/// 文件处理服务
/// 负责读取和处理各种类型的文件内容
class FileProcessingService {
  /// 支持的文本文件扩展名
  static const Set<String> _textExtensions = {
    'txt',
    'md',
    'markdown',
    'json',
    'xml',
    'csv',
    'log',
    'ini',
    'cfg',
    'conf',
    'yaml',
    'yml',
    'toml',
    'properties',
    'gitignore',
    'dockerfile',
    'makefile',
    'readme',
    'license',
    'changelog',
    'todo',
  };

  /// 支持的代码文件扩展名
  static const Set<String> _codeExtensions = {
    'dart',
    'js',
    'ts',
    'jsx',
    'tsx',
    'vue',
    'py',
    'java',
    'kt',
    'swift',
    'go',
    'rs',
    'c',
    'cpp',
    'cc',
    'cxx',
    'h',
    'hpp',
    'cs',
    'php',
    'rb',
    'scala',
    'clj',
    'hs',
    'elm',
    'r',
    'matlab',
    'm',
    'sh',
    'bash',
    'zsh',
    'fish',
    'ps1',
    'bat',
    'cmd',
    'sql',
    'html',
    'css',
    'scss',
    'sass',
    'less',
    'styl',
  };

  /// 支持的图片文件扩展名
  static const Set<String> _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'svg',
    'ico',
    'tiff',
    'tif',
  };

  /// 支持的办公文件扩展名
  static const Set<String> _officeExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'odt',
    'ods',
    'odp',
    'rtf',
  };

  /// 最大文件大小限制 (10MB)
  static const int _maxFileSize = 10 * 1024 * 1024;

  /// 最大文本内容长度 (100KB)
  static const int _maxTextLength = 100 * 1024;

  /// 处理附件，读取文件内容并生成上下文信息
  ///
  /// 大文件（>5MB）会自动上传到 OSS 并生成访问 URL
  static Future<ChatAttachment> processAttachment(
    ChatAttachment attachment,
  ) async {
    if (attachment.filePath == null || attachment.filePath!.isEmpty) {
      return attachment;
    }

    try {
      final file = File(attachment.filePath!);

      // 检查文件是否存在
      if (!await file.exists()) {
        debugPrint('文件不存在: ${attachment.filePath}');
        return attachment.copyWith(content: '[文件不存在或已被移动]');
      }

      // 获取文件信息
      final fileStat = await file.stat();
      final fileSize = fileStat.size;

      // 检查文件大小
      if (fileSize > _maxFileSize) {
        return attachment.copyWith(
          content: '[文件过大，无法读取内容。文件大小: ${_formatFileSize(fileSize)}]',
          size: fileSize,
        );
      }

      // 根据文件类型处理
      final extension = _getFileExtension(attachment.name).toLowerCase();
      String? content;
      String? processedType;

      if (_textExtensions.contains(extension)) {
        content = await _readTextFile(file);
        processedType = 'text';
      } else if (_codeExtensions.contains(extension)) {
        content = await _readCodeFile(file, extension);
        processedType = 'code';
      } else if (_imageExtensions.contains(extension)) {
        content = await _processImageFile(file, attachment.name);
        processedType = 'image';
      } else if (_officeExtensions.contains(extension)) {
        content = await _readOfficeFile(file, extension, attachment.name);
        processedType = 'office';
      } else {
        // 尝试作为文本文件读取
        content = await _tryReadAsText(file);
        processedType = content != null ? 'text' : 'binary';
        content ??= '[二进制文件，无法读取内容]';
      }

      return attachment.copyWith(
        content: content,
        size: fileSize,
        type: processedType,
      );
    } catch (e) {
      debugPrint('处理文件时出错: $e');
      return attachment.copyWith(content: '[读取文件时出错: $e]');
    }
  }

  /// 在后台处理附件，避免阻塞UI
  static Future<ChatAttachment> processAttachmentInBackground(
    ChatAttachment attachment,
  ) async {
    if (attachment.filePath == null || attachment.filePath!.isEmpty) {
      return attachment;
    }

    // 使用compute来在后台isolate中处理文件
    try {
      return await compute(_processAttachmentIsolate, attachment);
    } catch (e) {
      debugPrint('后台处理附件失败: $e');
      return attachment.copyWith(content: 'ERROR_PROCESSING');
    }
  }

  /// 在isolate中处理附件的静态方法
  static Future<ChatAttachment> _processAttachmentIsolate(
    ChatAttachment attachment,
  ) async {
    return await processAttachment(attachment);
  }

  /// 读取文本文件
  static Future<String> _readTextFile(File file) async {
    try {
      // 首先尝试UTF-8编码
      final content = await file.readAsString(encoding: utf8);
      return _truncateText(content);
    } catch (e) {
      // UTF-8失败，尝试其他方法
      try {
        final bytes = await file.readAsBytes();

        // 检测文件是否可能是中文编码
        String? content;

        // 尝试系统默认编码
        try {
          content = await file.readAsString();
          return _truncateText(content);
        } catch (e) {
          // 系统默认编码失败
        }

        // 尝试多种方式读取字节
        try {
          // 尝试UTF-8但忽略错误
          content = utf8.decode(bytes, allowMalformed: true);

          // 检查是否包含大量替换字符（�），如果是则可能编码不正确
          if (content.contains('�') &&
              content.split('�').length > content.length / 10) {
            // 太多替换字符，可能编码不正确
            content = '[文件编码不支持，可能是中文GBK或其他编码]\n原始字节长度: ${bytes.length}';
          }

          return _truncateText(content);
        } catch (e) {
          // 最后尝试latin1（避免完全失败）
          content = latin1.decode(bytes);
          return _truncateText('[编码检测失败，可能显示乱码]\n$content');
        }
      } catch (e2) {
        throw '无法读取文本文件: $e';
      }
    }
  }

  /// 读取代码文件
  static Future<String> _readCodeFile(File file, String extension) async {
    // 保留原始代码内容，不再包裹 ``` 以避免后续整理时格式被二次加工
    // 仍应用截断逻辑：_readTextFile 内部已调用 _truncateText
    final content = await _readTextFile(file);
    return content; // 直接返回原始文本以保持缩进/空行
  }

  /// 尝试作为文本文件读取
  static Future<String?> _tryReadAsText(File file) async {
    try {
      // 读取前1KB检查是否为文本
      final bytes = await file.openRead(0, 1024).first;

      // 检查是否包含大量控制字符（二进制文件的特征）
      int controlChars = 0;
      for (int byte in bytes) {
        if (byte < 32 && byte != 9 && byte != 10 && byte != 13) {
          controlChars++;
        }
      }

      // 如果控制字符超过5%，认为是二进制文件
      if (controlChars > bytes.length * 0.05) {
        return null;
      }

      // 尝试读取为文本
      final content = await file.readAsString(encoding: utf8);
      return _truncateText(content);
    } catch (e) {
      return null;
    }
  }

  /// 截断过长的文本
  static String _truncateText(String text) {
    if (text.length <= _maxTextLength) {
      return text;
    }

    return '${text.substring(0, _maxTextLength)}\n\n[文件内容过长，已截断...]';
  }

  /// 获取文件扩展名
  static String _getFileExtension(String fileName) {
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDotIndex + 1);
  }

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 检查文件是否为支持的类型
  static bool isSupportedFileType(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return _textExtensions.contains(extension) ||
        _codeExtensions.contains(extension) ||
        _imageExtensions.contains(extension) ||
        _officeExtensions.contains(extension);
  }

  /// 获取文件类型描述
  static String getFileTypeDescription(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();

    if (_textExtensions.contains(extension)) {
      return '文本文件';
    } else if (_codeExtensions.contains(extension)) {
      return '代码文件';
    } else if (_imageExtensions.contains(extension)) {
      return '图片文件';
    } else if (_officeExtensions.contains(extension)) {
      return _getOfficeFileTypeDescription(extension);
    } else {
      return '其他文件';
    }
  }

  /// 生成文件上下文信息，用于AI理解
  static String generateFileContext(List<ChatAttachment> attachments) {
    if (attachments.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== 附件文件信息 ===');

    for (int i = 0; i < attachments.length; i++) {
      final attachment = attachments[i];
      buffer.writeln();
      buffer.writeln('文件 ${i + 1}: ${attachment.name}');
      buffer.writeln('类型: ${getFileTypeDescription(attachment.name)}');

      if (attachment.size != null) {
        buffer.writeln('大小: ${_formatFileSize(attachment.size!)}');
      }

      if (attachment.content != null && attachment.content!.isNotEmpty) {
        buffer.writeln('内容:');
        buffer.writeln(attachment.content);
      }

      if (i < attachments.length - 1) {
        buffer.writeln('\n${'=' * 50}');
      }
    }

    buffer.writeln('\n=== 附件信息结束 ===\n');
    return buffer.toString();
  }

  /// 读取办公文件
  static Future<String> _readOfficeFile(
    File file,
    String extension,
    String fileName,
  ) async {
    final buffer = StringBuffer();

    // 添加文件基本信息
    buffer.writeln('[办公文件: $fileName]');
    buffer.writeln('文件类型: ${_getOfficeFileTypeDescription(extension)}');

    final fileStat = await file.stat();
    buffer.writeln('文件大小: ${_formatFileSize(fileStat.size)}');
    buffer.writeln('修改时间: ${fileStat.modified.toString().split('.')[0]}');

    switch (extension.toLowerCase()) {
      case 'docx':
        try {
          final text = await _extractDocxText(file);
          buffer.writeln('\n📝 Word文档内容预览:');
          buffer.writeln(text.isNotEmpty ? text : '[未能提取到正文内容]');
        } catch (e) {
          buffer.writeln('\n📝 Word文档');
          buffer.writeln('解析内容失败: $e');
        }
        break;

      case 'pdf':
        try {
          final pdfText = await _extractPdfText(file);
          buffer.writeln('\n📄 PDF文档');
          if (pdfText.isNotEmpty) {
            buffer.writeln('文档内容:');
            // 使用文本截断方法处理PDF文本
            buffer.writeln(_truncateText(pdfText));
          } else {
            buffer.writeln('📄 PDF文档信息');
            buffer.writeln('文件类型: PDF文档');
            buffer.writeln('状态: 已识别但无法提取文本内容');
            buffer.writeln('\n可能的原因:');
            buffer.writeln('• PDF是扫描版本（图片格式）');
            buffer.writeln('• PDF有密码保护');
            buffer.writeln('• PDF使用了特殊编码');
            buffer.writeln('\n建议:');
            buffer.writeln('• 如果是扫描版PDF，请使用OCR工具转换为文字');
            buffer.writeln('• 如果有密码，请先解除保护');
            buffer.writeln('• 您可以直接描述PDF的内容，我来协助分析');
          }
        } catch (e) {
          buffer.writeln('\n📄 PDF文档');
          buffer.writeln('文件类型: PDF文档');
          buffer.writeln('处理状态: 解析失败');
          buffer.writeln('错误信息: $e');
          buffer.writeln('\n📝 使用建议:');
          buffer.writeln('• 请确保PDF文件没有损坏');
          buffer.writeln('• 如果PDF有密码保护，请先解除保护');
          buffer.writeln('• 您可以手动复制PDF中的文字内容进行提问');
          debugPrint('PDF处理失败: $e');
        }
        break;

      case 'doc':
        buffer.writeln('\n📝 旧版Word文档(.doc)暂不支持内容解析，仅显示基本信息。');
        break;

      case 'xls':
      case 'xlsx':
        buffer.writeln('\n📊 Excel表格');
        buffer.writeln('这是一个Microsoft Excel电子表格。目前显示基本信息，内容解析功能正在开发中。');
        buffer.writeln('您可以描述表格内容或提出数据相关问题，我会尽力帮助您。');
        break;

      case 'ppt':
      case 'pptx':
        buffer.writeln('\n📋 PowerPoint演示文稿');
        buffer.writeln('这是一个Microsoft PowerPoint演示文稿。目前显示基本信息，内容解析功能正在开发中。');
        buffer.writeln('您可以描述演示内容或提出相关问题，我会尽力帮助您。');
        break;

      case 'rtf':
        // RTF文件可以尝试作为文本读取
        try {
          final content = await file.readAsString(encoding: utf8);
          buffer.writeln('\n📄 RTF富文本文档');
          buffer.writeln('文档内容（原始格式）:');
          buffer.writeln('```rtf');
          buffer.writeln(_truncateText(content));
          buffer.writeln('```');
        } catch (e) {
          buffer.writeln('\n📄 RTF富文本文档');
          buffer.writeln('无法读取RTF文件内容: $e');
        }
        break;

      case 'odt':
      case 'ods':
      case 'odp':
        buffer.writeln('\n📄 LibreOffice文档');
        buffer.writeln('这是一个LibreOffice/OpenOffice文档。目前显示基本信息，内容解析功能正在开发中。');
        buffer.writeln('您可以描述文档内容或提出相关问题，我会尽力帮助您。');
        break;

      default:
        buffer.writeln('\n📄 办公文档');
        buffer.writeln('目前显示基本信息，内容解析功能正在开发中。');
    }

    // buffer.writeln('\n💡 提示: 您可以：');
    // buffer.writeln('• 描述文档的主要内容');
    // buffer.writeln('• 提出关于文档的具体问题');
    // buffer.writeln('• 请求文档分析或总结建议');

    return buffer.toString();
  }

  /// 提取 docx 文本内容（分段优化）
  /// Public method to extract DOCX text content
  static Future<String> extractDocxText(File file) async {
    return await _extractDocxText(file);
  }
  
  /// 提取 docx 文本内容（分段优化）
  static Future<String> _extractDocxText(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docFile = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw '未找到 word/document.xml',
    );
    final xmlStr = utf8.decode(docFile.content as List<int>);
    final document = XmlDocument.parse(xmlStr);
    final buffer = StringBuffer();
    for (final para in document.findAllElements('w:p')) {
      final texts = para.findAllElements('w:t').map((e) => e.text).join();
      if (texts.trim().isNotEmpty) {
        buffer.writeln(texts.trim());
      }
    }
    return buffer.toString();
  }

  /// 提取PDF文本内容
  ///
  /// 使用Syncfusion PDF库进行专业的PDF文本提取
  static Future<String> _extractPdfText(File file) async {
    try {
      // 读取PDF文件字节
      final bytes = await file.readAsBytes();

      // 使用Syncfusion PDF库加载PDF文档
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // 创建文本提取器
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);

      // 提取文本内容
      final StringBuffer textBuffer = StringBuffer();

      // 遍历所有页面提取文本
      for (int i = 0; i < document.pages.count; i++) {
        // 提取页面文本
        final String pageText = textExtractor.extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (pageText.trim().isNotEmpty) {
          textBuffer.writeln('=== 第 ${i + 1} 页 ===');
          textBuffer.writeln(pageText.trim());
          textBuffer.writeln();
        }
      }

      // 关闭PDF文档
      document.dispose();

      final extractedText = textBuffer.toString().trim();

      if (extractedText.isNotEmpty) {
        debugPrint('PDF文本提取成功，共提取 ${extractedText.length} 个字符');
        return _truncateText(extractedText);
      } else {
        debugPrint('PDF文本提取成功，但文档中没有文本内容');
        return '[PDF文档加载成功，但未检测到文本内容。这可能是一个纯图像PDF或扫描文档。]';
      }
    } catch (e) {
      debugPrint('PDF文本提取失败: $e');

      // 如果专业库失败，尝试基础方法作为后备
      try {
        final basicText = await _extractPdfTextBasic(file);
        if (basicText.isNotEmpty) {
          return basicText;
        }
      } catch (basicError) {
        debugPrint('基础PDF文本提取也失败: $basicError');
      }

      return '[PDF文件处理失败: ${e.toString()}]';
    }
  }

  /// 基础PDF文本提取方法（后备方案）
  static Future<String> _extractPdfTextBasic(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final content = String.fromCharCodes(bytes);

      final textBuffer = StringBuffer();

      // 查找PDF中的文本流
      final streamPattern = RegExp(r'stream\s*(.*?)\s*endstream', dotAll: true);
      final matches = streamPattern.allMatches(content);

      for (final match in matches) {
        final streamContent = match.group(1) ?? '';
        final readableText = _extractReadableTextFromPdfStream(streamContent);
        if (readableText.isNotEmpty) {
          textBuffer.writeln(readableText);
        }
      }

      final extractedText = textBuffer.toString().trim();
      return extractedText.isNotEmpty ? extractedText : '';
    } catch (e) {
      return '';
    }
  }

  /// 从PDF流中提取可读文本（简单实现）
  static String _extractReadableTextFromPdfStream(String streamContent) {
    try {
      // 移除PDF的特殊字符和控制序列
      String text =
          streamContent
              .replaceAll(RegExp(r'[^\x20-\x7E\s]'), '') // 保留可打印ASCII字符
              .replaceAll(RegExp(r'\s+'), ' ') // 规范化空白字符
              .trim();

      // 过滤掉太短的文本（可能是控制字符）
      if (text.length < 10) {
        return '';
      }

      // 简单的PDF文本清理
      text =
          text
              .replaceAll(RegExp(r'\b[A-Z]{2,}\b'), '') // 移除全大写的控制字符
              .replaceAll(RegExp(r'\d+\s+\d+\s+obj'), '') // 移除对象引用
              .trim();

      return text.length > 20 ? text : '';
    } catch (e) {
      return '';
    }
  }

  /// 获取办公文件类型描述
  static String _getOfficeFileTypeDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF文档';
      case 'doc':
        return 'Word文档(.doc)';
      case 'docx':
        return 'Word文档(.docx)';
      case 'xls':
        return 'Excel表格(.xls)';
      case 'xlsx':
        return 'Excel表格(.xlsx)';
      case 'ppt':
        return 'PowerPoint演示文稿(.ppt)';
      case 'pptx':
        return 'PowerPoint演示文稿(.pptx)';
      case 'odt':
        return 'OpenDocument文字处理文档(.odt)';
      case 'ods':
        return 'OpenDocument电子表格(.ods)';
      case 'odp':
        return 'OpenDocument演示文稿(.odp)';
      case 'rtf':
        return 'RTF富文本文档';
      default:
        return '办公文档';
    }
  }

  /// 处理图片文件
  ///
  /// 提取图片的元数据信息和基本属性
  /// 大图片会上传到 OSS，小图片保持 base64
  static Future<String> _processImageFile(File file, String fileName) async {
    try {
      // 读取图片文件字节
      final bytes = await file.readAsBytes();

      // 解码图片获取基本信息
      final image = img.decodeImage(bytes);

      if (image == null) {
        return '[图片文件: $fileName - 无法解析图片格式]';
      }

      // 获取文件信息
      final fileStat = await file.stat();
      final fileSize = fileStat.size;

      // 计算图片哈希（用于去重和标识）
      final imageHash = md5.convert(bytes).toString().substring(0, 8);

      // 构建图片信息描述
      final buffer = StringBuffer();
      buffer.writeln('=== 图片文件信息 ===');
      buffer.writeln('文件名: $fileName');
      buffer.writeln('尺寸: ${image.width} × ${image.height} 像素');
      buffer.writeln('文件大小: ${_formatFileSize(fileSize)}');
      buffer.writeln('图片哈希: $imageHash');

      // 检测图片格式
      final extension = fileName.toLowerCase().split('.').last;
      buffer.writeln('格式: ${_getImageFormatDescription(extension)}');

      // 检测图片类型和特征
      if (image.hasAlpha) {
        buffer.writeln('透明度: 支持透明通道');
      } else {
        buffer.writeln('透明度: 不支持透明通道');
      }

      // 计算宽高比
      final aspectRatio = image.width / image.height;
      if (aspectRatio > 1.5) {
        buffer.writeln('方向: 横向图片 (${aspectRatio.toStringAsFixed(2)}:1)');
      } else if (aspectRatio < 0.75) {
        buffer.writeln('方向: 纵向图片 (1:${(1 / aspectRatio).toStringAsFixed(2)})');
      } else {
        buffer.writeln('方向: 方形或近似方形图片');
      }

      // 估算图片复杂度
      buffer.writeln(
        '像素总数: ${(image.width * image.height / 1000000).toStringAsFixed(1)}M',
      );

      // 添加使用建议
      buffer.writeln();
      buffer.writeln('=== AI 分析建议 ===');
      if (fileSize > 5 * 1024 * 1024) {
        buffer.writeln('• 这是一个大尺寸图片，可能包含丰富的细节');
      }
      if (image.width > 2000 || image.height > 2000) {
        buffer.writeln('• 高分辨率图片，适合详细分析');
      }
      if (extension == 'svg') {
        buffer.writeln('• SVG矢量图，可能包含可编辑的图形元素');
      }
      buffer.writeln('• 您可以向AI询问这张图片的内容、风格、用途等');
      buffer.writeln('• AI可以帮助描述图片中的对象、颜色、构图等元素');

      return buffer.toString();
    } catch (e) {
      debugPrint('处理图片文件失败: $e');
      return '[图片文件: $fileName - 处理失败: ${e.toString()}]';
    }
  }

  /// 获取图片格式描述
  static String _getImageFormatDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'JPEG (有损压缩，适合照片)';
      case 'png':
        return 'PNG (无损压缩，支持透明)';
      case 'gif':
        return 'GIF (支持动画，256色)';
      case 'bmp':
        return 'BMP (位图，无压缩)';
      case 'webp':
        return 'WebP (现代格式，高压缩比)';
      case 'svg':
        return 'SVG (矢量图，可缩放)';
      case 'ico':
        return 'ICO (图标文件)';
      case 'tiff':
      case 'tif':
        return 'TIFF (高质量，支持多页)';
      default:
        return '未知格式';
    }
  }
}
