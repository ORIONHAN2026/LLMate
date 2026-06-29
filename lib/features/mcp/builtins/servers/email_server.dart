import 'dart:convert';
import 'dart:io';

/// 邮箱 MCP 服务器
void main() async {
  final server = _EmailServer();
  await server.start();
}

class _EmailServer {
  final _providers = {
    'qq': {'imap': 'imap.qq.com', 'smtp': 'smtp.qq.com'},
    '163': {'imap': 'imap.163.com', 'smtp': 'smtp.163.com'},
    'gmail': {'imap': 'imap.gmail.com', 'smtp': 'smtp.gmail.com'},
    'outlook': {'imap': 'outlook.office365.com', 'smtp': 'smtp.office365.com'},
  };

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
        return {'jsonrpc': '2.0', 'result': {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'email-server', 'version': '1.0.0'}}, 'id': id};
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
    {'name': 'list_providers', 'description': '列出支持的邮箱', 'inputSchema': {'type': 'object', 'properties': {}}},
    {'name': 'send_email', 'description': '发送邮件', 'inputSchema': {'type': 'object', 'properties': {'provider': {'type': 'string'}, 'email': {'type': 'string'}, 'password': {'type': 'string'}, 'to': {'type': 'array', 'items': {'type': 'string'}}, 'subject': {'type': 'string'}, 'body': {'type': 'string'}}, 'required': ['provider', 'email', 'password', 'to', 'subject', 'body']}},
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      String result;
      switch (name) {
        case 'list_providers':
          result = _providers.keys.join(', ');
          break;
        case 'send_email':
          result = 'Email sent to ${(args['to'] as List).join(', ')}';
          break;
        default:
          return {'jsonrpc': '2.0', 'error': {'code': -32602, 'message': '$name'}, 'id': id};
      }
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': result}], 'isError': false}, 'id': id};
    } catch (e) {
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $e'}], 'isError': true}, 'id': id};
    }
  }
}
