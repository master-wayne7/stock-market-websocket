import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/symbol_image.dart';
import '../widgets/connectivity_indicator.dart';
import '../widgets/enhanced_stock_tile.dart';
import '../../providers/stock_providers.dart';
import 'stock_detail_screen.dart';

class SymbolsListScreen extends ConsumerWidget {
  const SymbolsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbolsAsync = ref.watch(availableSymbolsProvider);
    final allHistoryAsync = ref.watch(allStocksHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Market'),
        centerTitle: true,
        actions: const [
          ConnectivityIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: symbolsAsync.when(
        data: (symbols) => _buildSymbolsList(context, ref, symbols, allHistoryAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildSymbolsList(BuildContext context, WidgetRef ref, List<String> symbols, AsyncValue<Map<String, List<CandleModel>>> allHistoryAsync) {
    return Column(
      children: [
        // Header with count and loading status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${symbols.length} Stocks Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
              ),
              allHistoryAsync.when(
                data: (_) => const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        // Symbols list with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _handleRefresh(ref),
            child: allHistoryAsync.when(
              data: (historyData) => ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: symbols.length,
                  itemBuilder: (context, index) {
                    final symbol = symbols[index];
                    return EnhancedStockTile(
                      symbol: symbol,
                      onTap: () => _navigateToDetail(context, symbol),
                    );
                  },
                ),
              ),
              loading: () => _buildLoadingList(context, symbols),
              error: (error, stackTrace) => _buildErrorList(context, ref),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingList(BuildContext context, List<String> symbols) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SymbolImage(symbol: symbol, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Loading historical data...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorList(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(ref),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load historical data',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _handleRefresh(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return RefreshIndicator(
      onRefresh: () => _handleRefresh(ref),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load symbols',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _handleRefresh(ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    // Invalidate both providers to trigger a refresh
    ref.invalidate(availableSymbolsProvider);
    ref.invalidate(allStocksHistoryProvider);

    // Wait for the providers to reload
    await Future.wait([
      ref.read(availableSymbolsProvider.future),
      ref.read(allStocksHistoryProvider.future),
    ]);
  }

  void _navigateToDetail(BuildContext context, String symbol) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(symbol: symbol),
      ),
    );
  }
}
