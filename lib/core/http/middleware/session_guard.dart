import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:shelf/shelf.dart';

import '../../../controllers/session_controller.dart';
import '../../../models/chat/chat_session.dart';
import '../../../models/chat/chat_message.dart';
import '../../../models/chat/content_block.dart';
import '../../../models/responses/openai_response.dart' show ToolCall;
import 'audit_guard.dart';

/// 流式请求完成后的数据载体
///
/// 由业务层（_streamDirectProxy）在流结束后通过 [StreamCompleteCallback] 回传。
class StreamCompletionData {
  final String content;
  final Map<String, dynamic> requestBodyMap;
  final ChatSession session;
  final DateTime generationStartTime;
  final int? promptTokens;
  final int? completionTokens;
  final Object? error;

  StreamCompletionData({
    required this.content,
    required this.requestBodyMap,
    required this.session,
    required this.generationStartTime,
    this.promptTokens,
    this.completionTokens,
    this.error,
  });
}

/// 供业务层调用的完成回调
typedef StreamCompleteCallback = void Function(StreamCompletionData data);

/// 会话更新 + 审计补全中间件
///
/// 在流式请求完成后（洋葱模型响应路径）：
/// 1. 更新本地会话：添加用户消息 + AI 回复 + token 统计 + 配额计数 + 计费
/// 2. 触发审计回调补全响应内容
///
/// 通过 `request.context['streamComplete']` 向业务层暴露完成回调。
Handler sessionGuard(Handler innerHandler) {
  return (Request request) async {
    final updatedRequest = request.change(context: {
      ...request.context,
      'streamComplete': (StreamCompletionData data) {
        // 异步执行，不阻塞任何流程
        () async {
          if (data.error != null) {
            debugPrint('❌ [SessionGuard] 流处理失败: ${data.error}');
            final auditCallback =
                request.context['auditCallback'] as AuditCallback?;
            auditCallback?.call(error: 'Stream error: ${data.error}');
          } else {
            // 从 userMessageGuard 中间件中获取预创建的用户消息
            final userMessage =
                request.context['userMessage'] as ChatMessage?;

            _updateSession(
              session: data.session,
              userMessage: userMessage,
              content: data.content,
              generationStartTime: data.generationStartTime,
              promptTokens: data.promptTokens,
              completionTokens: data.completionTokens,
            );

            // 审计回调：补全响应内容
            final auditCallback =
                request.context['auditCallback'] as AuditCallback?;
            auditCallback?.call(responseContent: data.content);
          }
        }();
      },
    });

    return innerHandler(updatedRequest);
  };
}

/// 流结束后更新本地会话：追加 AI 回复消息 + token 统计 + 配额计数 + 计费
///
/// 用户消息已由 [messageGuard] 中间件在请求路径上预创建，通过 [userMessage] 传入。
void _updateSession({
  required ChatSession session,
  ChatMessage? userMessage,
  required String content,
  int? promptTokens,
  int? completionTokens,
  required DateTime generationStartTime,
  List<ToolCall>? toolCalls,
}) {
  try {
    final sessionController = Get.find<SessionController>();
    final now = DateTime.now();

    // 构建工具调用 contentBlocks（如果有）
    List<ContentBlock> contentBlocks = [];
    final extractedToolCalls =
        toolCalls != null && toolCalls.isNotEmpty ? toolCalls : <ToolCall>[];
    for (final tc in extractedToolCalls) {
      final name = tc.function?.name ?? '';
      final args = tc.function?.arguments ?? '';
      contentBlocks.add(
        ContentBlock(type: ContentBlockType.tool, text: '$name\n$args'),
      );
    }

    final totalTokens = (promptTokens ?? 0) + (completionTokens ?? 0);

    // 创建 AI 回复消息（用户消息已由 messageGuard 预创建）
    final botMsgId = '${DateTime.now().millisecondsSinceEpoch}_bot';
    final botMessage = ChatMessage(
      msgId: botMsgId,
      role: MessageRole.bot,
      content: content,
      timestamp: now,
      sessionId: session.sessionId,
      pairedMsgId: userMessage?.msgId,
      contentBlocks: contentBlocks,
      generationStartTime: generationStartTime,
      generationEndTime: now,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens > 0 ? totalTokens : null,
      generationDuration: now.difference(generationStartTime),
    );

    // 更新会话消息列表（用户消息 + AI 回复）
    final newMessages = <ChatMessage>[
      if (userMessage != null) userMessage,
      botMessage,
    ];
    var updatedSession = session.copyWith(messages: [
      ...session.messages,
      ...newMessages,
    ]);

    // 记录一次请求（配额计数）
    updatedSession = updatedSession.recordRequest();

    // updateSession 内部会调用 _recalculateBilling 自动计算费用
    sessionController.updateSession(updatedSession);

    final userPreview =
        userMessage != null
            ? userMessage.content
                .substring(0, userMessage.content.length.clamp(0, 30))
            : '';
    debugPrint(
      '✅ 会话已更新: ${session.sessionId}, '
      '用户消息: "$userPreview", '
      'AI回复: "${content.substring(0, content.length.clamp(0, 30))}", '
      'tokens: prompt=$promptTokens, completion=$completionTokens, total=$totalTokens',
    );
  } catch (e) {
    debugPrint('❌ 更新会话失败: $e');
  }
}
