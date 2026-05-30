import 'dart:convert';
import 'package:chathub/models/chat/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat/chat_session.dart';
import '../models/bigmodel/chat_model.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';

class SessionController extends GetxController {
  var sessions = <ChatSession>[].obs;
  var currentSession = Rxn<ChatSession>();

  Future<void> setSessions(List<ChatSession> newSessions) async {
    sessions.value = newSessions;
    if (newSessions.isNotEmpty && currentSession.value == null) {
      currentSession.value = newSessions.first;
    }
    await _persistSessions();
  }

  Future<void> setCurrentSession(ChatSession? session) async {
    currentSession.value = session;
    await _persistCurrentSession();
  }

  /// 新增会话并持久化
  Future<void> addSession(ChatSession session) async {
    sessions.add(session);
    currentSession.value = session;

    await _persistCurrentSession();
    await _persistSessions();
  }

  /// 更新会话并持久化
  Future<void> updateSession(ChatSession updatedSession) async {
    return Future.microtask(() async {
      final idx = sessions.indexWhere(
        (s) => s.sessionId == updatedSession.sessionId,
      );
      if (idx != -1) {
        sessions[idx] = updatedSession;
        await _persistSessions();
      }
      if (currentSession.value?.sessionId == updatedSession.sessionId) {
        currentSession.value = updatedSession;
        await _persistCurrentSession();
      }
    });
  }

  /// 更新消息并持久化
  Future<void> updateMessage(ChatMessage updateMessage) async {
    return Future.microtask(() async {
      final sessionIndex = sessions.indexWhere(
        (s) => s.sessionId == updateMessage.sessionId,
      );
      if (sessionIndex == -1) return;

      final session = sessions[sessionIndex];
      final messageIndex = session.messages.indexWhere(
        (m) => m.msgId == updateMessage.msgId,
      );
      if (messageIndex == -1) return;

      session.messages[messageIndex] = updateMessage;
      sessions[sessionIndex] = session;

      if (currentSession.value?.sessionId == session.sessionId) {
        currentSession.value = session;
        await _persistCurrentSession();
      }
      await _persistSessions();
    });
  }

  /// 删除消息
  Future<void> deleteMessage(ChatMessage message) async {
    return Future.microtask(() async {
      final sessionIndex = sessions.indexWhere(
        (s) => s.sessionId == message.sessionId,
      );
      if (sessionIndex == -1) return;

      final session = sessions[sessionIndex];
      final messageIndex = session.messages.indexWhere(
        (m) => m.msgId == message.msgId,
      );
      if (messageIndex == -1) return;

      session.messages.removeAt(messageIndex);
      sessions[sessionIndex] = session;

      if (currentSession.value?.sessionId == session.sessionId) {
        currentSession.value = session;
        await _persistCurrentSession();
      }
      await _persistSessions();
    });
  }

