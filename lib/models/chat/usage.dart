/// 单次请求的用量明细
class UsageDetail {
  final String sessionId;
  final DateTime timestamp;
  final int promptTokens;
  final int completionTokens;
  final int cacheWriteTokens;
  final int cacheReadTokens;
  final double cost;
  final String modelId;
  final String currency;

  int get totalTokens => promptTokens + completionTokens;
  int get cacheTokens => cacheWriteTokens + cacheReadTokens;

  const UsageDetail({
    required this.sessionId,
    required this.timestamp,
    required this.promptTokens,
    required this.completionTokens,
    this.cacheWriteTokens = 0,
    this.cacheReadTokens = 0,
    required this.cost,
    required this.modelId,
    this.currency = 'USD',
  });

  factory UsageDetail.fromJson(Map<String, dynamic> json) {
    return UsageDetail(
      sessionId: json['sessionId'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      promptTokens: json['promptTokens'] as int,
      completionTokens: json['completionTokens'] as int,
      cacheWriteTokens: json['cacheWriteTokens'] as int? ?? 0,
      cacheReadTokens: json['cacheReadTokens'] as int? ?? 0,
      cost: (json['cost'] as num).toDouble(),
      modelId: json['modelId'] as String,
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
    'totalTokens': totalTokens,
    'cacheWriteTokens': cacheWriteTokens,
    'cacheReadTokens': cacheReadTokens,
    'cacheTokens': cacheTokens,
    'cost': cost,
    'modelId': modelId,
    'currency': currency,
  };
}

/// 按分钟累计的用量统计，按货币区分费用。
class UsageStats {
  int requests;
  int promptTokens;
  int completionTokens;
  int cacheWriteTokens;
  int cacheReadTokens;

  /// 按货币累计的费用，key 为货币代码（如 USD、CNY）
  Map<String, double> costsByCurrency;
  List<UsageDetail> details;

  int get totalTokens => promptTokens + completionTokens;
  int get cacheTokens => cacheWriteTokens + cacheReadTokens;

  /// 所有货币的总费用
  double get totalCost => costsByCurrency.values.fold(0.0, (sum, c) => sum + c);

  UsageStats({
    this.requests = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.cacheWriteTokens = 0,
    this.cacheReadTokens = 0,
    Map<String, double>? costsByCurrency,
    List<UsageDetail>? details,
  }) : costsByCurrency = costsByCurrency ?? {},
       details = details ?? [];

  /// 添加一次请求明细，自动累计（token + 按货币累加费用）
  void add(UsageDetail detail) {
    requests++;
    promptTokens += detail.promptTokens;
    completionTokens += detail.completionTokens;
    cacheWriteTokens += detail.cacheWriteTokens;
    cacheReadTokens += detail.cacheReadTokens;
    costsByCurrency.update(
      detail.currency,
      (current) => current + detail.cost,
      ifAbsent: () => detail.cost,
    );
    details.add(detail);
  }

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    final rawCosts = json['costsByCurrency'] as Map<String, dynamic>?;
    final costs = <String, double>{};
    if (rawCosts != null) {
      rawCosts.forEach((k, v) {
        costs[k] = (v as num).toDouble();
      });
    }

    return UsageStats(
      requests: json['requests'] as int,
      promptTokens: json['promptTokens'] as int,
      completionTokens: json['completionTokens'] as int,
      cacheWriteTokens: json['cacheWriteTokens'] as int? ?? 0,
      cacheReadTokens: json['cacheReadTokens'] as int? ?? 0,
      costsByCurrency: costs,
      details:
          (json['details'] as List<dynamic>?)
              ?.map((d) => UsageDetail.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'requests': requests,
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
    'totalTokens': totalTokens,
    'cacheWriteTokens': cacheWriteTokens,
    'cacheReadTokens': cacheReadTokens,
    'cacheTokens': cacheTokens,
    'costsByCurrency': costsByCurrency,
    'totalCost': totalCost,
    'details': details.map((d) => d.toJson()).toList(),
  };

  /// 创建空的用量统计条目
  factory UsageStats.empty() {
    return UsageStats();
  }
}
