import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'symbol_image.dart';
import '../../providers/daily_ohlc_provider.dart';

class StockInfoCard extends ConsumerWidget {
  final String symbol;

  const StockInfoCard({super.key, required this.symbol});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the new daily OHLC provider for proper daily data
    final dailyOHLC = ref.watch(dailyOHLCProvider(symbol));

    if (dailyOHLC == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Loading $symbol data...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final isPositive = dailyOHLC.isPositive;
    final changeColor = isPositive ? Colors.green : (dailyOHLC.priceChange == 0 ? Colors.grey : Colors.red);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with symbol and real-time indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SymbolImage(
                      symbol: symbol,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        _buildLiveIndicator(),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${dailyOHLC.close.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                    ),
                    _buildTrendIndicator(dailyOHLC, changeColor),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price change with better formatting
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: changeColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Change',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _getTrendIcon(dailyOHLC),
                        size: 16,
                        color: changeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${dailyOHLC.priceChange.abs().toStringAsFixed(2)} (${isPositive ? '+' : ''}${dailyOHLC.percentageChange.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Daily OHLC Data with proper labels
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s OHLC',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                      ),
                      Text(
                        'Real-time data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOHLCItem(
                          context,
                          'Open',
                          'Today\'s First',
                          dailyOHLC.open,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildOHLCItem(
                          context,
                          'High',
                          'Day\'s Peak',
                          dailyOHLC.high,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildOHLCItem(
                          context,
                          'Low',
                          'Day\'s Bottom',
                          dailyOHLC.low,
                          Colors.red,
                        ),
                      ),
                      Expanded(
                        child: _buildOHLCItem(
                          context,
                          'Close',
                          'Current',
                          dailyOHLC.close,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Enhanced timestamp with real-time info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last update: ${DateFormat('HH:mm:ss').format(dailyOHLC.lastUpdated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                ),
                _buildRangeInfo(dailyOHLC),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'LIVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(DailyOHLC dailyOHLC, Color changeColor) {
    final trendText = dailyOHLC.priceChange > 0 ? 'UP' : (dailyOHLC.priceChange < 0 ? 'DOWN' : 'FLAT');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        trendText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: changeColor,
        ),
      ),
    );
  }

  Widget _buildOHLCItem(BuildContext context, String label, String description, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildRangeInfo(DailyOHLC dailyOHLC) {
    final range = dailyOHLC.high - dailyOHLC.low;
    final rangePercent = dailyOHLC.low != 0 ? (range / dailyOHLC.low) * 100 : 0.0;

    return Text(
      'Range: \$${range.toStringAsFixed(2)} (${rangePercent.toStringAsFixed(1)}%)',
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _getTrendIcon(DailyOHLC dailyOHLC) {
    if (dailyOHLC.priceChange > 0) {
      return Icons.trending_up;
    } else if (dailyOHLC.priceChange < 0) {
      return Icons.trending_down;
    } else {
      return Icons.trending_flat;
    }
  }
}
