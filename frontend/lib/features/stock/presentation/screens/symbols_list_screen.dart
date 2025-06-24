import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/symbol_image.dart';
import '../widgets/connectivity_indicator.dart';
import '../../providers/stock_providers.dart';
import '../../providers/daily_ohlc_provider.dart';
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

        // Symbols list
        Expanded(
          child: allHistoryAsync.when(
            data: (historyData) => ListView.builder(
              itemCount: symbols.length,
              itemBuilder: (context, index) {
                final symbol = symbols[index];
                return _buildSymbolListItem(context, ref, symbol);
              },
            ),
            loading: () => _buildLoadingList(symbols),
            error: (error, stackTrace) => _buildErrorList(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingList(List<String> symbols) {
    return ListView.builder(
      itemCount: symbols.length,
      itemBuilder: (context, index) {
        final symbol = symbols[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: SymbolImage(symbol: symbol, size: 48),
            title: Text(
              symbol,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text('Loading historical data...'),
            trailing: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorList(BuildContext context, WidgetRef ref) {
    return Center(
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(allStocksHistoryProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolListItem(BuildContext context, WidgetRef ref, String symbol) {
    // Watch the daily OHLC for preview data (uses historical data only)
    final dailyOHLC = ref.watch(dailyOHLCProvider(symbol));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SymbolImage(symbol: symbol, size: 48),
        title: Text(
          symbol,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: dailyOHLC != null
            ? _buildQuickPreview(dailyOHLC)
            : Text(
                'Loading...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dailyOHLC != null) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${dailyOHLC.close.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getPriceColor(dailyOHLC),
                    ),
                  ),
                  Text(
                    '${dailyOHLC.isPositive ? '+' : ''}${dailyOHLC.percentageChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriceColor(dailyOHLC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () => _navigateToDetail(context, symbol),
      ),
    );
  }

  Widget _buildQuickPreview(DailyOHLC dailyOHLC) {
    final changeColor = _getPriceColor(dailyOHLC);

    return Row(
      children: [
        Icon(
          dailyOHLC.isPositive ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: changeColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${dailyOHLC.isPositive ? '+' : ''}\$${dailyOHLC.priceChange.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: changeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'H: \$${dailyOHLC.high.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        Text(
          'L: \$${dailyOHLC.low.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(availableSymbolsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriceColor(DailyOHLC dailyOHLC) {
    return dailyOHLC.isPositive ? Colors.green : Colors.red;
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
