import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'five_minute_candles_provider.dart';
import 'time_period_provider.dart';

// Provider that filters candle data based on selected time period
final filteredCandleDataProvider = Provider.family<List<ChartCandleData>, String>((ref, symbol) {
  final allCandles = ref.watch(oneMinuteCandlesProvider(symbol));
  final selectedPeriod = ref.watch(selectedTimePeriodProvider(symbol));

  print('🔍 Filtering data for $symbol with period: ${selectedPeriod.label}');
  print('📊 Total available candles: ${allCandles.length}');

  if (allCandles.isEmpty) {
    print('⚠️ No candles available for $symbol');
    return [];
  }

  // Debug: Show date range of available data
  if (allCandles.isNotEmpty) {
    final sortedCandles = List<ChartCandleData>.from(allCandles);
    sortedCandles.sort((a, b) => a.time.compareTo(b.time));
    print('📅 Available data range: ${sortedCandles.first.time} to ${sortedCandles.last.time}');
  }

  final startDate = selectedPeriod.getStartDate();
  print('🎯 Filter start date: $startDate');

  // Filter candles based on the selected time period date range
  List<ChartCandleData> filteredCandles;
  if (startDate != null) {
    filteredCandles = allCandles.where((candle) => candle.time.isAfter(startDate) || candle.time.isAtSameMomentAs(startDate)).toList();
  } else {
    // Show all data for "ALL" period
    filteredCandles = allCandles;
  }

  // Sort by time to ensure proper ordering
  filteredCandles.sort((a, b) => a.time.compareTo(b.time));

  print('✅ Filtered to ${filteredCandles.length} candles');

  // If we have a start date but no filtered data (or gap), generate zero-value candles
  if (startDate != null) {
    filteredCandles = _fillMissingDataWithZeros(filteredCandles, startDate, selectedPeriod);
    print('📊 After filling gaps: ${filteredCandles.length} candles');
  }

  if (filteredCandles.isNotEmpty) {
    print('📈 Final range: ${filteredCandles.first.time} to ${filteredCandles.last.time}');
  }

  return filteredCandles;
});

// Helper function to fill missing historical data with zero-value candles
List<ChartCandleData> _fillMissingDataWithZeros(
  List<ChartCandleData> existingCandles,
  DateTime startDate,
  TimePeriod period,
) {
  if (existingCandles.isEmpty) {
    // No existing data - create all zero candles from start date to now
    return _generateZeroCandles(startDate, DateTime.now(), period);
  }

  final sortedCandles = List<ChartCandleData>.from(existingCandles);
  sortedCandles.sort((a, b) => a.time.compareTo(b.time));

  final firstDataTime = sortedCandles.first.time;
  final result = <ChartCandleData>[];

  // If there's a gap between start date and first real data, fill with zeros
  if (startDate.isBefore(firstDataTime)) {
    final zeroCandles = _generateZeroCandles(startDate, firstDataTime, period);
    result.addAll(zeroCandles);
  }

  // Add existing real data
  result.addAll(sortedCandles);

  return result;
}

// Generate zero-value candles for a given time range
List<ChartCandleData> _generateZeroCandles(
  DateTime startDate,
  DateTime endDate,
  TimePeriod period,
) {
  final candles = <ChartCandleData>[];

  // Determine appropriate interval based on period
  Duration interval;
  switch (period) {
    case TimePeriod.oneDay:
      interval = const Duration(minutes: 5); // 5-minute intervals for 1D
      break;
    case TimePeriod.oneWeek:
      interval = const Duration(minutes: 30); // 30-minute intervals for 1W
      break;
    case TimePeriod.oneMonth:
      interval = const Duration(hours: 2); // 2-hour intervals for 1M
      break;
    case TimePeriod.oneYear:
      interval = const Duration(days: 1); // Daily intervals for 1Y
      break;
    case TimePeriod.fiveYears:
      interval = const Duration(days: 7); // Weekly intervals for 5Y
      break;
    case TimePeriod.all:
      interval = const Duration(days: 30); // Monthly intervals for ALL
      break;
  }

  DateTime currentTime = startDate;
  while (currentTime.isBefore(endDate)) {
    candles.add(ChartCandleData(
      time: currentTime,
      open: 0.0,
      high: 0.0,
      low: 0.0,
      close: 0.0,
      volume: 0,
    ));

    currentTime = currentTime.add(interval);
  }

  return candles;
}
