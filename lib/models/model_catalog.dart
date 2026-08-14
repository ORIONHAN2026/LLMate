/// 本地写死的供应商模型清单，作为 GET /models 不可用时的 fallback。
///
/// key 与 `ModelProvider.id` / `onlineProviders` 的 id 对齐。
library;

/// 模型能力分级：用于省钱路由的「便宜 / 复杂」划分。
enum ModelTier { cheap, complex }

class ModelCatalog {
  /// 显式能力分级表：真实模型 id → 分级（优先级最高，不依赖关键词猜测）。
  ///
  /// 覆盖主流已知模型；未收录的模型走 [tierOf] 的关键词兜底。
  static const Map<String, ModelTier> explicitTiers = {
    // DeepSeek
    'deepseek-v4-flash': ModelTier.cheap,
    'deepseek-v4-pro': ModelTier.complex,
    'deepseek-chat': ModelTier.cheap,
    'deepseek-reasoner': ModelTier.complex,
    // OpenAI
    'gpt-3.5-turbo': ModelTier.cheap,
    'gpt-4o-mini': ModelTier.cheap,
    'gpt-4o': ModelTier.complex,
    'gpt-4-turbo': ModelTier.complex,
    'gpt-4': ModelTier.complex,
    'o1-mini': ModelTier.complex,
    'o1': ModelTier.complex,
    'o3-mini': ModelTier.complex,
    'o3': ModelTier.complex,
    // Google Gemini
    'gemini-2.0-flash': ModelTier.cheap,
    'gemini-2.0-flash-lite': ModelTier.cheap,
    'gemini-1.5-flash': ModelTier.cheap,
    'gemini-pro': ModelTier.complex,
    'gemini-2.5-pro': ModelTier.complex,
    // 通义千问（代表性模型；其余走关键词兜底）
    'qwen-flash': ModelTier.cheap,
    'qwen-turbo': ModelTier.cheap,
    'qwen-plus': ModelTier.complex,
    'qwen-max': ModelTier.complex,
    'qwen-reasoner': ModelTier.complex,
    // 其他厂商
    'glm-4-flash': ModelTier.cheap,
    'glm-4-plus': ModelTier.complex,
    'moonshot-v1-8k': ModelTier.complex,
    'moonshot-v1-32k': ModelTier.complex,
    'moonshot-v1-128k': ModelTier.complex,
  };

  /// 便宜模型关键词兜底（显式表未收录时使用）
  static const List<String> _cheapKeywords = [
    'flash',
    'lite',
    'turbo',
    'mini',
    'air',
    'small',
    'base',
  ];

  /// 复杂模型关键词兜底（显式表未收录时使用）
  static const List<String> _complexKeywords = [
    'reasoner',
    'r1',
    'pro',
    'max',
    'plus',
    'thinking',
    'o1',
    'o3',
    'deep',
    'large',
  ];

  /// 各供应商本地写死的模型 id 列表（真实 API 模型名）
  ///
  /// 注意：`deepseek-chat` / `deepseek-reasoner` 已于 2026/07/24 弃用
  /// （兼容映射到 V4-Flash 的非思考/思考模式），现改用新模型名。
  static const Map<String, List<String>> builtinModels = {
    'deepseek': [
      'deepseek-v4-flash', // 便宜：V4 Flash 通用对话（非思考模式）
      'deepseek-v4-pro', // 复杂：V4 Pro 深度推理
    ],
  };

  /// 取供应商候选模型列表：优先在线查询结果，为空则回退本地写死
  static List<String> resolveModels(String providerId, List<String> online) {
    return online.isNotEmpty
        ? online
        : (builtinModels[providerId] ?? const []);
  }

  /// 判断单个模型的分级：显式表优先，其次关键词兜底，未知返回 null。
  static ModelTier? tierOf(String modelId) {
    final id = modelId.toLowerCase();
    final explicit = explicitTiers[modelId];
    if (explicit != null) return explicit;

    for (final kw in _complexKeywords) {
      if (id.contains(kw)) return ModelTier.complex;
    }
    for (final kw in _cheapKeywords) {
      if (id.contains(kw)) return ModelTier.cheap;
    }
    return null;
  }

  /// 从候选列表自动挑「便宜模型」：显式分级表 → 关键词 → 第一个
  static String? pickCheap(List<String> models) {
    if (models.isEmpty) return null;
    for (final m in models) {
      if (tierOf(m) == ModelTier.cheap) return m;
    }
    for (final kw in _cheapKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.first;
  }

  /// 从候选列表自动挑「复杂模型」：显式分级表 → 关键词 → 最后一个
  static String? pickComplex(List<String> models) {
    if (models.isEmpty) return null;
    for (final m in models) {
      if (tierOf(m) == ModelTier.complex) return m;
    }
    for (final kw in _complexKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.length > 1 ? models.last : null;
  }
}
