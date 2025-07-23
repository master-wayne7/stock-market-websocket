package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"stock-market-websocket/internal/broadcaster"
	"stock-market-websocket/internal/config"
	"stock-market-websocket/internal/database"
	"stock-market-websocket/internal/handlers"
	"stock-market-websocket/internal/middleware"
	"stock-market-websocket/internal/models"
	"stock-market-websocket/internal/services"
	"stock-market-websocket/internal/websocket"
)

var (
	symbols = []string{"AAPL", "AMZN", "TSLA", "GOOGL", "MSFT", "NVDA", "META", "NFLX", "INTC", "CSCO", "ORCL", "IBM", "PYPL"}
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to database
	db := database.Connect(cfg)

	// Initialize services
	candleService := services.NewCandleService(db)
	clientManager := websocket.NewClientManager()
	broadcaster := broadcaster.NewBroadcaster(clientManager)

	// Start broadcaster
	broadcaster.Start()

	// Connect candle service to broadcaster
	go func() {
		for msg := range candleService.GetBroadcastChannel() {
			broadcaster.GetBroadcastChannel() <- msg
		}
	}()

	// Initialize Finnhub client with candle service integration
	finnhubClient := websocket.NewFinnhubClient(
		cfg,
		db,
		symbols,
		candleService,
		func(msg *models.BroadcastMessage) {
			// This callback can be used for additional processing if needed
			log.Printf("Broadcast message received for symbol: %s", msg.Candle.Symbol)
		},
	)

	// Start Finnhub client
	finnhubClient.Connect()
	finnhubClient.Start()

	// Initialize handlers (after Finnhub client is created)
	handler := handlers.NewHandler(candleService, symbols, finnhubClient, clientManager)

	// Keep-alive mechanism to prevent Render from sleeping
	go keepAlivePing(cfg.SERVER_PORT)

	// Setup routes
	setupRoutes(handler, clientManager)

	// Start server
	log.Printf("Server is running on port %s", cfg.SERVER_PORT)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", cfg.SERVER_PORT), nil))
}

// keepAlivePing pings the server to keep it alive
func keepAlivePing(port string) {
	ticker := time.NewTicker(10 * time.Minute) // Ping every 10 minutes
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// Ping our own health endpoint to keep the instance alive
			go func() {
				resp, err := http.Get(fmt.Sprintf("http://localhost:%s/health", port))
				if err != nil {
					log.Printf("Keep-alive ping failed: %v", err)
				} else {
					resp.Body.Close()
					log.Printf("Keep-alive ping successful")
				}
			}()
		}
	}
}

// setupRoutes configures all HTTP routes
func setupRoutes(handler *handlers.Handler, clientManager *websocket.ClientManager) {
	// Health check endpoint
	http.HandleFunc("/health", handler.HandleHealth)

	// Keep-alive endpoint for external ping services
	http.HandleFunc("/ping", handler.HandlePing)

	// Connection status endpoint
	http.HandleFunc("/status", handler.HandleStatus)

	// Connect to WebSocket
	http.HandleFunc("/ws", middleware.CORS(clientManager.HandleWebSocket))

	// Get available symbols
	http.HandleFunc("/symbols", middleware.CORS(handler.HandleGetSymbols))

	// Fetch all previous candles of all symbols
	http.HandleFunc("/stocks-history", middleware.CORS(handler.HandleStocksHistory))

	// Fetch all previous candles of a symbol
	http.HandleFunc("/stocks-candles", middleware.CORS(handler.HandleStocksCandles))
}
