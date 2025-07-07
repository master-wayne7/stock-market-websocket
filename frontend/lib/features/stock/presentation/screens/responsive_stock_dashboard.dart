import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/responsive_breakpoints.dart';
import '../../../../core/services/websocket_service.dart';

import '../widgets/connectivity_indicator.dart';
import '../widgets/symbol_selector.dart';
import '../widgets/stock_info_card.dart';
import '../widgets/stock_chart_widget.dart';
import '../../providers/stock_providers.dart';

class ResponsiveStockDashboard extends ConsumerStatefulWidget {
  const ResponsiveStockDashboard({super.key});

  @override
  ConsumerState<ResponsiveStockDashboard> createState() => _ResponsiveStockDashboardState();
}

class _ResponsiveStockDashboardState extends ConsumerState<ResponsiveStockDashboard> {
  String selectedSymbol = 'AAPL';

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(webSocketConnectionNotifierProvider);
    final symbolsAsync = ref.watch(availableSymbolsProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: ResponsiveContainer(
        centerContent: false,
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context, connectionState, symbolsAsync),
          tablet: _buildTabletLayout(context, connectionState, symbolsAsync),
          desktop: _buildDesktopLayout(context, connectionState, symbolsAsync),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.trending_up, size: 24),
          const SizedBox(width: 8),
          Text(AppConstants.appName),
          if (AppConfig.enableDebugFeatures) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEV',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        const ConnectivityIndicator(),
        if (AppConfig.enableDebugFeatures) ...[
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showEnvironmentInfo(context),
            tooltip: 'Environment Info',
          ),
        ],
        const SizedBox(width: 16),
      ],
      elevation: ResponsiveUtils.isMobile(context) ? 1 : 0,
    );
  }

  Widget _buildMobileLayout(BuildContext context, WebSocketConnectionState connectionState, AsyncValue<List<String>> symbolsAsync) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSymbolSelector(symbolsAsync),
          const SizedBox(height: 16),
          _buildConnectionStatus(context, connectionState),
          const SizedBox(height: 16),
          _buildStockInfoCard(),
          const SizedBox(height: 16),
          _buildChartSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, WebSocketConnectionState connectionState, AsyncValue<List<String>> symbolsAsync) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSymbolSelector(symbolsAsync),
          const SizedBox(height: 24),
          _buildConnectionStatus(context, connectionState),
          const SizedBox(height: 24),
          // Two-column layout for tablet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildStockInfoCard(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildChartSection(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WebSocketConnectionState connectionState, AsyncValue<List<String>> symbolsAsync) {
    return Column(
      children: [
        // Top section with symbol selector and connection status
        Row(
          children: [
            Expanded(child: _buildSymbolSelector(symbolsAsync)),
            const SizedBox(width: 24),
            _buildConnectionStatus(context, connectionState),
          ],
        ),
        const SizedBox(height: 32),
        // Main content in desktop layout
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar with stock info
              SizedBox(
                width: 350,
                child: _buildStockInfoCard(),
              ),
              const SizedBox(width: 32),
              // Main chart area
              Expanded(
                child: _buildChartSection(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymbolSelector(AsyncValue<List<String>> symbolsAsync) {
    return Card(
      child: Padding(
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
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading symbols',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                  if (AppConfig.enableDebugFeatures) ...[
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, WebSocketConnectionState connectionState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: ResponsiveUtils.isMobile(context) ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              _getConnectionIcon(connectionState),
              color: _getConnectionColor(connectionState),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _getConnectionText(connectionState),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getConnectionColor(connectionState),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (ResponsiveUtils.isDesktop(context)) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConnectionColor(connectionState).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getConnectionColor(connectionState),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoCard() {
    return StockInfoCard(symbol: selectedSymbol);
  }

  Widget _buildChartSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Price Chart - $selectedSymbol',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: ResponsiveUtils.isMobile(context) ? 300 : 400,
              child: StockChartWidget(symbol: selectedSymbol),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnvironmentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Environment Information'),
        content: SelectableText(AppConfig.getEnvironmentInfo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getConnectionIcon(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Icons.wifi;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Icons.wifi_protected_setup;
      case WebSocketConnectionState.failed:
      case WebSocketConnectionState.disconnected:
        return Icons.wifi_off;
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
