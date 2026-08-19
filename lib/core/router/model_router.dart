import '../../models/chat/session.dart';
import '../../models/model.dart';
import '../../models/model_catalog.dart';
import '../../models/model_price_catalog.dart';

/// 一次路由决策的完整明细（供埋点回测调参）。
///
/// 记录决策输入特征（token 估算、成本估算、各信号命中情况）与输出
/// （最终模型、是否使用高能力模型），可序列化 JSON 写入路由日志供离线分析：
/// - 检验各信号阈值是否合理（如 costThreshold 0.03 是否过严/过松）
/// - 统计高能力模型使用率与预估/实际 token 偏差
class RouteDecision {
  final String modelId;
  final String? lightweightModel;
  final String? capableModel;
  final bool usedCapable;

  /// 信号命中明细
  final bool hasTools;
  final bool toolIntentHit;
  final bool hasMultimodal;
  final bool structuredOutputHit;
  final bool simpleIntentHit;
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
  final int complexityScore;

  RouteDecision({
    required this.modelId,
    this.lightweightModel,
    this.capableModel,
    this.usedCapable = false,
    this.hasTools = false,
    this.toolIntentHit = false,
    this.hasMultimodal = false,
    this.structuredOutputHit = false,
    this.simpleIntentHit = false,
    this.intentHit = false,
    this.costHit = false,
    this.lengthHit = false,
    this.lastTextLen = 0,
    this.contextTokens = 0,
    this.estimatedCost,
    this.costThreshold = ModelRouter.costThreshold,
    this.contextTokenThreshold = ModelRouter.contextTokenThreshold,
    this.complexityThreshold = ModelRouter.complexityThreshold,
    this.complexityScore = 0,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'lightweightModel': lightweightModel,
    'capableModel': capableModel,
    'usedCapable': usedCapable,
    'signals': {
      'hasTools': hasTools,
      'toolIntent': toolIntentHit,
      'hasMultimodal': hasMultimodal,
      'structuredOutput': structuredOutputHit,
      'simpleIntent': simpleIntentHit,
      'intent': intentHit,
      'cost': costHit,
      'length': lengthHit,
    },
    'features': {
      'lastTextLen': lastTextLen,
      'contextTokens': contextTokens,
      'estimatedCostCny': estimatedCost,
      'complexityScore': complexityScore,
    },
    'thresholds': {
      'costCny': costThreshold,
      'contextTokens': contextTokenThreshold,
      'lastTextLen': complexityThreshold,
    },
  };
}

/// 自动模型选择器（多信号评分：工具 / 多模态 / 结构化输出 / 意图 / 上下文）
///
/// 决策逻辑：
/// - 关闭模型路由开关（routingEnabled=false）→ 强制使用 [ChatModel.model] 指定模型
/// - 开启开关但轻量/高能力模型无法形成路由对 → 兜底使用 [ChatModel.model]（绝不空发）
/// - 开启且配齐 → 强信号直接使用高能力模型，弱信号累计评分后再升级：
///   ① 工具调用 / 多模态 / 结构化输出 / 明确复杂意图 → 高能力模型
///   ② 上下文较长、用户输入较长等弱信号叠加达阈值 → 高能力模型
///   ③ 明显短闲聊、确认、致谢 → 尽量使用轻量模型
///   这样能减少“短消息也跳高能力模型”的打扰，同时保住复杂任务质量。
class ModelRouter {
  /// 最后一条 user 消息字符数阈值（弱信号，主要用于中长输入分流）
  static const int complexityThreshold = 800;

  /// 中等长度消息阈值：只作为弱信号，不单独升级高能力模型。
  static const int mediumTextThreshold = 280;

  /// 整段上下文（messages 全量文本）预估 token 阈值：超过后加弱信号分
  /// 该值只作为弱信号，避免单纯历史较长就频繁切高能力模型。
  static const int contextTokenThreshold = 3000;

  /// 极长上下文阈值：达到后强烈倾向高能力模型，降低丢上下文或答偏的概率。
  static const int veryLongContextTokenThreshold = 9000;

  /// 弱信号累计分数阈值。
  static const int complexityScoreThreshold = 3;

  /// 预估请求成本阈值（元，CNY）：仅作为观测与弱降噪信号
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
  /// - 开启自动选择：从 [ChatModel.availableModels] 里自动挑「轻量/高能力」
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
    // ① 关闭自动选择开关 → 强制使用指定模型
    if (!model.routingEnabled) {
      return RouteDecision(modelId: model.model);
    }

