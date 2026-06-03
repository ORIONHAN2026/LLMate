import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// PPT 文件读写内置工具
///
/// - `ppt_read`：读取 .pptx 文件，提取每页幻灯片的文本内容
/// - `ppt_write`：创建 .pptx 文件，支持多页幻灯片、标题、内容、项目列表
class PptToolService {
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

  // ── 读取 PPTX ─────────────────────────────────────────────

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
    if (ext != '.pptx') {
      return _error(callId, args, '仅支持 .pptx 格式，当前文件: $ext');
    }

    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slides = <Map<String, dynamic>>[];

      // 查找所有 slide 文件
      final slideFiles = <String, ArchiveFile>{};
      for (final f in archive) {
        final name = f.name;
        if (name.startsWith('ppt/slides/slide') && name.endsWith('.xml') && !name.contains('_rels')) {
          slideFiles[name] = f;
        }
      }

      // 按序号排序
      final sortedKeys = slideFiles.keys.toList()..sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

      for (final key in sortedKeys) {
        final content = String.fromCharCodes(slideFiles[key]!.content as List<int>);
        final doc = XmlDocument.parse(content);

        final texts = <String>[];
        // 提取所有 <a:t> 标签的文本
        for (final node in doc.findAllElements('a:t')) {
          final text = node.innerText.trim();
          if (text.isNotEmpty) texts.add(text);
        }

        slides.add({
          'slideIndex': slides.length + 1,
          'text': texts.join('\n'),
          'elements': texts,
        });
      }

