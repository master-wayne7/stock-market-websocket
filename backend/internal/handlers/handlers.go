package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"stock-market-websocket/internal/services"
	"stock-market-websocket/internal/websocket"
)

// Handler struct holds dependencies for HTTP handlers
type Handler struct {
	candleService *services.CandleService
	symbols       []string
	finnhubClient *websocket.FinnhubClient
	clientManager *websocket.ClientManager
	startTime     time.Time
}

// NewHandler creates a new handler instance
func NewHandler(candleService *services.CandleService, symbols []string, finnhubClient *websocket.FinnhubClient, clientManager *websocket.ClientManager) *Handler {
	return &Handler{
		candleService: candleService,
		symbols:       symbols,
		finnhubClient: finnhubClient,
		clientManager: clientManager,
		startTime:     time.Now(),
	}
}

// HandleHealth handles health check requests
func (h *Handler) HandleHealth(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := map[string]interface{}{
		"status":            "healthy",
		"time":              time.Now().Format(time.RFC3339),
		"finnhub_connected": h.finnhubClient != nil && h.finnhubClient.IsConnected(),
		"uptime":            time.Since(h.startTime).String(),
	}
	json.NewEncoder(w).Encode(response)
}

// HandlePing handles keep-alive ping requests
func (h *Handler) HandlePing(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	response := map[string]string{
		"pong": time.Now().Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

// HandleStatus handles status check requests
func (h *Handler) HandleStatus(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	var finnhubConnected bool
	var lastPingTime time.Time

	if h.finnhubClient != nil {
		finnhubConnected = h.finnhubClient.IsConnected()
		lastPingTime = h.finnhubClient.GetLastPingTime()
	}

	response := map[string]interface{}{
		"finnhub_connected": finnhubConnected,
		"finnhub_conn_nil":  h.finnhubClient == nil,
		"active_clients":    h.clientManager.GetActiveClientsCount(),
		"last_ping":         lastPingTime.Format(time.RFC3339),
		"uptime":            time.Since(h.startTime).String(),
		"server_start_time": h.startTime.Format(time.RFC3339),
	}
	json.NewEncoder(w).Encode(response)
}

// HandleGetSymbols handles symbol list requests
func (h *Handler) HandleGetSymbols(w http.ResponseWriter, _ *http.Request) {
	jsonResponse, err := json.Marshal(h.symbols)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}

// HandleStocksHistory handles requests for all stock history
func (h *Handler) HandleStocksHistory(w http.ResponseWriter, _ *http.Request) {
	candles, err := h.candleService.GetAllCandles()
	if err != nil {
		http.Error(w, "Failed to retrieve candles", http.StatusInternalServerError)
		return
	}

	jsonResponse, err := json.Marshal(candles)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}

// HandleStocksCandles handles requests for specific symbol candles
func (h *Handler) HandleStocksCandles(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		http.Error(w, "Symbol parameter is required", http.StatusBadRequest)
		return
	}

	candles, err := h.candleService.GetCandles(symbol)
	if err != nil {
		http.Error(w, "Failed to retrieve candles", http.StatusInternalServerError)
		return
	}

	jsonResponse, err := json.Marshal(candles)
	if err != nil {
		http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonResponse)
}
