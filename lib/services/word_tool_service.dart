import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';

// ── 段落描述符 ──────────────────────────────────────────────

class _ParagraphDesc {
  final String text;
  final String align; // left | center | right
  final bool bold;
  final String listType; // none | bullet | number

  const _ParagraphDesc({
    required this.text,
    this.align = 'left',
    this.bold = false,
    this.listType = 'none',
  });
}

// ── 章节描述符 ──────────────────────────────────────────────

class _SectionDesc {
  final String heading;
  final int level; // 1‑3
  final List<_ParagraphDesc> paragraphs;

  const _SectionDesc({
    required this.heading,
    this.level = 1,
    this.paragraphs = const [],
  });
}

// ── 表格描述符 ──────────────────────────────────────────────

class _TableDesc {
  final List<String> headers;
  final List<List<String>> rows;

  const _TableDesc({this.headers = const [], this.rows = const []});
}

// ── WordToolService ─────────────────────────────────────────

class WordToolService {
  static Future<Map<String, dynamic>> createDocument({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final normalizedArguments = _normalizeArguments(arguments);
      final paragraphs = _paragraphListArg(normalizedArguments, 'paragraphs');
      final sections = _sectionListArg(normalizedArguments, 'sections');
      final tables = _tableListArg(normalizedArguments, 'tables');
      final title = _resolveTitle(normalizedArguments, paragraphs, sections);

      if (paragraphs.isEmpty && sections.isEmpty && tables.isEmpty) {
        paragraphs.add(_ParagraphDesc(text: title));
      }

      final outputDir = await _resolveOutputDirectory(
        _stringArg(normalizedArguments, 'outputDirectory'),
      );
      await outputDir.create(recursive: true);

      final fileName = _normalizeDocxFileName(
        _stringArg(normalizedArguments, 'fileName').trim().isNotEmpty
            ? _stringArg(normalizedArguments, 'fileName')
            : title,
      );
      final file = File(await _availablePath(outputDir.path, fileName));

      final archive = Archive();
      _addTextFile(archive, '[Content_Types].xml', _contentTypesXml);
      _addTextFile(archive, '_rels/.rels', _rootRelsXml);
      _addTextFile(archive, 'docProps/app.xml', _appXml);
      _addTextFile(archive, 'docProps/core.xml', _coreXml(title));
      _addTextFile(archive, 'word/_rels/document.xml.rels', _documentRelsXml);
      _addTextFile(archive, 'word/styles.xml', _stylesXml);
      _addTextFile(archive, 'word/numbering.xml', _numberingXml);
      _addTextFile(
        archive,
        'word/document.xml',
        _documentXml(
          title: title,
          paragraphs: paragraphs,
          sections: sections,
          tables: tables,
        ),
      );

      final encoded = ZipEncoder().encode(archive);
      if (encoded == null) {
        return _error(callId, arguments, 'Word 文档打包失败');
      }
      await file.writeAsBytes(encoded, flush: true);

      return {
        'id': callId,
        'name': 'word_create_document',
        'args': normalizedArguments,
        'result': jsonEncode({
          'ok': true,
          'path': file.path,
          'fileName': p.basename(file.path),
          'message': 'Word 文档已创建',
        }),
        'isError': false,
      };
    } catch (e) {
      return _error(callId, arguments, '创建 Word 文档失败: $e');
    }
  }

  // ── 读取文档 ──────────────────────────────────────────────