  /// 切换到指定会话并持久化
  Future<void> switchToSession(String sessionId) async {
    final targetIndex = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (targetIndex >= 0 && targetIndex < sessions.length) {
      currentSession.value = sessions[targetIndex];
      await _persistCurrentSession();
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

    // 从 Isar 中删除
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final entity = await isar.isarChatSessions.getBySessionId(sessionId);
        if (entity != null) {
          await isar.isarChatSessions.delete(entity.id);
        }
      });
    } catch (e) {
      debugPrint('从 Isar 删除会话失败: $e');
    }

    await _persistCurrentSession();
    await _persistSessions();
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

        if (session.chatModel?.modelId == updatedModel.modelId) {
          sessions[i] = session.copyWith(chatModel: updatedModel);
          hasUpdates = true;
          updatedCount++;

          if (currentSession.value?.sessionId == session.sessionId) {
            currentSession.value = sessions[i];
          }
        }
      }

      if (hasUpdates) {
        await _persistSessions();
        await _persistCurrentSession();
        debugPrint('已同步更新 $updatedCount 个会话的模型设置: ${updatedModel.name}');
      }
    });
  }

  /// 更新会话消息并持久化
  Future<void> updateSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    return Future.microtask(() async {
      final idx = sessions.indexWhere((s) => s.sessionId == sessionId);
      if (idx != -1) {
        sessions[idx] = sessions[idx].copyWith(messages: messages);
        if (currentSession.value?.sessionId == sessionId) {
          currentSession.value = sessions[idx];
        }
        await _persistCurrentSession();
        await _persistSessions();
      }
    });
  }

  /// 清空所有会话并持久化
  Future<void> clearAllSessions() async {
    sessions.clear();
    currentSession.value = null;
    await _persistSessions();
    await _persistCurrentSession();
  }

  /// 加载所有会话和当前会话
  Future<void> loadAll() async {
    try {
      final isar = IsarService.instance.isar;

      // 加载所有 Isar 会话
      final isarSessions =
          await isar.isarChatSessions.buildQuery<IsarChatSession>().findAll();

      final List<ChatSession> loaded = [];
      ChatSession? current;

      for (final entity in isarSessions) {
        final session = _isarToChatSession(entity);
        loaded.add(session);
        if (entity.isCurrent) {
          current = session;
        }
      }

      // 按创建时间排序
      loaded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      sessions.value = loaded;
      currentSession.value = current;
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
  }

  // ==================== 内部持久化方法 ====================

  Future<void> _persistSessions() async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        // 清除所有旧数据
        await isar.isarChatSessions.clear();
        // 写入所有会话
        for (final session in sessions) {
          final entity = _chatSessionToIsar(session);
          // 标记当前会话
          entity.isCurrent =
              currentSession.value?.sessionId == session.sessionId;
          await isar.isarChatSessions.put(entity);
        }
      });
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }

  Future<void> _persistCurrentSession() async {
    try {
      if (currentSession.value == null) return;
      final isar = IsarService.instance.isar;
      final currentId = currentSession.value!.sessionId;

      await isar.writeTxn(() async {
        // 清除所有 isCurrent 标记
        final all = await isar.isarChatSessions.buildQuery<IsarChatSession>().findAll();
        for (final s in all) {
          if (s.isCurrent) {
            s.isCurrent = false;
            await isar.isarChatSessions.put(s);
          }
        }
        // 设置当前会话
        final entity = await isar.isarChatSessions
            .getBySessionId(currentId);
        if (entity != null) {
          // 同时更新 session 数据
          final updated = _chatSessionToIsar(currentSession.value!);
          updated.id = entity.id;
          updated.isCurrent = true;
          await isar.isarChatSessions.put(updated);
        }
      });
    } catch (e) {
      debugPrint('保存当前会话失败: $e');
    }
  }

  // ==================== 转换方法 ====================

  /// ChatSession → IsarChatSession
  IsarChatSession _chatSessionToIsar(ChatSession session) {
    return IsarChatSession()
      ..sessionId = session.sessionId
      ..name = session.name
      ..createdAt = session.createdAt
      ..isFavorite = session.isFavorite
      ..isSending = session.isSending
      ..shouldStopResponse = session.shouldStopResponse
      ..scrollPosition = session.scrollPosition
      ..inputContent = session.inputContent
      ..lastSelectedDirectory = session.lastSelectedDirectory
      ..messagesJson = jsonEncode(
        session.messages.map((m) => m.toJson()).toList(),
      )
      ..chatModelJson =
          session.chatModel != null
              ? jsonEncode(session.chatModel!.toMap())
              : null
      ..mcpServerJson =
          session.mcpServer != null
              ? jsonEncode(session.mcpServer!.toJson())
              : null
      ..skillJson =
          session.skill != null
              ? jsonEncode(session.skill!.toJson())
              : null
      ..attachmentsJson =
          session.attachments.isNotEmpty
              ? jsonEncode(
                session.attachments.map((a) => a.toJson()).toList(),
              )
              : null
      ..sessionQuickCommandsJson =
          session.sessionQuickCommands.isNotEmpty
              ? jsonEncode(
                session.sessionQuickCommands
                    .map((c) => c.toJson())
                    .toList(),
              )
              : null
      ..isCurrent = false; // 由调用方设置
  }

  /// IsarChatSession → ChatSession
  ChatSession _isarToChatSession(IsarChatSession entity) {
    // 解析消息
    List<ChatMessage> messages = [];
    if (entity.messagesJson != null && entity.messagesJson!.isNotEmpty) {
      try {
        final list = jsonDecode(entity.messagesJson!) as List<dynamic>;
        messages = list
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // 解析 ChatModel
    ChatModel? chatModel;
    if (entity.chatModelJson != null && entity.chatModelJson!.isNotEmpty) {
      try {
        final map = jsonDecode(entity.chatModelJson!) as Map<String, dynamic>;
        chatModel = ChatModel.fromMap(map);
      } catch (_) {}
    }

    return ChatSession(
      sessionId: entity.sessionId,
      name: entity.name,
      createdAt: entity.createdAt,
      messages: messages,
      isFavorite: entity.isFavorite,
      isSending: entity.isSending,
      shouldStopResponse: entity.shouldStopResponse,
      scrollPosition: entity.scrollPosition,
      inputContent: entity.inputContent,
      lastSelectedDirectory: entity.lastSelectedDirectory,
      chatModel: chatModel,
      // mcpServer, skill, attachments, sessionQuickCommands 暂不还原
      // 可在后续需要时补充
    );
  }
}