      if (kDebugMode) {
        debugPrint('📊 [PptTool] 读取: $filePath (${slides.length} 页)');
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'slideCount': slides.length,
        'slides': slides,
        'message': '已读取 $filePath（${slides.length} 页幻灯片）',
      });
    } catch (e) {
      return _error(callId, args, '读取 PPTX 失败: $e');
    }
  }

  // ── 写入 PPTX ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> _write(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final filePath = _stringArg(args, 'filePath').trim();
    final slidesRaw = args['slides'];

    if (filePath.isEmpty) {
      return _error(callId, args, 'filePath 参数不能为空');
    }
    if (slidesRaw is! List || slidesRaw.isEmpty) {
      return _error(callId, args, 'slides 参数不能为空');
    }

    try {
      final archive = Archive();

      // [Content_Types].xml
      final contentTypes = _buildContentTypes(slidesRaw.length);
      archive.addFile(_af('[Content_Types].xml', contentTypes));

      // _rels/.rels
      final rels = _buildRels();
      archive.addFile(_af('_rels/.rels', rels));

      // ppt/presentation.xml
      final presentation = _buildPresentation(slidesRaw.length);
      archive.addFile(_af('ppt/presentation.xml', presentation));

      // ppt/_rels/presentation.xml.rels
      final presRels = _buildPresentationRels(slidesRaw.length);
      archive.addFile(_af('ppt/_rels/presentation.xml.rels', presRels));

      // ppt/theme/theme1.xml
      final theme = _buildTheme();
      archive.addFile(_af('ppt/theme/theme1.xml', theme));

      // ppt/slideMasters/slideMaster1.xml
      final slideMaster = _buildSlideMaster();
      archive.addFile(_af('ppt/slideMasters/slideMaster1.xml', slideMaster));

      // ppt/slideLayouts/slideLayout1.xml
      final slideLayout = _buildSlideLayout();
      archive.addFile(_af('ppt/slideLayouts/slideLayout1.xml', slideLayout));

      // ppt/slideMasters/_rels/slideMaster1.xml.rels
      final smRels = _buildSlideMasterRels();
      archive.addFile(_af('ppt/slideMasters/_rels/slideMaster1.xml.rels', smRels));

      // 每页幻灯片
      for (int i = 0; i < slidesRaw.length; i++) {
        final slideData = slidesRaw[i] as Map<String, dynamic>;
        final slideXml = _buildSlide(slideData, i + 1);
        final num = i + 1;
        archive.addFile(_af('ppt/slides/slide$num.xml', slideXml));

        final slideRelXml = _buildSlideRels(num);
        archive.addFile(_af('ppt/slides/_rels/slide$num.xml.rels', slideRelXml));
      }

      // 打包保存
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        return _error(callId, args, '生成 PPTX 失败');
      }

      final file = File(filePath);
      final parent = file.parent;
      if (!parent.existsSync()) {
        await parent.create(recursive: true);
      }
      await file.writeAsBytes(zipBytes);

      if (kDebugMode) {
        debugPrint('📊 [PptTool] 创建: $filePath (${slidesRaw.length} 页)');
      }

      return _ok(callId, args, {
        'filePath': filePath,
        'fileName': p.basename(filePath),
        'slideCount': slidesRaw.length,
        'message': '已创建 PPT: $filePath（${slidesRaw.length} 页）',
      });
    } catch (e) {
      return _error(callId, args, '创建 PPTX 失败: $e');
    }
  }

  // ── PPTX XML 构建 ─────────────────────────────────────────

  static String _buildContentTypes(int slideCount) {
    final overrides = StringBuffer();
    overrides.writeln('<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>');
    overrides.writeln('<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>');
    overrides.writeln('<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>');
    overrides.writeln('<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      overrides.writeln('<Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '$overrides'
        '</Types>';
  }

  static String _buildRels() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>'
        '</Relationships>';
  }

  static String _buildPresentation(int slideCount) {
    final slideIds = StringBuffer();
    for (int i = 1; i <= slideCount; i++) {
      final id = 256 + i;
      slideIds.writeln('<p:sldId id="$id" r:id="rId${i + 2}"/>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        '<p:sldIdLst>$slideIds</p:sldIdLst>'
        '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>'
        '</p:presentation>';
  }

  static String _buildPresentationRels(int slideCount) {
    final rels = StringBuffer();
    rels.writeln('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');
    rels.writeln('<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      rels.writeln('<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>');
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">$rels</Relationships>';
  }

  static String _buildSlideRels(int slideNum) {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
        '</Relationships>';
  }

  static String _buildTheme() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">'
        '<a:themeElements><a:clrScheme name="Office"><a:dk1><a:sysVal val="windowText"/></a:dk1>'
        '<a:lt1><a:sysVal val="window"/></a:lt1><a:dk2><a:srgbClr val="1F497D"/></a:dk2>'
        '<a:lt2><a:srgbClr val="EEECE1"/></a:lt2><a:accent1><a:srgbClr val="4F81BD"/></a:accent1>'
        '<a:accent2><a:srgbClr val="C0504D"/></a:accent2><a:accent3><a:srgbClr val="9BBB59"/></a:accent3>'
        '<a:accent4><a:srgbClr val="8064A2"/></a:accent4><a:accent5><a:srgbClr val="4BACC6"/></a:accent5>'
        '<a:accent6><a:srgbClr val="F79646"/></a:accent6></a:clrScheme>'
        '<a:fontScheme name="Office"><a:majorFont><a:latin typeface="Calibri"/>'
        '</a:majorFont><a:minorFont><a:latin typeface="Calibri"/></a:minorFont></a:fontScheme>'
        '<a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/>'
        '</a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill>'
        '<a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>'
        '<a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>'
        '<a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
        '</a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>';
  }

  static String _buildSlideMaster() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        '<p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg></p:cSld>'
        '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" '
        'accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6"/>'
        '</p:sldMaster>';
  }

  static String _buildSlideLayout() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="obj">'
        '<p:cSld name="Title and Content"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/>'
        '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>'
        '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" '
        'accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6"/>'
        '</p:sldLayout>';
  }

  static String _buildSlideMasterRels() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>'
        '</Relationships>';
  }

  static String _buildSlide(Map<String, dynamic> slideData, int slideNum) {
    final slideTitle = _stringArg(slideData, 'title');
    final content = _stringArg(slideData, 'content');
    final items = slideData['items'];

    final shapes = StringBuffer();

    // 标题
    if (slideTitle.isNotEmpty) {
      shapes.writeln('<p:sp><p:nvSpPr><p:cNvPr id="1" name="Title ${slideNum}"/>'
          '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="title"/></p:nvPr></p:nvSpPr>'
          '<p:spPr><a:xfrm><a:off x="457200" y="274638"/><a:ext cx="8229600" cy="1143000"/></a:xfrm>'
          '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>'
          '<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang="zh-CN" sz="4400" b="1" dirty="0"/>'
          '<a:t>${_xmlEsc(slideTitle)}</a:t></a:r></a:p></p:txBody></p:sp>');
    }

    // 内容 - 纯文本或项目列表
    if (items is List && items.isNotEmpty) {
      final paras = StringBuffer();
      for (final item in items) {
        final text = item?.toString() ?? '';
        paras.writeln('<a:p><a:pPr lvl="0"/><a:r><a:rPr lang="zh-CN" sz="1800" dirty="0"/>'
            '<a:t>${_xmlEsc(text)}</a:t></a:r></a:p>');
      }
      shapes.writeln('<p:sp><p:nvSpPr><p:cNvPr id="2" name="Content ${slideNum}"/>'
          '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr>'
          '<p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm>'
          '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>'
          '<p:txBody><a:bodyPr/><a:lstStyle/>$paras</p:txBody></p:sp>');
    } else if (content.isNotEmpty) {
      // 按换行分割成段落
      final lines = content.split('\n');
      final paras = StringBuffer();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final isBullet = line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('• ');
        final text = isBullet ? line.trimLeft().substring(2) : line;
        paras.writeln('<a:p><a:pPr lvl="${isBullet ? 0 : 1}"/>'
            '<a:r><a:rPr lang="zh-CN" sz="1800" dirty="0"/>'
            '<a:t>${_xmlEsc(text)}</a:t></a:r></a:p>');
      }
      shapes.writeln('<p:sp><p:nvSpPr><p:cNvPr id="2" name="Content ${slideNum}"/>'
          '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr><p:nvPr><p:ph type="body" idx="1"/></p:nvPr></p:nvSpPr>'
          '<p:spPr><a:xfrm><a:off x="457200" y="1600200"/><a:ext cx="8229600" cy="4525963"/></a:xfrm>'
          '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>'
          '<p:txBody><a:bodyPr/><a:lstStyle/>$paras</p:txBody></p:sp>');
    }

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/>'
        '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/>$shapes</p:spTree></p:cSld>'
        '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>';
  }

  // ── 辅助 ──────────────────────────────────────────────────

  static String _xmlEsc(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static ArchiveFile _af(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static String _stringArg(Map<String, dynamic> args, String key, [String defaultValue = '']) {
    final value = args[key];
    return value == null ? defaultValue : value.toString();
  }

  static Map<String, dynamic> _ok(String callId, Map<String, dynamic> args, Map<String, dynamic> data) {
    return {'id': callId, 'name': 'ppt_read', 'args': args, 'result': jsonEncode(data), 'isError': false};
  }

  static Map<String, dynamic> _error(String callId, Map<String, dynamic> args, String message) {
    return {'id': callId, 'name': 'ppt_read', 'args': args, 'result': message, 'isError': true};
  }
}
