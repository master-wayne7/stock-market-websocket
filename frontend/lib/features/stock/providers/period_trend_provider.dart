import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'filtered_candle_provider.dart';
import 'time_period_provider.dart';
import '../../../core/constants/app_constants.dart';

// Model for period-based trend information
class PeriodTrend {
  final bool isPositive;
  final double changeAmount;
  final double changePercentage;
  final double startPrice;
  final double endPrice;
  final Color trendColor;

  const PeriodTrend({
    required this.isPositive,
    required this.changeAmount,
    required this.changePercentage,
    required this.startPrice,
    required this.endPrice,
    required this.trendColor,
  });

  static const PeriodTrend neutral = PeriodTrend(
    isPositive: true,
    changeAmount: 0.0,
    changePercentage: 0.0,
    startPrice: 0.0,
    endPrice: 0.0,
    trendColor: AppColors.chartNeutral,
  );
}

// Provider that calculates trend based on selected time period
final periodTrendProvider = Provider.family<PeriodTrend, String>((ref, symbol) {
  final filteredCandles = ref.watch(filteredCandleDataProvider(symbol));
  final selectedPeriod = ref.watch(selectedTimePeriodProvider(symbol));

  if (filteredCandles.isEmpty) {
    return PeriodTrend.neutral;
  }

  // Find first and last non-zero values for meaningful comparison
  final nonZeroCandles = filteredCandles.where((candle) => candle.close > 0).toList();

  if (nonZeroCandles.isEmpty) {
    return PeriodTrend.neutral;
  }

  if (nonZeroCandles.length == 1) {
    // Only one data point - assume positive trend from zero
    final price = nonZeroCandles.first.close;
    return PeriodTrend(
      isPositive: true,
      changeAmount: price,
      changePercentage: 100.0, // 100% gain from zero
      startPrice: 0.0,
      endPrice: price,
      trendColor: AppColors.chartPositive,
    );
  }

  // Calculate trend over the selected period
  final startPrice = nonZeroCandles.first.close;
  final endPrice = nonZeroCandles.last.close;
  final changeAmount = endPrice - startPrice;
  final changePercentage = startPrice > 0 ? (changeAmount / startPrice) * 100 : 0.0;
  final isPositive = changeAmount >= 0;

  return PeriodTrend(
    isPositive: isPositive,
    changeAmount: changeAmount,
    changePercentage: changePercentage,
    startPrice: startPrice,
    endPrice: endPrice,
    trendColor: isPositive ? AppColors.chartPositive : AppColors.chartNegative,
  );
});

// Helper provider for formatted trend text
final trendDisplayProvider = Provider.family<String, String>((ref, symbol) {
  final trend = ref.watch(periodTrendProvider(symbol));
  final selectedPeriod = ref.watch(selectedTimePeriodProvider(symbol));

  if (trend.changeAmount == 0) {
    return 'No change';
  }

  final sign = trend.isPositive ? '+' : '';
  return '$sign\$${trend.changeAmount.abs().toStringAsFixed(2)} ($sign${trend.changePercentage.toStringAsFixed(2)}%) ${selectedPeriod.label}';
});
