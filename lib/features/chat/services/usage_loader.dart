import '../../../../controllers/usage_controller.dart';

/// 图表数据点
class UsageChartPoint {
  final DateTime timestamp;
  final int totalTokens;
  final int promptTokens;
  final int completionTokens;
  final double totalCost;
  final Map<String, double> costsByCurrency;

  const UsageChartPoint({
    required this.timestamp,
    required this.totalTokens,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalCost,
    required this.costsByCurrency,
  });
}

/// 用量数据加载器，从用量数据库（[UsageController] / `~/.llmate/usages.db`）读取
/// 原始用量明细，并按指定时间粒度聚合成曲线数据点。
class UsageLoader {
  UsageLoader._();

  /// 加载指定会话和模型的用量曲线数据
  ///
  /// [granularity]: 'minute' | 'hour' | 'day' | 'month' | 'year'
  /// [start] / [end]: 可选的时间范围过滤（含端点）。为 null 表示不限制该侧。
  static Future<List<UsageChartPoint>> load({
    required String sessionId,
    required String modelId,
    required String granularity,
    DateTime? start,
    DateTime? end,
  }) async {
    final details = await UsageController.instance.loadDetails(
      sessionId: sessionId,
      modelId: modelId,
      start: start,
      end: end,
    );

    final Map<DateTime, UsageChartPoint> buckets = {};
    for (final d in details) {
      final bucket = _bucketStart(d.timestamp, granularity);
      if (bucket == null) continue;

      final existing = buckets[bucket];
      if (existing == null) {
        buckets[bucket] = UsageChartPoint(
          timestamp: bucket,
          totalTokens: d.totalTokens,
          promptTokens: d.promptTokens,
          completionTokens: d.completionTokens,
          totalCost: d.cost,
          costsByCurrency: {d.currency: d.cost},
        );
      } else {
        buckets[bucket] = UsageChartPoint(
          timestamp: bucket,
          totalTokens: existing.totalTokens + d.totalTokens,
          promptTokens: existing.promptTokens + d.promptTokens,
          completionTokens: existing.completionTokens + d.completionTokens,
          totalCost: existing.totalCost + d.cost,
          costsByCurrency: {
            ...existing.costsByCurrency,
            d.currency: (existing.costsByCurrency[d.currency] ?? 0) + d.cost,
          },
        );
      }
    }

    final points = buckets.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  /// 将时间戳对齐到指定粒度的起始时刻（聚合桶）
  static DateTime? _bucketStart(DateTime t, String granularity) {
    switch (granularity) {
      case 'minute':
        return DateTime(t.year, t.month, t.day, t.hour, t.minute);
      case 'hour':
        return DateTime(t.year, t.month, t.day, t.hour);
      case 'day':
        return DateTime(t.year, t.month, t.day);
      case 'month':
        return DateTime(t.year, t.month);
      case 'year':
        return DateTime(t.year);
      default:
        return null;
    }
  }
}

