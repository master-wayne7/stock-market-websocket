package websocket

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"

	"stock-market-websocket/internal/config"
	"stock-market-websocket/internal/models"
	"stock-market-websocket/internal/services"
)

// FinnhubClient manages the connection to Finnhub WebSocket
type FinnhubClient struct {
	conn            *websocket.Conn
	connMutex       sync.Mutex
	isConnected     bool
	lastPingTime    time.Time
	reconnectTicker *time.Ticker
	config          *config.Env
	db              *gorm.DB
	symbols         []string
	candleService   *services.CandleService
	onMessage       func(*models.BroadcastMessage)
}

// NewFinnhubClient creates a new Finnhub WebSocket client
func NewFinnhubClient(cfg *config.Env, db *gorm.DB, symbols []string, candleService *services.CandleService, onMessage func(*models.BroadcastMessage)) *FinnhubClient {
	return &FinnhubClient{
		config:          cfg,
		db:              db,
		symbols:         symbols,
		candleService:   candleService,
		onMessage:       onMessage,
		reconnectTicker: time.NewTicker(30 * time.Second),
		lastPingTime:    time.Now(),
	}
}

// Connect establishes connection to Finnhub WebSocket with retry logic
func (f *FinnhubClient) Connect() {
	f.connMutex.Lock()
	defer f.connMutex.Unlock()

	// Close existing connection if any
	if f.conn != nil {
		f.conn.Close()
		f.conn = nil
	}

	// Reset connection status
	f.isConnected = false

	// Attempt to connect with retries
	maxRetries := 5
	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("Attempting to connect to Finnhub WebSocket (attempt %d/%d)", attempt, maxRetries)

		ws, _, err := websocket.DefaultDialer.Dial(fmt.Sprintf("wss://ws.finnhub.io?token=%s", f.config.API_KEY), nil)
		if err != nil {
			log.Printf("Failed to connect to Finnhub WebSocket (attempt %d): %v", attempt, maxRetries)
			if attempt < maxRetries {
				time.Sleep(time.Duration(attempt) * 5 * time.Second) // Exponential backoff
				continue
			} else {
				log.Printf("Failed to connect to Finnhub WebSocket after %d attempts", maxRetries)
				return
			}
		}

		// Subscribe to symbols
		for _, s := range f.symbols {
			msg, _ := json.Marshal(map[string]interface{}{"type": "subscribe", "symbol": s})
			if err := ws.WriteMessage(websocket.TextMessage, msg); err != nil {
				log.Printf("Failed to subscribe to symbol %s: %v", s, err)
				ws.Close()
				if attempt < maxRetries {
					time.Sleep(time.Duration(attempt) * 5 * time.Second)
					continue
				} else {
					return
				}
			}
		}

		// Set up ping handler
		ws.SetPingHandler(func(appData string) error {
			log.Printf("Received ping from Finnhub")
			return ws.WriteMessage(websocket.PongMessage, []byte(appData))
		})

		// Set up pong handler
		ws.SetPongHandler(func(appData string) error {
			log.Printf("Received pong from Finnhub")
			return nil
		})

		// Connection successful
		f.conn = ws
		f.isConnected = true
		f.lastPingTime = time.Now()
		log.Printf("Successfully connected to Finnhub WebSocket")
		return
	}
}

// Start begins listening for messages and monitoring connection health
func (f *FinnhubClient) Start() {
	// Start message handling
	go f.handleMessages()

	// Start connection monitoring
	go f.monitorConnection()
}

// Stop closes the connection and stops monitoring
func (f *FinnhubClient) Stop() {
	f.reconnectTicker.Stop()

	f.connMutex.Lock()
	if f.conn != nil {
		f.conn.Close()
		f.conn = nil
	}
	f.isConnected = false
	f.connMutex.Unlock()
}

// IsConnected returns the current connection status
func (f *FinnhubClient) IsConnected() bool {
	f.connMutex.Lock()
	defer f.connMutex.Unlock()
	return f.isConnected && f.conn != nil
}

// GetLastPingTime returns the last ping time
func (f *FinnhubClient) GetLastPingTime() time.Time {
	return f.lastPingTime
}

// handleMessages processes incoming messages from Finnhub
func (f *FinnhubClient) handleMessages() {
	for {
		f.connMutex.Lock()
		conn := f.conn
		connected := f.isConnected
		f.connMutex.Unlock()

		if !connected || conn == nil {
			log.Printf("No active Finnhub connection, waiting for reconnection...")
			time.Sleep(5 * time.Second)
			continue
		}

		finnhubMessage := &models.FinnhubMessage{}
		if err := conn.ReadJSON(finnhubMessage); err != nil {
			log.Printf("Failed to read message from Finnhub WebSocket: %v", err)

			// Mark connection as disconnected
			f.connMutex.Lock()
			f.isConnected = false
			f.connMutex.Unlock()

			// Wait before attempting reconnection
			time.Sleep(5 * time.Second)
			continue
		}

		if finnhubMessage.Type == "trade" {
			for _, trade := range finnhubMessage.Data {
				f.processTradeData(&trade)
			}
		}
	}
}

// monitorConnection checks connection health and reconnects if needed
func (f *FinnhubClient) monitorConnection() {
	for {
		select {
		case <-f.reconnectTicker.C:
			f.connMutex.Lock()
			connHealthy := f.isConnected && f.conn != nil
			f.connMutex.Unlock()

			if !connHealthy {
				log.Printf("Connection unhealthy, attempting to reconnect...")
				f.Connect()
			} else {
				// Send ping to check if connection is still alive
				f.connMutex.Lock()
				if f.conn != nil {
					if err := f.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
						log.Printf("Ping failed, connection may be dead: %v", err)
						f.isConnected = false
						f.connMutex.Unlock()
						f.Connect()
						continue
					}
				}
				f.connMutex.Unlock()
			}
		}
	}
}

// processTradeData processes individual trade data and creates candles
func (f *FinnhubClient) processTradeData(trade *models.TradeData) {
	// Process the trade data through the candle service
	if f.candleService != nil {
		f.candleService.ProcessTradeData(trade)
		log.Printf("Processed trade: %s @ %.2f (vol: %d)", trade.Symbol, trade.Price, trade.Volume)
	} else {
		log.Printf("Warning: Candle service not available, skipping trade: %s @ %.2f", trade.Symbol, trade.Price)
	}
}
