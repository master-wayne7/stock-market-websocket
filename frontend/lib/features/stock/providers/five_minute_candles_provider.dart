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

// 1-minute candle aggregator with continuity
class OneMinuteCandleAggregator {
  static List<ChartCandleData> aggregateToOneMinute(List<CandleModel> candles) {
    if (candles.isEmpty) return [];

    // Sort candles by timestamp
    final sortedCandles = List<CandleModel>.from(candles);
    sortedCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<DateTime, List<CandleModel>> groupedCandles = {};

    // Group candles by 1-minute intervals
    for (final candle in sortedCandles) {
      final oneMinuteTimestamp = _roundToOneMinute(candle.timestamp);

      if (!groupedCandles.containsKey(oneMinuteTimestamp)) {
        groupedCandles[oneMinuteTimestamp] = [];
      }
      groupedCandles[oneMinuteTimestamp]!.add(candle);
    }

    // Convert grouped candles to ChartCandleData with continuity
    final List<ChartCandleData> result = [];
    final sortedEntries = groupedCandles.entries.toList();
    sortedEntries.sort((a, b) => a.key.compareTo(b.key));

    ChartCandleData? previousCandle;

    for (final entry in sortedEntries) {
      final timestamp = entry.key;
      final candleGroup = entry.value;

      if (candleGroup.isNotEmpty) {
        // Sort by timestamp within the group
        candleGroup.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Calculate OHLC for this 1-minute period with continuity
        final groupOpen = candleGroup.first.close; // Use first candle's close as open
        final groupClose = candleGroup.last.close;
        final groupHigh = candleGroup.map((c) => c.high).reduce((a, b) => a > b ? a : b);
        final groupLow = candleGroup.map((c) => c.low).reduce((a, b) => a < b ? a : b);

        // Ensure continuity: open should equal previous close
        final open = previousCandle?.close ?? groupOpen;

        // Make sure high/low include the open price for continuity
        final high = [
          groupHigh,
          open,
          groupClose
        ].reduce((a, b) => a > b ? a : b);
        final low = [
          groupLow,
          open,
          groupClose
        ].reduce((a, b) => a < b ? a : b);

        final newCandle = ChartCandleData(
          time: timestamp,
          open: open,
          high: high,
          low: low,
          close: groupClose,
          volume: candleGroup.length, // Use count as volume
        );

        result.add(newCandle);
        previousCandle = newCandle;
      }
    }

    return result;
  }

  static DateTime _roundToOneMinute(DateTime timestamp) {
    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      0,
      0,
    );
  }
}

// Provider for 1-minute candles using the new data flow
final oneMinuteCandlesProvider = StateNotifierProvider.family<OneMinuteCandlesNotifier, List<ChartCandleData>, String>(
  (ref, symbol) {
    print('🔄 Creating OneMinuteCandlesNotifier for $symbol');
    return OneMinuteCandlesNotifier(symbol, ref);
  },
);

class OneMinuteCandlesNotifier extends StateNotifier<List<ChartCandleData>> {
  final String symbol;
  final Ref ref;

  OneMinuteCandlesNotifier(this.symbol, this.ref) : super([]) {
    _initializeData();
  }

  void _initializeData() {
    // Load initial data immediately
    _updateCandles();

    // Listen to combined candle data changes (historical + live)
    ref.listen(combinedCandleDataProvider(symbol), (previous, next) {
      _updateCandles();
    });
  }

  void _updateCandles() {
    final combinedData = ref.read(combinedCandleDataProvider(symbol));

    print('🔄 Updating 1min candles for $symbol: ${combinedData.length} raw candles');

    if (combinedData.isNotEmpty) {
      // Aggregate to 1-minute candles
      final oneMinuteCandles = OneMinuteCandleAggregator.aggregateToOneMinute(combinedData);

      print('📊 Generated ${oneMinuteCandles.length} one-minute candles');

      if (oneMinuteCandles.isNotEmpty) {
        print('📈 First candle: ${oneMinuteCandles.first.time} - O:${oneMinuteCandles.first.open} C:${oneMinuteCandles.first.close}');
        print('📈 Last candle: ${oneMinuteCandles.last.time} - O:${oneMinuteCandles.last.open} C:${oneMinuteCandles.last.close}');
      }

      // Keep only the last 200 candles for performance (since 1-min creates more candles)
      if (oneMinuteCandles.length > 200) {
        state = oneMinuteCandles.sublist(oneMinuteCandles.length - 200);
      } else {
        state = oneMinuteCandles;
      }
    } else {
      print('⚠️ No combined data available for $symbol');
      state = [];
    }
  }

  void clearCandles() {
    // This will trigger a refresh of the underlying data
    ref.invalidate(combinedCandleDataProvider(symbol));
  }
}

// Provider for current candle progress (optional, for UI feedback)
final currentCandleProgressProvider = Provider.family<double, String>((ref, symbol) {
  final now = DateTime.now();
  final currentSecond = now.second;

  // Return progress through current minute as 0.0 to 1.0
  return currentSecond / 60.0;
});
