import '../../models/chat/session.dart';
import '../../models/model.dart';
import '../../models/model_catalog.dart';
import '../../models/model_price_catalog.dart';

/// 一次路由决策的完整明细（供埋点回测调参）。
///
/// 记录决策输入特征（token 估算、成本估算、各信号命中情况）与输出
/// （最终模型、是否复杂），可序列化 JSON 写入路由日志供离线分析：
/// - 检验各信号阈值是否合理（如 costThreshold 0.03 是否过严/过松）
/// - 统计复杂模型使用率与预估/实际 token 偏差
class RouteDecision {
  final String modelId;
  final String? cheapModel;
  final String? complexModel;
  final bool usedComplex;

  /// 信号命中明细
  final bool hasTools;
  final bool intentHit;
  final bool costHit;
  final bool lengthHit;

  /// 决策输入特征
  final int lastTextLen;
  final int contextTokens;
  final double? estimatedCost;

  /// 决策时使用的阈值（回测时便于对齐调整前后差异）
  final double costThreshold;
  final int contextTokenThreshold;
  final int complexityThreshold;

  RouteDecision({
    required this.modelId,
    this.cheapModel,
    this.complexModel,
    this.usedComplex = false,
    this.hasTools = false,
    this.intentHit = false,
    this.costHit = false,
    this.lengthHit = false,
    this.lastTextLen = 0,
    this.contextTokens = 0,
    this.estimatedCost,
    this.costThreshold = ModelRouter.costThreshold,
    this.contextTokenThreshold = ModelRouter.contextTokenThreshold,
    this.complexityThreshold = ModelRouter.complexityThreshold,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'cheapModel': cheapModel,
    'complexModel': complexModel,
    'usedComplex': usedComplex,
    'signals': {
      'hasTools': hasTools,
      'intent': intentHit,
      'cost': costHit,
      'length': lengthHit,
    },
    'features': {
      'lastTextLen': lastTextLen,
      'contextTokens': contextTokens,
      'estimatedCostCny': estimatedCost,
    },
    'thresholds': {
      'costCny': costThreshold,
      'contextTokens': contextTokenThreshold,
      'lastTextLen': complexityThreshold,
    },
  };
}

/// 省钱路由判断器（多信号：预估 token 累计 + 意图 + 工具调用 + 成本）
///
/// 决策逻辑：
/// - 关闭费用优化开关（routingEnabled=false）→ 强制使用 [ChatModel.model] 指定模型
/// - 开启开关但便宜/复杂模型未配齐 → 兜底使用 [ChatModel.model]（绝不空发）
/// - 开启且配齐 → 依次检查以下信号，任一命中走复杂模型：
///   ① 本次请求携带工具定义（tools）→ 复杂模型（工具遵循能力更强）
///   ② 最后一条 user 消息命中强意图（代码/数学/深度推理）→ 复杂模型
///   ③ 预估请求成本（含历史上下文）超阈值 → 复杂模型（无价格时退化为 token 阈值）
///   ④ 最后一条 user 消息超过字符阈值 → 复杂模型（弱信号）
///   以上均未命中 → 便宜模型
class ModelRouter {
  /// 最后一条 user 消息字符数阈值（保留为弱信号，主要用于短文本快速分流）
  static const int complexityThreshold = 200;

  /// 整段上下文（messages 全量文本）预估 token 阈值：超过则送复杂模型
  /// （仅在模型没有价格信息时退化为该 token 阈值）
  static const int contextTokenThreshold = 3000;

  /// 预估请求成本阈值（元，CNY）：有价格信息时，预估成本超过则送复杂模型
  static const double costThreshold = 0.03;

  /// 决策本次请求用哪个模型（返回模型 id，写入 body['model']）
  static String decide({
    required ChatModel model,
    required Map<String, dynamic> body,
  }) {
    return decideDetailed(model: model, body: body).modelId;
  }

  /// 决策本次请求用哪个模型（会话级模型设置）。
  ///
  /// - [ChatSession.autoSelectModel] 为 false：使用 [ChatSession.model]
  ///   （手动选定），为空则回退 [ChatModel.model]。
  /// - 开启自动选择：从 [ChatModel.availableModels] 里自动挑「便宜/复杂」
  ///   模型，并按多信号路由（见类注释），候选池为可用模型清单。
  static String decideForSession({
    required ChatSession session,
    required Map<String, dynamic> body,
  }) {
    return decideForSessionDetailed(session: session, body: body).modelId;
  }

