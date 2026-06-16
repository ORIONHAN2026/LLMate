import 'dart:convert';
import 'package:llmwork/models/chat/chat_message.dart';
import 'package:llmwork/models/chat/scheduled_task.dart';
import 'package:llmwork/models/chat/memory_turn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../models/chat/chat_session.dart';
import '../models/bigmodel/chat_model.dart';
import '../storage/isar_models.dart';
import '../storage/isar_service.dart';
import '../services/mcp_service.dart';
import '../services/skill_service.dart';
import 'model_controller.dart';
import 'mcp_controller.dart';

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
    if (session == null) {
      currentSession.value = null;
      await _persistCurrentSession();
      return;
    }

    // 使用非空局部变量，允许后续 copyWith 重新赋值
    ChatSession s = session;
    bool updated = false;

    // 懒加载：如果消息为空，从 IsarChatMessage 加载
    if (s.messages.isEmpty) {
      final messages = await loadMessages(s.sessionId);
      if (messages.isNotEmpty) {
        s = s.copyWith(messages: messages);
        updated = true;
      }
    }

    // 每次进入会话时，根据 modelId 动态重新加载 chatModel
    if (s.modelId != null && s.modelId!.isNotEmpty) {
      try {
        final modelController = Get.find<ModelController>();
        final m = modelController.models.firstWhere(
          (m) => m.modelId == s.modelId,
        );
        s = s.copyWith(chatModel: m);
        updated = true;
      } catch (_) {
        // 模型已被删除，chatModel 保持为 null
      }
    }

    // 根据 mcpId 动态解析 mcp
    if (s.mcpId != null && s.mcpId!.isNotEmpty) {
      final mcpController = Get.find<McpController>();
      await mcpController.ensureLoaded();
      final mcp = mcpController.getMcpById(s.mcpId!);
      if (mcp != null) {
        s = s.copyWith(mcp: mcp);
        updated = true;
      }
    }

    // 根据 skillId 动态解析 skill
    if (s.skillId != null && s.skillId!.isNotEmpty) {
      await SkillService.ensureLoaded();
      final skillObj = SkillService.getSkillById(s.skillId!);
      if (skillObj != null) {
        s = s.copyWith(skill: skillObj);
        updated = true;
      }
    }

    // 同步更新 sessions 列表中的对应项
    if (updated) {
      final idx = sessions.indexWhere((ss) => ss.sessionId == s.sessionId);
      if (idx != -1) {
        sessions[idx] = s;
      }
    }

    // 会话打开时预初始化 MCP 连接
    // McpService.initForSession(s);

    currentSession.value = s;
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
  }

  /// 更新消息并持久化
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

    // 创建新的 messages 列表，确保 RxList 能检测到变化
    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages[messageIndex] = updateMessage;
    sessions[sessionIndex] = session.copyWith(messages: newMessages);

    if (currentSession.value?.sessionId == session.sessionId) {
      currentSession.value = sessions[sessionIndex];
      await _persistCurrentSession();
    }
    await _persistSessions();
  }

  /// 删除消息
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

    // 创建新的 messages 列表（不含被删除的消息），确保 RxList 能检测到变化
    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages.removeAt(messageIndex);
    sessions[sessionIndex] = session.copyWith(messages: newMessages);

    if (currentSession.value?.sessionId == session.sessionId) {
      currentSession.value = sessions[sessionIndex];
      await _persistCurrentSession();
    }
    await _persistSessions();
  }

  /// 切换到指定会话并持久化（不阻塞 UI）
  Future<void> switchToSession(String sessionId) async {
    // 切换会话时关闭所有 MCP 连接
    await McpService.closeAllClients();

    final targetIndex = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (targetIndex >= 0 && targetIndex < sessions.length) {
      currentSession.value = sessions[targetIndex];
      // 新会话有 MCP 则立即预初始化
      McpService.initForSession(sessions[targetIndex]);
      // 持久化放到微任务中异步执行，不阻塞 UI 切换
      Future.microtask(() => _persistCurrentSession());
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

    // 从 Isar 中删除会话及关联消息
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        // 删除关联消息
        final sessionMessages = await isar.isarChatMessages
            .where()
            .sessionIdEqualTo(sessionId)
            .sortByTimestamp()
            .findAll();
        if (sessionMessages.isNotEmpty) {
          await isar.isarChatMessages
              .deleteAll(sessionMessages.map((m) => m.id).toList());
        }
        // 删除会话本身
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

  /// 加载所有会话和当前会话（消息懒加载：仅加载会话元数据）
  Future<void> loadAll() async {
    try {
      final isar = IsarService.instance.isar;

      // 加载所有 Isar 会话（不含消息，消息独立存储）
      final isarSessions =
          await isar.isarChatSessions.buildQuery<IsarChatSession>().findAll();

      final List<ChatSession> loaded = [];
      ChatSession? current;

      for (final entity in isarSessions) {
        // 轻量加载：不含消息
        final session = _isarToChatSession(entity, loadMessages: false);
        loaded.add(session);
        if (entity.isCurrent) {
          current = session;
        }
      }

      // 按创建时间排序
      loaded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      sessions.value = loaded;

      // 通过 setCurrentSession 解析 mcp/skill/model，并加载当前会话的消息
      if (current != null) {
        await setCurrentSession(current);
      } else {
        currentSession.value = null;
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
  }

  /// 为指定会话加载消息（从 IsarChatMessage 集合）
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final isar = IsarService.instance.isar;
      final entities = await isar.isarChatMessages
          .where()
          .sessionIdEqualTo(sessionId)
          .sortByTimestamp()
          .findAll();

      return entities.map((e) {
        try {
          return ChatMessage.fromJson(
            jsonDecode(e.messageJson) as Map<String, dynamic>,
          );
        } catch (_) {
          return null;
        }
      }).whereType<ChatMessage>().toList();
    } catch (e) {
      debugPrint('加载会话消息失败: $e');
      return [];
    }
  }

  // ==================== 内部持久化方法 ====================

  Future<void> _persistSessions() async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        final currentSessionIds = sessions.map((s) => s.sessionId).toSet();
        for (final session in sessions) {
          // 查找已有实体，存在则更新，不存在则新建（避免唯一索引冲突）
          final existing =
              await isar.isarChatSessions.getBySessionId(session.sessionId);
          if (existing != null) {
            _updateIsarSessionFromChatSession(existing, session);
            existing.isCurrent =
                currentSession.value?.sessionId == session.sessionId;
            await isar.isarChatSessions.put(existing);
          } else {
            final entity = _chatSessionToIsar(session);
            entity.isCurrent =
                currentSession.value?.sessionId == session.sessionId;
            await isar.isarChatSessions.put(entity);
          }
        }
        // 再删除不在当前会话列表中的旧数据（避免先删后写导致崩溃丢数据）
        final allEntities =
            await isar.isarChatSessions.buildQuery<IsarChatSession>().findAll();
        for (final entity in allEntities) {
          if (!currentSessionIds.contains(entity.sessionId)) {
            await isar.isarChatSessions.delete(entity.id);
          }
        }
      });
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }

  /// 持久化单个会话的所有消息（先写后删，避免崩溃丢数据）
  Future<void> _persistMessagesForSession(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    try {
      final isar = IsarService.instance.isar;
      await isar.writeTxn(() async {
        // 先写入新消息（查找已有实体，存在则更新，不存在则新建，避免唯一索引冲突）
        if (messages.isNotEmpty) {
          for (final m in messages) {
            final existing =
                await isar.isarChatMessages.getByMsgId(m.msgId);
            if (existing != null) {
              existing.sessionId = sessionId;
              existing.timestamp = m.timestamp;
              existing.messageJson = jsonEncode(m.toJson());
              await isar.isarChatMessages.put(existing);
            } else {
              final entity = IsarChatMessage()
                ..msgId = m.msgId
                ..sessionId = sessionId
                ..timestamp = m.timestamp
                ..messageJson = jsonEncode(m.toJson());
              await isar.isarChatMessages.put(entity);
            }
          }
        }
        // 再删除不在新消息列表中的旧消息
        final currentMsgIds = messages.map((m) => m.msgId).toSet();
        final oldMessages = await isar.isarChatMessages
            .where()
            .sessionIdEqualTo(sessionId)
            .sortByTimestamp()
            .findAll();
        for (final oldMsg in oldMessages) {
          if (!currentMsgIds.contains(oldMsg.msgId)) {
            await isar.isarChatMessages.delete(oldMsg.id);
          }
        }
      });
    } catch (e) {
      debugPrint('持久化消息失败: $e');
    }
  }

  Future<void> _persistCurrentSession() async {
    try {
      if (currentSession.value == null) return;
      final isar = IsarService.instance.isar;
      final currentId = currentSession.value!.sessionId;

      await isar.writeTxn(() async {
        // 只查找旧当前会话（而非加载全部），清除 isCurrent 标记
        final allSessions =
            await isar.isarChatSessions.buildQuery<IsarChatSession>().findAll();
        IsarChatSession? oldCurrent;
        for (final s in allSessions) {
          if (s.isCurrent) {
            oldCurrent = s;
            break;
          }
        }
        if (oldCurrent != null && oldCurrent.sessionId != currentId) {
          oldCurrent.isCurrent = false;
          await isar.isarChatSessions.put(oldCurrent);
        }

        // 设置新当前会话 - 使用 putBySessionId 避免唯一索引冲突
        final entity = await isar.isarChatSessions.getBySessionId(currentId);
        if (entity != null) {
          // 直接更新现有实体的字段，而不是创建新对象
          _updateIsarSessionFromChatSession(entity, currentSession.value!);
          entity.isCurrent = true;
          await isar.isarChatSessions.put(entity);
        } else {
          // 新会话首次持久化
          final newEntity = _chatSessionToIsar(currentSession.value!);
          newEntity.isCurrent = true;
          await isar.isarChatSessions.put(newEntity);
        }
      });

      // 单独持久化当前会话的消息
      await _persistMessagesForSession(
        currentId,
        currentSession.value!.messages,
      );
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
      ..workDirectory = session.workDirectory
      ..messagesJson = null // 不再写入，消息已通过 _persistMessagesForSession 独立存储
      ..modelId = session.modelId
      ..mcpId = session.mcpId
      ..skillId = session.skillId
      ..attachmentsJson =
          session.attachments.isNotEmpty
              ? jsonEncode(session.attachments.map((a) => a.toJson()).toList())
              : null
      ..sessionQuickCommandsJson =
          session.sessionQuickCommands.isNotEmpty
              ? jsonEncode(
                session.sessionQuickCommands.map((c) => c.toJson()).toList(),
              )
              : null
      ..scheduledTasksJson =
          session.scheduledTask != null
              ? jsonEncode(session.scheduledTask!.toJson())
              : null
      ..memoryRounds = session.memoryRounds
      ..deepThink = session.deepThink
      ..memoryJson =
          session.memory.isNotEmpty
              ? jsonEncode(session.memory.map((t) => t.toJson()).toList())
              : null
      ..compressedMemory = session.compressedMemory
      ..isCurrent = false; // 由调用方设置
  }

  /// 更新 IsarChatSession 实体字段（复用现有实体，避免唯一索引冲突）
  void _updateIsarSessionFromChatSession(
    IsarChatSession entity,
    ChatSession session,
  ) {
    entity.sessionId = session.sessionId;
    entity.name = session.name;
    entity.createdAt = session.createdAt;
    entity.isFavorite = session.isFavorite;
    entity.isSending = session.isSending;
    entity.shouldStopResponse = session.shouldStopResponse;
    entity.scrollPosition = session.scrollPosition;
    entity.inputContent = session.inputContent;
    entity.lastSelectedDirectory = session.lastSelectedDirectory;
    entity.workDirectory = session.workDirectory;
    entity.messagesJson = null; // 不再写入，消息已通过 _persistMessagesForSession 独立存储
    entity.modelId = session.modelId;
    entity.mcpId = session.mcpId;
    entity.skillId = session.skillId;
    entity.attachmentsJson =
        session.attachments.isNotEmpty
            ? jsonEncode(session.attachments.map((a) => a.toJson()).toList())
            : null;
    entity.sessionQuickCommandsJson =
        session.sessionQuickCommands.isNotEmpty
            ? jsonEncode(
              session.sessionQuickCommands.map((c) => c.toJson()).toList(),
            )
            : null;
    entity.scheduledTasksJson =
        session.scheduledTask != null
            ? jsonEncode(session.scheduledTask!.toJson())
            : null;
    entity.memoryRounds = session.memoryRounds;
    entity.deepThink = session.deepThink;
    entity.memoryJson =
        session.memory.isNotEmpty
            ? jsonEncode(session.memory.map((t) => t.toJson()).toList())
            : null;
    entity.compressedMemory = session.compressedMemory;
  }

  /// 根据消息ID查找会话（先从内存查找，未找到则从Isar搜索消息集合）
  Future<ChatSession?> findSessionByMessageId(String messageId) async {
    // 先从内存列表查找
    for (final session in sessions) {
      if (session.messages.any((msg) => msg.msgId == messageId)) {
        return session;
      }
    }

    // 内存中未找到，从 IsarChatMessage 集合搜索
    try {
      final isar = IsarService.instance.isar;
      final msgEntity = await isar.isarChatMessages.getByMsgId(messageId);
      if (msgEntity != null) {
        final sessionEntity = await isar.isarChatSessions
            .getBySessionId(msgEntity.sessionId);
        if (sessionEntity != null) {
          return _isarToChatSession(sessionEntity);
        }
      }
    } catch (e) {
      debugPrint('从Isar搜索会话失败: $e');
    }

    return null;
  }

  /// IsarChatSession → ChatSession
  /// [loadMessages] 为 true 时从旧格式 messagesJson 加载消息（兼容），默认 false 配合懒加载
  ChatSession _isarToChatSession(IsarChatSession entity, {bool loadMessages = false}) {
    // 解析消息（仅在 loadMessages=true 时从遗留 messagesJson 加载）
    List<ChatMessage> messages = [];
    if (loadMessages && entity.messagesJson != null && entity.messagesJson!.isNotEmpty) {
      try {
        final list = jsonDecode(entity.messagesJson!) as List<dynamic>;
        messages =
            list
                .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList();
      } catch (_) {}
    }

    // 根据 modelId 动态解析 ChatModel
    final String? modelId = entity.modelId;
    ChatModel? chatModel;
    if (modelId != null && modelId.isNotEmpty) {
      try {
        final modelController = Get.find<ModelController>();
        chatModel = modelController.models.firstWhere(
          (m) => m.modelId == modelId,
        );
      } catch (_) {
        // 模型已被删除，chatModel 为 null
      }
    }

    // mcp / skill 在 setCurrentSession 中动态解析（此时 MCP/Skill 可能尚未加载）

    // 解析定时任务（兼容旧格式列表 → 取第一条）
    ScheduledTask? scheduledTask;
    if (entity.scheduledTasksJson != null && entity.scheduledTasksJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(entity.scheduledTasksJson!);
        if (decoded is List && decoded.isNotEmpty) {
          scheduledTask = ScheduledTask.fromJson(decoded.first as Map<String, dynamic>);
        } else if (decoded is Map<String, dynamic>) {
          scheduledTask = ScheduledTask.fromJson(decoded);
        }
      } catch (_) {}
    }

    // 解析记忆
    List<MemoryTurn> memory = [];
    if (entity.memoryJson != null && entity.memoryJson!.isNotEmpty) {
      try {
        final list = jsonDecode(entity.memoryJson!) as List<dynamic>;
        memory =
            list
                .map((t) => MemoryTurn.fromJson(t as Map<String, dynamic>))
                .toList();
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
      workDirectory: entity.workDirectory,
      modelId: modelId,
      mcpId: entity.mcpId,
      skillId: entity.skillId,
      chatModel: chatModel,
      memoryRounds: entity.memoryRounds,
      deepThink: entity.deepThink,
      scheduledTask: scheduledTask,
      memory: memory,
      compressedMemory: entity.compressedMemory,
    );
  }
}
