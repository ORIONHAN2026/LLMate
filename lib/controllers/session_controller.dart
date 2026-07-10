import 'package:llmwork/models/chat/chat_message.dart';
import 'package:llmwork/models/chat/scheduled_task.dart';
import 'package:llmwork/models/chat/chat_attachment.dart';
import 'package:llmwork/models/chat/chat_setting.dart';
import 'package:llmwork/models/chat/contract_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat/chat_session.dart';
import '../models/chat/mcp_config.dart';
import '../models/bigmodel/chat_model.dart';
import '../data/storage_service.dart';
import '../data/storage_paths.dart';

import '../features/models/controllers/model_controller.dart';
import './mcp_controller.dart';

/// 从会话存储实体中解析 MCP 文件夹名（兼容旧格式 mcpId / mcp Map）
String? _resolveMcpFolder(Map<String, dynamic> entity) {
  final dynamic raw = entity['mcp'] ?? entity['mcpId'];
  if (raw is String) {
    return raw.startsWith('mcp_') ? raw.substring(4) : raw;
  } else if (raw is Map<String, dynamic>) {
    final id = (raw['mcpId'] as String? ?? '');
    if (id.isEmpty) return null;
    return id.startsWith('mcp_') ? id.substring(4) : id;
  }
  return null;
}

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
        final m = modelController.models.firstWhere(
          (m) => m.modelId == s.modelId,
        );
        s = s.copyWith(chatModel: m);
        updated = true;
      } catch (_) {}
    }

    // 根据 mcp 文件夹名解析 server.json / config.json
    if (s.mcp != null && s.mcp!.isNotEmpty) {
      final mcpController = Get.find<McpController>();
      await mcpController.ensureLoaded();
      final mcp = mcpController.getMcp(s.mcp!) ?? s.mcpServer;
      if (mcp != null) {
        s = s.copyWith(mcpServer: mcp);
        updated = true;
      }
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
    final isCurrent = currentSession.value?.sessionId == updatedSession.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    if (idx != -1 || isCurrent) {
      await _persistSessionAndCurrent(updatedSession, isCurrent: isCurrent);
    }
  }

  /// 自动计算会话的累计计费信息
  ChatSession _recalculateBilling(ChatSession session) {
    int inputTotal = 0;
    int outputTotal = 0;
    double cost = 0.0;

    for (final msg in session.messages) {
      if (msg.promptTokens != null) inputTotal += msg.promptTokens!;
      if (msg.completionTokens != null) outputTotal += msg.completionTokens!;
    }

    // 根据模型价格计算费用（美元/百万token）
    if (session.chatModel != null) {
      final inputPrice = session.chatModel!.inputPrice;
      final outputPrice = session.chatModel!.outputPrice;
      if (inputPrice != null) {
        cost += inputTotal * inputPrice / 1000000.0;
      }
      if (outputPrice != null) {
        cost += outputTotal * outputPrice / 1000000.0;
      }
    }

    // 只有值发生变化时才创建新对象
    if (inputTotal != session.promptTokens ||
        outputTotal != session.completionTokens ||
        cost != session.totalCost) {
      return session.copyWith(
        promptTokens: inputTotal,
        completionTokens: outputTotal,
        totalCost: cost,
      );
    }
    return session;
  }

  /// 合并持久化：session.json + message.json + memory.md + 相关文件
  Future<void> _persistSessionAndCurrent(ChatSession updatedSession,
      {required bool isCurrent}) async {
    try {
      final store = StorageService.instance.store;

      // === 1. 持久化所有会话元数据 ===
      final currentSessionIds = sessions.map((s) => s.sessionId).toSet();
      for (final session in sessions) {
        final sessionData = _sessionToMap(session);
        sessionData['isCurrent'] =
            currentSession.value?.sessionId == session.sessionId;
        await store.isarChatSessions.put(sessionData);
      }

      // 删除不在当前列表中的旧会话
      final allSessions = await store.isarChatSessions.findAll();
      for (final entity in allSessions) {
        final sid = entity['sessionId'] as String;
        if (!currentSessionIds.contains(sid)) {
          await store.isarChatSessions.delete(sid);
        }
      }

      // === 2. 持久化当前会话的消息 ===
      if (isCurrent) {
        final messages = updatedSession.messages;
        final messagesJson =
            messages.map((m) => m.toJson()).toList();
        await store.isarChatMessages.putAll(
            updatedSession.sessionId, messagesJson);
      }

      // === 3. 持久化 MCP 绑定到 mcp.json ===
      if (updatedSession.mcpServer != null) {
        await SessionFileStore.writeMcp(
            updatedSession.sessionId, updatedSession.mcpServer!.toFullJson());
      }
    } catch (e) {
      debugPrint('合并持久化失败: $e');
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

    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages[messageIndex] = updateMessage;
    final updatedSession = session.copyWith(messages: newMessages);
    sessions[sessionIndex] = updatedSession;

    final isCurrent =
        currentSession.value?.sessionId == session.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    await _persistSessionAndCurrent(updatedSession, isCurrent: isCurrent);
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

    final newMessages = List<ChatMessage>.from(session.messages);
    newMessages.removeAt(messageIndex);
    final updatedSession = session.copyWith(messages: newMessages);
    sessions[sessionIndex] = updatedSession;

    final isCurrent =
        currentSession.value?.sessionId == session.sessionId;
    if (isCurrent) {
      currentSession.value = updatedSession;
    }
    await _persistSessionAndCurrent(updatedSession, isCurrent: isCurrent);
  }

  /// 切换到指定会话并持久化
  Future<void> switchToSession(String sessionId) async {
    await McpController.instance.closeAllClients();

    final targetIndex = sessions.indexWhere((s) => s.sessionId == sessionId);
    if (targetIndex >= 0 && targetIndex < sessions.length) {
      final target = sessions[targetIndex];
      currentSession.value = target;
      McpController.instance.initForSession(target);
      Future.microtask(() =>
          _persistSessionAndCurrent(target, isCurrent: true));
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

    // 从文件系统删除
    try {
      final store = StorageService.instance.store;
      await store.isarChatSessions.delete(sessionId);
      // 删除会话目录（包含 session.json, message.json, memory.md 等）
      await store.isarChatMessages.delete(sessionId);
    } catch (e) {
      debugPrint('删除会话失败: $e');
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

  /// 更新会话消息并持久化
  Future<void> updateSessionMessages(
    String sessionId,
    List<ChatMessage> messages,
  ) async {
    return Future.microtask(() async {
      final idx = sessions.indexWhere((s) => s.sessionId == sessionId);
      if (idx != -1) {
        final updated = sessions[idx].copyWith(messages: messages);
        sessions[idx] = updated;
        final isCurrent =
            currentSession.value?.sessionId == sessionId;
        if (isCurrent) {
          currentSession.value = updated;
        }
        await _persistSessionAndCurrent(updated, isCurrent: isCurrent);
      }
    });
  }

  /// 清空所有会话并持久化
  Future<void> clearAllSessions() async {
    sessions.clear();
    currentSession.value = null;
    await _persistSessions();
  }

  /// 加载所有会话和当前会话（消息懒加载）
  Future<void> loadAll() async {
    try {
      final store = StorageService.instance.store;
      final isarSessions = await store.isarChatSessions.findAll();

      final List<ChatSession> loaded = [];
      ChatSession? current;

      for (final entity in isarSessions) {
        final session = await _mapToSession(entity);
        loaded.add(session);
        if (entity['isCurrent'] == true) {
          current = session;
        }
      }

      loaded.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      sessions.value = loaded;

      if (current != null) {
        await setCurrentSession(current);
      } else {
        currentSession.value = null;
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
  }

  /// 为指定会话加载消息
  Future<List<ChatMessage>> loadMessages(String sessionId) async {
    try {
      final store = StorageService.instance.store;
      final messagesData =
          await store.isarChatMessages.getBySessionId(sessionId);

      return messagesData
          .map((m) {
            try {
              return ChatMessage.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<ChatMessage>()
          .toList();
    } catch (e) {
      debugPrint('加载会话消息失败: $e');
      return [];
    }
  }

  // ==================== 内部持久化方法 ====================

  Future<void> _persistSessions() async {
    try {
      final store = StorageService.instance.store;
      final currentSessionIds = sessions.map((s) => s.sessionId).toSet();

      for (final session in sessions) {
        final sessionData = _sessionToMap(session);
        sessionData['isCurrent'] =
            currentSession.value?.sessionId == session.sessionId;
        await store.isarChatSessions.put(sessionData);
      }

      // 删除不在当前列表中的旧会话
      final allSessions = await store.isarChatSessions.findAll();
      for (final entity in allSessions) {
        final sid = entity['sessionId'] as String;
        if (!currentSessionIds.contains(sid)) {
          await store.isarChatSessions.delete(sid);
        }
      }
    } catch (e) {
      debugPrint('保存会话失败: $e');
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

    // 从文件系统搜索
    try {
      final store = StorageService.instance.store;
      final ids = await StoragePaths.listSessionIds();
      for (final sid in ids) {
        final messagesData =
            await store.isarChatMessages.getBySessionId(sid);
        if (messagesData.any((m) => m['id'] == messageId)) {
          final sessionData =
              await store.isarChatSessions.getBySessionId(sid);
          if (sessionData != null) {
            return await _mapToSession(sessionData);
          }
        }
      }
    } catch (e) {
      debugPrint('从文件搜索会话失败: $e');
    }

    return null;
  }

  // ==================== 转换方法 ====================

  /// ChatSession → Map（用于 session.json）
  Map<String, dynamic> _sessionToMap(ChatSession session) {
    return {
      'sessionId': session.sessionId,
      'name': session.name,
      'createdAt': session.createdAt.toIso8601String(),
      'isFavorite': session.isFavorite,
      'isSending': false, // 运行时状态不持久化
      'shouldStopResponse': false, // 运行时状态不持久化
      'scrollPosition': session.scrollPosition,
      'inputContent': session.inputContent,
      'lastSelectedDirectory': session.lastSelectedDirectory,
      'workDirectory': session.workDirectory,
      'modelId': session.modelId,
      if (session.mcp != null) 'mcp': session.mcp!,
      if (session.mcpServer != null) 'mcpServer': session.mcpServer!.toJson(),
      'deepThink': session.deepThink,
      'connectPrompt': session.connectPrompt,
      'sessionQuickCommands':
          session.sessionQuickCommands.map((c) => c.toJson()).toList(),
      'scheduledTask': session.scheduledTask?.toJson(),
      'attachments':
          session.attachments.map((a) => a.toJson()).toList(),
      'emoji': session.emoji,
      'totalInputTokens': session.promptTokens,
      'totalOutputTokens': session.completionTokens,
      'totalCost': session.totalCost,
      'apiKey': session.apiKey,
      'quotaEnabled': session.quotaEnabled,
      'quotaTokenLimit': session.quotaTokenLimit,
      'quotaCostLimit': session.quotaCostLimit,
      'quotaRequestLimit': session.quotaRequestLimit,
      'quotaResetPeriod': session.quotaResetPeriod,
      'quotaPeriodStart': session.quotaPeriodStart?.toIso8601String(),
      'quotaRequestCount': session.quotaRequestCount,
    };
  }

  /// Map → ChatSession（从 session.json）
  Future<ChatSession> _mapToSession(Map<String, dynamic> entity) async {
    final String? modelId = entity['modelId'] as String?;
    ChatModel? chatModel;
    if (modelId != null && modelId.isNotEmpty) {
      try {
        final modelController = Get.find<ModelController>();
        chatModel =
            modelController.models.firstWhere((m) => m.modelId == modelId);
      } catch (_) {}
    }

    // 解析定时任务
    ScheduledTask? scheduledTask;
    if (entity['scheduledTask'] is Map<String, dynamic>) {
      try {
        scheduledTask =
            ScheduledTask.fromJson(entity['scheduledTask'] as Map<String, dynamic>);
      } catch (_) {}
    }

    // 解析快捷指令
    List<ChatCommand> commands = [];
    if (entity['sessionQuickCommands'] is List) {
      try {
        commands = (entity['sessionQuickCommands'] as List)
            .map((c) => ChatCommand.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // 解析附件
    List<ChatAttachment> attachments = [];
    if (entity['attachments'] is List) {
      try {
        attachments = (entity['attachments'] as List)
            .map((a) => ChatAttachment.fromJson(a as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return ChatSession(
      sessionId: entity['sessionId'] as String? ?? '',
      name: entity['name'] as String? ?? '新对话',
      createdAt: entity['createdAt'] != null
          ? DateTime.tryParse(entity['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      messages: [], // 消息懒加载
      modelId: modelId,
      mcp: _resolveMcpFolder(entity),
      mcpServer: entity['mcpServer'] is Map<String, dynamic>
          ? Mcp.fromMap(entity['mcpServer'])
          : (entity['mcpConfig'] is Map<String, dynamic>
              ? Mcp.fromMap(entity['mcpConfig'])
              : null),
      chatModel: chatModel,
      isFavorite: entity['isFavorite'] as bool? ?? false,
      inputContent: entity['inputContent'] as String? ?? '',
      attachments: attachments,
      isSending: false,
      shouldStopResponse: false,
      scrollPosition: (entity['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      lastSelectedDirectory: entity['lastSelectedDirectory'] as String?,
      workDirectory: entity['workDirectory'] as String?,
      deepThink: entity['deepThink'] as bool? ?? false,
      connectPrompt: entity['connectPrompt'] as String?,
      sessionQuickCommands: commands,
      scheduledTask: scheduledTask,
      contracts: await _loadContracts(entity['sessionId'] as String? ?? ''),
      emoji: entity['emoji'] as String?,
      apiKey: entity['apiKey'] as String?,
      quotaEnabled: entity['quotaEnabled'] as bool? ?? false,
      quotaTokenLimit: entity['quotaTokenLimit'] as int?,
      quotaCostLimit: (entity['quotaCostLimit'] as num?)?.toDouble(),
      quotaRequestLimit: entity['quotaRequestLimit'] as int?,
      quotaResetPeriod: entity['quotaResetPeriod'] as String?,
      quotaPeriodStart: entity['quotaPeriodStart'] != null
          ? DateTime.tryParse(entity['quotaPeriodStart'] as String)
          : null,
      quotaRequestCount: entity['quotaRequestCount'] as int? ?? 0,
    );
  }

  /// 从 business.md 加载合约要点
  Future<List<ContractInfo>?> _loadContracts(String sessionId) async {
    if (sessionId.isEmpty) return null;
    try {
      final content = await SessionFileStore.readBusiness(sessionId);
      if (content == null || content.trim().isEmpty) return null;
      return _parseContractsFromMarkdown(content);
    } catch (_) {
      return null;
    }
  }

  /// 从 Markdown 解析合约列表
  List<ContractInfo> _parseContractsFromMarkdown(String markdown) {
    final contracts = <ContractInfo>[];
    // 按 ## 分割合同段落
    final sections = markdown.split(RegExp(r'^## ', multiLine: true));

    for (final section in sections) {
      final trimmed = section.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split('\n');
      final name = lines.first.trim();
      if (name.isEmpty || name == '合约要点' || name.startsWith('# ')) continue;

      String? contractType;
      String? startDate, endDate, signingDate;
      String? paymentClause, paymentSchedule, breachClause, liabilityClause;
      final parties = <ContractParty>[];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty || line == '---') continue;

        // 单值字段: **标签**: 值
        final kvMatch = RegExp(r'^\*\*(.+?)\*\*:\s*(.*)').firstMatch(line);
        if (kvMatch != null) {
          final label = kvMatch.group(1)!;
          final value = kvMatch.group(2)!.trim();
          switch (label) {
            case '合同类型':
              contractType = value;
            case '收支条款':
              paymentClause = _readMultilineBlock(lines, i + 1);
            case '支付计划':
              paymentSchedule = _readMultilineBlock(lines, i + 1);
            case '违约条款':
              breachClause = _readMultilineBlock(lines, i + 1);
            case '违约责任':
              liabilityClause = _readMultilineBlock(lines, i + 1);
            case '签署方':
              // 跳过，下面用 - 解析
              break;
            case '合同期限':
              // 跳过，下面用 - 解析
              break;
          }
          continue;
        }

        // 签署方: - **角色**: 名称
        final partyMatch = RegExp(r'^-\s*\*\*(.+?)\*\*:\s*(.+)').firstMatch(line);
        if (partyMatch != null) {
          parties.add(ContractParty(
            role: partyMatch.group(1)!,
            name: partyMatch.group(2)!.trim(),
          ));
          continue;
        }

        // 期限项: - 标签: 值
        final periodMatch = RegExp(r'^-\s*(.+?):\s*(.+)').firstMatch(line);
        if (periodMatch != null) {
          final label = periodMatch.group(1)!;
          final value = periodMatch.group(2)!.trim();
          if (label.contains('起始')) startDate = value;
          else if (label.contains('结束')) endDate = value;
          else if (label.contains('签订') || label.contains('签署')) signingDate = value;
        }
      }

      contracts.add(ContractInfo(
        name: name,
        parties: parties,
        contractType: contractType,
        startDate: startDate,
        endDate: endDate,
        signingDate: signingDate,
        paymentClause: paymentClause,
        paymentSchedule: paymentSchedule,
        breachClause: breachClause,
        liabilityClause: liabilityClause,
      ));
    }

    return contracts;
  }

  /// 从当前位置读取多行文本块（直到遇到下一个 **标签**: 或 --- 或空行后跟 **标签**:）
  String _readMultilineBlock(List<String> lines, int start) {
    final buf = StringBuffer();
    for (int i = start; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line == '---') break;
      if (line.startsWith('**') && line.contains('**:')) break;
      if (buf.isNotEmpty) buf.writeln();
      buf.write(line);
    }
    return buf.toString().trim();
  }
}
