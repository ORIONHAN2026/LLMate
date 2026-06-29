import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// PaddleOCR 图片文字识别服务。
///
/// 使用 PaddleOCR 对图片执行 OCR 文字识别，提取图片中的文字内容。
/// PaddleOCR 是百度开源的 OCR 引擎，支持中英文混合识别，准确率高。
class PaddleOcrService {
  static const _toolName = 'paddle_ocr';
  static const _execTimeoutSeconds = 60;

  /// 执行 PaddleOCR 识别
  static Future<Map<String, dynamic>> execute({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    final filePath = (arguments['filePath'] as String?)?.trim() ?? '';
    final lang = (arguments['lang'] as String?)?.trim() ?? 'ch';

    // ── 参数校验 ──
    if (filePath.isEmpty) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': '错误: 必须提供 filePath 参数，指定要识别的图片文件路径。',
        'isError': true,
      };
    }

    // ── 检查文件是否存在 ──
    final file = File(filePath);
    if (!await file.exists()) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': '错误: 文件不存在: $filePath',
        'isError': true,
      };
    }

    // ── 找到 Python ──
    final pythonPath = await _findPython();
    if (pythonPath.isEmpty) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': '错误: 未找到 Python3 解释器，请安装 Python3。',
        'isError': true,
      };
    }

    // ── 自动安装依赖 ──
    try {
      final pipResult = await Process.run(
        pythonPath,
        ['-m', 'pip', 'install', 'paddlepaddle', 'paddleocr'],
        runInShell: true,
      ).timeout(const Duration(seconds: 120));

      if (pipResult.exitCode != 0) {
        debugPrint('⚠️ pip 安装 paddleocr 失败: ${pipResult.stderr}');
      }
    } catch (e) {
      debugPrint('⚠️ pip 安装超时: $e');
    }

    // ── 构建 PaddleOCR Python 脚本 ──
    final escapedPath = filePath.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    final script = '''
import sys
import json

try:
    from paddleocr import PaddleOCR
    
    # 初始化 PaddleOCR
    # use_angle_cls: 是否使用方向分类器
    # lang: 语言，ch=中文，en=英文
    ocr = PaddleOCR(use_angle_cls=True, lang="$lang", show_log=False)
    
    # 执行 OCR
    result = ocr.ocr("$escapedPath", cls=True)
    
    # 提取所有文字
    texts = []
    if result and result[0]:
        for line in result[0]:
            if line and len(line) >= 2:
                text = line[1][0]  # 文字内容
                confidence = line[1][1]  # 置信度
                texts.append(text)
    
    full_text = "\\n".join(texts)
    char_count = len(full_text.replace("\\n", ""))
    
    output = {
        "text": full_text,
        "file": "$escapedPath",
        "lang": "$lang",
        "char_count": char_count,
        "line_count": len(texts),
    }
    print(json.dumps(output, ensure_ascii=False))
except ImportError as e:
    print(json.dumps({"error": f"缺少依赖: {e}. 请安装: pip install paddlepaddle paddleocr"}, ensure_ascii=False))
    sys.exit(1)
except Exception as e:
    print(json.dumps({"error": f"PaddleOCR 失败: {e}"}, ensure_ascii=False))
    sys.exit(1)
''';

    // ── 执行脚本 ──
    try {
      final result = await Process.run(
        pythonPath,
        ['-c', script],
        runInShell: true,
      ).timeout(
        Duration(seconds: _execTimeoutSeconds),
        onTimeout: () => throw TimeoutException('PaddleOCR 执行超时 ($_execTimeoutSeconds}s)'),
      );

      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();

      if (result.exitCode == 0 && stdout.isNotEmpty) {
        try {
          final jsonResult = jsonDecode(stdout) as Map<String, dynamic>;
          if (jsonResult.containsKey('error')) {
            return {
              'id': callId,
              'name': _toolName,
              'args': arguments,
              'result': jsonResult['error'] as String,
              'isError': true,
            };
          }
          final text = jsonResult['text'] as String? ?? '';
          final charCount = jsonResult['char_count'] as int? ?? 0;
          final lineCount = jsonResult['line_count'] as int? ?? 0;
          return {
            'id': callId,
            'name': _toolName,
            'args': arguments,
            'result': text.isEmpty
                ? '图片中未识别到文字内容。可能图片无文字或图片质量不佳。'
                : 'PaddleOCR 识别结果 (${charCount} 字, ${lineCount} 行):\n$text',
            'isError': false,
          };
        } catch (_) {
          return {
            'id': callId,
            'name': _toolName,
            'args': arguments,
            'result': stdout,
            'isError': false,
          };
        }
      } else {
        final errorMsg = stderr.isNotEmpty ? stderr : stdout;
        return {
          'id': callId,
          'name': _toolName,
          'args': arguments,
          'result': 'PaddleOCR 执行失败: $errorMsg',
          'isError': true,
        };
      }
    } on TimeoutException {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': 'PaddleOCR 执行超时 ($_execTimeoutSeconds}s)，图片可能过大。',
        'isError': true,
      };
    } catch (e) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': 'PaddleOCR 执行异常: $e',
        'isError': true,
      };
    }
  }

  /// 扫描文件并检测是否包含发票关键词
  static Future<bool> scanForInvoice(String filePath) async {
    try {
      final result = await execute(
        arguments: {'filePath': filePath, 'lang': 'ch'},
        callId: 'invoice_scan_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isError'] == true) return false;

      final text = result['result'] as String? ?? '';
      
      // 发票关键词列表
      const invoiceKeywords = [
        '发票', 'invoice', '增值税', '普通发票', '专用发票',
        '电子发票', '机打发票', '发票代码', '发票号码',
        '开票日期', '价税合计', '税额', '税率',
        '购买方', '销售方', '纳税人识别号',
      ];

      for (final keyword in invoiceKeywords) {
        if (text.toLowerCase().contains(keyword.toLowerCase())) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('PaddleOCR 发票检测失败: $e');
      return false;
    }
  }

  /// 查找可用的 Python3 解释器
  static Future<String> _findPython() async {
    const candidates = ['python3', 'python'];

    for (final cmd in candidates) {
      try {
        final result = await Process.run(
          cmd,
          ['-c', 'import sys; print(sys.version)'],
          runInShell: true,
        ).timeout(const Duration(seconds: 3));
        if (result.exitCode == 0) {
          final version = result.stdout.toString().trim();
          if (version.startsWith('3.')) {
            debugPrint('🐍 找到 Python3: $cmd ($version)');
            return cmd;
          }
        }
      } catch (_) {}
    }

    return '';
  }
}