  /// [decide] 的明细版：返回完整 [RouteDecision]，供埋点记录。
  static RouteDecision decideDetailed({
    required ChatModel model,
    required Map<String, dynamic> body,
  }) {
    // ① 关闭费用优化开关 → 强制使用指定模型（等价老行为）
    if (!model.routingEnabled) {
      return RouteDecision(modelId: model.model);
    }

    // ② 开启开关但便宜/复杂模型未配齐 → 兜底用指定模型（绝不空发）
    final cheap = model.cheapModel;
    final complex = model.complexModel;
    if (cheap == null ||
        cheap.isEmpty ||
        complex == null ||
        complex.isEmpty) {
      return RouteDecision(modelId: model.model);
    }

    // ③ 多信号路由
    final signals = _pickBySignals(body, model);
    final usedComplex = signals.any;
    return RouteDecision(
      modelId: usedComplex ? complex : cheap,
      cheapModel: cheap,
      complexModel: complex,
      usedComplex: usedComplex,
      hasTools: signals.hasTools,
      intentHit: signals.intentHit,
      costHit: signals.costHit,
      lengthHit: signals.lengthHit,
      lastTextLen: signals.lastTextLen,
      contextTokens: signals.contextTokens,
      estimatedCost: signals.estimatedCost,
    );
  }

  /// [decideForSession] 的明细版：返回完整 [RouteDecision]，供埋点记录。
  static RouteDecision decideForSessionDetailed({
    required ChatSession session,
    required Map<String, dynamic> body,
  }) {
    final chatModel = session.chatModel;
    if (chatModel == null) {
      return RouteDecision(modelId: session.model ?? '');
    }

    final available = chatModel.availableModels.isNotEmpty
        ? chatModel.availableModels
        : (chatModel.model.isNotEmpty
              ? [chatModel.model]
              : const <String>[]);

    // 手动模式：使用会话选定模型，为空回退 chatModel.model
    if (!session.autoSelectModel) {
      final selected = session.model;
      return RouteDecision(
        modelId: (selected != null && selected.isNotEmpty)
            ? selected
            : chatModel.model,
      );
    }

    // 自动模式：从候选池自动挑便宜/复杂（绝不空发）
    if (available.isEmpty) {
      return RouteDecision(modelId: chatModel.model);
    }
    if (available.length < 2) {
      return RouteDecision(modelId: available.first);
    }

    final cheap = ModelCatalog.pickCheap(available);
    final complex = ModelCatalog.pickComplex(available);
    if (cheap == null || complex == null) {
      return RouteDecision(modelId: available.first);
    }

    final signals = _pickBySignals(body, chatModel);
    final usedComplex = signals.any;
    return RouteDecision(
      modelId: usedComplex ? complex : cheap,
      cheapModel: cheap,
      complexModel: complex,
      usedComplex: usedComplex,
      hasTools: signals.hasTools,
      intentHit: signals.intentHit,
      costHit: signals.costHit,
      lengthHit: signals.lengthHit,
      lastTextLen: signals.lastTextLen,
      contextTokens: signals.contextTokens,
      estimatedCost: signals.estimatedCost,
    );
  }

  /// 失败回退：返回当前模型出错时应切换的复杂模型 id。
  ///
  /// 仅当启用费用优化（routingEnabled）、当前模型恰为便宜模型、
  /// 且便宜/复杂模型均存在且不同时返回复杂模型；否则返回 null。
  /// 供本机 HTTP 服务在便宜模型失败（网络/超时/5xx/429）时重试。
  static String? fallbackModelFor(ChatSession session, String currentModelId) {
    final chatModel = session.chatModel;
    if (chatModel == null || !chatModel.routingEnabled) return null;
    final cheap = chatModel.cheapModel;
    final complex = chatModel.complexModel;
    if (cheap == null || cheap.isEmpty || complex == null || complex.isEmpty) {
      return null;
    }
    if (currentModelId != cheap) return null;
    if (cheap == complex) return null;
    return complex;
  }

  /// 多信号判定结果（各信号命中情况 + 决策输入特征）
  static _SignalResult _pickBySignals(
    Map<String, dynamic> body,
    ChatModel? model,
  ) {
    // 信号①：工具调用
    final hasTools = _hasTools(body);

    final lastText = _lastUserText(body);

    // 信号②：强意图（代码/数学/推理）
    final intentHit = _requiresStrongModel(lastText);

    // 信号③：预估成本（有价格时按成本，否则按 token 阈值）
    final costResult = _costSignal(body, model);
    final costHit = costResult.$1;
    final contextTokens = costResult.$2;
    final estimatedCost = costResult.$3;

    // 弱信号：最后一条消息字符数
    final lastTextLen = lastText.runes.length;
    final lengthHit = lastTextLen > complexityThreshold;

    return _SignalResult(
      hasTools: hasTools,
      intentHit: intentHit,
      costHit: costHit,
      lengthHit: lengthHit,
      lastTextLen: lastTextLen,
      contextTokens: contextTokens,
      estimatedCost: estimatedCost,
    );
  }

