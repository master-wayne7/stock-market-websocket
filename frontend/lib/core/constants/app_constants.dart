import 'app_config.dart';

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
