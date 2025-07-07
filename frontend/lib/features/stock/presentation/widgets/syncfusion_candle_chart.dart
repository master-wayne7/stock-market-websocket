import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../providers/five_minute_candles_provider.dart';
import '../../providers/filtered_candle_provider.dart';
import '../../providers/stock_providers.dart';

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
    final candlesData = ref.watch(filteredCandleDataProvider(widget.symbol));
    final combinedData = ref.watch(combinedCandleDataProvider(widget.symbol));
    final historicalData = ref.watch(symbolHistoricalDataProvider(widget.symbol));
    final webSocketState = ref.watch(symbolWebSocketProvider(widget.symbol));

    // Debug logging (development only)
    if (kDebugMode) {
      print('📊 Chart Debug for ${widget.symbol}:');
      print('  - 5min candles: ${candlesData.length}');
      print('  - Combined data: ${combinedData.length}');
      print('  - Historical data: ${historicalData.length}');
      print('  - Live candles: ${webSocketState.liveCandles.length}');
      print('  - WebSocket connected: ${webSocketState.isConnected}');

      if (historicalData.isNotEmpty) {
        print('  - First historical: ${historicalData.first.timestamp} - \$${historicalData.first.close}');
        print('  - Last historical: ${historicalData.last.timestamp} - \$${historicalData.last.close}');
      }

      if (combinedData.isNotEmpty) {
        print('  - First combined: ${combinedData.first.timestamp} - \$${combinedData.first.close}');
        print('  - Last combined: ${combinedData.last.timestamp} - \$${combinedData.last.close}');
      }
    }

    // Show different states based on data availability
    if (combinedData.isEmpty && historicalData.isEmpty) {
      return _buildNoDataState();
    }

    if (candlesData.isEmpty && combinedData.isNotEmpty) {
      return _buildAggregatingState(combinedData.length);
    }

    if (candlesData.isEmpty) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              backgroundColor: Colors.white,
              primaryXAxis: const DateTimeAxis(
                isVisible: false,
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
              ),
              primaryYAxis: const NumericAxis(
                isVisible: false,
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final combinedData = ref.watch(combinedCandleDataProvider(widget.symbol));
    final historicalData = ref.watch(symbolHistoricalDataProvider(widget.symbol));
    final webSocketState = ref.watch(symbolWebSocketProvider(widget.symbol));

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
            'Building 1-minute candles from live data',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Debug information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Historical: ${historicalData.length} candles', style: TextStyle(fontSize: 11)),
                Text('Live: ${webSocketState.liveCandles.length} candles', style: TextStyle(fontSize: 11)),
                Text('Combined: ${combinedData.length} candles', style: TextStyle(fontSize: 11)),
                Text('WebSocket: ${webSocketState.isConnected ? "Connected" : "Disconnected"}', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 64,
            color: Colors.orange.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available for ${widget.symbol}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check if the backend server is running and has data for this symbol',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAggregatingState(int rawCandleCount) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Processing ${widget.symbol} data...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Aggregating $rawCandleCount candles into 1-minute intervals',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
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
              '${widget.symbol} - 1Min Chart',
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
              '1-min intervals',
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
          onPressed: () => ref.read(oneMinuteCandlesProvider(widget.symbol).notifier).clearCandles(),
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
            _buildInfoRow('Timeframe', '1 Minute'),
            _buildInfoRow('Data Source', 'Real-time WebSocket'),
            _buildInfoRow('Update Frequency', 'Live'),
            _buildInfoRow('Max Candles', '200 (3+ hours)'),
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
