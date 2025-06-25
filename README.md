# Stock Market WebSocket App

A real-time stock market tracking application with a Go backend and a Flutter frontend. The backend provides REST and WebSocket APIs for stock data, while the frontend offers a responsive, interactive UI for monitoring stock prices and charts.

---

## Features

- **Real-time Stock Data:** Live updates via WebSocket connection
- **Interactive Charts:** Candlestick and line charts (using fl_chart)
- **Multiple Stock Symbols:** Support for AAPL, AMZN, BINANCE:BTCUSDT, IC MARKETS:1, and more
- **Connectivity Monitoring:** Internet connection status indicator
- **Clean Architecture:** Modular code structure with Riverpod state management
- **Responsive UI:** Modern Material Design 3 interface

---

## Architecture

### Backend (`/backend`)
- Written in Go
- Provides REST and WebSocket endpoints
- Uses Finnhub API for real-time data
- See [backend/config.go](backend/config.go), [backend/main.go](backend/main.go)

### Frontend (`/frontend`)
- Built with Flutter (Dart)
- Modular structure with feature-based folders
- Uses Riverpod for state management
- See [frontend/lib/](frontend/lib/)

#### Folder Structure
```
lib/
├── core/
│   ├── constants/
│   ├── models/
│   ├── services/
│   └── di/
├── features/
│   └── stock/
│       ├── providers/
│       └── presentation/
│           ├── screens/
│           └── widgets/
└── main.dart
```

#### Key Components
- **Services:** `ConnectivityService`, `WebSocketService`, `ApiService`
- **UI:** `StockDashboardScreen`, `StockChartWidget`, `ConnectivityIndicator`, `SymbolSelector`

---

## Prerequisites

- Flutter SDK (latest stable)
- Dart SDK
- Go (for backend)
- Finnhub API key

---

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd stock-market-websocket
   ```

2. **Install frontend dependencies:**
   ```bash
   cd frontend
   flutter pub get
   ```

3. **(Optional) Run code generation:**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Start the backend server:**
   ```bash
   cd ../backend
   make start
   ```

5. **Run the Flutter app:**
   ```bash
   cd ../frontend
   flutter run
   ```

---

## Usage

- **Select Stock Symbol:** Choose from available symbols (AAPL, AMZN, etc.)
- **View Real-time Data:** Stock price updates in real-time via WebSocket
- **Chart Interaction:** Switch between line and candlestick charts
- **Monitor Connection:** Check connectivity status in the top-right corner

---

## API Endpoints

- `ws://localhost:3080/ws` — WebSocket for real-time data
- `http://localhost:3080/symbols` — Get available stock symbols
- `http://localhost:3080/stocks-history` — Historical data for all symbols
- `http://localhost:3080/stocks-candles?symbol=<SYMBOL>` — Historical data for a specific symbol

---

## Symbol Images

- **Primary:** `https://eodhd.com/img/logos/US/{SYMBOL_UPPERCASE}.png`
- **Fallback:** `https://eodhd.com/img/logos/US/{symbol_lowercase}.png`
- **Final Fallback:** Text-based initials

---

## Customization

- **Add Stock Symbols:** Update `AppConstants.availableSymbols` in [`lib/core/constants/app_constants.dart`](frontend/lib/core/constants/app_constants.dart)
- **Change Backend URL:** Edit `AppConstants.baseUrl` and `AppConstants.wsUrl` in the same file
- **Modify Chart Appearance:** Edit `StockChartWidget` in [`lib/features/stock/presentation/widgets/stock_chart_widget.dart`](frontend/lib/features/stock/presentation/widgets/stock_chart_widget.dart)

---

## Troubleshooting

- **WebSocket Connection Failed:** Ensure backend is running, check firewall, verify URL/port
- **No Data Loading:** Check internet, backend API, browser console
- **Build Errors:** Run `flutter clean`, `flutter pub get`, check dependencies

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.