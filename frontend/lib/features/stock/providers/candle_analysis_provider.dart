import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../core/models/candle_model.dart';

// Trend direction enum
enum TrendDirection {
  up,
  down,
  flat
}

// Trend colors configuration
class TrendingColors {
  static const Map<TrendDirection, Color> colors = {
    TrendDirection.up: Colors.green,
    TrendDirection.down: Colors.red,
    TrendDirection.flat: Colors.black,
  };
}

// Chart visibility type
enum ChartType {
  candlesticks,
  line
}

// Analysis result model
class CandleAnalysis {
  final TrendDirection trending;
  final Color trendingColor;
  final String trendingSign;
  final double amountDifference;
  final double percentageDifference;
  final CandleModel? oldest;
  final CandleModel? newest;
  final List<Map<String, dynamic>> chartData;

  const CandleAnalysis({
    required this.trending,
    required this.trendingColor,
    required this.trendingSign,
    required this.amountDifference,
    required this.percentageDifference,
    this.oldest,
    this.newest,
    required this.chartData,
  });

  CandleAnalysis copyWith({
    TrendDirection? trending,
    Color? trendingColor,
    String? trendingSign,
    double? amountDifference,
    double? percentageDifference,
    CandleModel? oldest,
    CandleModel? newest,
    List<Map<String, dynamic>>? chartData,
  }) {
    return CandleAnalysis(
      trending: trending ?? this.trending,
      trendingColor: trendingColor ?? this.trendingColor,
      trendingSign: trendingSign ?? this.trendingSign,
      amountDifference: amountDifference ?? this.amountDifference,
      percentageDifference: percentageDifference ?? this.percentageDifference,
      oldest: oldest ?? this.oldest,
      newest: newest ?? this.newest,
      chartData: chartData ?? this.chartData,
    );
  }
}

// Provider for chart type selection
final chartTypeProvider = StateProvider<ChartType>((ref) => ChartType.candlesticks);

// Provider for candle analysis - equivalent to the React useCandles hook
final candleAnalysisProvider = Provider.family<CandleAnalysis, List<CandleModel>>((ref, candles) {
  final chartType = ref.watch(chartTypeProvider);

  // Handle empty candles
  if (candles.isEmpty) {
    return const CandleAnalysis(
      trending: TrendDirection.flat,
      trendingColor: Colors.black,
      trendingSign: '',
      amountDifference: 0.0,
      percentageDifference: 0.0,
      chartData: [],
    );
  }

  final newest = candles.last;
  final oldest = candles.first;

  // Calculate trending direction and differences
  TrendDirection trending = TrendDirection.flat;
  double amountDifference = 0.0;
  double percentageDifference = 0.0;

  if (candles.length >= 2) {
    amountDifference = newest.close - oldest.close;
    percentageDifference = (amountDifference / oldest.close) * 100;

    if (amountDifference > 0) {
      trending = TrendDirection.up;
    } else if (amountDifference < 0) {
      trending = TrendDirection.down;
    } else {
      trending = TrendDirection.flat;
    }
  }

  // Get trending color and sign
  final trendingColor = TrendingColors.colors[trending]!;
  final trendingSign = trending == TrendDirection.up ? '+' : '';

  // Transform chart data based on chart type
  final chartData = candles.map((candle) {
    final baseData = <String, dynamic>{
      'timestamp': candle.timestamp.millisecondsSinceEpoch,
    };

    if (chartType == ChartType.candlesticks) {
      // Include all OHLC data for candlestick chart
      baseData.addAll({
        'open': candle.open,
        'high': candle.high,
        'low': candle.low,
        'close': candle.close,
      });
    } else {
      // Only include close price for line chart
      baseData['value'] = candle.close;
    }

    return baseData;
  }).toList();

  return CandleAnalysis(
    trending: trending,
    trendingColor: trendingColor,
    trendingSign: trendingSign,
    amountDifference: amountDifference,
    percentageDifference: percentageDifference,
    oldest: oldest,
    newest: newest,
    chartData: chartData,
  );
});

// Helper providers for symbol-specific analysis data
final symbolAnalysisProvider = Provider.family<CandleAnalysis, String>((ref, symbol) {
  // This would be used by passing candles from the new data flow
  // Components should call candleAnalysisProvider directly with their candle data
  return const CandleAnalysis(
    trending: TrendDirection.flat,
    trendingColor: Colors.black,
    trendingSign: '',
    amountDifference: 0.0,
    percentageDifference: 0.0,
    chartData: [],
  );
});
