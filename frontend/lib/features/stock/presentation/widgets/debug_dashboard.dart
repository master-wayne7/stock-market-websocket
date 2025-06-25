import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stock_providers.dart';
import '../../providers/five_minute_candles_provider.dart';

class DebugDashboard extends ConsumerStatefulWidget {
  const DebugDashboard({super.key});

  @override
  ConsumerState<DebugDashboard> createState() => _DebugDashboardState();
}

class _DebugDashboardState extends ConsumerState<DebugDashboard> {
  String _testResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final symbolsAsync = ref.watch(availableSymbolsProvider);
    final allHistoryAsync = ref.watch(allStocksHistoryProvider);
    final connectivity = ref.watch(connectivityNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Test Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Tests',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testAllApis,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test All APIs'),
                    ),
                    const SizedBox(height: 12),
                    if (_testResults.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Connectivity Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connectivity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          connectivity ? Icons.wifi : Icons.wifi_off,
                          color: connectivity ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          connectivity ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: connectivity ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Symbols Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symbols',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    symbolsAsync.when(
                      data: (symbols) => Text('✅ ${symbols.length} symbols loaded'),
                      loading: () => const Text('⏳ Loading symbols...'),
                      error: (error, _) => Text('❌ Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Historical Data Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historical Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    allHistoryAsync.when(
                      data: (history) {
                        final totalCandles = history.values.fold<int>(0, (sum, candles) => sum + candles.length);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✅ ${history.length} symbols with historical data'),
                            Text('📊 $totalCandles total candles'),
                            if (history.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Sample symbols:'),
                              ...history.keys.take(5).map((symbol) => Text('  • $symbol: ${history[symbol]!.length} candles')),
                            ],
                          ],
                        );
                      },
                      loading: () => const Text('⏳ Loading historical data...'),
                      error: (error, _) => Text('❌ Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chart Data Test for AAPL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chart Data Test (AAPL)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildChartDataTest('AAPL'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartDataTest(String symbol) {
    final historicalData = ref.watch(symbolHistoricalDataProvider(symbol));
    final combinedData = ref.watch(combinedCandleDataProvider(symbol));
    final webSocketState = ref.watch(symbolWebSocketProvider(symbol));
    final oneMinCandles = ref.watch(oneMinuteCandlesProvider(symbol));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historical: ${historicalData.length} candles'),
        Text('Live: ${webSocketState.liveCandles.length} candles'),
        Text('Combined: ${combinedData.length} candles'),
        Text('1-min: ${oneMinCandles.length} candles'),
        Text('WebSocket: ${webSocketState.isConnected ? "Connected" : "Disconnected"}'),
        if (historicalData.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('First historical: ${historicalData.first.timestamp}'),
          Text('Last historical: ${historicalData.last.timestamp}'),
        ],
        if (oneMinCandles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('First 1min: ${oneMinCandles.first.time}'),
          Text('Last 1min: ${oneMinCandles.last.time}'),
        ],
      ],
    );
  }

  Future<void> _testAllApis() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _testResults = 'Running API tests...\n\n';
    });

    final StringBuffer results = StringBuffer();

    results.writeln('🔄 Starting API Tests');
    results.writeln('Time: ${DateTime.now()}');
    results.writeln('');

    // Test providers and their data
    try {
      results.writeln('📋 Testing Symbols Provider...');
      ref.invalidate(availableSymbolsProvider);
      results.writeln('✅ Invalidated symbols provider');
    } catch (e) {
      results.writeln('❌ FAILED: $e');
    }

    try {
      results.writeln('📈 Testing Historical Data Provider...');
      ref.invalidate(allStocksHistoryProvider);
      results.writeln('✅ Invalidated historical data provider');
    } catch (e) {
      results.writeln('❌ FAILED: $e');
    }
    results.writeln('');

    results.writeln('🏁 API Tests Complete');
    results.writeln('Check the debug data below for actual results.');

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }
}
