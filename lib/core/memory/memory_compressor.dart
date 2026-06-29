import 'package:flutter/foundation.dart';
import '../llm/llm_client.dart';
import '../../models/chat/chat_session.dart';
import '../../models/chat/memory_turn.dart';

/// 记忆压缩服务
///
/// 将会话记忆发给 LLM 进行总结压缩，生成压缩摘要。
class MemoryCompressor {
  /// 压缩记忆
  ///
  /// 将 [compressedMemory]（已有压缩摘要）+ [memory]（最近对话记忆）发给 LLM，
  /// 生成一份合并后的压缩摘要。
  ///
  /// 返回压缩后的文字摘要，失败返回 null。
  static Future<String?> compress({
    required ChatSession session,
    required String? compressedMemory,
    required List<MemoryTurn> memory,
  }) async {
    if (memory.isEmpty) return compressedMemory;

    // 没有模型无法压缩
    if (session.chatModel == null) return null;

    // 构建压缩提示词
    final prompt = _buildCompressPrompt(compressedMemory, memory);

    try {
      // 使用 LlmClient 发送非流式请求进行压缩
      final client = LlmClient(session);
      final response = await client.sendCompressRequest(prompt);

      if (response != null && response.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '🧠 [MemoryCompressor] 压缩完成，'
            '原记忆 ${memory.length} 条 (${MemoryTurn.roundCount(memory)} 轮) → '
            '压缩摘要 ${response.length} 字',
          );
        }
        return response;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('🧠 [MemoryCompressor] 压缩失败: $e');
      return null;
    }
  }

  /// 构建压缩提示词
  static String _buildCompressPrompt(
    String? compressedMemory,
    List<MemoryTurn> memory,
  ) {
    final buf = StringBuffer();

    buf.writeln('你是一个记忆压缩助手。请将以下对话历史总结成一段简洁的摘要，');
    buf.writeln('保留关键信息：用户偏好、重要决策、待办事项、讨论主题等。');
    buf.writeln('使用中文输出，控制在 500 字以内。\n');

    if (compressedMemory != null && compressedMemory.isNotEmpty) {
      buf.writeln('## 之前的记忆摘要');
      buf.writeln(compressedMemory);
      buf.writeln();
    }

    buf.writeln('## 最近的对话');
    for (int i = 0; i < memory.length; i++) {
      final turn = memory[i];
      final label = turn.role == 'user' ? '👤 用户' : '🤖 助手';
      buf.writeln('$label: ${turn.content}');
    }

    buf.writeln();
    buf.writeln('请输出合并后的记忆摘要：');

    return buf.toString();
  }
}
