/// 模型价格表与成本估算
///
/// 用途：
/// 1. 为智能选模提供「成本信号」：当模型配置了价格时，用预估成本而非
///    纯 token 长度做决策；
/// 2. 为后续「预算上限 / 费用预估」功能提供统一取价入口。
///
/// 优先级：用户自定义价格（ChatModel.promptPrice/completionPrice） >
/// 内置价格表 > 关键词兜底 > null。
library;

/// 货币类型
enum PriceCurrency { cny, usd }

/// 每百万 token 的价格
class ModelPrice {
  /// 输入价格（/百万 token）
  final double prompt;

  /// 输出价格（/百万 token）
  final double completion;

  /// 货币类型
  final PriceCurrency currency;

  const ModelPrice({
    required this.prompt,
    required this.completion,
    this.currency = PriceCurrency.cny,
  });

  /// 统一折算为人民币（元）便于成本比较
  double get promptCny => currency == PriceCurrency.cny ? prompt : prompt * 7.2;

  double get completionCny =>
      currency == PriceCurrency.cny ? completion : completion * 7.2;
}

/// 内置价格表（近似参考价，单位为「元/百万 token」，CNY 计价）
///
/// 数据为常见模型的公开定价近似值；用户自定义价格始终优先于此表。
class ModelPriceCatalog {
  static const Map<String, ModelPrice> _builtin = {
    // DeepSeek
    'deepseek-v4-flash': ModelPrice(prompt: 0.5, completion: 2.0),
    'deepseek-v4-pro': ModelPrice(prompt: 4.0, completion: 16.0),
    // OpenAI
    'gpt-3.5-turbo': ModelPrice(prompt: 3.6, completion: 10.8),
    'gpt-4o-mini': ModelPrice(prompt: 1.1, completion: 4.4),
    'gpt-4o': ModelPrice(prompt: 18.0, completion: 72.0),
    'gpt-4-turbo': ModelPrice(prompt: 72.0, completion: 216.0),
    // Google Gemini
    'gemini-2.0-flash': ModelPrice(prompt: 0.7, completion: 2.2),
    'gemini-2.0-flash-lite': ModelPrice(prompt: 0.4, completion: 1.0),
    'gemini-2.5-pro': ModelPrice(prompt: 9.0, completion: 36.0),
    // 通义千问
    'qwen-flash': ModelPrice(prompt: 0.3, completion: 0.6),
    'qwen-turbo': ModelPrice(prompt: 0.7, completion: 2.0),
    'qwen-plus': ModelPrice(prompt: 2.5, completion: 8.0),
    'qwen-max': ModelPrice(prompt: 15.0, completion: 50.0),
    // 智谱
    'glm-4-flash': ModelPrice(prompt: 0.1, completion: 0.1),
    'glm-4-plus': ModelPrice(prompt: 7.0, completion: 7.0),
    // Moonshot
    'moonshot-v1-8k': ModelPrice(prompt: 4.0, completion: 12.0),
    'moonshot-v1-32k': ModelPrice(prompt: 4.0, completion: 12.0),
    'moonshot-v1-128k': ModelPrice(prompt: 4.0, completion: 12.0),
  };

  /// 兜底价格：未收录模型按能力分级给保守参考价
  static const ModelPrice _lightweightFallbackPrice = ModelPrice(
    prompt: 1.0,
    completion: 3.0,
  );
  static const ModelPrice _capableFallbackPrice = ModelPrice(
    prompt: 3.0,
    completion: 10.0,
  );

  /// 取模型价格。
  ///
  /// [customPrompt]/[customCompletion] 为用户在模型配置里填写的价格
  /// （/百万 token，[customCurrency] 为其货币）；两者都填写时优先使用。
  /// 否则查内置表；再否则按轻量/高能力分级给保守兜底价；仍未知返回 null。
  static ModelPrice? priceOf(
    String modelId, {
    double? customPrompt,
    double? customCompletion,
    String? customCurrency,
  }) {
    // 1. 用户自定义价格（需输入/输出都填写）
    if (customPrompt != null && customCompletion != null) {
      return ModelPrice(
        prompt: customPrompt,
        completion: customCompletion,
        currency:
            customCurrency == 'CNY' ? PriceCurrency.cny : PriceCurrency.usd,
      );
    }

    // 2. 内置价格表
    final builtin = _builtin[modelId];
    if (builtin != null) return builtin;

    // 3. 关键词兜底：按能力分级给保守参考价
    final id = modelId.toLowerCase();
    if (RegExp(r'flash|lite|turbo|mini|air|small|base').hasMatch(id)) {
      return _lightweightFallbackPrice;
    }
    if (RegExp(r'reasoner|r1|pro|max|plus|thinking|o1|o3').hasMatch(id)) {
      return _capableFallbackPrice;
    }
    return null;
  }

  /// 估算一次请求的成本（元，CNY）。
  ///
  /// [promptTokens] 为上下文预估 token 数（含历史），
  /// [completionTokens] 为预估输出 token 数（可传 null，按输入的 1/3 估算）。
  /// 无价格信息时返回 null。
  static double? estimateCost(
    String modelId, {
    required int promptTokens,
    int? completionTokens,
    double? customPrompt,
    double? customCompletion,
    String? customCurrency,
  }) {
    final price = priceOf(
      modelId,
      customPrompt: customPrompt,
      customCompletion: customCompletion,
      customCurrency: customCurrency,
    );
    if (price == null || promptTokens <= 0) return null;
    final outTokens = completionTokens ?? (promptTokens * 0.3).round();
    return promptTokens * price.promptCny / 1e6 +
        outTokens * price.completionCny / 1e6;
  }
}
