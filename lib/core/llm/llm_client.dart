import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/model.dart';
import '../../models/chat/session.dart';
import '../../models/chat/message.dart';
import 'common/openai_provider.dart';
import './common/message_builder.dart';
import './modes/mode_utils.dart';
import 'common/stream_http_service.dart';

/// LLM 客户端（聊天窗口侧代理）
///
/// 负责把会话消息组装好并转发给本机会话 HTTP 服务。
/// 会话模式：工具注入 / 工具执行 / 会话持久化 / 用量统计均由 HTTP 服务统一处理；
/// 管理模式：管理工具 schema 由客户端注入、服务端视作第三方透传回来，
/// 由客户端本地执行并回填，继续多轮请求。
class LlmClient {
  final ChatSession _session;
  final OpenAiProvider _provider;
  bool _cancelled = false;

  LlmClient(ChatSession session)
    : _session = session,
      _provider = OpenAiProvider() {
    _provider.configure(session.chatModel!);
  }

  ChatModel? get model => _session.chatModel;

  void dispose() {}

  void configure(ChatModel model) => _provider.configure(model);

  Future<bool> validateConfiguration() => _provider.validateConfiguration();

  String buildSystemPrompt({ChatSession? session}) {
    return MessageBuilder.buildSystemPrompt(model: model, session: session);
  }

  /// 发送消息并获取流式响应。
  ///
  /// 始终经由本机会话 HTTP 服务转发，复用服务侧中间件
  /// （鉴权 / 配额 / 模型工具注入 / 审计 / 用量统计）。
  /// 会话模式的工具执行由服务端完成；管理模式的工具由客户端本地执行。
  Stream<Map<String, dynamic>> llmChat(ChatMessage userMessage) async* {
    _cancelled = false;

    if (kDebugMode) {
      debugPrint(
        '🧠 [LLMChat] 会话消息数: ${_session.messages.length}, 当前消息ID: ${userMessage.msgId}',
      );
    }

    final messages = await _buildMessages(
      userMessage: userMessage,
      session: _session,
    );

    // 统一经由本机会话 HTTP 服务转发（含管理模式），复用服务侧中间件
    // （鉴权 / 配额 / 模型工具注入 / 审计 / 用量统计）。
    // 管理模式同样走 HTTP：客户端注入管理工具、服务端视作第三方透传，
    // 客户端本地执行并回填，用量不计入统计。
    await for (final chunk in streamViaHttpService(
      session: _session,
      provider: _provider,
      isCancelled: () => _cancelled,
      messages: messages,
    )) {
      yield chunk;
    }
  }

  void cancel() => _cancelled = true;

  // ======================== 消息构建 ========================

  /// 构建发送给 HTTP 服务的消息列表。
  ///
  /// 仅包含会话历史 + 当前用户消息；系统提示词（模型级 / 会话级 / 语言要求等）
  /// 由 HTTP 服务端 [sessionCheckGuard]/[modelCheckGuard]/[languageCheckGuard]
  /// 统一注入，客户端不再组装。
  Future<List<Map<String, dynamic>>> _buildMessages({
    required ChatMessage userMessage,
    required ChatSession session,
  }) async {
    final messages = <Map<String, dynamic>>[];
    // 1. 历史消息
    if (session.messages.isNotEmpty) {
      appendHistoryMessages(messages, session, userMessage);
    }
    // 2. 当前用户消息
    messages.add({'role': 'user', 'content': buildUserContent(userMessage)});
    return messages;
  }
}
