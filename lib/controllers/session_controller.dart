import 'package:llmate/models/chat/message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/database.dart';
import '../models/chat/session.dart';
import '../models/model.dart';

import './model_controller.dart';
import './mcp_controller.dart';
import './message_controller.dart';

class SessionController extends GetxController {
  var sessions = <ChatSession>[].obs;
  var currentSession = Rxn<ChatSession>();

  /// 会话存储已迁移至 Drift / SQLite（单例 [appDatabase]，~/.llmate/llmate.sqlite）

  /// 用新的完整列表替换内存列表，并逐条 upsert 每个会话到数据库。
  ///
  /// 与 MessageController 原则一致：多条会话的持久化通过逐条 upsert
  /// 完成，不再整体替换后删除旧记录。
  Future<void> setSessions(List<ChatSession> newSessions) async {
    sessions.value = newSessions;
    if (newSessions.isNotEmpty && currentSession.value == null) {
      currentSession.value = newSessions.first;
    }
    await _persistSessions();
  }

  Future<void> setCurrentSession(ChatSession? session) async {
    if (session == null) {
      currentSession.value = null;
      return;
    }

    ChatSession s = session;
    bool updated = false;

    // 懒加载：如果消息为空，从文件加载
    if (s.messages.isEmpty) {
      final messages = await loadMessages(s.sessionId);
      if (messages.isNotEmpty) {
        s = s.copyWith(messages: messages);
        updated = true;
      }
    }

    // 根据 modelId 动态重新加载 chatModel
    if (s.modelId != null && s.modelId!.isNotEmpty) {
      try {
        final modelController = Get.find<ModelController>();
        final m = await modelController.getModel(s.modelId!);
        if (m != null) {
          s = s.copyWith(chatModel: m);
          updated = true;
        }
      } catch (_) {}
    }

    if (updated) {
      final idx = sessions.indexWhere((ss) => ss.sessionId == s.sessionId);
      if (idx != -1) {
        sessions[idx] = s;
      }
    }

    currentSession.value = s;
    await _persistSessionAndCurrent(s, isCurrent: true);
  }

  /// 新增会话并持久化
  Future<void> addSession(ChatSession session) async {
    sessions.add(session);
    currentSession.value = session;
    await _persistSessionAndCurrent(session, isCurrent: true);
  }

  /// 更新会话并持久化
  Future<void> updateSession(ChatSession updatedSession) async {
    // 自动计算计费信息
    updatedSession = _recalculateBilling(updatedSession);

    final idx = sessions.indexWhere(
      (s) => s.sessionId == updatedSession.sessionId,
    );
    if (idx != -1) {
      sessions[idx] = updatedSession;
    }
    final isCurrent =
        currentSession.value?.sessionId == updatedSession.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    if (idx != -1 || isCurrent) {
      await _persistSessionAndCurrent(updatedSession, isCurrent: isCurrent);
    }
  }

  /// 自动计算会话的累计计费信息（Token 统计，费用由 ChatSession.totalCost getter 实时计算）
  ChatSession _recalculateBilling(ChatSession session) {
    // 如果消息列表为空（懒加载未完成），保留现有的 token 值，避免覆盖为 0
    if (session.messages.isEmpty) return session;

    int inputTotal = 0;
    int outputTotal = 0;

    for (final msg in session.messages) {
      if (msg.promptTokens != null) inputTotal += msg.promptTokens!;
      if (msg.completionTokens != null) outputTotal += msg.completionTokens!;
    }

    // 只有值发生变化时才创建新对象
    if (inputTotal != session.promptTokens ||
        outputTotal != session.completionTokens) {
      return session.copyWith(
        promptTokens: inputTotal,
        completionTokens: outputTotal,
      );
    }
    return session;
  }

  /// 合并持久化：会话元数据（SQLite）+ 消息（委托 MessageController）
  Future<void> _persistSessionAndCurrent(
    ChatSession updatedSession, {
    required bool isCurrent,
  }) async {
    try {
      // === 1. 持久化所有会话元数据到 SQLite（逐条 upsert）===
      await _persistSessions();
      // 消息由 MessageController 以单条增删改方式落盘，此处不再批量写入。
    } catch (e) {
      debugPrint('合并持久化失败: $e');
    }
  }

  /// 更新消息并持久化（消息落盘委托给 MessageController）
  Future<void> updateMessage(ChatMessage updateMessage) async {
    final sessionIndex = sessions.indexWhere(
      (s) => s.sessionId == updateMessage.sessionId,
    );
    if (sessionIndex == -1) return;

    final session = sessions[sessionIndex];
    final messageIndex = session.messages.indexWhere(
      (m) => m.msgId == updateMessage.msgId,
    );
    if (messageIndex == -1) return;

    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages[messageIndex] = updateMessage;
    final updatedSession = session.copyWith(messages: newMessages);
    sessions[sessionIndex] = updatedSession;

    final isCurrent = currentSession.value?.sessionId == session.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    await MessageController.instance.updateMessage(updateMessage);
  }

