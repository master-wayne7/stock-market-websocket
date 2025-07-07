import 'package:flutter/material.dart';
import '../../../../core/constants/app_config.dart';
import 'debug_dashboard.dart';
import 'data_debug_widget.dart';

class ConditionalDebugWidget extends StatelessWidget {
  final Widget child;
  final String? symbol;

  const ConditionalDebugWidget({
    super.key,
    required this.child,
    this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableDebugFeatures) {
      return child;
    }

    return Column(
      children: [
        child,
        if (symbol != null) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Panel (Development Only)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DataDebugWidget(symbol: symbol!),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showDebugDashboard(context),
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Open Debug Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showDebugDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugDashboard(),
      ),
    );
  }
}

class ConditionalDebugFab extends StatelessWidget {
  const ConditionalDebugFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableDebugFeatures) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _showDebugDashboard(context),
      tooltip: 'Debug Dashboard',
      backgroundColor: Colors.orange.shade100,
      foregroundColor: Colors.orange.shade800,
      child: const Icon(Icons.bug_report),
    );
  }

  void _showDebugDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugDashboard(),
      ),
    );
  }
}

class ConditionalDebugOverlay extends StatelessWidget {
  final Widget child;

  const ConditionalDebugOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableDebugFeatures) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
