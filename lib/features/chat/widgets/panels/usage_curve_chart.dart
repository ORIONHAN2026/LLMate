import 'dart:math';

import 'package:flutter/material.dart';
import 'package:llmate/l10n/app_localizations.dart';

import '../../services/usage_loader.dart';

class UsageCurveChart extends StatelessWidget {
  final List<UsageChartPoint> data;
  final bool showTokens;
  final String granularity;
  final String rangeLabel;

  const UsageCurveChart({
    super.key,
    required this.data,
    required this.showTokens,
    this.granularity = 'day',
    this.rangeLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE1E4E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '使用趋势',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                rangeLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                data.isEmpty
                    ? Center(
                      child: Text(
                        l10n.noUsageData,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    )
                    : CustomPaint(
                      size: Size.infinite,
                      painter: _UsageTrendPainter(
                        data: data,
                        isDark: isDark,
                        granularity: granularity,
                      ),
                    ),
          ),
          const SizedBox(height: 14),
          _Legend(theme: theme),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final ThemeData theme;

  const _Legend({required this.theme});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SeriesStyle('请求数', const Color(0xFF3B82F6)),
      _SeriesStyle('输入Token', const Color(0xFF16A34A)),
      _SeriesStyle('输出Token', const Color(0xFFF97316)),
      _SeriesStyle('写缓存', const Color(0xFF06B6D4), dashed: true),
      _SeriesStyle('命中缓存', const Color(0xFFEC4899)),
    ];

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 10,
        children:
            items.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendLine(style: item),
                  const SizedBox(width: 9),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.58,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final _SeriesStyle style;

  const _LegendLine({required this.style});

  @override
  Widget build(BuildContext context) {
    if (style.dashed) {
      return SizedBox(
        width: 36,
        height: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            3,
            (_) => Container(
              width: 8,
              height: 3,
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _UsageTrendPainter extends CustomPainter {
  final List<UsageChartPoint> data;
  final bool isDark;
  final String granularity;

  _UsageTrendPainter({
    required this.data,
    required this.isDark,
    required this.granularity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartLeft = 34.0;
    final chartRight = size.width - 12;
    final chartTop = 10.0;
    final chartBottom = size.height - 26;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final gridPaint =
        Paint()
          ..color = isDark ? const Color(0xFF273142) : const Color(0xFFE5E7EB)
          ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight * i / 4;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    final styles = [
      _SeriesStyle('requests', const Color(0xFF3B82F6)),
      _SeriesStyle('prompt', const Color(0xFF16A34A)),
      _SeriesStyle('completion', const Color(0xFFF97316)),
      _SeriesStyle('cacheWrite', const Color(0xFF06B6D4), dashed: true),
      _SeriesStyle('cacheRead', const Color(0xFFEC4899)),
    ];

    final values = <_SeriesStyle, List<double>>{
      styles[0]: data.map((p) => p.requests.toDouble()).toList(),
      styles[1]: data.map((p) => p.promptTokens.toDouble()).toList(),
      styles[2]: data.map((p) => p.completionTokens.toDouble()).toList(),
      styles[3]: data.map((p) => p.cacheWriteTokens.toDouble()).toList(),
      styles[4]: data.map((p) => p.cacheReadTokens.toDouble()).toList(),
    };

    for (final entry in values.entries) {
      if (entry.value.every((v) => v <= 0)) continue;
      _drawSeries(
        canvas,
        values: entry.value,
        style: entry.key,
        chartLeft: chartLeft,
        chartWidth: chartWidth,
        chartTop: chartTop,
        chartHeight: chartHeight,
      );
    }

    _drawXLabels(canvas, size, chartLeft, chartWidth, chartBottom);
  }

  void _drawSeries(
    Canvas canvas, {
    required List<double> values,
    required _SeriesStyle style,
    required double chartLeft,
    required double chartWidth,
    required double chartTop,
    required double chartHeight,
  }) {
    if (values.length < 2) return;
    final maxValue = values.reduce(max);
    if (maxValue <= 0) return;

    final stepX = chartWidth / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      points.add(
        Offset(
          chartLeft + stepX * i,
          chartTop + chartHeight * (1 - values[i] / maxValue),
        ),
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final paint =
        Paint()
          ..color = style.color
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    if (style.dashed) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = min(distance + 8, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 14;
      }
    }
  }

  void _drawXLabels(
    Canvas canvas,
    Size size,
    double chartLeft,
    double chartWidth,
    double chartBottom,
  ) {
    if (data.length <= 1) return;
    final stepX = chartWidth / (data.length - 1);
    final textStyle = TextStyle(
      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      fontSize: 11,
    );

    double previousRight = -double.infinity;
    for (var i = 0; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final text = _formatXLabel(data[i].timestamp);
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      var labelX = x - tp.width / 2;
      labelX = labelX.clamp(0, size.width - tp.width);
      if (labelX < previousRight + 18 && i != data.length - 1) continue;
      tp.paint(canvas, Offset(labelX, chartBottom + 8));
      previousRight = labelX + tp.width;
    }
  }

  String _formatXLabel(DateTime dt) {
    switch (granularity) {
      case 'minute':
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      case 'hour':
        return '${dt.hour.toString().padLeft(2, '0')}:00';
      case 'day':
        return '${dt.month}/${dt.day}';
      case 'month':
        return '${dt.year}/${dt.month.toString().padLeft(2, '0')}';
      case 'year':
        return '${dt.year}';
      default:
        return '${dt.month}/${dt.day}';
    }
  }

  @override
  bool shouldRepaint(covariant _UsageTrendPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isDark != isDark ||
        oldDelegate.granularity != granularity;
  }
}

class _SeriesStyle {
  final String label;
  final Color color;
  final bool dashed;

  const _SeriesStyle(this.label, this.color, {this.dashed = false});
}
