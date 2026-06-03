import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as p;

/// 图片文件读写内置工具
///
/// - `image_read`：读取图片信息（尺寸、格式、文件大小）
/// - `image_write`：图片处理（缩放、裁剪、旋转、格式转换、压缩、添加水印）
class ImageToolService {
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

  // ── 读取图片信息 ──────────────────────────────────────────

  static Map<String, dynamic> _read(String callId, Map<String, dynamic> args) {
    final filePath = _stringArg(args, 'filePath').trim();
    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return _error(callId, args, '文件不存在: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase();
    const imageExts = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.tiff', '.ico'];
    if (!imageExts.contains(ext)) {
      return _error(callId, args, '不支持的图片格式: $ext');
    }

    try {
      final bytes = file.readAsBytesSync();
      final image = decodeImage(bytes);

      final stat = file.statSync();

      final result = <String, dynamic>{
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'format': ext.replaceAll('.', '').toUpperCase(),
        'fileSize': stat.size,
        'fileSizeFormatted': _formatSize(stat.size),
      };

      if (image != null) {
        result['width'] = image.width;
        result['height'] = image.height;
        result['channels'] = image.numChannels;
        result['hasAlpha'] = image.hasAlpha;
        result['pixelCount'] = image.width * image.height;
      }

      if (kDebugMode) {
        debugPrint('🖼️ [ImageTool] 读取: $filePath (${image?.width ?? "?"}x${image?.height ?? "?"})');
      }

      return _ok(callId, args, {
        ...result,
        'message': image != null
            ? '已读取 $filePath（${image.width}x${image.height}，${_formatSize(stat.size)}）'
            : '已读取 $filePath（${_formatSize(stat.size)}），但无法解析图片内容',
      });
    } catch (e) {
      return _error(callId, args, '读取图片失败: $e');
    }
  }

  // ── 写入/处理图片 ─────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final sourcePath = _stringArg(args, 'sourcePath').trim();
    final filePath = _stringArg(args, 'filePath').trim();
    final action = _stringArg(args, 'action', 'resize');

    if (sourcePath.isEmpty) {
      return _error(callId, args, 'sourcePath（源图片路径）参数不能为空');
    }
    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath（输出路径）参数不能为空');
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return _error(callId, args, '源文件不存在: $sourcePath');
    }

