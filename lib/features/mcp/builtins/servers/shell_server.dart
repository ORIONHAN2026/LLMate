import 'dart:convert';
import 'dart:io';

/// Shell MCP 服务器
void main() async {
  final server = _ShellServer();
  await server.start();
}

class _ShellServer {
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
        return {'jsonrpc': '2.0', 'result': {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'shell-server', 'version': '1.0.0'}}, 'id': id};
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
    {'name': 'execute', 'description': '执行命令', 'inputSchema': {'type': 'object', 'properties': {'command': {'type': 'string'}, 'workingDirectory': {'type': 'string'}}, 'required': ['command']}},
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      if (name == 'execute') {
        final command = args['command'] as String;
        final workDir = args['workingDirectory'] as String?;
        final result = await Process.run('sh', ['-c', command], workingDirectory: workDir);
        final output = result.stdout.toString() + result.stderr.toString();
        return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': output.trim()}], 'isError': false}, 'id': id};
      }
      return {'jsonrpc': '2.0', 'error': {'code': -32602, 'message': '$name'}, 'id': id};
    } catch (e) {
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $e'}], 'isError': true}, 'id': id};
    }
  }
}
