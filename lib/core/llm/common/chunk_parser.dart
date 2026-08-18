import 'dart:convert';

/// 服务端正在执行 MCP 工具的 SSE 推理内容哨兵值。
///
/// 该值由本机 HTTP 服务（[sessionCheckGuard] 工具执行）与本地管理模式共同使用，
/// 用于向聊天 UI 透传「大模型正在执行工具」的状态。
const String mcpExecutingSentinel = '大模型正在执行MCP服务';

/// 将单个 OpenAI SSE data 负载解析为若干 LLMChat chunk。
///
/// HTTP 服务转发路径与管理模式本地路径共用此解析函数，保证两者产出一致。
List<Map<String, dynamic>> parseOpenAiChunk(String dataStr) {
  final out = <Map<String, dynamic>>[];
  try {
    final json = jsonDecode(dataStr) as Map<String, dynamic>;
    final choices = json['choices'];
    if (choices is! List || choices.isEmpty) return out;
    final choice = choices.first;
    final delta = choice is Map ? choice['delta'] : null;
    if (delta is! Map) return out;

    final content = delta['content'];
    if (content is String && content.isNotEmpty) {
      out.add({'content': content});
    }

    final reasoning = delta['reasoning_content'];
    if (reasoning is String && reasoning.isNotEmpty) {
      if (reasoning == mcpExecutingSentinel) {
        // 服务端正在执行 MCP 工具
        out.add({'tool': 'true'});
        out.add({'toolcall': reasoning});
      } else {
        out.add({'think': reasoning});
      }
    }

    final toolCalls = delta['tool_calls'];
    if (toolCalls is List && toolCalls.isNotEmpty) {
      out.add({'toolcall': jsonEncode(toolCalls)});
    }
  } catch (_) {}
  return out;
}
