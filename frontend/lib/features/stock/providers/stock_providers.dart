import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/candle_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/di/injection.dart';

// Export models for use in other files
export '../../../core/models/candle_model.dart';

// Services
final apiServiceProvider = Provider<ApiService>((ref) => getIt<ApiService>());
final webSocketServiceProvider = Provider<WebSocketService>((ref) => getIt<WebSocketService>());
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => getIt<ConnectivityService>());

// Connectivity State
final connectivityNotifierProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier(ref.watch(connectivityServiceProvider));
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final ConnectivityService _service;

  ConnectivityNotifier(this._service) : super(_service.isConnected) {
    _service.connectivityStream.listen((isConnected) {
      state = isConnected;
    });
  }
}

// Available Symbols
final availableSymbolsProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final symbols = await apiService.fetchAvailableSymbols();

  // Preload symbol images for better performance
  CacheService.preloadSymbolImages(symbols.take(20).toList());

  return symbols;
});

// All Stocks Historical Data (fetched once)
final allStocksHistoryProvider = FutureProvider<Map<String, List<CandleModel>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.fetchAllStocksHistory();
});

// Historical data for a specific symbol
final symbolHistoricalDataProvider = Provider.family<List<CandleModel>, String>((ref, symbol) {
  final allHistoryAsync = ref.watch(allStocksHistoryProvider);

  return allHistoryAsync.when(
    data: (allHistory) => allHistory[symbol] ?? [],
    loading: () => [],
    error: (_, __) => [],
  );
});

// Symbol-specific WebSocket connection (only when viewing detail)
final symbolWebSocketProvider = StateNotifierProvider.family<SymbolWebSocketNotifier, SymbolWebSocketState, String>((ref, symbol) {
  return SymbolWebSocketNotifier(symbol, ref);
});

class SymbolWebSocketState {
  final bool isConnected;
  final List<CandleModel> liveCandles;
  final CandleModel? latestCandle;

  const SymbolWebSocketState({
    this.isConnected = false,
    this.liveCandles = const [],
    this.latestCandle,
  });

  SymbolWebSocketState copyWith({
    bool? isConnected,
    List<CandleModel>? liveCandles,
    CandleModel? latestCandle,
  }) {
    return SymbolWebSocketState(
      isConnected: isConnected ?? this.isConnected,
      liveCandles: liveCandles ?? this.liveCandles,
      latestCandle: latestCandle ?? this.latestCandle,
    );
  }
}

class SymbolWebSocketNotifier extends StateNotifier<SymbolWebSocketState> {
  final String symbol;
  final Ref _ref;

  SymbolWebSocketNotifier(this.symbol, this._ref) : super(const SymbolWebSocketState()) {
    // DO NOT auto-connect here - only connect when explicitly requested
  }

  Future<void> connect() async {
    final webSocketService = _ref.read(webSocketServiceProvider);

    // Connect to this specific symbol
    await webSocketService.connect(symbol);

    // Listen to WebSocket messages for this symbol only
    webSocketService.messageStream.listen((message) {
      if (message.candle.symbol == symbol) {
        _handleWebSocketMessage(message);
      }
    });

    // Listen to connection state
    webSocketService.connectionStateStream.listen((connectionState) {
      state = state.copyWith(
        isConnected: connectionState == WebSocketConnectionState.connected,
      );
    });
  }

  Future<void> disconnect() async {
    final webSocketService = _ref.read(webSocketServiceProvider);
    await webSocketService.disconnect();

    state = const SymbolWebSocketState();
  }

  void _handleWebSocketMessage(BroadcastMessage message) {
    final candle = message.candle;
    final currentCandles = List<CandleModel>.from(state.liveCandles);

    // Find existing candle with same timestamp
    final existingIndex = currentCandles.indexWhere(
      (c) => c.timestamp.isAtSameMomentAs(candle.timestamp),
    );

    if (existingIndex != -1) {
      // Update existing candle
      currentCandles[existingIndex] = candle;
    } else {
      // Add new candle
      currentCandles.add(candle);
      // Keep only recent live candles (last 100)
      if (currentCandles.length > 100) {
        currentCandles.removeAt(0);
      }
    }

    // Sort by timestamp
    currentCandles.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    state = state.copyWith(
      liveCandles: currentCandles,
      latestCandle: candle,
    );
  }
}

// Combined data provider (historical + live)
final combinedCandleDataProvider = Provider.family<List<CandleModel>, String>((ref, symbol) {
  final historicalData = ref.watch(symbolHistoricalDataProvider(symbol));
  final webSocketState = ref.watch(symbolWebSocketProvider(symbol));

  // Combine historical + live data
  final allCandles = [
    ...historicalData,
    ...webSocketState.liveCandles
  ];

  // Remove duplicates based on timestamp and sort
  final Map<DateTime, CandleModel> uniqueCandles = {};
  for (final candle in allCandles) {
    uniqueCandles[candle.timestamp] = candle;
  }

  final result = uniqueCandles.values.toList();
  result.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  return result;
});

// Latest price provider for a symbol
final latestPriceProvider = Provider.family<double?, String>((ref, symbol) {
  final webSocketState = ref.watch(symbolWebSocketProvider(symbol));
  final historicalData = ref.watch(symbolHistoricalDataProvider(symbol));

  // Return latest live price if available, otherwise latest historical
  if (webSocketState.latestCandle != null) {
    return webSocketState.latestCandle!.close;
  }

  if (historicalData.isNotEmpty) {
    return historicalData.last.close;
  }

  return null;
});

// WebSocket Connection State
final webSocketConnectionNotifierProvider = StateNotifierProvider<WebSocketConnectionNotifier, WebSocketConnectionState>((ref) {
  return WebSocketConnectionNotifier(ref.watch(webSocketServiceProvider));
});

class WebSocketConnectionNotifier extends StateNotifier<WebSocketConnectionState> {
  final WebSocketService _service;

  WebSocketConnectionNotifier(this._service) : super(_service.connectionState) {
    _service.connectionStateStream.listen((connectionState) {
      state = connectionState;
    });
  }
}
