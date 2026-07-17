import 'package:llmate/models/chat/chat_message.dart';
import 'package:llmate/models/chat/chat_setting.dart';
import 'package:llmate/models/chat/contract_info.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../models/chat/chat_session.dart';
import '../models/bigmodel/chat_model.dart';
import '../data/storage_service.dart';

import './model_controller.dart';
import './mcp_controller.dart';
import './message_controller.dart';

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

/// 从会话存储实体中解析 MCP 文件夹名列表（兼容旧格式）
List<String>? _resolveMcpFolders(Map<String, dynamic> entity) {
  // 新格式: mcps 列表
  if (entity['mcps'] is List) {
    return (entity['mcps'] as List).cast<String>();
  }
  // 旧格式: 单个 mcp
  final single = _resolveMcpFolder(entity);
  return single != null ? [single] : null;
}

class SessionController extends GetxController {
  var sessions = <ChatSession>[].obs;
  var currentSession = Rxn<ChatSession>();

  /// 会话数据库路径：~/.llmate/sessions.db
  static String get _dbPath => p.join(StoragePaths.root, 'sessions.db');

  /// sembast store 名称（每个 record 的 key 为 sessionId）
  static const String _storeName = 'sessions';
  final _store = stringMapStoreFactory.store(_storeName);

  Database? _db;

  /// 懒加载并打开 sembast 数据库（单例）
  Future<Database> get _database async {
    if (_db != null) return _db!;
    await StoragePaths.ensureRoot();
    _db = await databaseFactoryIo.openDatabase(_dbPath);
    return _db!;
  }

  /// 将单个会话 upsert 到数据库（key 为 sessionId）
  Future<void> _upsertSession(Database db, ChatSession session) async {
    final data = _sessionToMap(session);
    data['isCurrent'] = currentSession.value?.sessionId == session.sessionId;
    await _store.record(session.sessionId).put(db, data);
  }

  /// 用新的完整列表替换内存列表，并逐条 upsert 每个会话到数据库。
  ///
  /// 与 MessageController 原则一致：多条会话的持久化通过逐条 [_upsertSession]
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

