enum Environment {
  development,
  production
}

class AppConfig {
  // Current environment - change this for different builds
  static const Environment environment = Environment.development;

  // Base URLs for different environments
  static const Map<Environment, String> _baseUrls = {
    Environment.development: 'http://10.0.2.2:8080', // Android emulator
    Environment.production: 'https://your-app-name.onrender.com', // Replace with your actual Render URL
  };

  // WebSocket URLs for different environments
  static const Map<Environment, String> _wsUrls = {
    Environment.development: 'ws://10.0.2.2:8080/ws', // Android emulator
    Environment.production: 'wss://your-app-name.onrender.com/ws', // Replace with your actual Render URL
  };

  // Alternative localhost URLs for development
  static const String localhostBaseUrl = 'http://localhost:8080';
  static const String localhostWsUrl = 'ws://localhost:8080/ws';

  // Getters for current environment
  static String get baseUrl => _baseUrls[environment] ?? _baseUrls[Environment.development]!;
  static String get wsUrl => _wsUrls[environment] ?? _wsUrls[Environment.development]!;

  // Environment info
  static String get environmentName => environment.name;
  static bool get isProduction => environment == Environment.production;
  static bool get isDevelopment => environment == Environment.development;

  // Debug information
  static String getEnvironmentInfo() {
    return 'Environment: $environmentName\n'
        'Base URL: $baseUrl\n'
        'WebSocket URL: $wsUrl\n'
        'Is Production: $isProduction';
  }

  // For different device types
  static String getBaseUrlForDevice({bool useLocalhost = false}) {
    if (isDevelopment) {
      return useLocalhost ? localhostBaseUrl : baseUrl;
    }
    return baseUrl;
  }

  static String getWsUrlForDevice({bool useLocalhost = false}) {
    if (isDevelopment) {
      return useLocalhost ? localhostWsUrl : wsUrl;
    }
    return wsUrl;
  }
}