    try {
      final sourceBytes = sourceFile.readAsBytesSync();
      final image = decodeImage(sourceBytes);
      if (image == null) {
        return _error(callId, args, '无法解析源图片: $sourcePath');
      }

      final result = switch (action) {
        'resize' => _resize(image, args),
        'crop' => _crop(image, args),
        'rotate' => _rotate(image, args),
        'convert' => image,
        'compress' => image,
        'watermark' => _watermark(image, args),
        _ => null,
      };
      if (result == null) {
        return _error(callId, args, '不支持的 image_write action: $action，可用: resize/crop/rotate/convert/compress/watermark');
      }

      // 编码输出
      final outputBytes = _encodeImage(result, filePath, args);
      final file = File(filePath);
      final parent = file.parent;
      if (!parent.existsSync()) {
        await parent.create(recursive: true);
      }
      await file.writeAsBytes(outputBytes);

      if (kDebugMode) {
        debugPrint('🖼️ [ImageTool] $action: $sourcePath → $filePath');
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'action': action,
        'width': result.width,
        'height': result.height,
        'outputSize': outputBytes.length,
        'message': '已${_actionLabel(action)}: $filePath（${result.width}x${result.height}，${_formatSize(outputBytes.length)}）',
      });
    } catch (e) {
      return _error(callId, args, '图片处理失败: $e');
    }
  }

  // ── 具体操作 ──────────────────────────────────────────────

  static Image _resize(Image image, Map<String, dynamic> args) {
    final width = args['width'];
    final height = args['height'];
    final maintainAspectRatio = args['maintainAspectRatio'] != false;

    int? w = width is int ? width : (width is double ? width.toInt() : null);
    int? h = height is int ? height : (height is double ? height.toInt() : null);

    if (w == null && h == null) {
      throw ArgumentError('resize 需要指定 width 或 height');
    }

    if (maintainAspectRatio) {
      if (w != null && h != null) {
        // 按比例缩放，不超过目标尺寸
        final ratioW = w / image.width;
        final ratioH = h / image.height;
        final ratio = ratioW < ratioH ? ratioW : ratioH;
        w = (image.width * ratio).round();
        h = (image.height * ratio).round();
      } else if (w != null) {
        h = (image.height * w / image.width).round();
      } else {
        w = (image.width * h! / image.height).round();
      }
    }

    return copyResize(image, width: w!, height: h!);
  }

  static Image _crop(Image image, Map<String, dynamic> args) {
    final x = (args['x'] ?? 0) as int;
    final y = (args['y'] ?? 0) as int;
    final cropWidth = args['cropWidth'] as int?;
    final cropHeight = args['cropHeight'] as int?;

    if (cropWidth == null || cropHeight == null) {
      throw ArgumentError('crop 需要指定 cropWidth 和 cropHeight');
    }

    return copyCrop(image, x: x, y: y, width: cropWidth, height: cropHeight);
  }

  static Image _rotate(Image image, Map<String, dynamic> args) {
    final angle = (args['angle'] ?? 90) as int;
    // angle 为顺时针度数，只支持 90 的倍数
    final rotations = ((angle % 360) / 90).round() % 4;
    var result = image;
    for (int i = 0; i < rotations; i++) {
      result = copyRotate(result, angle: 90);
    }
    return result;
  }

  static Image _watermark(Image image, Map<String, dynamic> args) {
    final text = _stringArg(args, 'watermarkText');
    final fontSize = (args['fontSize'] ?? 24) as int;

    if (text.isEmpty) {
      throw ArgumentError('watermark 需要指定 watermarkText');
    }

    // 在图片中央绘制半透明水印文字
    final font = arial24;
    final x = (image.width - text.length * fontSize) ~/ 2;
    final y = (image.height - fontSize) ~/ 2;

    drawString(
      image,
      text,
      x: x < 0 ? 0 : x,
      y: y < 0 ? 0 : y,
      font: font,
      color: ColorRgba8(200, 200, 200, 128),
    );

    return image;
  }

  // ── 编码 ──────────────────────────────────────────────────

  static List<int> _encodeImage(Image image, String filePath, Map<String, dynamic> args) {
    final ext = p.extension(filePath).toLowerCase();
    final quality = (args['quality'] ?? 85) as int;

    switch (ext) {
      case '.png':
        return encodePng(image, level: (100 - quality) ~/ 10);
      case '.jpg':
      case '.jpeg':
        return encodeJpg(image, quality: quality);
      case '.gif':
        return encodeGif(image);
      case '.bmp':
        return encodeBmp(image);
      case '.ico':
        return encodeIco(image);
      case '.tiff':
      case '.tif':
        return encodeTiff(image);
      case '.webp':
        // webp 编码可能不被 image 包支持，降级为 png
        return encodePng(image);
      default:
        return encodePng(image);
    }
  }

  // ── 辅助 ──────────────────────────────────────────────────

  static String _actionLabel(String action) {
    const labels = {
      'resize': '缩放',
      'crop': '裁剪',
      'rotate': '旋转',
      'convert': '转换格式',
      'compress': '压缩',
      'watermark': '添加水印',
    };
    return labels[action] ?? action;
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _stringArg(Map<String, dynamic> args, String key, [String defaultValue = '']) {
    final value = args[key];
    return value == null ? defaultValue : value.toString();
  }

  static Map<String, dynamic> _ok(String callId, Map<String, dynamic> args, Map<String, dynamic> data) {
    return {'id': callId, 'name': 'image_read', 'args': args, 'result': jsonEncode(data), 'isError': false};
  }

  static Map<String, dynamic> _error(String callId, Map<String, dynamic> args, String message) {
    return {'id': callId, 'name': 'image_read', 'args': args, 'result': message, 'isError': true};
  }
}
