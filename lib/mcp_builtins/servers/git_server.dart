import 'dart:convert';
import 'dart:io';

/// Git MCP 服务器
void main() async {
  final server = _GitServer();
  await server.start();
}

class _GitServer {
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
        return {'jsonrpc': '2.0', 'result': {'protocolVersion': '2024-11-05', 'capabilities': {'tools': {}}, 'serverInfo': {'name': 'git-server', 'version': '1.0.0'}}, 'id': id};
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
    {'name': 'git_status', 'description': '查看仓库状态', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']}},
    {'name': 'git_log', 'description': '查看提交历史', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}, 'count': {'type': 'integer'}}, 'required': ['path']}},
    {'name': 'git_diff', 'description': '查看差异', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']}},
    {'name': 'git_commit', 'description': '提交', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}, 'message': {'type': 'string'}}, 'required': ['path', 'message']}},
    {'name': 'git_branch', 'description': '分支操作', 'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}, 'action': {'type': 'string'}, 'name': {'type': 'string'}}, 'required': ['path', 'action']}},
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final name = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      final path = args['path'] as String;
      String result;
      switch (name) {
        case 'git_status':
          result = await _run(path, ['status']);
          break;
        case 'git_log':
          final count = (args['count'] as num?)?.toInt() ?? 20;
          result = await _run(path, ['log', '--oneline', '-n', '$count']);
          break;
        case 'git_diff':
          result = await _run(path, ['diff']);
          break;
        case 'git_commit':
          result = await _run(path, ['commit', '-m', args['message'] as String]);
          break;
        case 'git_branch':
          final action = args['action'] as String;
          final branchName = args['name'] as String?;
          switch (action) {
            case 'list': result = await _run(path, ['branch', '-a']); break;
            case 'create': result = await _run(path, ['branch', branchName!]); break;
            case 'checkout': result = await _run(path, ['checkout', branchName!]); break;
            case 'delete': result = await _run(path, ['branch', '-d', branchName!]); break;
            default: result = 'Unknown action: $action';
          }
          break;
        default:
          return {'jsonrpc': '2.0', 'error': {'code': -32602, 'message': '$name'}, 'id': id};
      }
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': result}], 'isError': false}, 'id': id};
    } catch (e) {
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $e'}], 'isError': true}, 'id': id};
    }
  }

  Future<String> _run(String path, List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: path);
    return result.stdout.toString().trim() + (result.stderr.toString().isNotEmpty ? '\n${result.stderr}' : '');
  }
}
