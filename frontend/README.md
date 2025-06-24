# Stock Market WebSocket Flutter App

A real-time stock market tracking application built with Flutter that consumes data from a Go WebSocket backend.

## Features

- **Real-time Stock Data**: Live updates via WebSocket connection
- **Interactive Charts**: Candlestick and line charts with fl_chart
- **Multiple Stock Symbols**: Support for AAPL, AMZN, BINANCE:BTCUSDT, IC MARKETS:1
- **Connectivity Monitoring**: Internet connection status indicator
- **Clean Architecture**: Modular code structure with Riverpod state management
- **Responsive UI**: Modern Material Design 3 interface

## Architecture

### Folder Structure
```
lib/
├── core/                           # Core application components
│   ├── constants/                  # App constants and configuration
│   ├── models/                     # Data models
│   ├── services/                   # Business logic services
│   └── di/                        # Dependency injection
├── features/                       # Feature-based modules
│   └── stock/                     # Stock tracking feature
│       ├── providers/             # Riverpod state providers
│       └── presentation/          # UI components
│           ├── screens/           # App screens
│           └── widgets/           # Reusable widgets
└── main.dart                      # App entry point
```

### Key Components

1. **Services**:
   - `ConnectivityService`: Monitors internet connectivity
   - `WebSocketService`: Handles real-time WebSocket connections
   - `ApiService`: Manages HTTP API calls for historical data

2. **State Management**:
   - Flutter Riverpod for reactive state management
   - Separate providers for different data states
   - Clean separation of concerns

3. **UI Components**:
   - `StockDashboardScreen`: Main application screen
   - `StockChartWidget`: Interactive charting component
   - `ConnectivityIndicator`: Network status indicator
   - `SymbolSelector`: Stock symbol selection widget

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Go backend server running on port 3080

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd stock-market-websocket/frontend
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation** (if using freezed/json_annotation):
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Start the backend server**:
   ```bash
   cd ../backend
   make start
   ```

5. **Run the Flutter app**:
   ```bash
   flutter run
   ```

## Backend Configuration

Make sure your Go backend is configured with:
- Server running on port 3080
- WebSocket endpoint at `/ws`
- REST endpoints for historical data
- Finnhub API key for real-time data

## Usage

1. **Select Stock Symbol**: Choose from available symbols (AAPL, AMZN, etc.)
2. **View Real-time Data**: Stock price updates in real-time via WebSocket
3. **Chart Interaction**: Switch between line and candlestick charts
4. **Monitor Connection**: Check connectivity status in the top-right corner

## API Endpoints

The app connects to these backend endpoints:

- `ws://localhost:3080/ws` - WebSocket for real-time data
- `http://localhost:3080/symbols` - Get available stock symbols
- `http://localhost:3080/stocks-history` - Historical data for all symbols
- `http://localhost:3080/stocks-candles?symbol=<SYMBOL>` - Historical data for specific symbol

## Symbol Images

The app displays stock symbol logos using the EODHD service:
- **Primary URL**: `https://eodhd.com/img/logos/US/{SYMBOL_UPPERCASE}.png`
- **Fallback URL**: `https://eodhd.com/img/logos/US/{symbol_lowercase}.png`
- **Final Fallback**: Text-based initials if both image URLs fail

## Data Flow

1. **Initial Load**: Fetch historical candlestick data via REST API
2. **Real-time Updates**: Subscribe to WebSocket for live price updates
3. **State Management**: Riverpod providers manage data state reactively
4. **UI Updates**: Charts and info cards update automatically

## Dependencies

Key packages used:

- `flutter_riverpod`: State management
- `get_it`: Dependency injection
- `web_socket_channel`: WebSocket client
- `dio`: HTTP client
- `fl_chart`: Chart visualization
- `connectivity_plus`: Network connectivity
- `intl`: Date/time formatting
- `logger`: Logging utilities

## Customization

### Adding New Stock Symbols

1. Update `AppConstants.availableSymbols` in `lib/core/constants/app_constants.dart`
2. Ensure your backend supports the new symbols

### Modifying Chart Appearance

1. Edit `StockChartWidget` in `lib/features/stock/presentation/widgets/stock_chart_widget.dart`
2. Customize colors, intervals, and styling

### Changing Backend URL

1. Update `AppConstants.baseUrl` and `AppConstants.wsUrl` in `lib/core/constants/app_constants.dart`

## Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**:
   - Ensure backend server is running
   - Check firewall settings
   - Verify correct URL and port

2. **No Data Loading**:
   - Check internet connectivity
   - Verify backend API is accessible
   - Check browser console for errors

3. **Build Errors**:
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are compatible

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
