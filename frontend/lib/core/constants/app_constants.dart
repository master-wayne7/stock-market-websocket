import 'app_config.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // API Configuration - Now using AppConfig for environment management
  static String get baseUrl => AppConfig.baseUrl;
  static String get wsUrl => AppConfig.wsUrl;

  // Alternative URLs for different environments (deprecated - use AppConfig)
  static const String localhostBaseUrl = 'http://localhost:8080';
  static const String localhostWsUrl = 'ws://localhost:8080/ws';

  static const String symbolsUrl = '/symbols';
  static const String stocksHistoryUrl = '/stocks-history';
  static const String stocksCandlesUrl = '/stocks-candles';

  // WebSocket Configuration - Improved settings
  static const Duration websocketTimeout = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;
  static const Duration connectionTimeout = Duration(seconds: 10);

  // App Configuration
  static const String appName = 'Stock Tracker';
  static const Duration chartUpdateInterval = Duration(seconds: 1);

  // Symbol Images Configuration
  static const String symbolImageBaseUrl = 'https://eodhd.com/img/logos/US';

  // Chart Configuration
  static const int maxCandlesDisplay = 100;
  static const double chartPadding = 16.0;

  // Symbol Image helper methods
  static String getSymbolImageUrl(String symbol, {bool lowercase = false}) {
    final symbolCase = lowercase ? symbol.toLowerCase() : symbol.toUpperCase();
    return '$symbolImageBaseUrl/$symbolCase.png';
  }

  // Environment helper methods
  static String getEnvironmentInfo() {
    return AppConfig.getEnvironmentInfo();
  }
}

class AppColors {
  // Stock market specific colors
  static const Color bullish = Color(0xFF4CAF50); // Green for gains
  static const Color bearish = Color(0xFFE53E3E); // Red for losses
  static const Color neutral = Color(0xFF718096); // Gray for neutral

  // Chart colors (better visibility)
  static const Color chartPositive = Color(0xFF10B981); // Emerald green
  static const Color chartNegative = Color(0xFFEF4444); // Red
  static const Color chartNeutral = Color(0xFF6B7280); // Cool gray

  // Background colors for charts
  static const Color chartBackground = Color(0xFFFAFAFA);
  static const Color chartBackgroundDark = Color(0xFF1F2937);

  // Selection and active states
  static const Color selectionLight = Color(0xFF3B82F6); // Blue
  static const Color selectionDark = Color(0xFF60A5FA); // Lighter blue
  static const Color selectionBackground = Color(0xFFEBF8FF); // Very light blue

  // Text colors for better readability
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnSelection = Color(0xFFFFFFFF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Get theme-aware colors
  static Color getBullishColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : chartPositive;
  }

  static Color getBearishColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : chartNegative;
  }

  static Color getSelectionColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? selectionDark : selectionLight;
  }

  static Color getChartBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? chartBackgroundDark : chartBackground;
  }
}
