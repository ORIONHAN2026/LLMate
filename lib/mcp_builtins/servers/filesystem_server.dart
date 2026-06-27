import 'dart:convert';
import 'dart:io';

/// 文件系统 MCP 服务器
void main() async {
  final server = _FilesystemServer();
  await server.start();
}

/// 获取文件名（不使用 path 包）
String _basename(String path) {
  return path.split(Platform.pathSeparator).last;
}

class _FilesystemServer {
  Future<void> start() async {
    stdin.transform(utf8.decoder).transform(LineSplitter()).listen(
      (line) async {
        if (line.isEmpty) return;
        try {
          final request = jsonDecode(line) as Map<String, dynamic>;
          final response = await _handleRequest(request);
          stdout.writeln(jsonEncode(response));
        } catch (e) {
          stdout.writeln(jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32700, 'message': 'Parse error: $e'},
            'id': null,
          }));
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
        return {
          'jsonrpc': '2.0',
          'result': {
            'protocolVersion': '2024-11-05',
            'capabilities': {'tools': {'listChanged': false}},
            'serverInfo': {'name': 'filesystem-server', 'version': '1.0.0'},
          },
          'id': id,
        };
      case 'tools/list':
        return {'jsonrpc': '2.0', 'result': {'tools': _tools}, 'id': id};
      case 'tools/call':
        return await _handleToolsCall(id, params);
      case 'ping':
        return {'jsonrpc': '2.0', 'result': {}, 'id': id};
      default:
        return {'jsonrpc': '2.0', 'error': {'code': -32601, 'message': 'Method not found: $method'}, 'id': id};
    }
  }

  final _tools = [
    {
      'name': 'read_file',
      'description': '读取文件内容',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']},
    },
    {
      'name': 'write_file',
      'description': '写入文件内容',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}, 'content': {'type': 'string'}}, 'required': ['path', 'content']},
    },
    {
      'name': 'list_directory',
      'description': '列出目录内容',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']},
    },
    {
      'name': 'create_directory',
      'description': '创建目录',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']},
    },
    {
      'name': 'delete_file',
      'description': '删除文件或目录',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}}, 'required': ['path']},
    },
    {
      'name': 'search_files',
      'description': '搜索文件',
      'inputSchema': {'type': 'object', 'properties': {'path': {'type': 'string'}, 'pattern': {'type': 'string'}}, 'required': ['path', 'pattern']},
    },
  ];

  Future<Map<String, dynamic>> _handleToolsCall(dynamic id, Map<String, dynamic> params) async {
    final toolName = params['name'] as String?;
    final args = (params['arguments'] as Map<String, dynamic>?) ?? {};
    try {
      String result;
      switch (toolName) {
        case 'read_file':
          result = await File(args['path'] as String).readAsString();
          break;
        case 'write_file':
          await File(args['path'] as String).writeAsString(args['content'] as String);
          result = 'File written: ${args['path']}';
          break;
        case 'list_directory':
          final dir = Directory(args['path'] as String);
          final items = await dir.list().map((e) => _basename(e.path)).toList();
          result = items.join('\n');
          break;
        case 'create_directory':
          await Directory(args['path'] as String).create(recursive: true);
          result = 'Directory created: ${args['path']}';
          break;
        case 'delete_file':
          final path = args['path'] as String;
          final type = FileSystemEntity.typeSync(path);
          if (type == FileSystemEntityType.directory) {
            await Directory(path).delete(recursive: true);
          } else {
            await File(path).delete();
          }
          result = 'Deleted: $path';
          break;
        case 'search_files':
          final root = args['path'] as String;
          final pattern = args['pattern'] as String;
          final regex = RegExp(pattern.replaceAll('*', '.*').replaceAll('?', '.'));
          final results = <String>[];
          await for (final entity in Directory(root).list(recursive: true)) {
            if (regex.hasMatch(_basename(entity.path))) results.add(entity.path);
          }
          result = results.join('\n');
          break;
        default:
          return {'jsonrpc': '2.0', 'error': {'code': -32602, 'message': 'Unknown tool: $toolName'}, 'id': id};
      }
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': result}], 'isError': false}, 'id': id};
    } catch (e) {
      return {'jsonrpc': '2.0', 'result': {'content': [{'type': 'text', 'text': 'Error: $e'}], 'isError': true}, 'id': id};
    }
  }
}
