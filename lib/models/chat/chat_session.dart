import 'dart:math' as math;
import 'package:llmate/models/bigmodel/chat_model.dart';
import 'package:llmate/models/chat/mcp_config.dart';

import './chat_message.dart';
import './chat_setting.dart';
import './scheduled_task.dart';
import './contract_info.dart';

/// 生成会话级别的 API Key
/// 格式: lm-{32位随机hex字符串}
String generateSessionApiKey() {
  final random = math.Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  final hexString =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return 'lm-$hexString';
}

const List<String> kSessionEmojis = [
  // 表情
  '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😊',
  '😇', '🥰', '😍', '🤩', '😘', '😗', '😋', '😛', '😜', '🤪',
  '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🫡', '🤐', '🤨', '😐',
  '😑', '😶', '🫥', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔',
  '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🥵', '🥶',
  '😎', '🤓', '🧐', '😕', '😟', '🙁', '😮', '😯', '😲', '😳',
  // 手势
  '👍', '👎', '👏', '🙌', '🫶', '🤝', '💪', '✌️', '🤞', '🤟',
  '🤙', '👋', '🖐️', '✋', '🖖', '🫰', '👊', '✊', '🤛', '🤜',
  // 物品
  '💡', '🔦', '🕯️', '📱', '💻', '🖥️', '⌨️', '🖱️', '📷', '🎥',
  '📡', '🔑', '🔒', '🔓', '📦', '📫', '✏️', '🖊️', '📝', '📌',
  // 科技
  '🚀', '🛸', '⚡', '💎', '🤖', '👾', '🎮', '🎯', '🧩', '🎲',
  // 自然
  '🌍', '🌎', '🌏', '🌙', '⭐', '🌟', '✨', '💫', '🌈', '☀️',
  '🌤️', '⛅', '🌥️', '🌧️', '⛈️', '❄️', '🔥', '💧', '🌊', '🍀',
  // 植物
  '🌸', '🌺', '🌻', '🌹', '🌷', '🌱', '🌿', '🍃', '🍂', '🍁',
  // 动物
  '🦊', '🐱', '🐶', '🐻', '🐼', '🐨', '🦁', '🐯', '🐮', '🐷',
  '🐸', '🐵', '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇',
  '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜',
  '🐢', '🐍', '🦎', '🐙', '🦑', '🦐', '🦀', '🐬', '🐳', '🐋',
  '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🐘', '🦏', '🐪', '🐫',
  // 食物
  '🍕', '🍔', '🍟', '🌭', '🍿', '🧀', '🥚', '🍳', '🥞', '🥓',
  '🥩', '🍗', '🍖', '🌮', '🌯', '🥙', '🥗', '🍣', '🍱', '🍜',
  '🍝', '🍛', '🍲', '🥘', '🥟', '🍦', '🍩', '🎂', '🍰', '🧁',
  '🥧', '🍫', '🍬', '🍭', '☕', '🍵', '🥤', '🍺', '🍷', '🥂',
  // 运动
  '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸',
  '🥊', '🥋', '🎿', '🛹', '🏄', '🏊', '🚴', '🏋️', '🥇', '🏆',
  // 乐器
  '🎸', '🎹', '🎷', '🎺', '🎻', '🥁', '🪗', '🪘', '🎵', '🎶',
  // 艺术
  '🎨', '🖼️', '🎭', '🎪', '🎬', '🎤', '🎧', '🎼', '📸', '🎞️',
  // 交通
  '🚗', '🚕', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚',
  '✈️', '🛩️', '🚁', '⛵', '🚂', '🚊', '🚉', '🏠', '🏰', '🗼',
  // 符号
  '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
  '❤️‍🔥', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟',
  '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️',
  '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🩷',
  '🩵', '🩶', '🔶', '🔷', '🔸', '🔹', '💠', '🔘', '🏁', '🚩',
];

String randomEmoji() {
  return kSessionEmojis[math.Random().nextInt(kSessionEmojis.length)];
}