  static Future<Map<String, dynamic>> readDocument({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    try {
      final normalizedArguments = _normalizeArguments(arguments);
      final filePath = _stringArg(normalizedArguments, 'filePath').trim();
      if (filePath.isEmpty) {
        return _readError(callId, normalizedArguments, 'filePath 参数不能为空');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return _readError(callId, normalizedArguments, '文件不存在: $filePath');
      }
      if (!filePath.toLowerCase().endsWith('.docx')) {
        return _readError(callId, normalizedArguments, '仅支持 .docx 文件');
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. 解析 numbering 映射（numId → bullet/number）
      final numberingMap = _parseNumbering(archive);

      // 2. 解析 styles 映射（styleId → styleName）
      final styleMap = _parseStyles(archive);

      // 3. 解析 core properties
      final coreProps = _parseCoreProperties(archive);

      // 4. 解析 document.xml → 结构化 JSON
      final docFile = archive.findFile('word/document.xml');
      if (docFile == null) {
        return _readError(callId, normalizedArguments, '无法找到 word/document.xml，可能不是有效的 .docx 文件');
      }
      final docContent = utf8.decode(docFile.content as List<int>);
      final docXml = XmlDocument.parse(docContent);

      final structure = _parseDocumentXml(docXml, numberingMap, styleMap);

      final result = {
        'ok': true,
        'filePath': filePath,
        'fileName': p.basename(filePath),
        if (coreProps['title'] != null) 'title': coreProps['title'],
        if (coreProps['creator'] != null) 'creator': coreProps['creator'],
        if (coreProps['created'] != null) 'created': coreProps['created'],
        ...structure,
      };

      return {
        'id': callId,
        'name': 'word_read_document',
        'args': normalizedArguments,
        'result': jsonEncode(result),
        'isError': false,
      };
    } catch (e) {
      return _readError(callId, arguments, '读取 Word 文档失败: $e');
    }
  }

  // ── 文档结构解析 ──────────────────────────────────────────

  /// 解析 numbering.xml，返回 numId → listType 映射。
  static Map<String, String> _parseNumbering(Archive archive) {
    final map = <String, String>{};
    final numFile = archive.findFile('word/numbering.xml');
    if (numFile == null) return map;

    try {
      final content = utf8.decode(numFile.content as List<int>);
      final doc = XmlDocument.parse(content);

      // abstractNumId → numFmt
      final abstractFmt = <String, String>{};
      for (final absNum in doc.findAllElements('w:abstractNum')) {
        final id = absNum.getAttribute('w:abstractNumId') ?? '';
        final lvl = absNum.findElements('w:lvl').firstOrNull;
        if (lvl != null) {
          final fmt = lvl.findElements('w:numFmt').firstOrNull;
          abstractFmt[id] = fmt?.getAttribute('w:val') ?? 'decimal';
        }
      }

      // numId → abstractNumId → numFmt
      for (final num in doc.findAllElements('w:num')) {
        final numId = num.getAttribute('w:numId') ?? '';
        final absRef = num.findElements('w:abstractNumId').firstOrNull;
        final absId = absRef?.getAttribute('w:val') ?? '';
        final fmt = abstractFmt[absId] ?? 'decimal';
        map[numId] = fmt == 'bullet' ? 'bullet' : 'number';
      }
    } catch (_) {}

    return map;
  }

  /// 解析 styles.xml，返回 styleId → styleName。
  static Map<String, String> _parseStyles(Archive archive) {
    final map = <String, String>{};
    final stylesFile = archive.findFile('word/styles.xml');
    if (stylesFile == null) return map;

    try {
      final content = utf8.decode(stylesFile.content as List<int>);
      final doc = XmlDocument.parse(content);

      for (final style in doc.findAllElements('w:style')) {
        final styleId = style.getAttribute('w:styleId') ?? '';
        final nameEl = style.findElements('w:name').firstOrNull;
        final name = nameEl?.getAttribute('w:val') ?? '';
        if (styleId.isNotEmpty) map[styleId] = name;
      }
    } catch (_) {}

    return map;
  }

  /// 解析 core properties。
  static Map<String, String> _parseCoreProperties(Archive archive) {
    final props = <String, String>{};
    final coreFile = archive.findFile('docProps/core.xml');
    if (coreFile == null) return props;

    try {
      final content = utf8.decode(coreFile.content as List<int>);
      final doc = XmlDocument.parse(content);

      for (final tag in const ['dc:title', 'dc:creator', 'dcterms:created']) {
        final el = doc.findAllElements(tag).firstOrNull;
        if (el != null && el.innerText.trim().isNotEmpty) {
          props[tag.split(':').last] = el.innerText.trim();
        }
      }
    } catch (_) {}

    return props;
  }

  /// 解析 document.xml，提取段落、表格、章节结构。
  static Map<String, dynamic> _parseDocumentXml(
    XmlDocument doc,
    Map<String, String> numberingMap,
    Map<String, String> styleMap,
  ) {
    final body = doc.findAllElements('w:body').firstOrNull;
    if (body == null) return {'paragraphs': [], 'tables': [], 'sections': []};

    final paragraphs = <Map<String, dynamic>>[];
    final tables = <Map<String, dynamic>>[];
    final sections = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentSection;

    for (final child in body.childElements) {
      final localName = child.qualifiedName;

      if (localName == 'w:p') {
        final pResult = _parseParagraphElement(child, numberingMap, styleMap);
        if (pResult == null) continue;

        // 判断是否为标题段落
        final style = pResult['style'] as String? ?? '';
        final isHeading = style.startsWith('Heading') || style.startsWith('heading');
        final isTitle = style == 'Title';

        if (isTitle) {
          // Title 段落 → 顶层标题
          paragraphs.add(pResult);
        } else if (isHeading) {
          // 标题段落 → 新 section
          if (currentSection != null) sections.add(currentSection);
          int? level;
          final match = RegExp(r'(\d+)').firstMatch(style);
          if (match != null) level = int.tryParse(match.group(1) ?? '');
          currentSection = {
            'heading': pResult['text'] ?? '',
            if (level != null) 'level': level,
            'paragraphs': <Map<String, dynamic>>[],
          };
        } else {
          // 普通段落
          if (currentSection != null) {
            (currentSection['paragraphs'] as List).add(pResult);
          } else {
            paragraphs.add(pResult);
          }
        }
      } else if (localName == 'w:tbl') {
        final table = _parseTableElement(child);
        if (table != null) {
          if (currentSection != null) {
            // 表格归属到当前 section
            (currentSection['paragraphs'] as List).add(table);
          } else {
            tables.add(table);
          }
        }
      }
    }

    // 最后一个 section
    if (currentSection != null) sections.add(currentSection);

    // 清理空值
    return {
      if (paragraphs.isNotEmpty) 'paragraphs': paragraphs,
      if (tables.isNotEmpty) 'tables': tables,
      if (sections.isNotEmpty) 'sections': sections,
    };
  }

  /// 解析单个 <w:p> 元素。
  static Map<String, dynamic>? _parseParagraphElement(
    XmlElement p,
    Map<String, String> numberingMap,
    Map<String, String> styleMap,
  ) {
    final pPr = p.findElements('w:pPr').firstOrNull;

    // 提取样式
    String? styleId;
    if (pPr != null) {
      final pStyle = pPr.findElements('w:pStyle').firstOrNull;
      styleId = pStyle?.getAttribute('w:val');
    }
    final styleName = styleId != null ? (styleMap[styleId] ?? styleId) : null;

    // 提取对齐
    String align = 'left';
    if (pPr != null) {
      final jc = pPr.findElements('w:jc').firstOrNull;
      final jcVal = jc?.getAttribute('w:val') ?? '';
      if (jcVal == 'center') align = 'center';
      if (jcVal == 'right') align = 'right';
    }

    // 提取列表类型
    String listType = 'none';
    if (pPr != null) {
      final numPr = pPr.findElements('w:numPr').firstOrNull;
      if (numPr != null) {
        final numId = numPr.findElements('w:numId').firstOrNull?.getAttribute('w:val') ?? '';
        if (numId.isNotEmpty && numberingMap.containsKey(numId)) {
          listType = numberingMap[numId]!;
        } else if (numId.isNotEmpty) {
          listType = 'number'; // 有 numPr 但无法确定类型时默认有序
        }
      }
    }

    // 提取文本和加粗
    final runs = p.findElements('w:r');
    final textBuf = StringBuffer();
    bool bold = false;
    for (final run in runs) {
      final t = run.findElements('w:t').firstOrNull;
      if (t != null) textBuf.write(t.innerText);
      final rPr = run.findElements('w:rPr').firstOrNull;
      if (rPr != null && rPr.findElements('w:b').isNotEmpty) {
        bold = true;
      }
    }

    final text = textBuf.toString().trim();
    if (text.isEmpty && styleName == null) return null;

    return {
      if (text.isNotEmpty) 'text': text,
      if (styleName != null) 'style': styleName,
      if (align != 'left') 'align': align,
      if (bold) 'bold': true,
      if (listType != 'none') 'listType': listType,
    };
  }

  /// 解析 <w:tbl> 元素。
  static Map<String, dynamic>? _parseTableElement(XmlElement tbl) {
    final rows = tbl.findElements('w:tr');
    if (rows.isEmpty) return null;

    final allRows = <List<String>>[];
    for (final row in rows) {
      final cells = row.findElements('w:tc');
      final rowCells = <String>[];
      for (final cell in cells) {
        final cellText = StringBuffer();
        for (final p in cell.findElements('w:p')) {
          for (final run in p.findElements('w:r')) {
            final t = run.findElements('w:t').firstOrNull;
            if (t != null) cellText.write(t.innerText);
          }
        }
        rowCells.add(cellText.toString().trim());
      }
      allRows.add(rowCells);
    }

    if (allRows.isEmpty) return null;

    // 第一行视为表头（如果有多行）
    final headers = allRows.first;
    final dataRows = allRows.length > 1 ? allRows.sublist(1) : <List<String>>[];

    return {
      'type': 'table',
      'headers': headers,
      if (dataRows.isNotEmpty) 'rows': dataRows,
    };
  }

  static Map<String, dynamic> _readError(
    String callId,
    Map<String, dynamic> arguments,
    String message,
  ) {
    return {
      'id': callId,
      'name': 'word_read_document',
      'args': arguments,
      'result': message,
      'isError': true,
    };
  }

  static Map<String, dynamic> _normalizeArguments(
    Map<String, dynamic> arguments,
  ) {
    final normalized = Map<String, dynamic>.from(arguments);

    for (final key in const ['arguments', '_raw']) {
      final value = normalized[key];
      if (value is! String || value.trim().isEmpty) continue;

      final raw = _stripCodeFence(value.trim());
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          normalized.addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // 保留原始参数，后续字段级兜底继续处理。
      }
    }

    return normalized;
  }

  static String _stripCodeFence(String value) {
    return value
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  // ── 标题回退 ──────────────────────────────────────────────

  static String _resolveTitle(
    Map<String, dynamic> arguments,
    List<_ParagraphDesc> paragraphs,
    List<_SectionDesc> sections,
  ) {
    final explicitTitle = _stringArg(arguments, 'title').trim();
    if (explicitTitle.isNotEmpty) return explicitTitle;

    final fileName = p.basenameWithoutExtension(
      _stringArg(arguments, 'fileName').trim(),
    );
    if (fileName.isNotEmpty) return fileName;

    if (paragraphs.isNotEmpty && paragraphs.first.text.trim().isNotEmpty) {
      final first = paragraphs.first.text.trim();
      return first.length > 30 ? first.substring(0, 30) : first;
    }

    for (final section in sections) {
      if (section.heading.trim().isNotEmpty) return section.heading.trim();
    }

    return '未命名文档';
  }

  // ── 路径工具 ──────────────────────────────────────────────

  static Future<Directory> _resolveOutputDirectory(
    String outputDirectory,
  ) async {
    if (outputDirectory.trim().isNotEmpty) {
      return Directory(outputDirectory.trim());
    }
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'GeneratedDocuments'));
  }