  /// 成本信号：估算本次请求成本（含历史上下文与预估输出）。
  ///
  /// 返回 `(是否命中成本阈值, 上下文 token 估算, 预估成本元)`。
  /// - 模型有价格信息（用户配置或内置表）→ 按预估成本与 [costThreshold] 比较
  /// - 无价格信息 → 退化为上下文 token 与 [contextTokenThreshold] 比较
  static (bool, int, double?) _costSignal(
    Map<String, dynamic> body,
    ChatModel? model,
  ) {
    final tokens = _contextTokenEstimate(body);
    if (tokens <= 0) return (false, 0, null);
    final cost = ModelPriceCatalog.estimateCost(
      model?.model ?? '',
      promptTokens: tokens,
      customPrompt: model?.promptPrice,
      customCompletion: model?.completionPrice,
      customCurrency: model?.currency,
    );
    if (cost != null) return (cost > costThreshold, tokens, cost);
    return (tokens > contextTokenThreshold, tokens, null);
  }

  /// 判断请求是否携带工具定义
  static bool _hasTools(Map<String, dynamic> body) {
    final tools = body['tools'];
    if (tools is List && tools.isNotEmpty) return true;
    final toolChoice = body['tool_choice'];
    if (toolChoice != null && toolChoice is! String) return true;
    if (toolChoice is String && toolChoice.isNotEmpty) return true;
    return false;
  }

  /// 强意图检测：代码 / 数学 / 深度推理类任务交给复杂模型。
  ///
  /// 用轻量正则匹配常见触发点，避免把「闲聊」误判成强任务。
  static bool _requiresStrongModel(String text) {
    if (text.isEmpty) return false;
    // 代码相关（``` 代码块 / 明确的编程指令）
    if (text.contains('```')) return true;
    if (RegExp(r'\b(debug|refactor|implement|fix\s+b(ug|uild)|write\s+(a\s+)?(function|class|test)|explain\s+this\s+code|code\s+review)\b',
            caseSensitive: false)
        .hasMatch(text)) {
      return true;
    }
    // 数学 / 推理
    if (RegExp(r'\b(prove|derive|solve|calculate|reason|deduce|formal\s+proof)\b',
            caseSensitive: false)
        .hasMatch(text)) {
      return true;
    }
    return false;
  }

  /// 粗略估算一段文本的 token 数：
  /// CJK 字符 ≈ 1 token/字，其余字符 ≈ 0.3 token/字。
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    var cjk = 0;
    var nonCjk = 0;
    for (final unit in text.runes) {
      final c = String.fromCharCode(unit);
      final code = unit;
      // CJK 统一表意文字 / 扩展 / 全角标点
      final isCjk =
          (code >= 0x4E00 && code <= 0x9FFF) ||
          (code >= 0x3400 && code <= 0x4DBF) ||
          (code >= 0xF900 && code <= 0xFAFF) ||
          (code >= 0xFF00 && code <= 0xFFEF);
      if (isCjk) {
        cjk++;
      } else if (!RegExp(r'\s').hasMatch(c)) {
        nonCjk++;
      }
    }
    return cjk + (nonCjk * 0.3).round();
  }

  /// 估算整个 messages 的上下文 token 总量（含系统提示与历史）
  static int _contextTokenEstimate(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is! List) return 0;
    var total = 0;
    for (final m in messages) {
      if (m is! Map) continue;
      // system 消息计入（system prompt 本身占用上下文）
      final role = m['role'];
      final content = m['content'];
      if (content is String) {
        total += estimateTokens(content);
      } else if (content is List) {
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            total += estimateTokens(part['text'] ?? '');
          }
        }
      }
      // 工具调用结果可能很长，计入上下文
      if (role == 'tool' && m['content'] is String) {
        total += estimateTokens(m['content'] as String);
      }
    }
    return total;
  }

  /// 提取最后一条 role=user 的文本内容（兼容纯文本与多模态 content 数组）
  static String _lastUserText(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is! List) return '';
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m is! Map || m['role'] != 'user') continue;
      final content = m['content'];
      if (content is String) return content;
      if (content is List) {
        final sb = StringBuffer();
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            sb.write(part['text'] ?? '');
          }
        }
        return sb.toString();
      }
    }
    return '';
  }
}

/// 多信号判定结果（内部使用）
class _SignalResult {
  final bool hasTools;
  final bool intentHit;
  final bool costHit;
  final bool lengthHit;
  final int lastTextLen;
  final int contextTokens;
  final double? estimatedCost;

  const _SignalResult({
    required this.hasTools,
    required this.intentHit,
    required this.costHit,
    required this.lengthHit,
    required this.lastTextLen,
    required this.contextTokens,
    required this.estimatedCost,
  });

  /// 任一信号命中 → 使用复杂模型
  bool get any => hasTools || intentHit || costHit || lengthHit;
}
