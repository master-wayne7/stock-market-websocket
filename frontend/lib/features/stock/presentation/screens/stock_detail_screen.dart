import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/realtime_price_display.dart';
import '../widgets/debug_dashboard.dart';
import '../widgets/enhanced_chart_component.dart';
import '../widgets/data_debug_widget.dart';
import '../../providers/stock_providers.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;

  const StockDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  SymbolWebSocketNotifier? _webSocketNotifier;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket for this symbol when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _webSocketNotifier = ref.read(symbolWebSocketProvider(widget.symbol).notifier);
        _webSocketNotifier?.connect();
      }
    });
  }

  @override
  void dispose() {
    // Disconnect from WebSocket when leaving the screen
    _webSocketNotifier?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DebugDashboard(),
              ),
            ),
            tooltip: 'Debug Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugDialog(context),
            tooltip: 'Debug Info',
          ),
          const ConnectivityIndicator(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Real-time price display

          // // Stock info cards
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: StockInfoCard(symbol: widget.symbol),
          // ),

          // Enhanced Chart section with time intervals and chart type toggle
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: RealtimePriceDisplay(symbol: widget.symbol),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: EnhancedChartComponent(symbol: widget.symbol),
                  ),

                  // Debug widget (temporary) - remove after debugging
                  DataDebugWidget(symbol: widget.symbol),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Debug Information for ${widget.symbol}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WebSocket Connection',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const ConnectivityIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          'Symbol: ${widget.symbol}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Real-time data display
                RealtimePriceDisplay(symbol: widget.symbol),

                const SizedBox(height: 12),

                // Raw data section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Data Stream',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const SingleChildScrollView(
                            child: Text(
                              'WebSocket messages for this symbol will appear here...\n'
                              'Check the console logs for detailed message data.',
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.infinity,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Debug Dashboard - ${widget.symbol}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDebugContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
