/// MCP 协议类型定义
class McpRequest {
  final dynamic id;
  final String method;
  final Map<String, dynamic>? params;

  McpRequest({this.id, required this.method, this.params});

  factory McpRequest.fromJson(Map<String, dynamic> json) {
    return McpRequest(
      id: json['id'],
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }
}

class McpResponse {
  final dynamic id;
  final dynamic result;
  final Map<String, dynamic>? error;

  McpResponse({this.id, this.result, this.error});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
    };
    if (result != null) json['result'] = result;
    if (error != null) json['error'] = error;
    return json;
  }
}