  /// 删除消息（会话内存更新 + 消息落盘委托给 MessageController）
  Future<void> deleteMessage(ChatMessage message) async {
    final sessionIndex = sessions.indexWhere(
      (s) => s.sessionId == message.sessionId,
    );
    if (sessionIndex == -1) return;

    final session = sessions[sessionIndex];
    final messageIndex = session.messages.indexWhere(
      (m) => m.msgId == message.msgId,
    );
    if (messageIndex == -1) return;

    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages.removeAt(messageIndex);
    final updatedSession = session.copyWith(messages: newMessages);
    sessions[sessionIndex] = updatedSession;

    final isCurrent = currentSession.value?.sessionId == session.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    await MessageController.instance.deleteMessage(message);
  }

  /// 切换到指定会话并持久化
  Future<void> switchToSession(String sessionId) async {
    await McpController.instance.closeAllClients();

    final targetIndex = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (targetIndex >= 0 && targetIndex < sessions.length) {
      ChatSession target = sessions[targetIndex];

      // 懒加载：确保消息已加载再持久化，防止空列表覆盖磁盘数据
      if (target.messages.isEmpty) {
        final messages = await loadMessages(target.sessionId);
        if (messages.isNotEmpty) {
          target = target.copyWith(messages: messages);
          sessions[targetIndex] = target;
        }
      }

      // 根据 modelId 动态重新加载 chatModel
      if (target.modelId != null && target.modelId!.isNotEmpty) {
        try {
          final modelController = Get.find<ModelController>();
          final m = await modelController.getModel(target.modelId!);
          if (m != null) {
            target = target.copyWith(chatModel: m);
            sessions[targetIndex] = target;
          }
        } catch (_) {}
      }

      currentSession.value = target;
      McpController.instance.initForSession(target);
      await _persistSessionAndCurrent(target, isCurrent: true);
    }
  }

  /// 删除会话并持久化
  Future<void> deleteSession(String sessionId) async {
    final index = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (index < 0 || index >= sessions.length) return;
    final sessionToDelete = sessions[index];
    sessions.removeAt(index);

    if (currentSession.value?.sessionId == sessionToDelete.sessionId) {
      if (sessions.isEmpty) {
        currentSession.value = null;
      } else if (index > 0) {
        currentSession.value = sessions[index - 1];
      } else {
        currentSession.value = sessions[0];
      }
    }

    // 从文件系统删除消息并清理会话目录（memory/mcp/business 等，由 MessageController 负责）
    try {
      await MessageController.instance.deleteMessagesBySession(sessionId);
    } catch (e) {
      debugPrint('删除会话失败: $e');
    }

    // 从 SQLite 删除
    try {
      await appDatabase.deleteSessionRow(sessionId);
    } catch (e) {
      debugPrint('删除会话 DB 失败: $e');
    }
  }

  /// 收藏/取消收藏会话并持久化
  Future<void> toggleFavoriteSession(int index) async {
    return Future.microtask(() async {
      if (index < 0 || index >= sessions.length) return;
      final session = sessions[index];
      final newFavoriteStatus = !session.isFavorite;
      sessions[index] = session.copyWith(isFavorite: newFavoriteStatus);
      await _persistSessions();
    });
  }

