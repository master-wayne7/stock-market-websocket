import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'stock_providers.dart';

class DailyOHLC extends Equatable {
  final String symbol;
  final double open;
  final double high;
  final double low;
  final double close;
  final double priceChange;
  final double percentageChange;
  final bool isPositive;
  final DateTime lastUpdated;

  const DailyOHLC({
    required this.symbol,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.priceChange,
    required this.percentageChange,
    required this.isPositive,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        symbol,
        open,
        high,
        low,
        close,
        priceChange,
        percentageChange,
        isPositive,
        lastUpdated,
      ];

  @override
  String toString() => 'DailyOHLC($symbol: O:$open, H:$high, L:$low, C:$close, Change:$priceChange)';
}

class DailyOHLCCalculator {
  static DailyOHLC? calculateFromCandles(String symbol, List<CandleModel> candles) {
    if (candles.isEmpty) return null;

    // Sort candles by timestamp to ensure proper order
    final sortedCandles = List<CandleModel>.from(candles);
    sortedCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get today's date for filtering
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter for today's candles, or if no today candles, use recent candles
    final todayCandles = sortedCandles.where((candle) {
      final candleDate = DateTime(
        candle.timestamp.year,
        candle.timestamp.month,
        candle.timestamp.day,
      );
      return candleDate.isAtSameMomentAs(today);
    }).toList();

    // If no today candles, use the most recent candles
    final candlesToAnalyze = todayCandles.isNotEmpty
        ? todayCandles
        : sortedCandles.length > 50
            ? sortedCandles.sublist(sortedCandles.length - 50) // Use last 50 candles
            : sortedCandles;

    if (candlesToAnalyze.isEmpty) return null;

    // Calculate OHLC
    final open = candlesToAnalyze.first.open;
    final close = candlesToAnalyze.last.close;
    final high = candlesToAnalyze.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final low = candlesToAnalyze.map((c) => c.low).reduce((a, b) => a < b ? a : b);

    // Calculate change (compare with previous day's close or first candle's open)
    final priceChange = close - open;
    final percentageChange = open != 0 ? (priceChange / open) * 100 : 0.0;

    return DailyOHLC(
      symbol: symbol,
      open: open,
      high: high,
      low: low,
      close: close,
      priceChange: priceChange,
      percentageChange: percentageChange,
      isPositive: priceChange >= 0,
      lastUpdated: candlesToAnalyze.last.timestamp,
    );
  }
}

// Daily OHLC Provider using historical + live data
final dailyOHLCProvider = Provider.family<DailyOHLC?, String>((ref, symbol) {
  // Watch the combined data (historical + live)
  final candleData = ref.watch(combinedCandleDataProvider(symbol));

  if (candleData.isEmpty) {
    // If no combined data, try historical only
    final historicalData = ref.watch(symbolHistoricalDataProvider(symbol));
    return DailyOHLCCalculator.calculateFromCandles(symbol, historicalData);
  }

  return DailyOHLCCalculator.calculateFromCandles(symbol, candleData);
});

// Latest price provider
final latestPriceDisplayProvider = Provider.family<String, String>((ref, symbol) {
  final latestPrice = ref.watch(latestPriceProvider(symbol));

  if (latestPrice != null) {
    return '\$${latestPrice.toStringAsFixed(2)}';
  }

  // Fallback to historical data
  final historicalData = ref.watch(symbolHistoricalDataProvider(symbol));
  if (historicalData.isNotEmpty) {
    return '\$${historicalData.last.close.toStringAsFixed(2)}';
  }

  return '--';
});
