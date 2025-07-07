import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/candle_analysis_provider.dart';
import '../../../../core/constants/app_constants.dart';

class TrendIndicator extends ConsumerWidget {
  final String? symbol;

  const TrendIndicator({
    super.key,
    this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, return a default analysis since we need actual candle data
    // This widget would need to be updated to receive candle data as a parameter
    final analysis = ref.watch(candleAnalysisProvider([]));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: analysis.trendingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: analysis.trendingColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrendIcon(analysis.trending),
            size: 16,
            color: analysis.trendingColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${analysis.trendingSign}${analysis.amountDifference.toStringAsFixed(2)}',
            style: TextStyle(
              color: analysis.trendingColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${analysis.trendingSign}${analysis.percentageDifference.toStringAsFixed(2)}%)',
            style: TextStyle(
              color: analysis.trendingColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Icons.trending_up;
      case TrendDirection.down:
        return Icons.trending_down;
      case TrendDirection.flat:
        return Icons.trending_flat;
    }
  }
}

class ChartTypeToggle extends ConsumerWidget {
  const ChartTypeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartType = ref.watch(chartTypeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            context: context,
            ref: ref,
            type: ChartType.candlesticks,
            label: 'Candles',
            icon: Icons.candlestick_chart,
            isSelected: chartType == ChartType.candlesticks,
          ),
          _buildToggleButton(
            context: context,
            ref: ref,
            type: ChartType.line,
            label: 'Line',
            icon: Icons.show_chart,
            isSelected: chartType == ChartType.line,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required WidgetRef ref,
    required ChartType type,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final selectionColor = AppColors.getSelectionColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(chartTypeProvider.notifier).state = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectionColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  width: 1,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.textOnSelection : (isDark ? Colors.grey.shade300 : AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textOnSelection : (isDark ? Colors.grey.shade300 : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