  /// 更新所有使用特定模型的会话
  Future<void> updateModelInSessions(ChatModel updatedModel) async {
    return Future.microtask(() async {
      bool hasUpdates = false;
      int updatedCount = 0;

      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];

        if (session.modelId == updatedModel.modelId) {
          sessions[i] = session.copyWith(chatModel: updatedModel);
          hasUpdates = true;
          updatedCount++;

          if (currentSession.value?.sessionId == session.sessionId) {
            currentSession.value = sessions[i];
          }
        }
      }

      if (hasUpdates) {
        final cur = currentSession.value;
        await _persistSessionAndCurrent(
          cur ?? sessions.first,
          isCurrent: cur != null,
        );
        debugPrint('已同步更新 $updatedCount 个会话的模型设置: ${updatedModel.name}');
      }
    });
  }

  /// 清空所有会话并持久化
  Future<void> clearAllSessions() async {
    sessions.clear();
    currentSession.value = null;
    await _persistSessions();
  }

  /// 加载所有会话和当前会话（消息懒加载，从 SQLite 读取）
  Future<void> loadAll() async {
    try {
      List<ChatSession> loaded = await appDatabase.getAllSessions();

      // 解析 chatModel（按 modelId 动态绑定）
      for (int i = 0; i < loaded.length; i++) {
        loaded[i] = await _resolveChatModel(loaded[i]);
      }

      loaded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      sessions.value = loaded;

      final currentId = await appDatabase.getCurrentSessionId();
      final current =
          loaded.where((s) => s.sessionId == currentId).firstOrNull;

      if (current != null) {
        await setCurrentSession(current);
      } else {
        currentSession.value = null;
      }

      // 首次启动（无任何会话）时，自动创建一个默认会话，确保应用有初始配置
      if (sessions.isEmpty) {
        await _seedDefaultSession();
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
  }

  /// 按 modelId 动态解析并返回绑定了 chatModel 的会话（解析失败时原样返回）
  Future<ChatSession> _resolveChatModel(ChatSession s) async {
    if (s.modelId == null || s.modelId!.isEmpty) return s;
    try {
      final modelController = Get.find<ModelController>();
      final m = await modelController.getModel(s.modelId!);
      if (m != null) return s.copyWith(chatModel: m);
    } catch (_) {}
    return s;
  }

  /// 首次启动时创建一个默认会话（含一条欢迎消息），并持久化到 db。
  ///
  /// 默认会话会尝试绑定一个可用模型（优先 DeepSeekR1，否则取第一个），
  /// 与首页「新建会话」的模型匹配逻辑保持一致。
  Future<void> _seedDefaultSession() async {
    try {
      // 复用首页的模型匹配逻辑：优先 DeepSeekR1，否则第一个可用模型
      ChatModel? selectedModel;
      try {
        final modelController = Get.find<ModelController>();
        final available = await modelController.loadModels();
        if (available.isNotEmpty) {
          selectedModel = available.firstWhere(
            (m) => m.name == 'DeepSeekR1',
            orElse: () => available.first,
          );
        }
      } catch (_) {
        // ModelController 未初始化时跳过模型绑定
      }

      final welcomeMessage = ChatMessage(
        msgId: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.bot,
        content:
            '👋 你好，我是 LLMate！\n\n我可以帮你写代码、回答问题、分析文件，还能调用 MCP 工具完成更复杂的任务。\n\n直接下方输入框开始对话吧～',
        timestamp: DateTime.now(),
        sessionId: null, // 创建会话后回填
      );

      final defaultSession = ChatSession(
        sessionId: ChatSession.generateSessionId(),
        name: '新对话',
        createdAt: DateTime.now(),
        messages: [welcomeMessage.copyWith(sessionId: null)],
        chatModel: selectedModel,
        inputContent: '',
      );

      // 回填欢迎消息的 sessionId 并加入会话
      final sessionWithWelcome = defaultSession.copyWith(
        messages: [
          welcomeMessage.copyWith(sessionId: defaultSession.sessionId),
        ],
      );

      await addSession(sessionWithWelcome);
      // 持久化欢迎消息（单条落盘，替代原有的批量消息写入）
      final welcome = sessionWithWelcome.messages.firstOrNull;
      if (welcome != null) {
        await MessageController.instance.addMessage(welcome);
      }
      debugPrint('🌱 已创建默认会话（首次启动）');
    } catch (e) {
      debugPrint('⚠️ 创建默认会话失败: $e');
    }
  }

  /// 为指定会话加载消息（委托给 MessageController）
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    return MessageController.instance.loadMessages(sessionId);
  }

  // ==================== 内部持久化方法 ====================

  Future<void> _persistSessions() async {
    // 同步写入 SQLite（逐条 upsert，不再整体替换）
    try {
      await appDatabase.persistSessions(
        sessions,
        currentId: currentSession.value?.sessionId,
      );
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }

  /// 从 SQLite 读取单条会话元数据（并已解析 chatModel）
  Future<ChatSession?> _getSessionFromDb(String sid) async {
    try {
      final s = await appDatabase.getSession(sid);
      if (s == null) return null;
      return await _resolveChatModel(s);
    } catch (_) {
      return null;
    }
  }

  /// 根据消息ID查找会话
  Future<ChatSession?> findSessionByMessageId(String messageId) async {
    // 先从内存查找
    for (final session in sessions) {
      if (session.messages.any((msg) => msg.msgId == messageId)) {
        return session;
      }
    }

    // 从 SQLite（会话元数据 + 消息表）搜索
    try {
      final all = await appDatabase.getAllSessions();
      for (final session in all) {
        final messagesData =
            await MessageController.instance.loadMessages(session.sessionId);
        if (messagesData.any((m) => m.msgId == messageId)) {
          return await _getSessionFromDb(session.sessionId);
        }
      }
    } catch (e) {
      debugPrint('从 DB 搜索会话失败: $e');
    }

    return null;
  }
}
