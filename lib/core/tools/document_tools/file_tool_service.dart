import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// 通用文件读写内置工具
///
/// 提供两个操作：
/// - `file_read`：读取文本文件内容（代码、Markdown、配置等）
/// - `file_write`：写入/创建文本文件
class FileToolService {
  // ── 支持读取的文件扩展名白名单 ──────────────────────────────
  static const _readableExtensions = {
    // 代码
    '.dart', '.java', '.kt', '.swift', '.py', '.js', '.ts', '.tsx', '.jsx',
    '.c', '.cpp', '.h', '.hpp', '.cs', '.go', '.rs', '.rb', '.php', '.sh',
    '.lua', '.r', '.sql',
    // Web / 样式
    '.html', '.css', '.scss', '.less', '.xml', '.svg', '.vue', '.svelte',
    // 配置 / 数据
    '.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf', '.env',
    '.properties', '.gradle', '.cmake',
    // 文档 / 文本
    '.md', '.txt', '.log', '.csv', '.tsv',
    // Markdown 变体
    '.mdx', '.rmd',
  };

  static const _writableExtensions = _readableExtensions;

  // ── 入口 ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> execute({
    required String action,
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    switch (action) {
      case 'read':
        return _read(callId, arguments);
      case 'write':
        return await _write(callId, arguments);
      default:
        return _error(callId, arguments, '不支持的操作: $action，可用: read/write');
    }
  }

  // ── 读取文件 ──────────────────────────────────────────────

  static Map<String, dynamic> _read(
    String callId,
    Map<String, dynamic> args,
  ) {
    final filePath = _stringArg(args, 'filePath').trim();
    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return _error(callId, args, '文件不存在: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase();
    if (!_isReadableExt(ext)) {
      return _error(
        callId,
        args,
        '不支持的文件类型: $ext，支持: ${_readableExtensions.join(', ')}',
      );
    }

    try {
      final stat = file.statSync();
      final content = file.readAsStringSync();
      final lineCount = content.split('\n').length;

      if (kDebugMode) {
        debugPrint('📄 [FileTool] 读取文件: $filePath ($lineCount 行)');
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'extension': ext,
        'size': stat.size,
        'lineCount': lineCount,
        'content': content,
        'message': '已读取 $filePath（$lineCount 行，${_formatSize(stat.size)}）',
      });
    } catch (e) {
      return _error(callId, args, '读取文件失败: $e');
    }
  }

  // ── 写入文件 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final filePath = _stringArg(args, 'filePath').trim();
    final content = _stringArg(args, 'content');

    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    final ext = p.extension(filePath).toLowerCase();
    if (ext.isNotEmpty && !_isWritableExt(ext)) {
      return _error(
        callId,
        args,
        '不支持的文件类型: $ext，支持: ${_writableExtensions.join(', ')}',
      );
    }

    try {
      final file = File(filePath);

      // 确保父目录存在
      final parent = file.parent;
      if (!parent.existsSync()) {
        await parent.create(recursive: true);
      }

      final isOverwrite = file.existsSync();
      await file.writeAsString(content);

      final lineCount = content.split('\n').length;

      if (kDebugMode) {
        debugPrint(
          '📝 [FileTool] ${isOverwrite ? "覆盖" : "创建"}文件: $filePath ($lineCount 行)',
        );
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'extension': ext,
        'lineCount': lineCount,
        'overwritten': isOverwrite,
        'message':
            '${isOverwrite ? "已覆盖" : "已创建"} $filePath（$lineCount 行）',
      });
    } catch (e) {
      return _error(callId, args, '写入文件失败: $e');
    }
  }

  // ── 辅助方法 ──────────────────────────────────────────────

  /// 判断扩展名是否为可读取的文件类型（公开方法，供附件处理调用）
  static bool isReadableExtension(String ext) => _isReadableExt(ext);

  static bool _isReadableExt(String ext) {
    if (ext.isEmpty) return true; // 无扩展名视为文本文件
    return _readableExtensions.contains(ext.toLowerCase());
  }

  static bool _isWritableExt(String ext) {
    if (ext.isEmpty) return true;
    return _writableExtensions.contains(ext.toLowerCase());
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _stringArg(Map<String, dynamic> args, String key) {
    final value = args[key];
    return value == null ? '' : value.toString();
  }

  static Map<String, dynamic> _ok(
    String callId,
    Map<String, dynamic> args,
    Map<String, dynamic> data,
  ) {
    return {
      'id': callId,
      'name': 'file_read',
      'args': args,
      'result': jsonEncode(data),
      'isError': false,
    };
  }

  static Map<String, dynamic> _error(
    String callId,
    Map<String, dynamic> args,
    String message,
  ) {
    return {
      'id': callId,
      'name': 'file_read',
      'args': args,
      'result': message,
      'isError': true,
    };
  }
}
