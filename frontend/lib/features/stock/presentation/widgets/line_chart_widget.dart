import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/filtered_candle_provider.dart';
import '../../providers/period_trend_provider.dart';
import '../../../../core/constants/app_constants.dart';

class LineChartWidget extends ConsumerWidget {
  final String symbol;

  const LineChartWidget({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candles = ref.watch(filteredCandleDataProvider(symbol));
    final periodTrend = ref.watch(periodTrendProvider(symbol));

    if (candles.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Convert candle data to line chart points using close prices
    final spots = <FlSpot>[];
    for (int i = 0; i < candles.length; i++) {
      spots.add(FlSpot(i.toDouble(), candles[i].close));
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text('No data points available'),
      );
    }

    // Calculate min and max values for better scaling
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Better padding calculation for zero-value scenarios
    double padding;
    if (maxY == 0 && minY == 0) {
      // All zeros - set a small range
      padding = 1.0;
    } else if (maxY == minY) {
      // All same values - use 10% of the value or minimum 1
      padding = maxY * 0.1;
      if (padding < 1) padding = 1.0;
    } else {
      // Normal case - 10% padding
      padding = (maxY - minY) * 0.1;
    }

    // Use period-based trend color
    final lineColor = periodTrend.trendColor;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(
            show: false,
          ),
          titlesData: const FlTitlesData(
            show: false,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.1,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(
                show: false,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withOpacity(0.3),
                    lineColor.withOpacity(0.1),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.black87,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  return LineTooltipItem(
                    '\$${touchedSpot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchLineStart: (data, index) => 0,
            getTouchLineEnd: (data, index) => double.infinity,
            touchSpotThreshold: 50,
          ),
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
