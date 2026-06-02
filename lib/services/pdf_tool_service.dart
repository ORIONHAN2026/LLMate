import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF 文件读写内置工具
///
/// - `pdf_read`：读取 PDF，提取文本、页数、元数据
/// - `pdf_write`：创建 PDF（标题+段落）、添加文字水印
class PdfToolService {
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

  // ── 读取 PDF ──────────────────────────────────────────────

  static Map<String, dynamic> _read(String callId, Map<String, dynamic> args) {
    final filePath = _stringArg(args, 'filePath').trim();
    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return _error(callId, args, '文件不存在: $filePath');
    }

    try {
      final bytes = file.readAsBytesSync();
      final doc = PdfDocument(inputBytes: bytes);

      // 提取元数据
      final info = doc.documentInformation;
      final metadata = <String, String>{};
      if (info.title.isNotEmpty) metadata['title'] = info.title;
      if (info.author.isNotEmpty) metadata['author'] = info.author;
      if (info.subject.isNotEmpty) metadata['subject'] = info.subject;
      if (info.keywords.isNotEmpty) metadata['keywords'] = info.keywords;
      if (info.creator.isNotEmpty) metadata['creator'] = info.creator;

      // 提取每页文本
      final extractor = PdfTextExtractor(doc);
      final pages = <Map<String, dynamic>>[];

      for (int i = 0; i < doc.pages.count; i++) {
        final text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        pages.add({
          'pageIndex': i + 1,
          'text': text.trim(),
        });
      }

      final pageCount = doc.pages.count;
      doc.dispose();

      if (kDebugMode) {
        debugPrint('📄 [PdfTool] 读取: $filePath ($pageCount 页)');
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'pageCount': pageCount,
        'metadata': metadata,
        'pages': pages,
        'message': '已读取 $filePath（$pageCount 页）',
      });
    } catch (e) {
      return _error(callId, args, '读取 PDF 失败: $e');
    }
  }

  // ── 写入 PDF ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final filePath = _stringArg(args, 'filePath').trim();
    final action = _stringArg(args, 'action', 'create');

    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }

    try {
      switch (action) {
        case 'create':
          return await _createPdf(callId, args, filePath);
        case 'watermark':
          return await _addWatermark(callId, args, filePath);
        default:
          return _error(callId, args, '不支持的 pdf_write action: $action，可用: create/watermark');
      }
    } catch (e) {
      return _error(callId, args, 'PDF 操作失败: $e');
    }
  }

  // ── 创建 PDF ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _createPdf(
    String callId,
    Map<String, dynamic> args,
    String filePath,
  ) async {
    final title = _stringArg(args, 'title');
    final author = _stringArg(args, 'author');
    final sectionsRaw = args['sections'];

    final doc = PdfDocument();
    if (title.isNotEmpty) doc.documentInformation.title = title;
    if (author.isNotEmpty) doc.documentInformation.author = author;

    // 标题页
    if (title.isNotEmpty) {
      final page = doc.pages.add();
      page.graphics.drawString(
        title,
        PdfStandardFont(PdfFontFamily.helvetica, 28),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: const Rect.fromLTWH(40, 250, 500, 60),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    // 章节
    if (sectionsRaw is List) {
      for (final section in sectionsRaw) {
        if (section is! Map<String, dynamic>) continue;
        final heading = _stringArg(section, 'heading');
        final level = section['level'] ?? 1;
        final paragraphs = section['paragraphs'];

        final page = doc.pages.add();
        double offsetY = 40;

        // 章节标题
        if (heading.isNotEmpty) {
          final fontSize = level == 1 ? 20.0 : (level == 2 ? 16.0 : 14.0);
          page.graphics.drawString(
            heading,
            PdfStandardFont(PdfFontFamily.helvetica, fontSize),
            brush: PdfSolidBrush(PdfColor(0, 51, 102)),
            bounds: Rect.fromLTWH(40, offsetY, 500, 30),
          );
          offsetY += fontSize + 16;
        }

        // 段落
        if (paragraphs is List) {
          for (final para in paragraphs) {
            String text;
            bool isBold = false;
            String align = 'left';

            if (para is Map<String, dynamic>) {
              text = _stringArg(para, 'text');
              isBold = para['bold'] == true;
              align = _stringArg(para, 'align', 'left');
            } else {
              text = para?.toString() ?? '';
            }

            if (text.isEmpty) continue;

            final pdfAlign = align == 'center'
                ? PdfTextAlignment.center
                : align == 'right'
                    ? PdfTextAlignment.right
                    : PdfTextAlignment.left;

            final font = PdfStandardFont(
              PdfFontFamily.helvetica,
              11,
              style: isBold ? PdfFontStyle.bold : PdfFontStyle.regular,
            );

            // 测量文本高度
            final textSize = font.measureString(text, layoutArea: const Size(500, 0), format: PdfStringFormat(alignment: pdfAlign)..lineSpacing = 4);
            final textHeight = textSize.height;

            // 检查是否需要新页面
            if (offsetY + textHeight > 750) {
              // 简单处理：换页
              final newPage = doc.pages.add();
              offsetY = 40;
              newPage.graphics.drawString(
                text,
                font,
                brush: PdfSolidBrush(PdfColor(0, 0, 0)),
                bounds: Rect.fromLTWH(40, offsetY, 500, textHeight),
                format: PdfStringFormat(alignment: pdfAlign)..lineSpacing = 4,
              );
            } else {
              page.graphics.drawString(
                text,
                font,
                brush: PdfSolidBrush(PdfColor(0, 0, 0)),
                bounds: Rect.fromLTWH(40, offsetY, 500, textHeight),
                format: PdfStringFormat(alignment: pdfAlign)..lineSpacing = 4,
              );
            }
            offsetY += textHeight + 8;
          }
        }
      }
    }

    await _savePdf(doc, filePath);

    return _ok(callId, args, {
      'filePath': filePath,
      'fileName': p.basename(filePath),
      'action': 'create',
      'message': '已创建 PDF: $filePath',
    });
  }

  // ── 添加水印 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> _addWatermark(
    String callId,
    Map<String, dynamic> args,
    String outputPath,
  ) async {
    final sourcePath = _stringArg(args, 'sourcePath').trim();
    final watermarkText = _stringArg(args, 'watermarkText').trim();

    if (sourcePath.isEmpty) {
      return _error(callId, args, '添加水印需要 sourcePath 参数');
    }
    if (watermarkText.isEmpty) {
      return _error(callId, args, '添加水印需要 watermarkText 参数');
    }

    final file = File(sourcePath);
    if (!file.existsSync()) {
      return _error(callId, args, '源文件不存在: $sourcePath');
    }

    final bytes = file.readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);

    for (int i = 0; i < doc.pages.count; i++) {
      final page = doc.pages[i];
      final size = page.getClientSize();
      page.graphics.save();
      page.graphics.translateTransform(size.width / 2, size.height / 2);
      page.graphics.rotateTransform(-45);
      page.graphics.drawString(
        watermarkText,
        PdfStandardFont(PdfFontFamily.helvetica, 40),
        brush: PdfSolidBrush(PdfColor(200, 200, 200)),
        bounds: const Rect.fromLTWH(-200, -20, 400, 40),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      page.graphics.restore();
    }

    await _savePdf(doc, outputPath);

    return _ok(callId, args, {
      'filePath': outputPath,
      'fileName': p.basename(outputPath),
      'action': 'watermark',
      'message': '已添加水印: $watermarkText',
    });
  }

  // ── 辅助方法 ──────────────────────────────────────────────

  static Future<void> _savePdf(PdfDocument doc, String filePath) async {
    final file = File(filePath);
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }
    final bytes = doc.saveSync();
    await file.writeAsBytes(bytes);
    doc.dispose();
  }

  static String _stringArg(Map<String, dynamic> args, String key, [String defaultValue = '']) {
    final value = args[key];
    return value == null ? defaultValue : value.toString();
  }

  static Map<String, dynamic> _ok(String callId, Map<String, dynamic> args, Map<String, dynamic> data) {
    return {'id': callId, 'name': 'pdf_read', 'args': args, 'result': jsonEncode(data), 'isError': false};
  }

  static Map<String, dynamic> _error(String callId, Map<String, dynamic> args, String message) {
    return {'id': callId, 'name': 'pdf_read', 'args': args, 'result': message, 'isError': true};
  }
}
