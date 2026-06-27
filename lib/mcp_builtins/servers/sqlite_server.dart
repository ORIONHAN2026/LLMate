import 'dart:convert';
import 'dart:io';

/// SQLite MCP 服务器
///
/// 注意：此服务器需要系统安装 sqlite3 命令行工具
void main() async {
  final server = _SqliteServer();
  await server.start();
}

class _SqliteServer {
  String? _dbPath;

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
        return {'jsonrpc': '2.0', 'result': {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'sqlite-server', 'version': '1.0.0'}}, 'id': id};
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
    {'name': 'open_database', 'description': '打开数据库', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']}},
    {'name': 'execute_query', 'description': '执行查询', 'inputSchema': {'type': 'object', 'properties': {'sql': {'type': 'string'}}, 'required': ['sql']}},
    {'name': 'list_tables', 'description': '列出表', 'inputSchema': {'type': 'object', 'properties': {}}},
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      switch (name) {
        case 'open_database':
          _dbPath = args['path'] as String;
          return _ok(id, 'Database opened: $_dbPath');
        case 'execute_query':
          if (_dbPath == null) return _error(id, 'No database opened');
          final result = await Process.run('sqlite3', [_dbPath!, '-header', '-column', args['sql'] as String]);
          return _ok(id, result.stdout.toString());
        case 'list_tables':
          if (_dbPath == null) return _error(id, 'No database opened');
          final result = await Process.run('sqlite3', [_dbPath!, "SELECT name FROM sqlite_master WHERE type='table'"]);
          return _ok(id, result.stdout.toString());
        default:
          return _error(id, 'Unknown tool: $name');
      }
    } catch (e) {
      return _error(id, '$e');
    }
  }

  Map<String, dynamic> _ok(dynamic id, String text) => {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': text}], 'isError': false}, 'id': id};
  Map<String, dynamic> _error(dynamic id, String msg) => {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $msg'}], 'isError': true}, 'id': id};
}
