import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../constants/app_constants.dart';
import '../models/candle_model.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed
}

class WebSocketService {
  final Logger _logger = Logger();

  WebSocketChannel? _channel;
  StreamController<BroadcastMessage> _messageController = StreamController<BroadcastMessage>.broadcast();
  StreamController<WebSocketConnectionState> _stateController = StreamController<WebSocketConnectionState>.broadcast();

  Stream<BroadcastMessage> get messageStream => _messageController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream => _stateController.stream;

  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get connectionState => _connectionState;

  String? _currentSymbol;
  Timer? _reconnectTimer;
  Timer? _connectionTimer;
  int _reconnectAttempts = 0;
  String? _lastError;

  Future<void> connect(String symbol) async {
    if (_connectionState == WebSocketConnectionState.connected && _currentSymbol == symbol) {
      _logger.i('Already connected to symbol: $symbol');
      return;
    }

    _currentSymbol = symbol;
    _lastError = null;
    await _disconnect();
    await _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    try {
      _updateConnectionState(WebSocketConnectionState.connecting);
      _logger.i('Connecting to WebSocket: ${AppConstants.wsUrl}');
      _logger.i('Environment info: ${AppConstants.getEnvironmentInfo()}');

      // Set connection timeout
      _connectionTimer?.cancel();
      _connectionTimer = Timer(AppConstants.connectionTimeout, () {
        if (_connectionState == WebSocketConnectionState.connecting) {
          _logger.w('Connection timeout after ${AppConstants.connectionTimeout.inSeconds} seconds');
          _handleConnectionError('Connection timeout');
        }
      });

      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));

      // Send symbol subscription
      if (_currentSymbol != null) {
        _channel!.sink.add(_currentSymbol!);
        _logger.i('Subscribed to symbol: $_currentSymbol');
      }

      _connectionTimer?.cancel();
      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _lastError = null;

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.e('WebSocket error: $error');
          _handleConnectionError('WebSocket stream error: $error');
        },
        onDone: () {
          _logger.w('WebSocket connection closed gracefully');
          if (_connectionState == WebSocketConnectionState.connected) {
            _handleConnectionError('Connection closed unexpectedly');
          }
        },
      );
    } catch (e) {
      _connectionTimer?.cancel();
      _logger.e('Failed to connect to WebSocket: $e');
      _handleConnectionError('Connection failed: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      final broadcastMessage = BroadcastMessage.fromJson(data);
      _messageController.add(broadcastMessage);
      _logger.d('Received message: ${broadcastMessage.updateType} for ${broadcastMessage.candle.symbol}');
    } catch (e) {
      _logger.e('Failed to parse WebSocket message: $e');
      _logger.e('Raw message: $message');
    }
  }

  void _handleConnectionError([String? errorMessage]) {
    _connectionTimer?.cancel();
    _lastError = errorMessage;
    _updateConnectionState(WebSocketConnectionState.failed);

    _logger.e('Connection error (attempt ${_reconnectAttempts + 1}/${AppConstants.maxReconnectAttempts}): ${errorMessage ?? 'Unknown error'}');

    if (_reconnectAttempts < AppConstants.maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      _logger.e('Max reconnect attempts reached. Giving up.');
      _logger.e('Last error: $_lastError');
      _logger.e('Troubleshooting tips:');
      _logger.e('1. Check if the backend server is running on port 8080');
      _logger.e('2. Verify WebSocket endpoint is accessible: ${AppConstants.wsUrl}');
      _logger.e('3. For Android emulator, ensure you\'re using 10.0.2.2 instead of localhost');
      _logger.e('4. For physical device, use your machine\'s IP address');
      _updateConnectionState(WebSocketConnectionState.disconnected);
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    _updateConnectionState(WebSocketConnectionState.reconnecting);
    _logger.i('Scheduling reconnect attempt $_reconnectAttempts in ${AppConstants.reconnectDelay.inSeconds} seconds');

    _reconnectTimer = Timer(AppConstants.reconnectDelay, () {
      if (_currentSymbol != null && _connectionState != WebSocketConnectionState.connected) {
        _logger.i('Attempting reconnection...');
        _connectToWebSocket();
      }
    });
  }

  void _updateConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _stateController.add(_connectionState);
      _logger.i('WebSocket state changed: $state');
    }
  }

  Future<void> disconnect() async {
    _logger.i('Disconnecting WebSocket service');
    _currentSymbol = null;
    await _disconnect();
  }

  Future<void> _disconnect() async {
    _reconnectTimer?.cancel();
    _connectionTimer?.cancel();

    if (_channel != null) {
      try {
        await _channel!.sink.close();
        _logger.i('WebSocket channel closed successfully');
      } catch (e) {
        _logger.e('Error closing WebSocket: $e');
      }
      _channel = null;
    }

    _updateConnectionState(WebSocketConnectionState.disconnected);
  }

  // Helper methods for debugging
  String getConnectionInfo() {
    return 'State: $_connectionState, Symbol: $_currentSymbol, Attempts: $_reconnectAttempts, Last Error: $_lastError';
  }

  String getLastError() => _lastError ?? 'No error';

  void dispose() {
    _logger.i('Disposing WebSocket service');
    _disconnect();
    _messageController.close();
    _stateController.close();
  }
}
