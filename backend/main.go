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
)

func main() {
	// ENV Config
	env := EnvConfig()

	// DB Connection
	db := DBConneciton(env)

	// Connect to Finnhub Websocket
	finnhubWSConn := connectToFinnhubWS(env)
	defer finnhubWSConn.Close()

	// Handle Finnhub Websocket Messages
	go handleFinnhubMessages(finnhubWSConn, db)

	// Broadcast Candles to Clients
	go broadcastUpdates()

	// ---Endpoints---
	// Health check endpoint
	http.HandleFunc("/health", handleHealth)
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
	response := map[string]string{
		"status": "healthy",
		"time":   time.Now().Format(time.RFC3339),
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

// Connect to Finnhub Websocket
func connectToFinnhubWS(env *Env) *websocket.Conn {
	ws, _, err := websocket.DefaultDialer.Dial(fmt.Sprintf("wss://ws.finnhub.io?token=%s", env.API_KEY), nil)
	if err != nil {
		panic(err)
	}

	for _, s := range symbols {
		msg, _ := json.Marshal(map[string]interface{}{"type": "subscribe", "symbol": s})
		ws.WriteMessage(websocket.TextMessage, msg)
	}

	return ws
}

// Handle Finnhub Websocket Messages
func handleFinnhubMessages(ws *websocket.Conn, db *gorm.DB) {
	finnhubMessage := &FinnhubMessage{}
	for {
		if err := ws.ReadJSON(finnhubMessage); err != nil {
			log.Fatalf("Failed to read message from Finnhub Websocket: %v", err)
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
				log.Fatalf("Failed to create candle: %v", err)
			}
			broadcastChan <- &BroadcastMessage{
				UpdateType: Closed,
				Candle:     candle,
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
