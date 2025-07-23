# Stock Market WebSocket Backend

A Go backend service that provides real-time stock market data via WebSocket connections, with automatic reconnection and keep-alive mechanisms for deployment on free-tier cloud platforms.

## 🏗️ Project Structure

```
backend/
├── cmd/
│   └── main.go                 # Application entry point
├── internal/
│   ├── broadcaster/            # Real-time message broadcasting
│   │   └── broadcaster.go
│   ├── config/                 # Configuration management
│   │   └── config.go
│   ├── database/               # Database connection and operations
│   │   └── database.go
│   ├── handlers/               # HTTP request handlers
│   │   └── handlers.go
│   ├── middleware/             # HTTP middleware
│   │   └── middleware.go
│   ├── models/                 # Data models and structures
│   │   └── models.go
│   ├── services/               # Business logic services
│   │   └── candle_service.go
│   └── websocket/              # WebSocket management
│       ├── client.go           # Frontend client connections
│       └── finnhub.go          # Finnhub WebSocket client
├── config.go                   # Legacy config (deprecated)
├── db.go                       # Legacy database (deprecated)
├── main.go                     # Legacy main (deprecated)
├── model.go                    # Legacy models (deprecated)
├── go.mod                      # Go module file
├── go.sum                      # Go dependencies checksum
├── Dockerfile                  # Development Dockerfile
├── Dockerfile.prod             # Production Dockerfile
├── docker-compose.yaml         # Docker Compose configuration
├── render.yaml                 # Render deployment configuration
└── ping_service_config.md      # Keep-alive service configuration
```

## 🚀 Features

### Core Functionality
- **Real-time Stock Data**: WebSocket connection to Finnhub for live trade data
- **Candlestick Generation**: Automatic 1-minute candlestick creation from trade data
- **Client Broadcasting**: Real-time updates to connected frontend clients
- **Database Storage**: PostgreSQL storage for historical data

### Reliability Features
- **Automatic Reconnection**: Handles connection drops gracefully
- **Keep-Alive Mechanism**: Prevents cloud platform sleep (Render, etc.)
- **Health Monitoring**: Connection status and health checks
- **Error Recovery**: Robust error handling and recovery

### API Endpoints
- `GET /health` - Health check
- `GET /ping` - Keep-alive endpoint
- `GET /status` - Connection status
- `GET /symbols` - Available stock symbols
- `GET /stocks-history` - All historical data
- `GET /stocks-candles?symbol=AAPL` - Symbol-specific data
- `WS /ws` - WebSocket connection for real-time updates

## 🛠️ Development

### Prerequisites
- Go 1.24+
- PostgreSQL
- Finnhub API key

### Local Development
```bash
# Clone the repository
git clone <repository-url>
cd backend

# Install dependencies
go mod tidy

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run with hot reload (requires air)
air

# Or run directly
go run cmd/main.go
```

### Environment Variables
```env
PORT=8080
API_KEY=your_finnhub_api_key
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=stock_tracker
DB_SSL_MODE=disable
```

## 🐳 Docker Deployment

### Development
```bash
docker-compose up --build
```

### Production
```bash
docker build -f Dockerfile.prod -t stock-market-backend .
docker run -p 8080:8080 stock-market-backend
```

## ☁️ Cloud Deployment

### Render (Recommended)
1. Connect your GitHub repository to Render
2. Use the provided `render.yaml` configuration
3. Set environment variables in Render dashboard
4. Deploy

### Keep-Alive Setup
To prevent free-tier instances from sleeping:

1. **UptimeRobot** (Recommended):
   - Create account at uptimerobot.com
   - Add monitor: `https://your-app.onrender.com/ping`
   - Set interval to 5 minutes

2. **GitHub Actions**:
   - Use the provided `.github/workflows/ping-backend.yml`
   - Update the URL in the workflow file

3. **Manual HTML**:
   - Use the HTML snippet in `ping_service_config.md`
   - Open in a browser tab

## 📊 Architecture

### Package Responsibilities

#### `cmd/main.go`
- Application entry point
- Dependency injection
- Service orchestration

#### `internal/config`
- Environment variable management
- Configuration validation
- Default value handling

#### `internal/database`
- Database connection management
- Schema migration
- Connection pooling

#### `internal/models`
- Data structures
- JSON serialization
- Database models

#### `internal/services`
- Business logic
- Data processing
- Service coordination

#### `internal/handlers`
- HTTP request handling
- Response formatting
- Input validation

#### `internal/websocket`
- WebSocket connection management
- Client communication
- Finnhub integration

#### `internal/broadcaster`
- Real-time message broadcasting
- Update scheduling
- Client notification

#### `internal/middleware`
- HTTP middleware
- CORS handling
- Request processing

## 🔧 Configuration

### Database
- **Type**: PostgreSQL
- **Auto-migration**: Enabled
- **Connection pooling**: GORM default

### WebSocket
- **Finnhub**: Real-time trade data
- **Reconnection**: Automatic with exponential backoff
- **Heartbeat**: Ping/pong every 30 seconds

### Broadcasting
- **Update frequency**: 1 second for live data
- **Immediate broadcast**: For closed candles
- **Client filtering**: By symbol subscription

## 🧪 Testing

```bash
# Run tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific package
go test ./internal/services
```

## 📝 Logging

The application uses structured logging with different levels:
- **INFO**: Normal operations
- **WARN**: Recoverable issues
- **ERROR**: Connection failures, data processing errors

## 🚨 Monitoring

### Health Checks
- `/health` - Basic health status
- `/status` - Detailed connection status
- `/ping` - Keep-alive endpoint

### Metrics to Monitor
- Finnhub connection status
- Active client count
- Database connection health
- Message broadcast rate

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request
