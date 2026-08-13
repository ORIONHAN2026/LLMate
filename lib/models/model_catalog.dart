/// 本地写死的供应商模型清单，作为 GET /models 不可用时的 fallback。
///
/// key 与 `ModelProvider.id` / `onlineProviders` 的 id 对齐。
class ModelCatalog {
  /// 便宜模型关键词（命中优先作为 cheapModel）
  static const List<String> _cheapKeywords = [
    'chat',
    'flash',
    'lite',
    'turbo',
    'mini',
    'air',
  ];

  /// 复杂模型关键词（命中优先作为 complexModel）
  static const List<String> _complexKeywords = [
    'reasoner',
    'r1',
    'pro',
    'max',
    'plus',
    'thinking',
    'o1',
    'o3',
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

  /// 从候选列表自动挑「便宜模型」：命中 cheap 关键词，否则第一个
  static String? pickCheap(List<String> models) {
    if (models.isEmpty) return null;
    for (final kw in _cheapKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.first;
  }

  /// 从候选列表自动挑「复杂模型」：命中 complex 关键词，否则最后一个
  static String? pickComplex(List<String> models) {
    if (models.isEmpty) return null;
    for (final kw in _complexKeywords) {
      for (final m in models) {
        if (m.toLowerCase().contains(kw)) return m;
      }
    }
    return models.length > 1 ? models.last : null;
  }
}
