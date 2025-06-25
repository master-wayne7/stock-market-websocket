import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/websocket_service.dart';
import '../../providers/stock_providers.dart';

class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webSocketState = ref.watch(webSocketConnectionNotifierProvider);
    final isConnected = ref.watch(connectivityNotifierProvider);

    return GestureDetector(
      onTap: () => _showConnectionDetails(context, webSocketState, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStateColor(webSocketState).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getStateColor(webSocketState),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStateIcon(webSocketState),
            const SizedBox(width: 4),
            Text(
              _getStateText(webSocketState, isConnected),
              style: TextStyle(
                color: _getStateColor(webSocketState),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Icon(
          Icons.wifi,
          size: 16,
          color: _getStateColor(state),
        );
      case WebSocketConnectionState.connecting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStateColor(state)),
          ),
        );
      case WebSocketConnectionState.reconnecting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStateColor(state)),
          ),
        );
      case WebSocketConnectionState.failed:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: _getStateColor(state),
        );
      case WebSocketConnectionState.disconnected:
        return Icon(
          Icons.wifi_off,
          size: 16,
          color: _getStateColor(state),
        );
    }
  }

  Color _getStateColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
        return Colors.blue;
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.failed:
        return Colors.red;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String _getStateText(WebSocketConnectionState state, bool isConnected) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return 'Live';
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting...';
      case WebSocketConnectionState.failed:
        return 'Failed';
      case WebSocketConnectionState.disconnected:
        return isConnected ? 'Offline' : 'No Internet';
    }
  }

  void _showConnectionDetails(BuildContext context, WebSocketConnectionState state, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('WebSocket State:', _getStateText(state, true)),
            _buildDetailRow('Network:', ref.read(connectivityNotifierProvider) ? 'Connected' : 'Disconnected'),
            const SizedBox(height: 16),
            if (state == WebSocketConnectionState.failed || state == WebSocketConnectionState.disconnected) ...[
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Check if backend server is running'),
              const Text('• Verify server is accessible on port 8080'),
              const Text('• For emulator: using 10.0.2.2'),
              const Text('• For device: check IP address'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (state != WebSocketConnectionState.connected)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Note: Reconnection now handled per-symbol in detail screens
                // Global reconnection not available in new data flow
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
