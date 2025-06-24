import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/stock_providers.dart';
import 'symbol_image.dart';

class SymbolSelector extends ConsumerWidget {
  final String selectedSymbol;
  final Function(String) onSymbolChanged;

  const SymbolSelector({
    super.key,
    required this.selectedSymbol,
    required this.onSymbolChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbolsAsync = ref.watch(availableSymbolsProvider);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Stock Symbol',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            symbolsAsync.when(
              data: (symbols) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: symbols.map((symbol) {
                  final isSelected = symbol == selectedSymbol;
                  return GestureDetector(
                    onTap: () => onSymbolChanged(symbol),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SymbolImage(
                            symbol: symbol,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            symbol,
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load symbols: ${error.toString()}',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
