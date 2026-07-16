import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../data/storage_paths.dart';
import '../../../../models/chat/usage_stats.dart';

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

/// 用量数据加载器，从 ~/.llmate/usage/ 读取按时间粒度保存的统计文件
class UsageLoader {
  UsageLoader._();

  /// 加载指定会话和模型的用量曲线数据
  ///
  /// [granularity]: 'minute' | 'hour' | 'day' | 'month' | 'year'
  static Future<List<UsageChartPoint>> load({
    required String sessionId,
    required String modelId,
    required String granularity,
  }) async {
    final usageDir = Directory(p.join(StoragePaths.root, 'usage'));
    if (!await usageDir.exists()) return [];

    final suffix = '-$sessionId-usage.json';
    final entries = await usageDir.list().toList();

    final files = entries.whereType<File>().where(
          (f) => p.basename(f.path).endsWith(suffix),
        );

    final points = <UsageChartPoint>[];

    for (final file in files) {
      final name = p.basenameWithoutExtension(file.path);
      // 去掉末尾的 -{modelId}-{sessionId}-usage，剩下时间戳部分
      final nameWithoutSuffix = name.replaceAll('-$modelId-$sessionId-usage', '');

      final parts = nameWithoutSuffix.split('-');
      // parts 长度 = 粒度：5=分钟, 4=小时, 3=天, 2=月, 1=年
      final fileGranularity = _granularityFromParts(parts.length);
      if (fileGranularity != granularity) continue;

      final timestamp = _parseTimestamp(parts);
      if (timestamp == null) continue;

      try {
        final content = await file.readAsString();
        final stats = UsageStats.fromJson(
            jsonDecode(content) as Map<String, dynamic>);

        points.add(UsageChartPoint(
          timestamp: timestamp,
          totalTokens: stats.totalTokens,
          promptTokens: stats.promptTokens,
          completionTokens: stats.completionTokens,
          totalCost: stats.totalCost,
          costsByCurrency: stats.costsByCurrency,
        ));
      } catch (_) {
        // 跳过解析失败的文件
      }
    }

    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }

  static String _granularityFromParts(int count) {
    switch (count) {
      case 5: return 'minute';
      case 4: return 'hour';
      case 3: return 'day';
      case 2: return 'month';
      case 1: return 'year';
      default: return 'unknown';
    }
  }

  static DateTime? _parseTimestamp(List<String> parts) {
    try {
      switch (parts.length) {
        case 5: // minute: 年-月-日-时-分
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            int.parse(parts[3]),
            int.parse(parts[4]),
          );
        case 4: // hour: 年-月-日-时
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            int.parse(parts[3]),
          );
        case 3: // day: 年-月-日
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        case 2: // month: 年-月
          return DateTime(int.parse(parts[0]), int.parse(parts[1]));
        case 1: // year: 年
          return DateTime(int.parse(parts[0]));
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
