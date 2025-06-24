import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'realtime_price_display.dart';
import 'connectivity_indicator.dart';
import '../../providers/stock_providers.dart';

class DebugDashboard extends ConsumerStatefulWidget {
  const DebugDashboard({super.key});

  @override
  ConsumerState<DebugDashboard> createState() => _DebugDashboardState();
}

class _DebugDashboardState extends ConsumerState<DebugDashboard> {
  bool showDebugInfo = false;
  String selectedSymbol = 'AAPL'; // Default symbol

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Stock Data'),
        actions: [
          const ConnectivityIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                showDebugInfo = !showDebugInfo;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Symbol selector
            _buildSymbolSelector(),
            const SizedBox(height: 16),

            // Real-time price display
            RealtimePriceDisplay(symbol: selectedSymbol),

            if (showDebugInfo) ...[
              const SizedBox(height: 16),
              WebSocketDebugInfo(symbol: selectedSymbol),
              const SizedBox(height: 16),
              _buildRawDataDebug(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolSelector() {
    final symbolsAsync = ref.watch(availableSymbolsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Stock Symbol',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            symbolsAsync.when(
              data: (symbols) => DropdownButton<String>(
                value: selectedSymbol,
                hint: const Text('Select a symbol'),
                isExpanded: true,
                items: symbols.map((symbol) {
                  return DropdownMenuItem(
                    value: symbol,
                    child: Text(symbol),
                  );
                }).toList(),
                onChanged: (newSymbol) {
                  if (newSymbol != null) {
                    setState(() {
                      selectedSymbol = newSymbol;
                    });
                  }
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataDebug() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Raw WebSocket Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Last 5 messages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SingleChildScrollView(
                child: Text(
                  'WebSocket messages will appear here...\n'
                  'Check the console logs for detailed message data.',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable debug mode to see raw WebSocket messages in the console.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
