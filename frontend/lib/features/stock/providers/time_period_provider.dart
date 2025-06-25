import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimePeriod {
  oneDay('1D'),
  oneWeek('1W'),
  oneMonth('1M'),
  oneYear('1Y'),
  fiveYears('5Y'),
  all('ALL');

  const TimePeriod(this.label);
  final String label;

  // Get the start date for filtering data
  DateTime? getStartDate() {
    final now = DateTime.now();
    switch (this) {
      case TimePeriod.oneDay:
        // Last 24 hours from now (more practical than just "today")
        return now.subtract(const Duration(hours: 24));
      case TimePeriod.oneWeek:
        // Past 7 days including today
        return now.subtract(const Duration(days: 7));
      case TimePeriod.oneMonth:
        // Past 30 days including today
        return now.subtract(const Duration(days: 30));
      case TimePeriod.oneYear:
        // Past 365 days including today
        return now.subtract(const Duration(days: 365));
      case TimePeriod.fiveYears:
        // Past 5 years including today
        return now.subtract(const Duration(days: 365 * 5));
      case TimePeriod.all:
        // Show all available data
        return null;
    }
  }
}

// Provider for selected time period per symbol
final selectedTimePeriodProvider = StateProvider.family<TimePeriod, String>((ref, symbol) {
  return TimePeriod.oneDay; // Default to 1 day
});

// Provider for chart type (candlestick vs line)
final chartTypeProvider = StateProvider.family<bool, String>((ref, symbol) {
  return true; // Default to candlestick (true)
});
