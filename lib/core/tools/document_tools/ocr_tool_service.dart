import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// OCR 图片文字识别服务。
///
/// 使用 RapidOCR 对图片执行 OCR 文字识别，提取图片中的文字内容。
/// RapidOCR 基于 ONNXRuntime，无需安装 Tesseract-OCR，纯 pip 安装即可使用。
/// 支持中英文混合识别，速度比 Tesseract 更快。
class OcrToolService {
  static const _toolName = 'ocr_extract';
  static const _execTimeoutSeconds = 30;

  /// 执行 OCR 识别
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
        ['-m', 'pip', 'install', 'rapidocr_onnxruntime'],
        runInShell: true,
      ).timeout(const Duration(seconds: 60));

      if (pipResult.exitCode != 0) {
        debugPrint('⚠️ pip 安装 rapidocr_onnxruntime 失败: ${pipResult.stderr}');
      }
    } catch (e) {
      debugPrint('⚠️ pip 安装超时: $e');
    }

    // ── 构建 OCR Python 脚本 ──
    final escapedPath = filePath.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    final script = '''
import sys
import json

try:
    from rapidocr_onnxruntime import RapidOCR

    engine = RapidOCR()
    result, elapse = engine.rapidocr("$escapedPath")

    # result 是列表: [[bbox, text, confidence], ...]
    # 提取所有文字拼接
    if result:
        texts = [item[1] for item in result]
        full_text = "\\n".join(texts)
        char_count = len(full_text.replace("\\n", ""))
    else:
        full_text = ""
        char_count = 0

    output = {
        "text": full_text,
        "file": "$escapedPath",
        "lang": "$lang",
        "char_count": char_count,
        "line_count": len(texts) if result else 0,
        "elapse": round(sum(elapse), 2) if elapse else 0,
    }
    print(json.dumps(output, ensure_ascii=False))
except ImportError as e:
    print(json.dumps({"error": f"缺少依赖: {e}. 请安装: pip install rapidocr_onnxruntime"}, ensure_ascii=False))
    sys.exit(1)
except Exception as e:
    print(json.dumps({"error": f"OCR 失败: {e}"}, ensure_ascii=False))
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
        onTimeout: () => throw TimeoutException('OCR 执行超时 (${_execTimeoutSeconds}s)'),
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
          final elapse = jsonResult['elapse'] as num? ?? 0;
          return {
            'id': callId,
            'name': _toolName,
            'args': arguments,
            'result': text.isEmpty
                ? '图片中未识别到文字内容。可能图片无文字或图片质量不佳。'
                : 'OCR 识别结果 (${charCount} 字, ${lineCount} 行, ${elapse}s):\n$text',
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
          'result': 'OCR 执行失败: $errorMsg',
          'isError': true,
        };
      }
    } on TimeoutException {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': 'OCR 执行超时 (${_execTimeoutSeconds}s)，图片可能过大。',
        'isError': true,
      };
    } catch (e) {
      return {
        'id': callId,
        'name': _toolName,
        'args': arguments,
        'result': 'OCR 执行异常: $e',
        'isError': true,
      };
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