  /// 合并持久化：会话元数据（sessions.db）+ 消息（委托 MessageController）
  Future<void> _persistSessionAndCurrent(
    ChatSession updatedSession, {
    required bool isCurrent,
  }) async {
    try {
      // === 1. 持久化所有会话元数据到 sessions.db（逐条 upsert）===
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

    // 从 sessions.db 删除
    try {
      final db = await _database;
      await _store.record(sessionId).delete(db);
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

  /// 加载所有会话和当前会话（消息懒加载，从 sessions.db 读取）
  Future<void> loadAll() async {
    try {
      final db = await _database;
      final records = await _store.find(db);

      final List<ChatSession> loaded = [];
      ChatSession? current;

      for (final rec in records) {
        final entity = rec.value as Map<String, dynamic>;
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

      // 首次启动（无任何会话）时，自动创建一个默认会话，确保应用有初始配置
      if (sessions.isEmpty) {
        await _seedDefaultSession();
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
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
    // 同步写入 sessions.db（逐条 upsert，不再整体替换）
    try {
      final db = await _database;
      for (final session in sessions) {
        await _upsertSession(db, session);
      }
    } catch (e) {
      debugPrint('保存会话到 sessions.db 失败: $e');
    }
  }

  /// 从 sessions.db 读取单条会话元数据
  Future<Map<String, dynamic>?> _getSessionFromDb(String sid) async {
    try {
      final db = await _database;
      final rec = await _store.record(sid).get(db);
      return rec as Map<String, dynamic>?;
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

    // 从 sessions.db + messages.db 搜索
    try {
      final db = await _database;
      final records = await _store.find(db);
      for (final rec in records) {
        final sid = (rec.value as Map<String, dynamic>)['sessionId'] as String? ?? '';
        final messagesData =
            await MessageController.instance.loadMessages(sid);
        if (messagesData.any((m) => m.msgId == messageId)) {
          final sessionData = await _getSessionFromDb(sid);
          if (sessionData != null) {
            return await _mapToSession(sessionData);
          }
        }
      }
    } catch (e) {
      debugPrint('从 DB 搜索会话失败: $e');
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
      'modelId': session.modelId,
      if (session.mcps != null && session.mcps!.isNotEmpty) 'mcps': session.mcps,
      'deepThink': session.deepThink,
      'connectPrompt': session.connectPrompt,
      'sessionQuickCommands':
          session.sessionQuickCommands.map((c) => c.toJson()).toList(),
      'emoji': session.emoji,
      'promptTokens': session.promptTokens,
      'completionTokens': session.completionTokens,
      'totalTokens': session.totalTokens,
      'totalCost': session.totalCost,
      'apiKey': session.apiKey,
      if (session.group != null && session.group!.isNotEmpty)
        'group': session.group,
      'quotaEnabled': session.quotaEnabled,
      'quotaTokenLimit': session.quotaTokenLimit,
      'quotaCostLimit': session.quotaCostLimit,
      'quotaRequestLimit': session.quotaRequestLimit,
      'quotaResetPeriod': session.quotaResetPeriod,
      'quotaPeriodStart': session.quotaPeriodStart?.toIso8601String(),
      'quotaRequestCount': session.quotaRequestCount,
      'noAuthEnabled': session.noAuthEnabled,
    };
  }

  /// Map → ChatSession（从 session.json）
  Future<ChatSession> _mapToSession(Map<String, dynamic> entity) async {
    final String? modelId = entity['modelId'] as String?;
    ChatModel? chatModel;
    if (modelId != null && modelId.isNotEmpty) {
      try {
        final modelController = Get.find<ModelController>();
        chatModel = await modelController.getModel(modelId);
      } catch (_) {}
    }

    // 解析快捷指令
    List<ChatCommand> commands = [];
    if (entity['sessionQuickCommands'] is List) {
      try {
        commands =
            (entity['sessionQuickCommands'] as List)
                .map((c) => ChatCommand.fromJson(c as Map<String, dynamic>))
                .toList();
      } catch (_) {}
    }

    return ChatSession(
      sessionId: entity['sessionId'] as String? ?? '',
      name: entity['name'] as String? ?? '新对话',
      createdAt:
          entity['createdAt'] != null
              ? DateTime.tryParse(entity['createdAt'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      messages: [], // 消息懒加载
      modelId: modelId,
      mcps: _resolveMcpFolders(entity),
      chatModel: chatModel,
      isFavorite: entity['isFavorite'] as bool? ?? false,
      inputContent: entity['inputContent'] as String? ?? '',
      isSending: false,
      shouldStopResponse: false,
      scrollPosition: (entity['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      deepThink: entity['deepThink'] as bool? ?? false,
      connectPrompt: entity['connectPrompt'] as String?,
      sessionQuickCommands: commands,
      contracts: await _loadContracts(entity['sessionId'] as String? ?? ''),
      emoji: entity['emoji'] as String?,
      apiKey: entity['apiKey'] as String?,
      group: entity['group'] as String?,
      quotaEnabled: entity['quotaEnabled'] as bool? ?? false,
      quotaTokenLimit: entity['quotaTokenLimit'] as int?,
      quotaCostLimit: (entity['quotaCostLimit'] as num?)?.toDouble(),
      quotaRequestLimit: entity['quotaRequestLimit'] as int?,
      quotaResetPeriod: entity['quotaResetPeriod'] as String?,
      quotaPeriodStart:
          entity['quotaPeriodStart'] != null
              ? DateTime.tryParse(entity['quotaPeriodStart'] as String)
              : null,
      quotaRequestCount: entity['quotaRequestCount'] as int? ?? 0,
      promptTokens: entity['promptTokens'] as int? ?? 0,
      completionTokens: entity['completionTokens'] as int? ?? 0,
      totalTokens: entity['totalTokens'] as int? ?? 0,
      noAuthEnabled: entity['noAuthEnabled'] as bool? ?? false,
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
        final partyMatch = RegExp(
          r'^-\s*\*\*(.+?)\*\*:\s*(.+)',
        ).firstMatch(line);
        if (partyMatch != null) {
          parties.add(
            ContractParty(
              role: partyMatch.group(1)!,
              name: partyMatch.group(2)!.trim(),
            ),
          );
          continue;
        }

        // 期限项: - 标签: 值
        final periodMatch = RegExp(r'^-\s*(.+?):\s*(.+)').firstMatch(line);
        if (periodMatch != null) {
          final label = periodMatch.group(1)!;
          final value = periodMatch.group(2)!.trim();
          if (label.contains('起始'))
            startDate = value;
          else if (label.contains('结束'))
            endDate = value;
          else if (label.contains('签订') || label.contains('签署'))
            signingDate = value;
        }
      }

      contracts.add(
        ContractInfo(
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
        ),
      );
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
