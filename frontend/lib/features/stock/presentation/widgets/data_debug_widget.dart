import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/filtered_candle_provider.dart';
import '../../providers/five_minute_candles_provider.dart';
import '../../providers/time_period_provider.dart';

class DataDebugWidget extends ConsumerWidget {
  final String symbol;

  const DataDebugWidget({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCandles = ref.watch(oneMinuteCandlesProvider(symbol));
    final filteredCandles = ref.watch(filteredCandleDataProvider(symbol));
    final selectedPeriod = ref.watch(selectedTimePeriodProvider(symbol));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Debug for $symbol',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Selected Period', selectedPeriod.label),
          _buildInfoRow('Total Candles', '${allCandles.length}'),
          _buildInfoRow('Filtered Candles', '${filteredCandles.length}'),
          if (allCandles.isNotEmpty) ...[
            const SizedBox(height: 4),
            () {
              final sorted = List<ChartCandleData>.from(allCandles);
              sorted.sort((a, b) => a.time.compareTo(b.time));
              return Column(
                children: [
                  _buildInfoRow('First Candle', _formatDateTime(sorted.first.time)),
                  _buildInfoRow('Last Candle', _formatDateTime(sorted.last.time)),
                ],
              );
            }(),
          ],
          if (filteredCandles.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildInfoRow('Filtered First', _formatDateTime(filteredCandles.first.time)),
            _buildInfoRow('Filtered Last', _formatDateTime(filteredCandles.last.time)),
          ],
          const SizedBox(height: 8),
          _buildFilterStartDate(selectedPeriod),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStartDate(TimePeriod period) {
    final startDate = period.getStartDate();
    return _buildInfoRow(
      'Filter Start',
      startDate != null ? _formatDateTime(startDate) : 'No limit',
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
