import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// URL 内容读取内置工具
///
/// 提供 `url_fetch` 操作：抓取 URL 页面内容并提取纯文本。
class UrlFetchToolService {
  /// 请求超时（秒）
  static const _timeoutSeconds = 15;

  /// 最大响应体大小（5MB）
  static const _maxBodyBytes = 5 * 1024 * 1024;

  /// 入口
  static Future<Map<String, dynamic>> execute({
    required Map<String, dynamic> arguments,
    required String callId,
  }) async {
    return _fetch(callId, arguments);
  }

  static Future<Map<String, dynamic>> _fetch(
    String callId,
    Map<String, dynamic> args,
  ) async {
    final url = _stringArg(args, 'url').trim();
    if (url.isEmpty) {
      return _error(callId, args, 'url 参数不能为空');
    }

    // 校验 URL 格式
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return _error(callId, args, '无效的 URL: $url');
    }

    // 仅允许 http/https
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return _error(callId, args, '仅支持 http/https 协议: $url');
    }

    try {
      if (kDebugMode) {
        debugPrint('🌐 [UrlFetchTool] 抓取: $url');
      }

      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (compatible; ChatHub/1.0; +https://example.com)',
              'Accept': 'text/html,text/plain,application/json,*/*',
            },
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      final statusCode = response.statusCode;
      final contentType = response.headers['content-type'] ?? '';
      final isHtml =
          contentType.contains('text/html') || contentType.isEmpty;

      // 截断过大的响应体
      var bodyBytes = response.bodyBytes;
      final wasTruncated = bodyBytes.length > _maxBodyBytes;
      if (wasTruncated) {
        bodyBytes = bodyBytes.sublist(0, _maxBodyBytes);
      }

      String textContent;
      String encoding;

      /// 安全解码 body，对非标准 UTF-8 字节用 � 替代避免 FormatException
      String safeDecode(List<int> bytes) {
        try {
          return utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          // 极端情况降级为 Latin-1（永不会失败）
          return latin1.decode(bytes);
        }
      }

      if (isHtml) {
        // HTML → 纯文本
        final html = safeDecode(bodyBytes);
        textContent = _htmlToText(html);
        encoding = 'text/html';
      } else if (contentType.contains('application/json')) {
        final json = safeDecode(bodyBytes);
        // 格式化 JSON
        try {
          final decoded = jsonDecode(json);
          textContent = const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          textContent = json;
        }
        encoding = 'application/json';
      } else {
        textContent = safeDecode(bodyBytes);
        encoding = contentType.isNotEmpty ? contentType : 'text/plain';
      }

      // 再次截断文本长度（最多 20000 字符，避免 tokens 爆炸）
      const maxTextChars = 20000;
      final textTruncated = textContent.length > maxTextChars;
      final finalText =
          textTruncated
              ? textContent.substring(0, maxTextChars)
              : textContent;

      final bufs = StringBuffer();
      bufs.writeln('抓取成功');
      bufs.writeln('URL: $url');
      bufs.writeln('状态码: $statusCode');
      bufs.writeln('内容类型: $encoding');
      bufs.writeln(
        '内容长度: ${bodyBytes.length} 字节${wasTruncated ? ' (已截断)' : ''}',
      );
      if (textTruncated) {
        bufs.writeln('文本截断至 $maxTextChars 字符');
      }
      bufs.writeln();
      bufs.writeln('--- 页面内容 ---');
      bufs.writeln(finalText);

      return _ok(callId, args, {
        'url': url,
        'statusCode': statusCode,
        'contentType': encoding,
        'contentLength': bodyBytes.length,
        'truncated': wasTruncated || textTruncated,
        'text': finalText,
        'message': bufs.toString(),
      });
    } on http.ClientException catch (e) {
      return _error(callId, args, '网络请求失败: ${e.message}');
    } catch (e) {
      return _error(
        callId,
        args,
        e is FormatException ? '响应解析失败: $e' : '抓取失败: $e',
      );
    }
  }

  /// HTML → 纯文本转换
  static String _htmlToText(String html) {
    var text = html;

    // 1. 去除 script / style / noscript 整块内容
    for (final tag in ['script', 'style', 'noscript']) {
      text = text.replaceAll(
        RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
        '',
      );
    }

    // 2. 块级元素前后插入换行，便于段落分隔
    text = text.replaceAll(
      RegExp(
        r'</?(div|p|h[1-6]|li|tr|br|hr|section|article|header|footer'
        r'|nav|aside|main|table|thead|tbody|tfoot|figure|figcaption'
        r'|blockquote|pre|form|fieldset|details|summary)[^>]*/?>',
        caseSensitive: false,
      ),
      '\n',
    );

    // 3. 去除所有剩余 HTML 标签
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');

    // 4. 解码常见 HTML 实体
    text =
        text
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&#x27;', "'")
            .replaceAll('&nbsp;', ' ');

    // 5. 解码 Unicode 数字实体 (&#1234;)
    text = text.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!)),
    );

    // 6. 清理空白：去首尾空白 + 合并连续空行
    final lines =
        text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    return lines.join('\n');
  }

  // ── 辅助 ──

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
      'name': 'url_fetch',
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
      'name': 'url_fetch',
      'args': args,
      'result': message,
      'isError': true,
    };
  }
}