    // ② 开启开关但轻量/高能力模型未配齐 → 兜底用指定模型（绝不空发）
    final lightweight = model.lightweightModel;
    final capable = model.capableModel;
    if (lightweight == null ||
        lightweight.isEmpty ||
        capable == null ||
        capable.isEmpty) {
      return RouteDecision(modelId: model.model);
    }

    // ③ 多信号路由
    final signals = _pickBySignals(body, model);
    final usedCapable = signals.useCapable;
    return RouteDecision(
      modelId: usedCapable ? capable : lightweight,
      lightweightModel: lightweight,
      capableModel: capable,
      usedCapable: usedCapable,
      hasTools: signals.hasTools,
      toolIntentHit: signals.toolIntentHit,
      hasMultimodal: signals.hasMultimodal,
      structuredOutputHit: signals.structuredOutputHit,
      simpleIntentHit: signals.simpleIntentHit,
      intentHit: signals.intentHit,
      costHit: signals.costHit,
      lengthHit: signals.lengthHit,
      lastTextLen: signals.lastTextLen,
      contextTokens: signals.contextTokens,
      estimatedCost: signals.estimatedCost,
      complexityScore: signals.complexityScore,
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

    // 手动模式：使用会话选定模型，为空回退 chatModel.model
    if (!session.autoSelectModel || !chatModel.routingEnabled) {
      return RouteDecision(modelId: _manualModelFor(session, chatModel));
    }

    final available = _candidateModels(chatModel);

    // 自动模式：从候选池自动挑轻量/高能力（绝不空发）
    if (available.isEmpty) {
      return RouteDecision(modelId: _manualModelFor(session, chatModel));
    }
    if (available.length < 2) {
      return RouteDecision(modelId: available.first);
    }

    final routePair = _resolveRoutePair(chatModel, available);
    if (routePair == null) {
      return RouteDecision(modelId: available.first);
    }

    final signals = _pickBySignals(body, chatModel);
    final usedCapable = signals.useCapable;
    return RouteDecision(
      modelId: usedCapable ? routePair.capable : routePair.lightweight,
      lightweightModel: routePair.lightweight,
      capableModel: routePair.capable,
      usedCapable: usedCapable,
      hasTools: signals.hasTools,
      toolIntentHit: signals.toolIntentHit,
      hasMultimodal: signals.hasMultimodal,
      structuredOutputHit: signals.structuredOutputHit,
      simpleIntentHit: signals.simpleIntentHit,
      intentHit: signals.intentHit,
      costHit: signals.costHit,
      lengthHit: signals.lengthHit,
      lastTextLen: signals.lastTextLen,
      contextTokens: signals.contextTokens,
      estimatedCost: signals.estimatedCost,
      complexityScore: signals.complexityScore,
    );
  }

  /// 失败回退：返回当前模型出错时应切换的高能力模型 id。
  ///
  /// 仅当启用自动选择（routingEnabled）、当前模型恰为轻量模型、
  /// 且轻量/高能力模型均存在且不同时返回高能力模型；否则返回 null。
  /// 供本机 HTTP 服务在轻量模型失败（网络/超时/5xx/429）时重试。
  static String? fallbackModelFor(ChatSession session, String currentModelId) {
    final chatModel = session.chatModel;
    if (chatModel == null ||
        !session.autoSelectModel ||
        !chatModel.routingEnabled) {
      return null;
    }
    final routePair = _resolveRoutePair(chatModel, _candidateModels(chatModel));
    if (routePair == null) return null;
    if (currentModelId != routePair.lightweight) return null;
    return routePair.capable;
  }

  static String _manualModelFor(ChatSession session, ChatModel chatModel) {
    final selected = session.model;
    if (selected != null && selected.isNotEmpty) return selected;
    return chatModel.model;
  }

  static List<String> _candidateModels(ChatModel chatModel) {
    final seen = <String>{};
    final models = <String>[chatModel.model, ...chatModel.availableModels];
    return models
        .where((model) => model.isNotEmpty && seen.add(model))
        .toList(growable: false);
  }

