package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"gorm.io/gorm"
)

var (
	symbols = []string{"AAPL", "AMZN", "TSLA", "GOOGL", "MSFT", "NVDA", "META", "NFLX", "SAP", "INTC", "CSCO", "ORCL", "IBM", "PYPL"}

	broadcastChan = make(chan *BroadcastMessage)

	clientConnections = make(map[*websocket.Conn]string)

	tempCandles = make(map[string]*TempCandle)

	mutex = &sync.Mutex{}

	// Connection management
	finnhubConn      *websocket.Conn
	finnhubConnMutex sync.Mutex
	isConnected      bool
	lastPingTime     time.Time
	reconnectTicker  *time.Ticker
)

func main() {
	// ENV Config
	env := EnvConfig()

	// DB Connection
	db := DBConneciton(env)

	// Initialize connection management
	lastPingTime = time.Now()
	reconnectTicker = time.NewTicker(30 * time.Second) // Check connection every 30 seconds

	// Connect to Finnhub Websocket
	connectToFinnhubWS(env)

	// Handle Finnhub Websocket Messages
	go handleFinnhubMessages(db)

	// Broadcast Candles to Clients
	go broadcastUpdates()

	// Keep-alive mechanism to prevent Render from sleeping
	go keepAlivePing()

	// Connection health monitoring
	go monitorConnectionHealth(env)

	// ---Endpoints---
	// Health check endpoint
	http.HandleFunc("/health", handleHealth)
	// Keep-alive endpoint for external ping services
	http.HandleFunc("/ping", handlePing)
	// Connection status endpoint
	http.HandleFunc("/status", handleStatus)
	// Connect to Websocket
	http.HandleFunc("/ws", corsMiddleware(handleWebSocket))
	// Get available symbols
	http.HandleFunc("/symbols", corsMiddleware(handleGetSymbols))
	// Fetch all previous candles of all symbols
	http.HandleFunc("/stocks-history", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		handleStocksHistory(w, r, db)
	}))
	// fetch all previous candles of a symbol
	http.HandleFunc("/stocks-candles", corsMiddleware(func(w http.ResponseWriter, r *http.Request) {
		handleStocksCandles(w, r, db)
	}))

	// Serve the Endpoints
	log.Printf("Server is running on port %s", env.SERVER_PORT)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", env.SERVER_PORT), nil))
}

// Keep-alive ping to prevent Render from sleeping
func keepAlivePing() {
	ticker := time.NewTicker(10 * time.Minute) // Ping every 10 minutes
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// Ping our own health endpoint to keep the instance alive
			go func() {
				resp, err := http.Get(fmt.Sprintf("http://localhost:%s/health", getServerPort()))
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

// Monitor connection health and reconnect if needed
func monitorConnectionHealth(env *Env) {
	for {
		select {
		case <-reconnectTicker.C:
			finnhubConnMutex.Lock()
			connHealthy := isConnected && finnhubConn != nil
			finnhubConnMutex.Unlock()

			if !connHealthy {
				log.Printf("Connection unhealthy, attempting to reconnect...")
				connectToFinnhubWS(env)
			} else {
				// Send ping to check if connection is still alive
				finnhubConnMutex.Lock()
				if finnhubConn != nil {
					if err := finnhubConn.WriteMessage(websocket.PingMessage, nil); err != nil {
						log.Printf("Ping failed, connection may be dead: %v", err)
						isConnected = false
						finnhubConnMutex.Unlock()
						connectToFinnhubWS(env)
						continue
					}
				}
				finnhubConnMutex.Unlock()
			}
		}
	}
}

// Get server port from environment or default
func getServerPort() string {
	env := EnvConfig()
	return env.SERVER_PORT
}

// Handle Websocket Connection
func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade to WebSocket: %v", err)
		return
	}
	defer ws.Close()
	defer func() {
		delete(clientConnections, ws)
		log.Printf("Client disconnected")
	}()

	for {
		_, symbol, err := ws.ReadMessage()
		clientConnections[ws] = string(symbol)
		log.Printf("Client connected: %s", symbol)
		if err != nil {
			log.Printf("Failed to read message from WebSocket: %v", err)
			break
		}
	}
}

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	finnhubConnMutex.Lock()
	connStatus := isConnected
	finnhubConnMutex.Unlock()

	response := map[string]interface{}{
		"status":            "healthy",
		"time":              time.Now().Format(time.RFC3339),
		"finnhub_connected": connStatus,
		"uptime":            time.Since(lastPingTime).String(),
	}
	json.NewEncoder(w).Encode(response)
}

// Keep-alive endpoint for external ping services
func handlePing(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"pong": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

// Connection status endpoint
func handleStatus(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	finnhubConnMutex.Lock()
	connStatus := isConnected
	conn := finnhubConn
	finnhubConnMutex.Unlock()

	response := map[string]interface{}{
		"finnhub_connected": connStatus,
		"finnhub_conn_nil":  conn == nil,
		"active_clients":    len(clientConnections),
		"last_ping":         lastPingTime.Format(time.RFC3339),
		"uptime":            time.Since(lastPingTime).String(),
	}
	json.NewEncoder(w).Encode(response)
}

func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Set CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		// Call the next handler
		next(w, r)
	}
}

func handleGetSymbols(w http.ResponseWriter, _ *http.Request) {
	jsonResponse, err := json.Marshal(symbols)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}