  static String _normalizeDocxFileName(String value) {
    final cleaned =
        value
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
    final name = cleaned.isEmpty ? 'document' : cleaned;
    return name.toLowerCase().endsWith('.docx') ? name : '$name.docx';
  }

  static Future<String> _availablePath(String dir, String fileName) async {
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    var candidate = p.join(dir, fileName);
    var index = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir, '$base ($index)$ext');
      index++;
    }
    return candidate;
  }

  // ── 参数解析 ──────────────────────────────────────────────

  /// 段落列表：兼容字符串和对象两种格式。
  static List<_ParagraphDesc> _paragraphListArg(
    Map<String, dynamic> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value is! List) {
      if (value is String && value.trim().isNotEmpty) {
        return [_ParagraphDesc(text: value)];
      }
      return <_ParagraphDesc>[];
    }
    return value.map((item) {
      if (item is String) return _ParagraphDesc(text: item);
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        return _ParagraphDesc(
          text: (m['text'] ?? '').toString(),
          align: _enumArg(m, 'align', ['left', 'center', 'right'], 'left'),
          bold: m['bold'] == true,
          listType: _enumArg(
            m,
            'listType',
            ['none', 'bullet', 'number'],
            'none',
          ),
        );
      }
      return _ParagraphDesc(text: item?.toString() ?? '');
    }).toList();
  }

  /// 章节列表：支持 level 字段，内部段落同样兼容字符串与对象。
  static List<_SectionDesc> _sectionListArg(
    Map<String, dynamic> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value is! List) return <_SectionDesc>[];
    return value.whereType<Map>().map((item) {
      final m = Map<String, dynamic>.from(item);
      return _SectionDesc(
        heading: (m['heading'] ?? '').toString(),
        level: m['level'] is int ? (m['level'] as int).clamp(1, 3) : 1,
        paragraphs: _paragraphListArg(m, 'paragraphs'),
      );
    }).toList();
  }

  /// 表格列表。
  static List<_TableDesc> _tableListArg(
    Map<String, dynamic> arguments,
    String key,
  ) {
    final value = arguments[key];
    if (value is! List) return <_TableDesc>[];
    return value.whereType<Map>().map((item) {
      final m = Map<String, dynamic>.from(item);
      final headers =
          (m['headers'] as List?)
              ?.map((h) => h?.toString() ?? '')
              .toList() ??
          <String>[];
      final rows =
          (m['rows'] as List?)
              ?.map((row) {
                if (row is List) {
                  return row.map((cell) => cell?.toString() ?? '').toList();
                }
                return <String>[];
              })
              .toList() ??
          <List<String>>[];
      return _TableDesc(headers: headers, rows: rows);
    }).toList();
  }

  static String _enumArg(
    Map<String, dynamic> map,
    String key,
    List<String> allowed,
    String defaultValue,
  ) {
    final value = (map[key] ?? '').toString().toLowerCase();
    return allowed.contains(value) ? value : defaultValue;
  }

  static String _stringArg(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    return value == null ? '' : value.toString();
  }

  // ── OOXML 生成 ────────────────────────────────────────────

  static String _documentXml({
    required String title,
    required List<_ParagraphDesc> paragraphs,
    required List<_SectionDesc> sections,
    required List<_TableDesc> tables,
  }) {
    final body = StringBuffer();

    // 文档标题
    body.writeln(_paragraph(title, style: 'Title'));

    // 顶层段落
    for (final p in paragraphs) {
      if (p.text.trim().isNotEmpty) {
        body.writeln(_paragraph(p.text, align: p.align, bold: p.bold, listType: p.listType));
      }
    }

    // 表格
    for (final table in tables) {
      final xml = _tableXml(table);
      if (xml.isNotEmpty) body.writeln(xml);
    }

    // 章节
    for (final section in sections) {
      final heading = section.heading.trim();
      if (heading.isNotEmpty) {
        body.writeln(_paragraph(heading, style: 'Heading${section.level.clamp(1, 3)}'));
      }
      for (final p in section.paragraphs) {
        if (p.text.trim().isNotEmpty) {
          body.writeln(_paragraph(p.text, align: p.align, bold: p.bold, listType: p.listType));
        }
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
$body    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  /// 生成段落 XML，支持对齐、加粗、列表。
  static String _paragraph(
    String text, {
    String? style,
    String align = 'left',
    bool bold = false,
    String listType = 'none',
  }) {
    final pPrBuf = StringBuffer();
    if (style != null) pPrBuf.write('<w:pStyle w:val="$style"/>');
    if (align == 'center') {
      pPrBuf.write('<w:jc w:val="center"/>');
    } else if (align == 'right') {
      pPrBuf.write('<w:jc w:val="right"/>');
    }
    if (listType == 'bullet') {
      pPrBuf.write('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>');
    } else if (listType == 'number') {
      pPrBuf.write('<w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr>');
    }

    final rPr = bold ? '<w:rPr><w:b/></w:rPr>' : '';
    final pPr = pPrBuf.isEmpty ? '' : '<w:pPr>$pPrBuf</w:pPr>';

    return '    <w:p>$pPr<w:r>$rPr<w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r></w:p>';
  }

  /// 生成表格 XML。
  static String _tableXml(_TableDesc table) {
    final colCount = table.headers.isNotEmpty
        ? table.headers.length
        : table.rows.isNotEmpty
            ? table.rows.first.length
            : 0;
    if (colCount == 0) return '';

    final buf = StringBuffer();
    buf.writeln('    <w:tbl>');
    buf.writeln('      <w:tblPr>');
    buf.writeln('        <w:tblStyle w:val="TableGrid"/>');
    buf.writeln('        <w:tblW w:w="0" w:type="auto"/>');
    buf.writeln('        <w:tblBorders>');
    buf.writeln('          <w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>');
    buf.writeln('        </w:tblBorders>');
    buf.writeln('      </w:tblPr>');
    buf.writeln('      <w:tblGrid>');
    for (var i = 0; i < colCount; i++) {
      buf.writeln('        <w:gridCol w:w="0"/>');
    }
    buf.writeln('      </w:tblGrid>');

    // 表头行
    if (table.headers.isNotEmpty) {
      buf.writeln('      <w:tr>');
      for (final header in table.headers) {
        buf.writeln('        <w:tc>');
        buf.writeln('          <w:tcPr><w:shd w:val="clear" w:color="auto" w:fill="D9E2F3"/></w:tcPr>');
        buf.writeln('          <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">${_escapeXml(header)}</w:t></w:r></w:p>');
        buf.writeln('        </w:tc>');
      }
      buf.writeln('      </w:tr>');
    }

    // 数据行
    for (final row in table.rows) {
      buf.writeln('      <w:tr>');
      for (var i = 0; i < colCount; i++) {
        final cellText = i < row.length ? row[i] : '';
        buf.writeln('        <w:tc>');
        buf.writeln('          <w:p><w:r><w:t xml:space="preserve">${_escapeXml(cellText)}</w:t></w:r></w:p>');
        buf.writeln('        </w:tc>');
      }
      buf.writeln('      </w:tr>');
    }

    buf.writeln('    </w:tbl>');
    return buf.toString();
  }

  // ── 通用工具 ──────────────────────────────────────────────

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static void _addTextFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static Map<String, dynamic> _error(
    String callId,
    Map<String, dynamic> arguments,
    String message,
  ) {
    return {
      'id': callId,
      'name': 'word_create_document',
      'args': arguments,
      'result': message,
      'isError': true,
    };
  }

  // ── OOXML 模板片段 ────────────────────────────────────────

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  static const String _rootRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  static const String _documentRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>''';

  static String _coreXml(String title) {
    final now = DateTime.now().toUtc().toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_escapeXml(title)}</dc:title>
  <dc:creator>ChatHub</dc:creator>
  <cp:lastModifiedBy>ChatHub</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>
</cp:coreProperties>''';
  }

  static const String _appXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>ChatHub</Application>
</Properties>''';

  static const String _stylesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:sz w:val="24"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:pPr><w:jc w:val="center"/><w:spacing w:after="300"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="28"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:pPr><w:spacing w:before="200" w:after="100"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="26"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:pPr><w:spacing w:before="160" w:after="80"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="24"/></w:rPr>
  </w:style>
  <w:style w:type="table" w:styleId="TableGrid">
    <w:name w:val="Table Grid"/>
    <w:tblPr>
      <w:tblBorders>
        <w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        <w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        <w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        <w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        <w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>
      </w:tblBorders>
    </w:tblPr>
  </w:style>
</w:styles>''';

  static const String _numberingXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="bullet"/>
      <w:lvlText w:val="&#x2022;"/>
      <w:lvlJc w:val="left"/>
      <w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>
    </w:lvl>
  </w:abstractNum>
  <w:abstractNum w:abstractNumId="1">
    <w:multiLevelType w:val="hybridMultilevel"/>
    <w:lvl w:ilvl="0">
      <w:start w:val="1"/>
      <w:numFmt w:val="decimal"/>
      <w:lvlText w:val="%1."/>
      <w:lvlJc w:val="left"/>
      <w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>
    </w:lvl>
  </w:abstractNum>
  <w:num w:numId="1">
    <w:abstractNumId w:val="0"/>
  </w:num>
  <w:num w:numId="2">
    <w:abstractNumId w:val="1"/>
  </w:num>
</w:numbering>''';
}
