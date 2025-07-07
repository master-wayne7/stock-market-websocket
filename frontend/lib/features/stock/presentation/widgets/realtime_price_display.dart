import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/daily_ohlc_provider.dart';
import '../../providers/stock_providers.dart';
import '../../../../core/constants/app_constants.dart';

class RealtimePriceDisplay extends ConsumerWidget {
  final String symbol;

  const RealtimePriceDisplay({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyOHLC = ref.watch(dailyOHLCProvider(symbol));

    if (dailyOHLC == null) {
      return _buildLoadingState(context);
    }

    final changeColor = dailyOHLC.isPositive ? AppColors.getBullishColor(context) : (dailyOHLC.priceChange == 0 ? AppColors.chartNeutral : AppColors.getBearishColor(context));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with symbol and current price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTrendIndicator(dailyOHLC, changeColor),
              ],
            ),
            const SizedBox(height: 8),

            // Current price
            Text(
              '\$${dailyOHLC.close.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: changeColor,
              ),
            ),

            // Price change
            Text(
              '${dailyOHLC.isPositive ? '+' : ''}\$${dailyOHLC.priceChange.abs().toStringAsFixed(2)} (${dailyOHLC.isPositive ? '+' : ''}${dailyOHLC.percentageChange.toStringAsFixed(2)}%)',
              style: TextStyle(
                fontSize: 16,
                color: changeColor,
              ),
            ),

            const SizedBox(height: 16),

            // OHLC Data
            _buildOHLCGrid(context, dailyOHLC),

            const SizedBox(height: 16),

            // Data info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last updated: ${_formatTime(dailyOHLC.lastUpdated)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Real-time data',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading real-time data...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(DailyOHLC dailyOHLC, Color changeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: changeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrendIcon(dailyOHLC),
            size: 16,
            color: changeColor,
          ),
          const SizedBox(width: 4),
          Text(
            _getTrendText(dailyOHLC),
            style: TextStyle(
              color: changeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOHLCGrid(BuildContext context, DailyOHLC dailyOHLC) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOHLCItem(context, 'Open', dailyOHLC.open, AppColors.info),
          _buildOHLCItem(context, 'High', dailyOHLC.high, AppColors.chartPositive),
          _buildOHLCItem(context, 'Low', dailyOHLC.low, AppColors.chartNegative),
          _buildOHLCItem(context, 'Close', dailyOHLC.close, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildOHLCItem(BuildContext context, String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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

  String _getTrendText(DailyOHLC dailyOHLC) {
    if (dailyOHLC.priceChange > 0) {
      return 'UP';
    } else if (dailyOHLC.priceChange < 0) {
      return 'DOWN';
    } else {
      return 'FLAT';
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}

// Debug widget to show WebSocket connection info
class WebSocketDebugInfo extends ConsumerWidget {
  final String symbol;

  const WebSocketDebugInfo({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(webSocketConnectionNotifierProvider);
    final webSocketState = ref.watch(symbolWebSocketProvider(symbol));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WebSocket Debug',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Connection: ${connectionState.toString().split('.').last}'),
            Text('Symbol: $symbol'),
            Text('Live candles: ${webSocketState.liveCandles.length}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Force reconnect
                ref.read(symbolWebSocketProvider(symbol).notifier).connect();
              },
              child: const Text('Reconnect'),
            ),
          ],
        ),
      ),
    );
  }
}
