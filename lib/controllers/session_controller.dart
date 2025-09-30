import 'package:chathub/models/chat/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/chat/chat_session.dart';
import '../models/bigmodel/chat_model.dart';

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

  // 新增会话并持久化（会话列表+当前会话）
  Future<void> addSession(ChatSession session) async {
    sessions.add(session);
    currentSession.value = session;

    await _persistCurrentSession();
    await _persistSessions();
  }

  // 更新会话并持久化
  Future<void> updateSession(ChatSession updatedSession) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
    // 这比 addPostFrameCallback 更及时，不会导致数据丢失
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

  // 更新消息并持久化
  Future<void> updateMessage(ChatMessage updateMessage) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
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

      // 如果当前会话是被更新的会话，更新 currentSession
      if (currentSession.value?.sessionId == session.sessionId) {
        currentSession.value = session;
        await _persistCurrentSession();
      }
      await _persistSessions();
    });
  }

  //删除消息
  Future<void> deleteMessage(ChatMessage message) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
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

      // 如果当前会话是被更新的会话，更新 currentSession
      if (currentSession.value?.sessionId == session.sessionId) {
        currentSession.value = session;
        await _persistCurrentSession();
      }
      await _persistSessions();
    });
  }

  // 切换到指定会话并持久化
  Future<void> switchToSession(String sessionId) async {
    final targetIndex = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (targetIndex >= 0 && targetIndex < sessions.length) {
      currentSession.value = sessions[targetIndex];
      await _persistCurrentSession();
    }
  }

  // 删除会话并持久化
  Future<void> deleteSession(String sessionId) async {
    final index = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (index < 0 || index >= sessions.length) return;
    final sessionToDelete = sessions[index];
    sessions.removeAt(index);
    // 如果删除的是当前会话，需要调整当前会话
    if (currentSession.value?.sessionId == sessionToDelete.sessionId) {
      if (sessions.isEmpty) {
        currentSession.value = null;
      } else if (index > 0) {
        currentSession.value = sessions[index - 1];
      } else {
        currentSession.value = sessions[0];
      }
    }
    await _persistCurrentSession();
    await _persistSessions();
  }

  // 收藏/取消收藏会话并持久化
  Future<void> toggleFavoriteSession(int index) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
    return Future.microtask(() async {
      if (index < 0 || index >= sessions.length) return;
      final session = sessions[index];
      final newFavoriteStatus = !session.isFavorite;
      sessions[index] = session.copyWith(isFavorite: newFavoriteStatus);
      await _persistSessions();
    });
  }

  // 更新所有使用特定模型的会话
  Future<void> updateModelInSessions(ChatModel updatedModel) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
    return Future.microtask(() async {
      bool hasUpdates = false;
      int updatedCount = 0;

      // 遍历所有会话，找到使用该模型的会话并更新
      for (int i = 0; i < sessions.length; i++) {
        final session = sessions[i];

        // 检查会话是否使用了该模型
        if (session.chatModel?.modelId == updatedModel.modelId) {
          // 更新会话中的模型信息
          sessions[i] = session.copyWith(chatModel: updatedModel);
          hasUpdates = true;
          updatedCount++;

          // 如果是当前会话，也要更新当前会话引用
          if (currentSession.value?.sessionId == session.sessionId) {
            currentSession.value = sessions[i];
          }
        }
      }

      // 如果有更新，保存数据
      if (hasUpdates) {
        await _persistSessions();
        await _persistCurrentSession();

        // 打印调试信息
        debugPrint('已同步更新 $updatedCount 个会话的模型设置: ${updatedModel.name}');
      }
    });
  }

  // 更新会话消息并持久化
  Future<void> updateSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    // 使用 Future.microtask 来避免在构建期间直接修改响应式变量
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

  // 清空所有会话并持久化
  Future<void> clearAllSessions() async {
    sessions.clear();
    currentSession.value = null;
    await _persistSessions();
    await _persistCurrentSession();
  }

  // 加载所有会话和当前会话（不再依赖外部 SessionStorageService）
  Future<void> loadAll() async {
    // 加载所有会话
    List<ChatSession> loaded = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('chat_sessions');
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        loaded =
            jsonList
                .map(
                  (json) => ChatSession.fromJson(json as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
    setSessions(loaded);
    // 加载当前会话
    ChatSession? session;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('chat_current_session');
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        session = ChatSession.fromJson(json);
      }
    } catch (e) {
      debugPrint('加载当前会话失败: $e');
    }
    setCurrentSession(session);
  }

  // 内部统一持久化方法（不再依赖外部 SessionStorageService）

  Future<void> _persistSessions() async {
    // 保存所有会话
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = sessions.map((session) => session.toJson()).toList();
      final jsonString = jsonEncode(sessionsJson);
      final result = await prefs.setString('chat_sessions', jsonString);
      if (result != true) {
        debugPrint('保存会话失败: setString 返回 $result');
      }
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
    // 保存当前会话
    if (currentSession.value != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(currentSession.value!.toJson());
        final result = await prefs.setString(
          'chat_current_session',
          jsonString,
        );
        if (result != true) {
          debugPrint('保存当前会话失败: setString 返回 $result');
        }
      } catch (e) {
        debugPrint('保存当前会话失败: $e');
      }
    }
  }

  Future<void> _persistCurrentSession() async {
    // 保存当前会话
    if (currentSession.value != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(currentSession.value!.toJson());
        final result = await prefs.setString(
          'chat_current_session',
          jsonString,
        );
        if (result != true) {
          debugPrint('保存当前会话失败: setString 返回 $result');
        }
      } catch (e) {
        debugPrint('保存当前会话失败: $e');
      }
    }
  }
}