// 聊天会话类
class ChatSession {
  final String sessionId;
  String name;
  final DateTime createdAt;
  final bool isFavorite;
  final String inputContent;
  final bool isSending;
  final bool shouldStopResponse;
  final double scrollPosition;

  // === 会话级功能配置 ===

  /// 绑定的 MCP 服务文件夹名列表（~/.llmate/mcps/{name}），null/empty = 未绑定
  final List<String>? mcps;

  /// 深度思考模式（默认关闭）
  final bool deepThink;

  /// 连接器的关联关系描述提示词
  final String? connectPrompt;

  /// 会话级系统提示词（若设置，则在第三方请求时作为最高优先级指令注入）
  final String? systemPrompt;

  // === 计费统计 ===

  /// 累计输入token数
  int promptTokens;

  /// 累计输出token数
  int completionTokens;

  /// 累计总token数
  int totalTokens;

  /// 累计费用（实时计算：基于输入/输出 token 数和模型定价）
  /// 货币类型由绑定的 chatModel.currency 决定
  /// 计算公式: promptTokens * promptPrice / 1,000,000 + completionTokens * completionPrice / 1,000,000
  double get totalCost => _calculateCost(promptTokens, completionTokens);

  /// 合约要点列表（商务模式下，由 contract_inspect 工具写入）
  final List<ContractInfo>? contracts;

  // ============================

  /// 绑定的模型ID，用于动态加载 chatModel
  final String? modelId;

  /// 会话头像 emoji
  final String emoji;

  /// 会话分组名称，null 或空字符串表示未分组
  final String? group;

  /// 运行时动态解析的模型对象（不持久化，由 modelId 解析而来）
  final ChatModel? chatModel;
  final List<ChatMessage> messages;
  final List<ChatCommand> sessionQuickCommands;
  final ScheduledTask? scheduledTask;

  /// 会话级别的 API 密钥，用于外部 HTTP 请求认证
  /// 格式: lm-{32位随机hex字符串}
  final String apiKey;

  /// 免授权模式：开启后外部请求无需提供 API Key 即可访问
  final bool noAuthEnabled;

  // === 用量配额设置 ===

  /// 是否启用用量限制
  final bool quotaEnabled;

  /// Token 用量上限（null = 不限制）
  final int? quotaTokenLimit;

  /// 费用预算上限（货币类型由绑定的模型决定，null = 不限制）
  final double? quotaCostLimit;

  /// 请求次数上限（null = 不限制）
  final int? quotaRequestLimit;

  /// 配额重置周期，null 表示永不过期
  /// - 'daily': 每天重置
  /// - 'monthly': 每月重置
  /// - null: 不自动重置
  String? quotaResetPeriod;

  /// 配额周期起始时间（用于判断是否该重置了）
  DateTime? quotaPeriodStart;

  /// 当前周期已使用的请求次数（增量计数，跟随重置周期清零）
  int quotaRequestCount;

  ChatSession({
    required this.sessionId,
    required this.name,
    required this.createdAt,
    required this.messages,
    String? modelId,
    List<String>? mcps,
    this.chatModel,
    this.isFavorite = false,
    this.inputContent = '',
    this.isSending = false,
    this.shouldStopResponse = false,
    this.scrollPosition = 0.0,
    this.deepThink = false,
    this.connectPrompt,
    this.systemPrompt,
    this.sessionQuickCommands = const [],
    this.scheduledTask,
    this.contracts,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    String? emoji,
    String? apiKey,
    this.group,
    this.quotaEnabled = false,
    this.quotaTokenLimit,
    this.quotaCostLimit,
    this.quotaRequestLimit,
    this.quotaResetPeriod,
    this.quotaPeriodStart,
    this.quotaRequestCount = 0,
    this.noAuthEnabled = false,
  }) : modelId = modelId ?? chatModel?.modelId,
       mcps = mcps,
       emoji = emoji ?? randomEmoji(),
       apiKey = apiKey ?? generateSessionApiKey();

