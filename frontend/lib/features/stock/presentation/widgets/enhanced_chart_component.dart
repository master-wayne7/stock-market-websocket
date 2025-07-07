import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'syncfusion_candle_chart.dart';
import 'line_chart_widget.dart';
import '../../providers/time_period_provider.dart';
import '../../providers/period_trend_provider.dart';
import '../../../../core/constants/app_constants.dart';

class EnhancedChartComponent extends ConsumerWidget {
  final String symbol;

  const EnhancedChartComponent({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimePeriod = ref.watch(selectedTimePeriodProvider(symbol));
    final isCandlestickChart = ref.watch(chartTypeProvider(symbol));
    final periodTrend = ref.watch(periodTrendProvider(symbol));
    final trendDisplay = ref.watch(trendDisplayProvider(symbol));

    return Column(
      children: [
        // Period Trend Information
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedTimePeriod.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : AppColors.textSecondary,
                ),
              ),
              Text(
                trendDisplay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: periodTrend.trendColor,
                ),
              ),
            ],
          ),
        ),

        // Chart Display
        Container(
          height: 250,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: isCandlestickChart ? SyncfusionCandleChart(symbol: symbol) : LineChartWidget(symbol: symbol),
        ),

        const SizedBox(height: 20),

        // Time Interval Chips and Chart Type Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Time interval chips
              ...TimePeriod.values.map((period) => _buildTimeIntervalChip(
                    context,
                    ref,
                    period,
                    selectedTimePeriod == period,
                  )),

              // Chart type toggle button
              GestureDetector(
                onTap: () {
                  ref.read(chartTypeProvider(symbol).notifier).state = !isCandlestickChart;
                },
                child: Container(
                  height: 32,
                  width: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.getSelectionColor(context),
                      width: 1.5,
                    ),
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white,
                  ),
                  child: Center(
                    child: Icon(
                      isCandlestickChart ? Icons.candlestick_chart : Icons.show_chart,
                      size: 18,
                      color: AppColors.getSelectionColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeIntervalChip(
    BuildContext context,
    WidgetRef ref,
    TimePeriod period,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedTimePeriodProvider(symbol).notifier).state = period;

        // Add haptic feedback
        //HapticFeedback.lightImpact();

        // Log the selection for debugging
        final startDate = period.getStartDate();
        print('📊 Selected time period: ${period.label} for symbol: $symbol');
        if (startDate != null) {
          print('📅 Showing data from: $startDate to now');
        } else {
          print('📅 Showing all available data');
        }
      },
      child: Container(
        height: 32,
        width: 43,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.getSelectionColor(context),
                  width: 1.5,
                ),
          color: isSelected ? AppColors.getSelectionColor(context) : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.white),
        ),
        child: Center(
          child: Text(
            period.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textOnSelection : AppColors.getSelectionColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
