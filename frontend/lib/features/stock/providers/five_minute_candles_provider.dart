import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'stock_providers.dart';

// Chart data model for Syncfusion
class ChartCandleData extends Equatable {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  const ChartCandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  @override
  List<Object?> get props => [
        time,
        open,
        high,
        low,
        close,
        volume
      ];

  @override
  String toString() => 'ChartCandleData(time: $time, O: $open, H: $high, L: $low, C: $close)';
}

// 5-minute candle aggregator
class FiveMinuteCandleAggregator {
  static List<ChartCandleData> aggregateToFiveMinutes(List<CandleModel> candles) {
    if (candles.isEmpty) return [];

    // Sort candles by timestamp
    final sortedCandles = List<CandleModel>.from(candles);
    sortedCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<DateTime, List<CandleModel>> groupedCandles = {};

    // Group candles by 5-minute intervals
    for (final candle in sortedCandles) {
      final fiveMinuteTimestamp = _roundToFiveMinutes(candle.timestamp);

      if (!groupedCandles.containsKey(fiveMinuteTimestamp)) {
        groupedCandles[fiveMinuteTimestamp] = [];
      }
      groupedCandles[fiveMinuteTimestamp]!.add(candle);
    }

    // Convert grouped candles to ChartCandleData
    final List<ChartCandleData> result = [];

    for (final entry in groupedCandles.entries) {
      final timestamp = entry.key;
      final candleGroup = entry.value;

      if (candleGroup.isNotEmpty) {
        // Sort by timestamp within the group
        candleGroup.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Calculate OHLC for this 5-minute period
        final open = candleGroup.first.open;
        final close = candleGroup.last.close;
        final high = candleGroup.map((c) => c.high).reduce((a, b) => a > b ? a : b);
        final low = candleGroup.map((c) => c.low).reduce((a, b) => a < b ? a : b);

        result.add(ChartCandleData(
          time: timestamp,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: candleGroup.length, // Use count as volume
        ));
      }
    }

    // Sort final result by timestamp
    result.sort((a, b) => a.time.compareTo(b.time));

    return result;
  }

  static DateTime _roundToFiveMinutes(DateTime timestamp) {
    final minutes = timestamp.minute;
    final roundedMinutes = (minutes ~/ 5) * 5;

    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      roundedMinutes,
      0,
      0,
    );
  }
}

// Provider for 5-minute candles using the new data flow
final fiveMinuteCandlesProvider = StateNotifierProvider.family<FiveMinuteCandlesNotifier, List<ChartCandleData>, String>(
  (ref, symbol) => FiveMinuteCandlesNotifier(symbol, ref),
);

class FiveMinuteCandlesNotifier extends StateNotifier<List<ChartCandleData>> {
  final String symbol;
  final Ref ref;

  FiveMinuteCandlesNotifier(this.symbol, this.ref) : super([]) {
    _initializeData();
  }

  void _initializeData() {
    // Listen to combined candle data (historical + live)
    ref.listen(combinedCandleDataProvider(symbol), (previous, next) {
      if (next.isNotEmpty) {
        // Aggregate to 5-minute candles
        final fiveMinuteCandles = FiveMinuteCandleAggregator.aggregateToFiveMinutes(next);

        // Keep only the last 100 candles for performance
        if (fiveMinuteCandles.length > 100) {
          state = fiveMinuteCandles.sublist(fiveMinuteCandles.length - 100);
        } else {
          state = fiveMinuteCandles;
        }
      }
    });
  }

  void clearCandles() {
    // This will trigger a refresh of the underlying data
    ref.invalidate(combinedCandleDataProvider(symbol));
  }
}

// Provider for current candle progress (optional, for UI feedback)
final currentCandleProgressProvider = Provider.family<double, String>((ref, symbol) {
  final now = DateTime.now();
  final currentMinute = now.minute;
  final minutesIntoFiveMinutePeriod = currentMinute % 5;

  // Return progress as 0.0 to 1.0
  return minutesIntoFiveMinutePeriod / 5.0;
});
