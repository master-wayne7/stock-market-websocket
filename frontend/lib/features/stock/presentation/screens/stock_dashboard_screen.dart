import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/websocket_service.dart';

import '../widgets/connectivity_indicator.dart';
import '../widgets/symbol_selector.dart';
import '../widgets/stock_info_card.dart';
import '../../providers/stock_providers.dart';

class StockDashboardScreen extends ConsumerStatefulWidget {
  const StockDashboardScreen({super.key});

  @override
  ConsumerState<StockDashboardScreen> createState() => _StockDashboardScreenState();
}

class _StockDashboardScreenState extends ConsumerState<StockDashboardScreen> {
  String selectedSymbol = 'AAPL'; // Default symbol

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(webSocketConnectionNotifierProvider);
    final symbolsAsync = ref.watch(availableSymbolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: const [
          ConnectivityIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Symbol Selector
            Container(
              padding: const EdgeInsets.all(16),
              child: symbolsAsync.when(
                data: (symbols) => SymbolSelector(
                  selectedSymbol: selectedSymbol,
                  onSymbolChanged: (symbol) {
                    setState(() {
                      selectedSymbol = symbol;
                    });
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading symbols'),
              ),
            ),

            // Connection Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    _getConnectionIcon(connectionState),
                    color: _getConnectionColor(connectionState),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getConnectionText(connectionState),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getConnectionColor(connectionState),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stock Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StockInfoCard(symbol: selectedSymbol),
            ),

            const SizedBox(height: 16),

            // Note: Chart functionality moved to StockDetailScreen
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Chart View',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Real-time charts are now available in the detailed view.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/symbols');
                        },
                        child: const Text('View All Symbols'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getConnectionIcon(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Icons.radio_button_checked;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Icons.radio_button_unchecked;
      case WebSocketConnectionState.failed:
      case WebSocketConnectionState.disconnected:
        return Icons.radio_button_off;
    }
  }

  Color _getConnectionColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.failed:
      case WebSocketConnectionState.disconnected:
        return Colors.red;
    }
  }

  String _getConnectionText(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return 'Connected';
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting...';
      case WebSocketConnectionState.failed:
        return 'Connection Failed';
      case WebSocketConnectionState.disconnected:
        return 'Disconnected';
    }
  }
}
