import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/daily_ohlc_provider.dart';
import 'symbol_image.dart';
import '../../../../core/constants/app_constants.dart';

class EnhancedStockTile extends ConsumerWidget {
  final String symbol;
  final VoidCallback onTap;

  const EnhancedStockTile({
    super.key,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyOHLC = ref.watch(dailyOHLCProvider(symbol));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Symbol image/icon
              SymbolImage(symbol: symbol, size: 48),

              const SizedBox(width: 12),

              // Stock name and full name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCompanyName(symbol),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini chart
              if (dailyOHLC != null) ...[
                SizedBox(
                  height: 40,
                  width: 60,
                  child: _buildMiniChart(dailyOHLC),
                ),
                const SizedBox(width: 12),
              ],

              // Price and change info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (dailyOHLC != null) ...[
                    Text(
                      '\$${dailyOHLC.close.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dailyOHLC.isPositive ? '+' : ''}${dailyOHLC.percentageChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: dailyOHLC.isPositive ? AppColors.chartPositive : AppColors.chartNegative,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(DailyOHLC dailyOHLC) {
    // Create sample data points for the mini chart
    // In a real implementation, you'd get actual historical data
    final spots = <FlSpot>[
      const FlSpot(0, 0.3),
      const FlSpot(1, 0.6),
      const FlSpot(2, 0.4),
      const FlSpot(3, 0.8),
      FlSpot(4, dailyOHLC.isPositive ? 0.9 : 0.2),
    ];

    final lineColor = dailyOHLC.isPositive ? AppColors.chartPositive : AppColors.chartNegative;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 4,
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.1,
            color: lineColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: false,
            ),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
      ),
      duration: const Duration(milliseconds: 0),
    );
  }

  String _getCompanyName(String symbol) {
    // Simple mapping for demo purposes
    // In a real app, you'd get this from your data source
    final companyNames = {
      'AAPL': 'Apple Inc.',
      'GOOGL': 'Alphabet Inc.',
      'MSFT': 'Microsoft Corp.',
      'TSLA': 'Tesla Inc.',
      'AMZN': 'Amazon.com Inc.',
      'META': 'Meta Platforms',
      'NFLX': 'Netflix Inc.',
      'NVDA': 'NVIDIA Corp.',
    };

    return companyNames[symbol] ?? '$symbol Corporation';
  }
}