  static _RouteModelPair? _resolveRoutePair(
    ChatModel chatModel,
    List<String> available,
  ) {
    if (available.length < 2) return null;

    final inferredLightweight = ModelCatalog.pickLightweight(available);
    final inferredCapable = ModelCatalog.pickCapable(available);

    var lightweight = _validConfiguredModel(
      chatModel.lightweightModel,
      available,
    );
    var capable = _validConfiguredModel(chatModel.capableModel, available);

    if (_tierOf(lightweight) == ModelTier.capable &&
        inferredLightweight != null &&
        inferredLightweight != lightweight) {
      lightweight = inferredLightweight;
    }

    if (_tierOf(capable) == ModelTier.lightweight &&
        inferredCapable != null &&
        inferredCapable != capable) {
      capable = inferredCapable;
    }

    lightweight ??= inferredLightweight;
    capable ??= inferredCapable;

    if (lightweight == null || capable == null) return null;

    if (lightweight == capable) {
      final lightweightTier = _tierOf(lightweight);
      if (lightweightTier == ModelTier.lightweight &&
          inferredCapable != null &&
          inferredCapable != lightweight) {
        capable = inferredCapable;
      } else if (lightweightTier == ModelTier.capable &&
          inferredLightweight != null &&
          inferredLightweight != capable) {
        lightweight = inferredLightweight;
      } else if (inferredLightweight != null &&
          inferredCapable != null &&
          inferredLightweight != inferredCapable) {
        lightweight = inferredLightweight;
        capable = inferredCapable;
      }
    }

    if (lightweight == capable) return null;
    return _RouteModelPair(lightweight: lightweight, capable: capable);
  }

  static String? _validConfiguredModel(
    String? modelId,
    List<String> available,
  ) {
    if (modelId == null || modelId.isEmpty) return null;
    return available.contains(modelId) ? modelId : null;
  }

  static ModelTier? _tierOf(String? modelId) {
    if (modelId == null || modelId.isEmpty) return null;
    return ModelCatalog.tierOf(modelId);
  }

