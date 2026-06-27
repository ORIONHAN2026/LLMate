import 'dart:convert';
import 'dart:io';

/// Fetch MCP 服务器
void main() async {
  final server = _FetchServer();
  await server.start();
}

class _FetchServer {
  Future<void> start() async {
    stdin.transform(utf8.decoder).transform(LineSplitter()).listen(
      (line) async {
        if (line.isEmpty) return;
        try {
          final request = jsonDecode(line) as Map<String, dynamic>;
          final response = await _handleRequest(request);
          stdout.writeln(jsonEncode(response));
        } catch (e) {
          stdout.writeln(jsonEncode({'jsonrpc': '2.0', 'error': {'code': -32700, 'message': '$e'}, 'id': null}));
        }
      },
    );
  }

  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>? ?? {};

    switch (method) {
      case 'initialize':
        return {'jsonrpc': '2.0', 'result': {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'fetch-server', 'version': '1.0.0'}}, 'id': id};
      case 'tools/list':
        return {'jsonrpc': '2.0', 'result': {'tools': _tools}, 'id': id};
      case 'tools/call':
        return await _handleToolsCall(id, params);
      case 'ping':
        return {'jsonrpc': '2.0', 'result': {}, 'id': id};
      default:
        return {'jsonrpc': '2.0', 'error': {'code': -32601, 'message': '$method'}, 'id': id};
    }
  }

  final _tools = [
    {'name': 'fetch_url', 'description': '获取网页内容', 'inputSchema': {'type': 'object', 'properties': {'url': {'type': 'string'}}, 'required': ['url']}},
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      if (name == 'fetch_url') {
        final url = args['url'] as String;
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        client.close();
        return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': body}], 'isError': false}, 'id': id};
      }
      return {'jsonrpc': '2.0', 'error': {'code': -32602, 'message': '$name'}, 'id': id};
    } catch (e) {
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $e'}], 'isError': true}, 'id': id};
    }
  }
}
