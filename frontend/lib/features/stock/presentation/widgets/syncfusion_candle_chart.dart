import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../providers/five_minute_candles_provider.dart';

class SyncfusionCandleChart extends ConsumerStatefulWidget {
  final String symbol;

  const SyncfusionCandleChart({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<SyncfusionCandleChart> createState() => _SyncfusionCandleChartState();
}

class _SyncfusionCandleChartState extends ConsumerState<SyncfusionCandleChart> {
  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Colors.black87,
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );

    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final candlesData = ref.watch(fiveMinuteCandlesProvider(widget.symbol));

    if (candlesData.isEmpty) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart header
          _buildChartHeader(candlesData),

          const SizedBox(height: 12),

          // Main chart
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.white,
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0.5, color: Colors.grey),
                axisLine: const AxisLine(width: 1, color: Colors.grey),
                labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                dateFormat: DateFormat('HH:mm'),
                intervalType: DateTimeIntervalType.minutes,
                interval: 15,
                edgeLabelPlacement: EdgeLabelPlacement.shift,
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(width: 0.5, color: Colors.grey),
                axisLine: const AxisLine(width: 1, color: Colors.grey),
                labelStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                numberFormat: NumberFormat.currency(symbol: '\$', decimalDigits: 2),
                opposedPosition: true,
              ),
              trackballBehavior: _trackballBehavior,
              zoomPanBehavior: _zoomPanBehavior,
              series: <CandleSeries<ChartCandleData, DateTime>>[
                CandleSeries<ChartCandleData, DateTime>(
                  name: widget.symbol,
                  dataSource: candlesData,
                  animationDuration: 400,
                  enableSolidCandles: true,
                  bullColor: Colors.green,
                  bearColor: Colors.red,
                  xValueMapper: (ChartCandleData candle, _) => candle.time,
                  lowValueMapper: (ChartCandleData candle, _) => candle.low,
                  highValueMapper: (ChartCandleData candle, _) => candle.high,
                  openValueMapper: (ChartCandleData candle, _) => candle.open,
                  closeValueMapper: (ChartCandleData candle, _) => candle.close,
                  showIndicationForSameValues: true,
                  dataLabelSettings: const DataLabelSettings(isVisible: false),
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                shared: true,
                format: 'Time: point.x\nOpen: \$point.open\nHigh: \$point.high\nLow: \$point.low\nClose: \$point.close',
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),

          // Chart controls
          _buildChartControls(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading ${widget.symbol} chart data...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Building 5-minute candles from live data',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChartHeader(List<ChartCandleData> candlesData) {
    final latest = candlesData.isNotEmpty ? candlesData.last : null;
    final previous = candlesData.length > 1 ? candlesData[candlesData.length - 2] : null;

    final priceChange = latest != null && previous != null ? latest.close - previous.close : 0.0;
    final percentChange = previous != null && previous.close != 0 ? (priceChange / previous.close) * 100 : 0.0;

    final changeColor = priceChange > 0 ? Colors.green : (priceChange < 0 ? Colors.red : Colors.grey);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.symbol} - 5Min Chart',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (latest != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '\$${latest.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${priceChange >= 0 ? '+' : ''}\$${priceChange.toStringAsFixed(2)} (${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${candlesData.length} Candles',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '5-min intervals',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.zoom_out_map,
          label: 'Fit',
          onPressed: () => _zoomPanBehavior.reset(),
        ),
        _buildControlButton(
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: () => ref.read(fiveMinuteCandlesProvider(widget.symbol).notifier).clearCandles(),
        ),
        _buildControlButton(
          icon: Icons.info_outline,
          label: 'Info',
          onPressed: _showChartInfo,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _showChartInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.symbol} Chart Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Timeframe', '5 Minutes'),
            _buildInfoRow('Data Source', 'Real-time WebSocket'),
            _buildInfoRow('Update Frequency', 'Live'),
            _buildInfoRow('Max Candles', '100 (8+ hours)'),
            const SizedBox(height: 12),
            const Text('Chart Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Pinch to zoom'),
            const Text('• Pan to navigate'),
            const Text('• Tap for crosshair'),
            const Text('• Double-tap to reset zoom'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
