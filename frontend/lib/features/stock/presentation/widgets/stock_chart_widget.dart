import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_providers.dart';
import '../../../../core/constants/app_constants.dart';

class StockChartWidget extends ConsumerStatefulWidget {
  final String symbol;

  const StockChartWidget({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends ConsumerState<StockChartWidget> {
  bool _showCandlesticks = false;

  @override
  Widget build(BuildContext context) {
    final candles = ref.watch(combinedCandleDataProvider(widget.symbol));

    if (candles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chart data...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Chart Type Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.symbol} Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Line'),
                  icon: Icon(Icons.show_chart),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Candles'),
                  icon: Icon(Icons.candlestick_chart),
                ),
              ],
              selected: {
                _showCandlesticks
              },
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _showCandlesticks = newSelection.first;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Chart
        Expanded(
          child: _showCandlesticks ? _buildCandlestickChart(candles) : _buildLineChart(candles),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<CandleModel> candles) {
    final spots = candles.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.close);
    }).toList();

    final minPrice = candles.map((c) => c.close).reduce((a, b) => a < b ? a : b);
    final maxPrice = candles.map((c) => c.close).reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: priceRange / 5,
          verticalInterval: candles.length / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: candles.length / 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < candles.length) {
                  return Text(
                    DateFormat('HH:mm').format(candles[index].timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (candles.length - 1).toDouble(),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < candles.length) {
                  final candle = candles[index];
                  return LineTooltipItem(
                    '${widget.symbol}\n'
                    'Price: \$${candle.close.toStringAsFixed(2)}\n'
                    'Time: ${DateFormat('HH:mm:ss').format(candle.timestamp)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCandlestickChart(List<CandleModel> candles) {
    // Simple candlestick visualization using custom paint
    return CustomPaint(
      painter: CandlestickPainter(
        candles,
        Theme.of(context),
        AppColors.getBullishColor(context),
        AppColors.getBearishColor(context),
      ),
      child: Container(),
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<CandleModel> candles;
  final ThemeData theme;
  final Color bullishColor;
  final Color bearishColor;

  CandlestickPainter(this.candles, this.theme, this.bullishColor, this.bearishColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final minPrice = candles
        .map((c) => [
              c.high,
              c.low,
              c.open,
              c.close
            ])
        .expand((x) => x)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = candles
        .map((c) => [
              c.high,
              c.low,
              c.open,
              c.close
            ])
        .expand((x) => x)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final candleWidth = size.width / candles.length * 0.8;
    final spacing = size.width / candles.length;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = i * spacing + spacing / 2;

      // Normalize prices to canvas height
      final highY = size.height - ((candle.high - minPrice) / priceRange) * size.height;
      final lowY = size.height - ((candle.low - minPrice) / priceRange) * size.height;
      final openY = size.height - ((candle.open - minPrice) / priceRange) * size.height;
      final closeY = size.height - ((candle.close - minPrice) / priceRange) * size.height;

      // Determine candle color
      final isGreen = candle.close > candle.open;
      final candleColor = isGreen ? bullishColor : bearishColor;

      // Draw high-low line
      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        Paint()
          ..color = candleColor
          ..strokeWidth = 1.5,
      );

      // Draw candle body
      final bodyRect = Rect.fromPoints(
        Offset(x - candleWidth / 2, openY),
        Offset(x + candleWidth / 2, closeY),
      );

      canvas.drawRect(
        bodyRect,
        Paint()
          ..color = candleColor.withOpacity(0.8)
          ..style = PaintingStyle.fill,
      );

      // Draw candle border
      canvas.drawRect(
        bodyRect,
        Paint()
          ..color = candleColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
