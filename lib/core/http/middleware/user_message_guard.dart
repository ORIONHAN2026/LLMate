import 'package:shelf/shelf.dart';

import '../../../models/chat/session.dart';
import '../../../models/chat/message.dart';

/// 用户消息创建中间件（请求路径 / 前置处理）
///
/// 在模型替换和工具注入完成后，从增强后的请求体中提取最后一条
/// 用户消息，创建 [ChatMessage] 并注入 `request.context['userMessage']`，
/// 供下游 sessionGuard 在流结束后关联追加到会话。
Handler userMessageGuard(Handler innerHandler) {
  return (Request request) async {
    final session = request.context['session'] as ChatSession;
    final body = request.context['body'] as Map<String, dynamic>;

    // 从请求体 messages 中提取最后一条用户消息
    final messages = body['messages'] as List?;
    final lastUserMsg = messages?.lastOrNull as Map<String, dynamic>?;
    final userContent = lastUserMsg?['content'] as String? ?? '';

    final now = DateTime.now();
    final userMsgId = '${now.millisecondsSinceEpoch}_user';
    final userMessage = ChatMessage(
      msgId: userMsgId,
      role: MessageRole.user,
      content: userContent,
      timestamp: now,
      sessionId: session.sessionId,
    );

    final updatedRequest = request.change(
      context: {...request.context, 'userMessage': userMessage},
    );

    return innerHandler(updatedRequest);
  };
}