  /// 多信号判定结果（各信号命中情况 + 决策输入特征）
  static _SignalResult _pickBySignals(
    Map<String, dynamic> body,
    ChatModel? model,
  ) {
    // 信号①：工具定义与工具意图分开处理，避免 MCP 常驻时闲聊也升级。
    final hasTools = _hasTools(body);
    final lastText = _lastUserText(body);
    final toolIntentHit =
        hasTools &&
        (_toolChoiceRequiresToolUse(body) || _requiresToolUse(lastText));
    final hasMultimodal = _hasMultimodalContent(body);
    final structuredOutputHit = _requiresStructuredOutput(body);

    // 信号②：强意图（代码/数学/推理）
    final intentHit = _requiresStrongModel(lastText);
    final simpleIntentHit = _isSimpleIntent(lastText);

    // 信号③：预估成本。成本高本身不直接升级，只用于观测与弱降噪。
    final costResult = _costSignal(body, model);
    final costHit = costResult.$1;
    final contextTokens = costResult.$2;
    final estimatedCost = costResult.$3;

    // 弱信号：最后一条消息字符数。
    final lastTextLen = lastText.runes.length;
    final lengthHit = lastTextLen > complexityThreshold;
    final mediumLengthHit = lastTextLen > mediumTextThreshold;

    var complexityScore = 0;
    if (toolIntentHit) complexityScore += 4;
    if (hasMultimodal) complexityScore += 4;
    if (structuredOutputHit) complexityScore += 3;
    if (intentHit) complexityScore += 3;
    if (contextTokens > veryLongContextTokenThreshold) {
      complexityScore += 3;
    } else if (contextTokens > contextTokenThreshold) {
      complexityScore += 1;
    }
    if (lengthHit) {
      complexityScore += 2;
    } else if (mediumLengthHit) {
      complexityScore += 1;
    }
    if (costHit && !toolIntentHit && !hasMultimodal && !intentHit) {
      complexityScore -= 1;
    }
    if (simpleIntentHit) complexityScore -= 2;

    return _SignalResult(
      hasTools: hasTools,
      toolIntentHit: toolIntentHit,
      hasMultimodal: hasMultimodal,
      structuredOutputHit: structuredOutputHit,
      simpleIntentHit: simpleIntentHit,
      intentHit: intentHit,
      costHit: costHit,
      lengthHit: lengthHit,
      lastTextLen: lastTextLen,
      contextTokens: contextTokens,
      estimatedCost: estimatedCost,
      complexityScore: complexityScore,
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
    final toolChoice = body['tool_choice'];
    if (toolChoice is String && toolChoice.toLowerCase() == 'none') {
      return false;
    }
    if (tools is! List || tools.isEmpty) return false;
    return true;
  }

  static bool _toolChoiceRequiresToolUse(Map<String, dynamic> body) {
    final toolChoice = body['tool_choice'];
    if (toolChoice is Map) return true;
    if (toolChoice is! String) return false;
    final normalized = toolChoice.toLowerCase();
    return normalized != 'none' && normalized != 'auto';
  }

  static bool _hasMultimodalContent(Map<String, dynamic> body) {
    final messages = body['messages'];
    if (messages is! List) return false;
    for (final m in messages) {
      if (m is! Map) continue;
      final content = m['content'];
      if (content is! List) continue;
      for (final part in content) {
        if (part is! Map) continue;
        final type = '${part['type'] ?? ''}';
        if (type != 'text' && type.isNotEmpty) return true;
        if (part.containsKey('image_url') ||
            part.containsKey('input_image') ||
            part.containsKey('file')) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _requiresStructuredOutput(Map<String, dynamic> body) {
    final responseFormat = body['response_format'];
    if (responseFormat is Map) {
      final type = '${responseFormat['type'] ?? ''}'.toLowerCase();
      if (type.contains('json_schema')) return true;
    }
    return false;
  }

  static bool _requiresToolUse(String text) {
    if (text.isEmpty) return false;
    return RegExp(
      r'(查一下|查询|搜索|联网|打开|读取|获取|调用|执行|运行|数据库|文件|订单|天气|日程|发送|创建|删除|更新|同步|导入|导出|search|lookup|fetch|open|read|call|execute|run|database|file|order|weather|schedule|send|create|delete|update|sync|import|export)',
      caseSensitive: false,
    ).hasMatch(text);
  }

  /// 强意图检测：代码 / 数学 / 深度推理类任务交给高能力模型。
  ///
  /// 用轻量正则匹配常见触发点，避免把「闲聊」误判成强任务。
  static bool _requiresStrongModel(String text) {
    if (text.isEmpty) return false;
    // 代码相关（``` 代码块 / 明确的编程指令）
    if (text.contains('```')) return true;
    if (RegExp(
      r'\b(debug|refactor|implement|fix\s+(bug|build)|write\s+(a\s+)?(function|class|test)|explain\s+this\s+code|code\s+review|optimize|architecture)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return true;
    }
    // 数学 / 推理
    if (RegExp(
      r'\b(prove|derive|solve|calculate|reason|deduce|formal\s+proof|analyze|compare|plan)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return true;
    }
    if (RegExp(
      r'(代码|报错|调试|重构|实现|函数|测试|架构|推理|证明|数学|计算|规划|深入分析|对比|复杂|方案|优化)',
    ).hasMatch(text)) {
      return true;
    }
    return false;
  }

  static bool _isSimpleIntent(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty || normalized.runes.length > 80) return false;
    if (RegExp(
      r'^(hi|hello|hey|ok|okay|thanks|thank you|yes|no|yep|nope)[.!。！\s]*$',
    ).hasMatch(normalized)) {
      return true;
    }
    if (RegExp(
      r'^(你好|您好|在吗|好的|可以|收到|谢谢|感谢|嗯|行|是的|不是)[。！!.\s]*$',
    ).hasMatch(normalized)) {
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
  final bool toolIntentHit;
  final bool hasMultimodal;
  final bool structuredOutputHit;
  final bool simpleIntentHit;
  final bool intentHit;
  final bool costHit;
  final bool lengthHit;
  final int lastTextLen;
  final int contextTokens;
  final double? estimatedCost;
  final int complexityScore;

  const _SignalResult({
    required this.hasTools,
    required this.toolIntentHit,
    required this.hasMultimodal,
    required this.structuredOutputHit,
    required this.simpleIntentHit,
    required this.intentHit,
    required this.costHit,
    required this.lengthHit,
    required this.lastTextLen,
    required this.contextTokens,
    required this.estimatedCost,
    required this.complexityScore,
  });

  bool get useCapable =>
      toolIntentHit ||
      hasMultimodal ||
      structuredOutputHit ||
      intentHit ||
      complexityScore >= ModelRouter.complexityScoreThreshold;
}

class _RouteModelPair {
  final String lightweight;
  final String capable;

  const _RouteModelPair({required this.lightweight, required this.capable});
}
