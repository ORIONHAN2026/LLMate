/// 本地写死的供应商模型清单，作为 GET /models 不可用时的 fallback。
///
/// key 与 `ModelProvider.id` / `onlineProviders` 的 id 对齐。
library;

/// 模型能力分级：用于自动模型选择的「轻量 / 高能力」划分。
enum ModelTier { lightweight, capable }

class ModelCatalog {
  /// 显式能力分级表：真实模型 id → 分级（优先级最高，不依赖关键词猜测）。
  ///
  /// 覆盖主流已知模型；未收录的模型走 [tierOf] 的关键词兜底。
  static const Map<String, ModelTier> explicitTiers = {
    // DeepSeek
    'deepseek-v4-flash': ModelTier.lightweight,
    'deepseek-v4-pro': ModelTier.capable,
    'deepseek-chat': ModelTier.lightweight,
    'deepseek-reasoner': ModelTier.capable,
    // OpenAI
    'gpt-3.5-turbo': ModelTier.lightweight,
    'gpt-4.1-mini': ModelTier.lightweight,
    'gpt-4.1-nano': ModelTier.lightweight,
    'gpt-4o-mini': ModelTier.lightweight,
    'gpt-5-mini': ModelTier.lightweight,
    'gpt-5-nano': ModelTier.lightweight,
    'gpt-5.1': ModelTier.capable,
    'gpt-5': ModelTier.capable,
    'gpt-4.1': ModelTier.capable,
    'gpt-4o': ModelTier.capable,
    'gpt-4-turbo': ModelTier.capable,
    'gpt-4': ModelTier.capable,
    'o1-mini': ModelTier.capable,
    'o1': ModelTier.capable,
    'o3-mini': ModelTier.capable,
    'o3': ModelTier.capable,
    // Google Gemini
    'gemini-3-pro': ModelTier.capable,
    'gemini-2.5-flash': ModelTier.lightweight,
    'gemini-2.5-flash-lite': ModelTier.lightweight,
    'gemini-2.0-flash': ModelTier.lightweight,
    'gemini-2.0-flash-lite': ModelTier.lightweight,
    'gemini-1.5-flash': ModelTier.lightweight,
    'gemini-pro': ModelTier.capable,
    'gemini-2.5-pro': ModelTier.capable,
    // 通义千问（代表性模型；其余走关键词兜底）
    'qwen-flash': ModelTier.lightweight,
    'qwen-turbo': ModelTier.lightweight,
    'qwen-plus': ModelTier.capable,
    'qwen-max': ModelTier.capable,
    'qwen-reasoner': ModelTier.capable,
    // 其他厂商
    'glm-4-flash': ModelTier.lightweight,
    'glm-4.5-air': ModelTier.lightweight,
    'glm-4.5': ModelTier.capable,
    'glm-4-plus': ModelTier.capable,
    'moonshot-v1-8k': ModelTier.capable,
    'moonshot-v1-32k': ModelTier.capable,
    'moonshot-v1-128k': ModelTier.capable,
  };

  /// 轻量模型关键词兜底（显式表未收录时使用）
  static const List<String> _lightweightKeywords = [
    'flash',
    'lite',
    'turbo',
    'mini',
    'air',
    'small',
    'base',
  ];

  /// 高能力模型关键词兜底（显式表未收录时使用）
  static const List<String> _capableKeywords = [
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
      'deepseek-v4-flash', // 轻量：V4 Flash 通用对话（非思考模式）
      'deepseek-v4-pro', // 高能力：V4 Pro 深度推理
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    'openai': [
      'gpt-5.1',
      'gpt-5',
      'gpt-5-mini',
      'gpt-5-nano',
      'gpt-4.1',
      'gpt-4.1-mini',
      'gpt-4.1-nano',
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-3.5-turbo',
      'o3',
      'o3-mini',
      'o1',
      'o1-mini',
    ],
    'google': [
      'gemini-3-pro',
      'gemini-2.5-pro',
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-1.5-pro',
      'gemini-1.5-flash',
      'gemini-pro',
    ],
    'zhipu': [
      'glm-4.5',
      'glm-4.5-air',
      'glm-4-plus',
      'glm-4-air',
      'glm-4-flash',
    ],
    'qwen': [
      'qwen3.7-max',
      'qwen3.7-plus',
      'qwen3.6-flash',
      'qwen3-max',
      'qwen3-plus',
      'qwen3-flash',
      'qwen3-coder-plus',
      'qwen3-coder-flash',
      'qwen-plus',
      'qwen-max',
      'qwen-turbo',
      'qwen-long',
      'qwq-plus',
      'qvq-max',
    ],
    'tencent': [
      'hy3-preview',
      'hunyuan-turbos-latest',
      'hunyuan-large',
      'hunyuan-lite',
      'deepseek-v4-flash',
      'deepseek-v4-pro',
      'deepseek-v3.2',
      'glm-5.2',
      'glm-5.1',
      'kimi-k2.7-code',
      'kimi-k2.6',
      'minimax-m3',
      'qwen3.5-flash',
      'qwen3.5-plus',
    ],
    'xiaomi_mimo': ['mimo-v2.5-pro', 'mimo-v2.5-lite'],
  };

  static String displayName(String modelId) {
    return modelId
        .split(RegExp(r'[-_]'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final lower = part.toLowerCase();
          if (lower == 'gpt' ||
              lower == 'glm' ||
              lower == 'qwen' ||
              lower == 'kimi' ||
              lower == 'mimo') {
            return part.toUpperCase();
          }
          if (part.length <= 3 && RegExp(r'^[a-zA-Z0-9.]+$').hasMatch(part)) {
            return part.toUpperCase();
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join('-');
  }

  static String shortDescription(String modelId) {
    final tier = tierOf(modelId);
    final capability = switch (tier) {
      ModelTier.lightweight => '快速响应 • 适合日常对话',
      ModelTier.capable => '高能力模型 • 推理与长文本',
      null => '通用模型',
    };
    return capability;
  }

  /// 取供应商候选模型列表：优先在线查询结果，为空则回退本地写死
  static List<String> resolveModels(String providerId, List<String> online) {
    return online.isNotEmpty ? online : (builtinModels[providerId] ?? const []);
  }

  /// 判断单个模型的分级：显式表优先，其次关键词兜底，未知返回 null。
  static ModelTier? tierOf(String modelId) {
    final id = modelId.toLowerCase();
    final explicit = explicitTiers[modelId];
    if (explicit != null) return explicit;

    for (final kw in _capableKeywords) {
      if (id.contains(kw)) return ModelTier.capable;
    }
    for (final kw in _lightweightKeywords) {
      if (id.contains(kw)) return ModelTier.lightweight;
    }
    return null;
  }

  /// 从候选列表自动挑「轻量模型」：显式分级表 → 关键词 → 第一个
  static String? pickLightweight(List<String> models) {
    if (models.isEmpty) return null;
    for (final m in models) {
      if (tierOf(m) == ModelTier.lightweight) return m;
    }
    for (final kw in _lightweightKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.first;
  }

  /// 从候选列表自动挑「高能力模型」：显式分级表 → 关键词 → 最后一个
  static String? pickCapable(List<String> models) {
    if (models.isEmpty) return null;
    for (final m in models) {
      if (tierOf(m) == ModelTier.capable) return m;
    }
    for (final kw in _capableKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.length > 1 ? models.last : null;
  }
}
