import 'dart:math';

import 'package:flutter/material.dart';

import '../services/usage_loader.dart';
import 'package:llmate/l10n/app_localizations.dart';

/// 用量曲线图组件 - 使用 CustomPaint 绘制，无第三方依赖
class UsageCurveChart extends StatelessWidget {
  final List<UsageChartPoint> data;
  final bool showTokens;
  final bool showCost;
  final String currencySymbol;
  final String granularity;

  const UsageCurveChart({
    super.key,
    required this.data,
    required this.showTokens,
    required this.showCost,
    required this.currencySymbol,
    this.granularity = 'day',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF23242A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Center(
          child: Text(l10n.noUsageData,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.4))),
        ),
      );
    }

    return _buildChart(theme, isDark, l10n);
  }

  Widget _buildChart(ThemeData theme, bool isDark, AppLocalizations l10n) {
    final maxTokens = showTokens
        ? data.map((p) => p.totalTokens).reduce(max)
        : 0;
    final maxCost = showCost
        ? data.map((p) => p.totalCost).reduce(max)
        : 0.0;

    return Container(
      padding: const EdgeInsets.only(top: 12, right: 8, bottom: 4, left: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23242A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D2F3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          if (showTokens)
            Row(
              children: [
                const SizedBox(width: 8),
                _legendDot(const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text(l10n.tokenToggle,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          if (showCost && maxCost > 0) ...[
            if (showTokens) const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: 8),
                _legendDot(const Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(l10n.chartLegendCost(currencySymbol),
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ChartPainter(
                data: data,
                showTokens: showTokens,
                showCost: showCost,
                maxTokens: maxTokens,
                maxCost: maxCost,
                isDark: isDark,
                currencySymbol: currencySymbol,
                granularity: granularity,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<UsageChartPoint> data;
  final bool showTokens;
  final bool showCost;
  final int maxTokens;
  final double maxCost;
  final bool isDark;
  final String currencySymbol;
  final String granularity;

  _ChartPainter({
    required this.data,
    required this.showTokens,
    required this.showCost,
    required this.maxTokens,
    required this.maxCost,
    required this.isDark,
    required this.currencySymbol,
    required this.granularity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartLeft = 40.0;
    final chartRight = size.width - 8;
    final chartTop = 16.0;
    final chartBottom = size.height - 18;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // 绘制 Y 轴刻度线
    final gridPaint = Paint()
      ..color = isDark
          ? const Color(0xFF2D2F3A)
          : const Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight * i / 4;
      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );
    }

    // Token 面积图
    if (showTokens && maxTokens > 0) {
      _drawArea(
        canvas,
        data: data,
        chartLeft: chartLeft,
        chartWidth: chartWidth,
        chartTop: chartTop,
        chartHeight: chartHeight,
        maxValue: maxTokens.toDouble(),
        color: const Color(0xFF2563EB),
      );
    }

    // 费用折线
    if (showCost && maxCost > 0) {
      _drawLine(
        canvas,
        data: data,
        chartLeft: chartLeft,
        chartWidth: chartWidth,
        chartTop: chartTop,
        chartHeight: chartHeight,
        maxValue: maxCost,
        color: const Color(0xFFDC2626),
        strokeWidth: 2.0,
      );
    }

    // Y 轴标签
    _drawYLabels(canvas, chartLeft, chartTop, chartHeight, maxTokens, maxCost);

    // X 轴标签（直接对齐到每个数据点的正下方）
    _drawXLabels(canvas: canvas, chartLeft: chartLeft, chartWidth: chartWidth,
        chartBottom: chartBottom, size: size);
  }

  void _drawXLabels({
    required Canvas canvas,
    required double chartLeft,
    required double chartWidth,
    required double chartBottom,
    required Size size,
  }) {
    if (data.length <= 1) return;

    final stepX =
        data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final textStyle = TextStyle(
      color: isDark ? const Color(0xFF888899) : const Color(0xFF999999),
      fontSize: 9,
    );

    double prevRight = -double.infinity;
    for (var i = 0; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final text = _formatXLabel(data[i].timestamp);
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      double labelX = x - tp.width / 2;

      // 边界裁剪
      if (labelX < 0) labelX = 0;
      if (labelX + tp.width > size.width) {
        labelX = size.width - tp.width;
      }

      // 避免相邻标签重叠：若与本点 x 对应的标签会与上一个重叠则跳过
      final labelCenter = labelX + tp.width / 2;
      if (labelCenter - tp.width / 2 < prevRight - 1 && i != data.length - 1) {
        continue;
      }

      final labelY = chartBottom + 4;
      tp.paint(canvas, Offset(labelX, labelY));
      prevRight = labelX + tp.width;
    }
  }

  String _formatXLabel(DateTime dt) {
    switch (granularity) {
      case 'minute':
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      case 'hour':
        return '${dt.hour.toString().padLeft(2, '0')}时';
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

  void _drawArea(
    Canvas canvas, {
    required List<UsageChartPoint> data,
    required double chartLeft,
    required double chartWidth,
    required double chartTop,
    required double chartHeight,
    required double maxValue,
    required Color color,
  }) {
    if (data.length < 2) return;

    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    final path = Path();
    final firstX = chartLeft;
    final firstY =
        chartTop + chartHeight * (1 - data[0].totalTokens / maxValue);
    path.moveTo(firstX, chartTop + chartHeight); // 从左下角开始
    path.lineTo(firstX, firstY);

    for (var i = 1; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final y =
          chartTop + chartHeight * (1 - data[i].totalTokens / maxValue);
      path.lineTo(x, y);
    }

    final lastX = chartLeft + stepX * (data.length - 1);
    path.lineTo(lastX, chartTop + chartHeight);
    path.close();

    // 渐变填充
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.02),
      ],
    );

    canvas.drawPath(
      path,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(
          chartLeft, chartTop, chartWidth, chartHeight)),
    );

    // 顶部线条
    final linePath = Path();
    linePath.moveTo(firstX, firstY);
    for (var i = 1; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final y =
          chartTop + chartHeight * (1 - data[i].totalTokens / maxValue);
      linePath.lineTo(x, y);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 数据点 + 标签
    for (var i = 0; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final y =
          chartTop + chartHeight * (1 - data[i].totalTokens / maxValue);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      _drawLabel(
        canvas,
        text: _formatTokenLabel(data[i].totalTokens),
        x: x,
        y: y,
        color: color,
        chartTop: chartTop,
        chartRight: chartLeft + chartWidth,
      );
    }
  }

  void _drawLine(
    Canvas canvas, {
    required List<UsageChartPoint> data,
    required double chartLeft,
    required double chartWidth,
    required double chartTop,
    required double chartHeight,
    required double maxValue,
    required Color color,
    required double strokeWidth,
  }) {
    if (data.length < 2) return;

    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    final path = Path();
    path.moveTo(chartLeft,
        chartTop + chartHeight * (1 - data[0].totalCost / maxValue));

    for (var i = 1; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final y =
          chartTop + chartHeight * (1 - data[i].totalCost / maxValue);
      path.lineTo(x, y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 数据点 + 标签
    for (var i = 0; i < data.length; i++) {
      final x = chartLeft + stepX * i;
      final y =
          chartTop + chartHeight * (1 - data[i].totalCost / maxValue);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(
          Offset(x, y), 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      _drawLabel(
        canvas,
        text: '$currencySymbol${data[i].totalCost.toStringAsFixed(4)}',
        x: x,
        y: y,
        color: color,
        chartTop: chartTop,
        chartRight: chartLeft + chartWidth,
      );
    }
  }

  /// 在数据点上方绘制数值标签
  void _drawLabel(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required Color color,
    required double chartTop,
    required double chartRight,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // 标签绘制在点的上方，优先靠上偏移
    double labelX = x - tp.width / 2;
    double labelY = y - tp.height - 6;

    // 确保标签不超出左右边界
    if (labelX < 0) labelX = 2;
    if (labelX + tp.width > chartRight) {
      labelX = chartRight - tp.width - 2;
    }

    // 如果标签超出顶部，改到点下方
    if (labelY < chartTop - 2) {
      labelY = y + 8;
    }

    tp.paint(canvas, Offset(labelX, labelY));
  }

  /// 格式化 Token 数值标签（简短表示）
  String _formatTokenLabel(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(2)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  void _drawYLabels(Canvas canvas, double chartLeft, double chartTop,
      double chartHeight, int maxTokensVal, double maxCostVal) {
    final textStyle = TextStyle(
      color: isDark
          ? const Color(0xFF888899)
          : const Color(0xFF999999),
      fontSize: 9,
    );

    void drawOne(String text, double y) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartLeft - tp.width - 4, y - tp.height / 2));
    }

    // 绘制 4 档刻度标签
    for (var i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight * i / 4;
      String label;
      if (showTokens && maxTokensVal > 0 && !showCost) {
        // 仅 Token：直接除
        final v = maxTokensVal * (1 - i / 4);
        label = _formatTokenLabel(v.round());
      } else if (showCost && maxCostVal > 0 && !showTokens) {
        // 仅费用
        final v = maxCostVal * (1 - i / 4);
        label = '$currencySymbol${v.toStringAsFixed(4)}';
      } else {
        label = '';
      }
      if (label.isNotEmpty) {
        drawOne(label, y);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        showTokens != oldDelegate.showTokens ||
        showCost != oldDelegate.showCost ||
        currencySymbol != oldDelegate.currencySymbol ||
        granularity != oldDelegate.granularity;
  }
}