  // 获取会话的预览文本
  String get previewText {
    if (messages.isEmpty) return '新对话';
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.role == MessageRole.user,
      orElse: () => messages.first,
    );
    return firstUserMessage.content.length > 20
        ? '${firstUserMessage.content.substring(0, 20)}...'
        : firstUserMessage.content;
  }

  DateTime get lastMessageTime {
    if (messages.isEmpty) return createdAt;
    return messages.last.timestamp;
  }

  String get modelName {
    if (chatModel != null) {
      return chatModel!.name.isNotEmpty ? chatModel!.name : chatModel!.model;
    }
    return '';
  }

  String get modelDisplayInfo {
    if (chatModel != null && chatModel!.model.isNotEmpty) {
      return chatModel!.name;
    } else {
      return '未设置对话大模型';
    }
  }

  /// 配额状态（用于 UI 展示和 HTTP 检查）
  QuotaCheckResult checkQuota() {
    if (!quotaEnabled) {
      return QuotaCheckResult(exceeded: false);
    }

    // 周期模式的用量数据
    final periodBilling = getPeriodBilling();
    final effectiveTokens =
        quotaPeriodStart != null
            ? periodBilling.inputTokens + periodBilling.outputTokens
            : promptTokens + completionTokens;
    final effectiveCost =
        quotaPeriodStart != null ? periodBilling.cost : totalCost;

    // 检查 Token 用量
    if (quotaTokenLimit != null && effectiveTokens >= quotaTokenLimit!) {
      return QuotaCheckResult(
        exceeded: true,
        reason: 'Token 用量已达上限',
        detail: '已使用 $effectiveTokens Token，上限 ${quotaTokenLimit} Token',
      );
    }

    // 检查费用预算
    if (quotaCostLimit != null && effectiveCost >= quotaCostLimit!) {
      return QuotaCheckResult(
        exceeded: true,
        reason: '费用预算已达上限',
        detail:
            '已花费 \$${effectiveCost.toStringAsFixed(4)}，预算 \$${quotaCostLimit!.toStringAsFixed(2)}',
      );
    }

    // 检查请求次数
    if (quotaRequestLimit != null && quotaRequestCount >= quotaRequestLimit!) {
      return QuotaCheckResult(
        exceeded: true,
        reason: '请求次数已达上限',
        detail: '已请求 $quotaRequestCount 次，上限 $quotaRequestLimit 次',
      );
    }

    return QuotaCheckResult(exceeded: false);
  }

  /// 记录一次请求（递增 quotaRequestCount）
  ChatSession recordRequest() {
    if (!quotaEnabled) return this;
    return copyWith(quotaRequestCount: quotaRequestCount + 1);
  }

  /// 检查是否需要重置配额周期，如果需要则返回重置后的会话
  /// 重置时仅清零请求计数，Token/费用的周期用量通过时间过滤计算
  /// 重置基于自然时间边界：每天零点、每月1号零点
  ChatSession? tryResetQuotaPeriod() {
    if (!quotaEnabled || quotaResetPeriod == null || quotaPeriodStart == null) {
      return null;
    }

    final now = DateTime.now();
    final periodStart = quotaPeriodStart!;

    // 计算当前自然周期的起点
    final DateTime currentPeriodStart;
    switch (quotaResetPeriod) {
      case 'daily':
        currentPeriodStart = DateTime(now.year, now.month, now.day);
        break;
      case 'monthly':
        currentPeriodStart = DateTime(now.year, now.month, 1);
        break;
      default:
        return null;
    }

    // 如果记录的周期起点早于当前自然周期起点，说明进入了新周期
    if (periodStart.isBefore(currentPeriodStart)) {
      return copyWith(
        quotaRequestCount: 0,
        quotaPeriodStart: currentPeriodStart,
      );
    }
    return null;
  }

  /// 获取当前配额周期内的 Token/费用用量（从消息中计算）
  /// 根据模型价格计算指定 token 量的费用
  /// 价格单位：/百万token
  double _calculateCost(int inputTokens, int outputTokens) {
    double cost = 0.0;
    final promptPrice = chatModel?.promptPrice;
    final completionPrice = chatModel?.completionPrice;
    if (promptPrice != null) {
      cost += inputTokens * promptPrice / 1000000.0;
    }
    if (completionPrice != null) {
      cost += outputTokens * completionPrice / 1000000.0;
    }
    return cost;
  }

  ({int inputTokens, int outputTokens, double cost}) getPeriodBilling() {
    if (!quotaEnabled || quotaPeriodStart == null || chatModel == null) {
      return (inputTokens: 0, outputTokens: 0, cost: 0.0);
    }

    int inputTotal = 0;
    int outputTotal = 0;

    for (final msg in messages) {
      if (msg.timestamp.isAfter(quotaPeriodStart!)) {
        if (msg.promptTokens != null) inputTotal += msg.promptTokens!;
        if (msg.completionTokens != null) outputTotal += msg.completionTokens!;
      }
    }

    return (inputTokens: inputTotal, outputTokens: outputTotal, cost: _calculateCost(inputTotal, outputTotal));
  }

  ChatSession copyWith({
    String? sessionId,
    String? title,
    DateTime? createdAt,
    List<ChatMessage>? messages,
    bool? isFavorite,
    String? inputContent,
    bool? isSending,
    bool? shouldStopResponse,
    double? scrollPosition,
    String? mcp,
    Mcp? mcpServer,
    bool clearMcp = false,
    List<String>? mcps,
    ChatModel? chatModel,
    bool clearChatModel = false,
    bool? deepThink,
    String? connectPrompt,
    bool clearConnectPrompt = false,
    String? systemPrompt,
    bool clearSystemPrompt = false,
    List<ChatCommand>? sessionQuickCommands,
    ScheduledTask? scheduledTask,
    bool clearScheduledTask = false,
    List<ContractInfo>? contracts,
    bool clearContracts = false,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    String? emoji,
    String? apiKey,
    String? group,
    bool clearGroup = false,
    bool? quotaEnabled,
    int? quotaTokenLimit,
    bool clearQuotaTokenLimit = false,
    double? quotaCostLimit,
    bool clearQuotaCostLimit = false,
    int? quotaRequestLimit,
    bool clearQuotaRequestLimit = false,
    String? quotaResetPeriod,
    bool clearQuotaResetPeriod = false,
    DateTime? quotaPeriodStart,
    bool clearQuotaPeriodStart = false,
    int? quotaRequestCount,
    bool? noAuthEnabled,
  }) {
    // 当显式设置 chatModel 时，自动同步 modelId
    final String? resolvedModelId;
    final ChatModel? resolvedChatModel;
    if (clearChatModel) {
      resolvedModelId = null;
      resolvedChatModel = null;
    } else if (chatModel != null) {
      resolvedModelId = chatModel.modelId;
      resolvedChatModel = chatModel;
    } else {
      resolvedModelId = modelId;
      resolvedChatModel = this.chatModel;
    }

    // 解析绑定的 MCP 文件夹名列表
    final List<String>? resolvedMcps;
    if (clearMcp) {
      resolvedMcps = null;
    } else if (mcps != null) {
      resolvedMcps = mcps;
    } else {
      resolvedMcps = this.mcps;
    }

    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      name: title ?? name,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      isFavorite: isFavorite ?? this.isFavorite,
      inputContent: inputContent ?? this.inputContent,
      isSending: isSending ?? this.isSending,
      shouldStopResponse: shouldStopResponse ?? this.shouldStopResponse,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      mcps: resolvedMcps,
      modelId: resolvedModelId,
      chatModel: resolvedChatModel,
      deepThink: deepThink ?? this.deepThink,
      connectPrompt:
          clearConnectPrompt ? null : (connectPrompt ?? this.connectPrompt),
      systemPrompt:
          clearSystemPrompt ? null : (systemPrompt ?? this.systemPrompt),
      sessionQuickCommands: sessionQuickCommands ?? this.sessionQuickCommands,
      scheduledTask:
          clearScheduledTask ? null : (scheduledTask ?? this.scheduledTask),
      contracts: clearContracts ? null : (contracts ?? this.contracts),
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      emoji: emoji ?? this.emoji,
      apiKey: apiKey ?? this.apiKey,
      group: clearGroup ? null : (group ?? this.group),
      quotaEnabled: quotaEnabled ?? this.quotaEnabled,
      quotaTokenLimit:
          clearQuotaTokenLimit
              ? null
              : (quotaTokenLimit ?? this.quotaTokenLimit),
      quotaCostLimit:
          clearQuotaCostLimit ? null : (quotaCostLimit ?? this.quotaCostLimit),
      quotaRequestLimit:
          clearQuotaRequestLimit
              ? null
              : (quotaRequestLimit ?? this.quotaRequestLimit),
      quotaResetPeriod:
          clearQuotaResetPeriod
              ? null
              : (quotaResetPeriod ?? this.quotaResetPeriod),
      quotaPeriodStart:
          clearQuotaPeriodStart
              ? null
              : (quotaPeriodStart ?? this.quotaPeriodStart),
      quotaRequestCount: quotaRequestCount ?? this.quotaRequestCount,
      noAuthEnabled: noAuthEnabled ?? this.noAuthEnabled,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final String? modelId = json['modelId'] as String?;

    // 解析 MCP 绑定：新格式为列表 'mcps'；兼容旧格式（字符串 'mcp' / Map / 'mcpId'）
    List<String>? mcpsList;
    List<Mcp>? mcpServersList;

    if (json['mcps'] is List) {
      mcpsList = (json['mcps'] as List).cast<String>();
    } else {
      // 兼容旧格式: 单个 mcp 字符串
      final dynamic mcpField = json['mcp'];
      final String? singleMcp;
      if (mcpField is String) {
        singleMcp =
            mcpField.startsWith('mcp_') ? mcpField.substring(4) : mcpField;
      } else if (mcpField is Map<String, dynamic>) {
        // 旧格式：mcp 是 Map，提取 name/mcpId
        mcpServersList = [Mcp.fromMap(mcpField)];
        final legacyId = (mcpField['mcpId'] as String? ?? '');
        singleMcp =
            legacyId.startsWith('mcp_')
                ? legacyId.substring(4)
                : (legacyId.isNotEmpty ? legacyId : null);
      } else {
        final old = json['mcpId'] as String?;
        singleMcp =
            old == null
                ? null
                : (old.startsWith('mcp_') ? old.substring(4) : old);
      }
      if (singleMcp != null) mcpsList = [singleMcp];
    }

    // 解析 mcpServers 列表（新格式），兼容旧格式 mcpServer
    if (json['mcpServers'] is List) {
      mcpServersList ??= (json['mcpServers'] as List)
          .map((m) => Mcp.fromMap(m as Map<String, dynamic>))
          .toList();
    } else if (mcpServersList == null && json['mcpServer'] is Map<String, dynamic>) {
      mcpServersList = [Mcp.fromMap(json['mcpServer'])];
    }

    // 如果 mcps 为空但 mcpServers 有数据，从 mcpServers 派生 mcps（兼容旧数据）
    if (mcpsList == null && mcpServersList != null && mcpServersList.isNotEmpty) {
      mcpsList = mcpServersList.map((s) => s.name).toList();
    }

    // 兼容旧数据
    final ChatModel? chatModel =
        json['chatModel'] != null ? ChatModel.fromMap(json['chatModel']) : null;
    return ChatSession(
      sessionId: json['id'] ?? '',
      name: json['name'] ?? '新对话',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((messageJson) => ChatMessage.fromJson(messageJson))
              .toList() ??
          [],
      isFavorite: json['isFavorite'] ?? false,
      inputContent: json['inputContent'] ?? '',
      isSending: json['isSending'] ?? false,
      shouldStopResponse: json['shouldStopResponse'] ?? false,
      scrollPosition: (json['scrollPosition'] as num?)?.toDouble() ?? 0.0,
      deepThink: json['deepThink'] as bool? ?? false,
      connectPrompt: json['connectPrompt'] as String?,
      systemPrompt: json['systemPrompt'] as String?,
      sessionQuickCommands:
          (json['sessionQuickCommands'] as List<dynamic>?)
              ?.map((commandJson) => ChatCommand.fromJson(commandJson))
              .toList() ??
          [],
      scheduledTask:
          json['scheduledTask'] is Map<String, dynamic>
              ? ScheduledTask.fromJson(json['scheduledTask'])
              : null,
      contracts:
          (json['contracts'] as List<dynamic>?)
              ?.map((c) => ContractInfo.fromJson(c as Map<String, dynamic>))
              .toList(),
      promptTokens: json['promptTokens'] as int? ?? 0,
      completionTokens: json['completionTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      modelId: modelId,
      mcps: mcpsList,
      chatModel: chatModel,
      emoji: json['emoji'] as String?,
      apiKey: json['apiKey'] as String?,
      group: json['group'] as String?,
      quotaEnabled: json['quotaEnabled'] as bool? ?? false,
      quotaTokenLimit: json['quotaTokenLimit'] as int?,
      quotaCostLimit: (json['quotaCostLimit'] as num?)?.toDouble(),
      quotaRequestLimit: json['quotaRequestLimit'] as int?,
      quotaResetPeriod: json['quotaResetPeriod'] as String?,
      quotaPeriodStart:
          json['quotaPeriodStart'] != null
              ? DateTime.tryParse(json['quotaPeriodStart'] as String)
              : null,
      quotaRequestCount: json['quotaRequestCount'] as int? ?? 0,
      noAuthEnabled: json['noAuthEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': sessionId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'isFavorite': isFavorite,
      'inputContent': inputContent,
      'isSending': isSending,
      'shouldStopResponse': shouldStopResponse,
      'scrollPosition': scrollPosition,
      'deepThink': deepThink,
      if (connectPrompt != null) 'connectPrompt': connectPrompt,
      if (systemPrompt != null && systemPrompt!.isNotEmpty)
        'systemPrompt': systemPrompt,
      'sessionQuickCommands':
          sessionQuickCommands.map((command) => command.toJson()).toList(),
      if (scheduledTask != null) 'scheduledTask': scheduledTask!.toJson(),
      if (contracts != null)
        'contracts': contracts!.map((c) => c.toJson()).toList(),
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'totalTokens': totalTokens,
      'totalCost': totalCost,
      if (modelId != null) 'modelId': modelId,
      if (mcps != null && mcps!.isNotEmpty) 'mcps': mcps,
      'chatModel': chatModel?.toMap(),
      'emoji': emoji,
      'apiKey': apiKey,
      if (group != null && group!.isNotEmpty) 'group': group,
      'quotaEnabled': quotaEnabled,
      if (quotaTokenLimit != null) 'quotaTokenLimit': quotaTokenLimit,
      if (quotaCostLimit != null) 'quotaCostLimit': quotaCostLimit,
      if (quotaRequestLimit != null) 'quotaRequestLimit': quotaRequestLimit,
      if (quotaResetPeriod != null) 'quotaResetPeriod': quotaResetPeriod,
      if (quotaPeriodStart != null)
        'quotaPeriodStart': quotaPeriodStart!.toIso8601String(),
      'quotaRequestCount': quotaRequestCount,
      'noAuthEnabled': noAuthEnabled,
    };
  }
}

/// 配额检查结果
class QuotaCheckResult {
  /// 是否超限
  final bool exceeded;

  /// 超限原因（仅供 UI 展示）
  final String? reason;

  /// 详细信息
  final String? detail;

  const QuotaCheckResult({required this.exceeded, this.reason, this.detail});
}
