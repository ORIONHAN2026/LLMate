/// 单次请求的用量明细
class UsageDetail {
  final DateTime timestamp;
  final int promptTokens;
  final int completionTokens;
  final double cost;
  final String model;
  final String currency;

  int get totalTokens => promptTokens + completionTokens;

  const UsageDetail({
    required this.timestamp,
    required this.promptTokens,
    required this.completionTokens,
    required this.cost,
    required this.model,
    this.currency = 'USD',
  });

  factory UsageDetail.fromJson(Map<String, dynamic> json) {
    return UsageDetail(
      timestamp: DateTime.parse(json['timestamp'] as String),
      promptTokens: json['promptTokens'] as int,
      completionTokens: json['completionTokens'] as int,
      cost: (json['cost'] as num).toDouble(),
      model: json['model'] as String,
      currency: json['currency'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'promptTokens': promptTokens,
    'completionTokens': completionTokens,
    'totalTokens': totalTokens,
    'cost': cost,
    'model': model,
    'currency': currency,
  };
}

/// 按分钟累计的用量统计，按货币区分费用。
class UsageStats {
  int requests;
  int promptTokens;
  int completionTokens;

  /// 按货币累计的费用，key 为货币代码（如 USD、CNY）
  Map<String, double> costsByCurrency;
  List<UsageDetail> details;

  int get totalTokens => promptTokens + completionTokens;

  /// 所有货币的总费用
  double get totalCost =>
      costsByCurrency.values.fold(0.0, (sum, c) => sum + c);

  UsageStats({
    this.requests = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    Map<String, double>? costsByCurrency,
    List<UsageDetail>? details,
  })  : costsByCurrency = costsByCurrency ?? {},
        details = details ?? [];

  /// 添加一次请求明细，自动累计（token + 按货币累加费用）
  void add(UsageDetail detail) {
    requests++;
    promptTokens += detail.promptTokens;
    completionTokens += detail.completionTokens;
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
      costsByCurrency: costs,
      details: (json['details'] as List<dynamic>?)
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
    'costsByCurrency': costsByCurrency,
    'totalCost': totalCost,
    'details': details.map((d) => d.toJson()).toList(),
  };

  /// 创建空的用量统计条目
  factory UsageStats.empty() {
    return UsageStats();
  }
}
