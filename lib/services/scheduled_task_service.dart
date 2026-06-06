import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../framework/llm_hub.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_session.dart';
import '../models/chat/scheduled_task.dart';

/// 定时任务调度服务
///
/// 每分钟检查所有会话的 cron 表达式，匹配则自动发送预设消息。
class ScheduledTaskService {
  static final ScheduledTaskService _instance = ScheduledTaskService._();
  factory ScheduledTaskService() => _instance;
  ScheduledTaskService._();

  SessionController get _sessionController => Get.find<SessionController>();

  Timer? _timer;
  bool _isRunning = false;

  /// 启动调度器（每分钟检查一次）
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    debugPrint('⏰ 定时任务调度器已启动');
  }

  /// 停止调度器
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    debugPrint('⏰ 定时任务调度器已停止');
  }

  /// 每分钟触发一次，检查所有会话的定时任务
  Future<void> _tick() async {
    final now = DateTime.now();
    final sessions = List<ChatSession>.from(_sessionController.sessions);

    for (final session in sessions) {
      if (session.scheduledTask == null) continue;
      if (session.chatModel == null) continue;

      final task = session.scheduledTask!;
      if (!task.enabled) continue;
      if (!_matchesCron(task.cronExpression, now)) continue;

      debugPrint(
        '⏰ 定时任务触发: 会话=${session.name}, cron=${task.cronExpression}, 消息="${_truncate(task.message)}"',
      );

      // 更新最后触发时间
      final updatedTask = task.copyWith(
        lastTriggeredAt: now,
      );
      final updatedSession = session.copyWith(
        scheduledTask: updatedTask,
      );
      _sessionController.updateSession(updatedSession);

      // 异步执行发送（不阻塞其他任务检查）
      _executeTask(session, task);
    }
  }

  /// 执行单个定时任务：发送消息并获取 AI 回复
  Future<void> _executeTask(ChatSession session, ScheduledTask task) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 创建用户消息
      final userMessage = ChatMessage(
        msgId: '${timestamp}_cron_user',
        role: MessageRole.user,
        content: task.message,
        timestamp: DateTime.now(),
        sessionId: session.sessionId,
      );

      // 添加用户消息到会话
      final updatedMessages = List<ChatMessage>.from(session.messages)
        ..add(userMessage);
      var updatedSession = session.copyWith(
        messages: updatedMessages,
        isSending: true,
      );
      _sessionController.updateSession(updatedSession);

      // 创建 AI 消息占位
      final botMessageId = '${timestamp}_cron_bot';
      final botMessage = ChatMessage(
        msgId: botMessageId,
        role: MessageRole.bot,
        content: '',
        timestamp: DateTime.now(),
        sessionId: session.sessionId,
      );

      final messagesWithBot = List<ChatMessage>.from(updatedSession.messages)
        ..add(botMessage);
      updatedSession = updatedSession.copyWith(messages: messagesWithBot);
      _sessionController.updateSession(updatedSession);

      // 调用 LLM
      final client = LlmClient(updatedSession);
      String accumulatedContent = '';

      final responseStream = client.LLMChat(userMessage);
      await for (final chunkMap in responseStream) {
        final contentChunk = chunkMap['content'] ?? '';
        final thinkChunk = chunkMap['think'] ?? '';

        if (contentChunk.isNotEmpty || thinkChunk.isNotEmpty) {
          accumulatedContent += contentChunk;

          botMessage.content = accumulatedContent;
          if (thinkChunk.isNotEmpty) {
            botMessage.think += thinkChunk;
          }

          final msgIndex = updatedSession.messages.indexWhere(
            (m) => m.msgId == botMessageId,
          );
          if (msgIndex != -1) {
            final msgs = List<ChatMessage>.from(updatedSession.messages);
            msgs[msgIndex] = botMessage;
            updatedSession = updatedSession.copyWith(messages: msgs);
            _sessionController.updateSession(updatedSession);
          }
        }
      }

      // 完成
      final finalSession = _sessionController.currentSession.value;
      if (finalSession?.sessionId == session.sessionId) {
        _sessionController.updateSession(
          updatedSession.copyWith(isSending: false),
        );
      }
      debugPrint('⏰ 定时任务执行完成: ${_truncate(task.message)}');
    } catch (e) {
      debugPrint('⏰ 定时任务执行失败: $e');
      // 确保重置发送状态
      try {
        final finalSession = _sessionController.currentSession.value;
        if (finalSession?.isSending == true) {
          _sessionController.updateSession(
            finalSession!.copyWith(isSending: false),
          );
        }
      } catch (_) {}
    }
  }

  /// 简单的 cron 匹配器（5字段：分 时 日 月 周）
  static bool _matchesCron(String cronExpression, DateTime now) {
    try {
      final parts = cronExpression.trim().split(RegExp(r'\s+'));
      if (parts.length != 5) return false;
      return _matchField(parts[0], now.minute, 0, 59) &&
          _matchField(parts[1], now.hour, 0, 23) &&
          _matchField(parts[2], now.day, 1, 31) &&
          _matchField(parts[3], now.month, 1, 12) &&
          _matchField(parts[4], now.weekday % 7, 0, 6); // DateTime.weekday: Mon=1..Sun=7 → 0=Sun..6=Sat
    } catch (_) {
      return false;
    }
  }

  /// 匹配单个 cron 字段
  static bool _matchField(String field, int value, int min, int max) {
    if (field == '*') return true;

    // 逗号分隔：1,2,5
    if (field.contains(',')) {
      return field.split(',').any((part) => _matchField(part.trim(), value, min, max));
    }

    // 步长：*/5 或 0/5
    if (field.contains('/')) {
      final split = field.split('/');
      final base = split[0] == '*' ? 0 : int.tryParse(split[0]) ?? 0;
      final step = int.tryParse(split[1]) ?? 1;
      if (step <= 0) return false;
      return value >= base && (value - base) % step == 0;
    }

    // 范围：1-5
    if (field.contains('-')) {
      final split = field.split('-');
      final start = int.tryParse(split[0]) ?? 0;
      final end = int.tryParse(split[1]) ?? 0;
      return value >= start && value <= end;
    }

    // 精确值
    final exact = int.tryParse(field);
    return exact == value;
  }

  static String _truncate(String text, {int maxLen = 40}) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}