func handleStocksHistory(w http.ResponseWriter, _ *http.Request, db *gorm.DB) {
	var candles []Candle
	db.Order("timestamp asc").Find(&candles)
	groupedData := make(map[string][]Candle)
	for _, candle := range candles {
		groupedData[candle.Symbol] = append(groupedData[candle.Symbol], candle)
	}
	jsonResponse, err := json.Marshal(groupedData)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}

func handleStocksCandles(w http.ResponseWriter, r *http.Request, db *gorm.DB) {
	symbol := r.URL.Query().Get("symbol")
	var candles []Candle
	db.Where("symbol = ?", symbol).Order("timestamp asc").Find(&candles)
	jsonResponse, err := json.Marshal(candles)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}

// Connect to Finnhub Websocket with retry logic
func connectToFinnhubWS(env *Env) {
	finnhubConnMutex.Lock()
	defer finnhubConnMutex.Unlock()

	// Close existing connection if any
	if finnhubConn != nil {
		finnhubConn.Close()
		finnhubConn = nil
	}

	// Reset connection status
	isConnected = false

	// Attempt to connect with retries
	maxRetries := 5
	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("Attempting to connect to Finnhub WebSocket (attempt %d/%d)", attempt, maxRetries)

		ws, _, err := websocket.DefaultDialer.Dial(fmt.Sprintf("wss://ws.finnhub.io?token=%s", env.API_KEY), nil)
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
		for _, s := range symbols {
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
		finnhubConn = ws
		isConnected = true
		lastPingTime = time.Now()
		log.Printf("Successfully connected to Finnhub WebSocket")
		return
	}
}

// Handle Finnhub Websocket Messages with reconnection logic
func handleFinnhubMessages(db *gorm.DB) {
	for {
		finnhubConnMutex.Lock()
		conn := finnhubConn
		connected := isConnected
		finnhubConnMutex.Unlock()

		if !connected || conn == nil {
			log.Printf("No active Finnhub connection, waiting for reconnection...")
			time.Sleep(5 * time.Second)
			continue
		}

		finnhubMessage := &FinnhubMessage{}
		if err := conn.ReadJSON(finnhubMessage); err != nil {
			log.Printf("Failed to read message from Finnhub WebSocket: %v", err)

			// Mark connection as disconnected
			finnhubConnMutex.Lock()
			isConnected = false
			finnhubConnMutex.Unlock()

			// Wait before attempting reconnection
			time.Sleep(5 * time.Second)
			continue
		}

		if finnhubMessage.Type == "trade" {
			for _, trade := range finnhubMessage.Data {
				processTradeData(&trade, db)
			}
		}
	}
}

// Process Trade Data
func processTradeData(trade *TradeData, db *gorm.DB) {
	mutex.Lock()
	defer mutex.Unlock()

	symbol := trade.Symbol
	timestamp := time.UnixMilli(trade.Timestamp)
	price := trade.Price
	volume := trade.Volume

	tempCandle, exists := tempCandles[symbol]
	if !exists || timestamp.After(tempCandle.CloseTime) {
		if exists {
			candle := tempCandle.toCandle()
			if err := db.Create(candle).Error; err != nil {
				log.Printf("Failed to create candle: %v", err)
			} else {
				broadcastChan <- &BroadcastMessage{
					UpdateType: Closed,
					Candle:     candle,
				}
			}
		}

		tempCandle = &TempCandle{
			Symbol:     symbol,
			OpenTime:   timestamp,
			OpenPrice:  price,
			HighPrice:  price,
			LowPrice:   price,
			CloseTime:  timestamp.Add(1 * time.Minute),
			ClosePrice: price,
			Volume:     volume,
		}
		tempCandle.ClosePrice = price
		tempCandle.Volume += volume
		if price > tempCandle.HighPrice {
			tempCandle.HighPrice = price
		}
		if price < tempCandle.LowPrice {
			tempCandle.LowPrice = price
		}

		tempCandles[symbol] = tempCandle

		broadcastChan <- &BroadcastMessage{
			UpdateType: Live,
			Candle:     tempCandle.toCandle(),
		}
	} else {
		// Update existing temp candle
		tempCandle.ClosePrice = price
		tempCandle.Volume += volume
		if price > tempCandle.HighPrice {
			tempCandle.HighPrice = price
		}
		if price < tempCandle.LowPrice {
			tempCandle.LowPrice = price
		}

		broadcastChan <- &BroadcastMessage{
			UpdateType: Live,
			Candle:     tempCandle.toCandle(),
		}
	}
}

func broadcastUpdates() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	var latestUpdate *BroadcastMessage

	for {
		select {
		// watch for new candles from broadcastChan
		case msg := <-broadcastChan:
			// if closed candle then broadcast immediately
			if msg.UpdateType == Closed {
				broadcastToClients(msg)
			} else {
				// replace temporary candle with the new live candle
				latestUpdate = msg
			}
		case <-ticker.C:
			// for every 1 second, broadcast the live candle
			if latestUpdate != nil {
				broadcastToClients(latestUpdate)
			}
			latestUpdate = nil
		}
	}
}

func broadcastToClients(msg *BroadcastMessage) {
	jsonMsg, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal message: %v", err)
		return
	}
	for conn, symbol := range clientConnections {
		if symbol == msg.Candle.Symbol {
			if err := conn.WriteMessage(websocket.TextMessage, jsonMsg); err != nil {
				log.Printf("Failed to write message to WebSocket: %v", err)
				conn.Close()
				delete(clientConnections, conn)
			}
		}
	}
}
