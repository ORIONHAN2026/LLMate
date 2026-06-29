import 'dart:convert';
import 'dart:io';
import 'dart:math';

import './protocol.dart';

/// WritePage MCP 服务器
///
/// 可部署到腾讯 CloudBase CloudRun 的远程 MCP 服务
/// 功能：将 Markdown 内容写入文件并生成可访问的网页链接
void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '3000');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final pagesDir = Platform.environment['PAGES_DIR'] ?? './pages';
  final pageBaseUrl = Platform.environment['PAGE_BASE_URL'] ?? 'http://$host:$port';

  // 确保 pages 目录存在
  await Directory(pagesDir).create(recursive: true);

  final server = await HttpServer.bind(host, port);
  print('[WritePage] 服务已启动: http://$host:$port');
  print('[WritePage] MCP 端点: http://$host:$port/mcp');
  print('[WritePage] 健康检查: http://$host:$port/health');

  await for (final request in server) {
    _handleRequest(request, pagesDir: pagesDir, pageBaseUrl: pageBaseUrl);
  }
}

Future<void> _handleRequest(
  HttpRequest request, {
  required String pagesDir,
  required String pageBaseUrl,
}) async {
  final path = request.uri.path;

  // CORS 头
  request.response.headers.set('Access-Control-Allow-Origin', '*');
  request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  if (path == '/health') {
    await _handleHealth(request);
  } else if (path == '/mcp' && request.method == 'POST') {
    await _handleMCP(request, pagesDir: pagesDir, pageBaseUrl: pageBaseUrl);
  } else if (path.startsWith('/p/')) {
    await _handlePage(request, path: path, pagesDir: pagesDir);
  } else {
    request.response.statusCode = 404;
    await request.response.close();
  }
}

Future<void> _handleHealth(HttpRequest request) async {
  final response = {
    'status': 'ok',
    'service': 'writePage',
    'version': '1.0.0',
  };
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(response));
  await request.response.close();
}

Future<void> _handleMCP(
  HttpRequest request, {
  required String pagesDir,
  required String pageBaseUrl,
}) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final mcpRequest = McpRequest.fromJson(json);

    McpResponse response;

    switch (mcpRequest.method) {
      case 'initialize':
        response = _handleInitialize(mcpRequest);
        break;
      case 'tools/list':
        response = _handleToolsList(mcpRequest);
        break;
      case 'tools/call':
        response = await _handleToolsCall(mcpRequest, pagesDir: pagesDir, pageBaseUrl: pageBaseUrl);
        break;
      case 'ping':
        response = McpResponse(id: mcpRequest.id, result: {});
        break;
      default:
        response = McpResponse(
          id: mcpRequest.id,
          error: {'code': -32601, 'message': 'Method not found: ${mcpRequest.method}'},
        );
    }

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response.toJson()));
  } catch (e) {
    request.response.statusCode = 400;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'jsonrpc': '2.0',
      'id': null,
      'error': {'code': -32700, 'message': 'Parse error: $e'},
    }));
  }

  await request.response.close();
}

McpResponse _handleInitialize(McpRequest request) {
  return McpResponse(
    id: request.id,
    result: {
      'protocolVersion': '2024-11-05',
      'capabilities': {'tools': {}},
      'serverInfo': {
        'name': 'writepage-server',
        'version': '1.0.0',
      },
    },
  );
}

McpResponse _handleToolsList(McpRequest request) {
  return McpResponse(
    id: request.id,
    result: {
      'tools': [
        {
          'name': 'writePage',
          'description': '将 Markdown 内容写入文件并生成可访问的网页链接',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'content': {
                'type': 'string',
                'description': 'Markdown 格式的文本内容',
              },
            },
            'required': ['content'],
          },
        },
      ],
    },
  );
}

Future<McpResponse> _handleToolsCall(
  McpRequest request, {
  required String pagesDir,
  required String pageBaseUrl,
}) async {
  final params = request.params ?? {};
  final toolName = params['name'] as String?;
  final args = (params['arguments'] as Map<String, dynamic>?) ?? {};

  if (toolName == 'writePage') {
    return await _writePage(request, args, pagesDir: pagesDir, pageBaseUrl: pageBaseUrl);
  }

  return McpResponse(
    id: request.id,
    result: {
      'content': [{'type': 'text', 'text': '❌ 未知工具: $toolName'}],
      'isError': true,
    },
  );
}

Future<McpResponse> _writePage(
  McpRequest request,
  Map<String, dynamic> args, {
  required String pagesDir,
  required String pageBaseUrl,
}) async {
  final content = args['content'] as String? ?? '';
  if (content.isEmpty) {
    return McpResponse(
      id: request.id,
      result: {
        'content': [{'type': 'text', 'text': '❌ 缺少参数: content'}],
        'isError': true,
      },
    );
  }

  final docId = _generateUUID();
  final file = File('$pagesDir/$docId.md');
  await file.writeAsString(content);

  print('[PAGE] 文件已写入: ${file.path}');

  final pageUrl = '$pageBaseUrl/p/$docId';
  final preview = content.length > 200 ? '${content.substring(0, 200)}...' : content;

  return McpResponse(
    id: request.id,
    result: {
      'content': [{'type': 'text', 'text': '''✅ **页面创建成功**

- **docId**: `$docId`
- **页面链接**: $pageUrl
- **内容预览**:

$preview'''}],
      'isError': false,
    },
  );
}

Future<void> _handlePage(
  HttpRequest request, {
  required String path,
  required String pagesDir,
}) async {
  final docId = path.replaceFirst('/p/', '');
  if (docId.isEmpty || docId == path) {
    request.response.statusCode = 400;
    request.response.write('缺少 docId');
    await request.response.close();
    return;
  }

  final file = File('$pagesDir/$docId.md');
  if (!await file.exists()) {
    request.response.statusCode = 404;
    request.response.write('页面不存在');
    await request.response.close();
    return;
  }

  final content = await file.readAsString();
  final html = _buildPageHTML(docId, content);

  request.response.headers.contentType = ContentType.html;
  request.response.write(html);
  await request.response.close();
}

String _buildPageHTML(String docId, String content) {
  final escaped = content
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  return '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>文档 $docId</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown-light.min.css">
<script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
<style>
body { background: #f6f8fa; padding: 0; margin: 0; }
.markdown-body { max-width: 980px; margin: 32px auto; padding: 45px; }
@media (max-width: 767px) { .markdown-body { padding: 15px; margin: 16px; } }
</style>
</head>
<body>
<article class="markdown-body">
<div id="content"></div>
</article>
<pre id="raw-content" style="display:none">$escaped</pre>
<script>
document.getElementById('content').innerHTML = marked.parse(document.getElementById('raw-content').textContent);
</script>
</body>
</html>''';
}

String _generateUUID() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  return '${_toHex(bytes, 0, 4)}-${_toHex(bytes, 4, 6)}-${_toHex(bytes, 6, 8)}-${_toHex(bytes, 8, 10)}-${_toHex(bytes, 10, 16)}';
}

String _toHex(List<int> bytes, int start, int end) {
  return bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
