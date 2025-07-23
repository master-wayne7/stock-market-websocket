package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"stock-market-websocket/internal/models"
)

// ClientManager manages WebSocket connections to frontend clients
type ClientManager struct {
	clients      map[*websocket.Conn]string
	clientsMutex sync.RWMutex
	upgrader     websocket.Upgrader
}

// NewClientManager creates a new client manager
func NewClientManager() *ClientManager {
	return &ClientManager{
		clients: make(map[*websocket.Conn]string),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins for now
			},
		},
	}
}

// HandleWebSocket handles new WebSocket connections from clients
func (cm *ClientManager) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	ws, err := cm.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade to WebSocket: %v", err)
		return
	}
	defer ws.Close()
	defer func() {
		cm.clientsMutex.Lock()
		delete(cm.clients, ws)
		cm.clientsMutex.Unlock()
		log.Printf("Client disconnected")
	}()

	for {
		_, symbol, err := ws.ReadMessage()
		if err != nil {
			log.Printf("Failed to read message from WebSocket: %v", err)
			break
		}

		cm.clientsMutex.Lock()
		cm.clients[ws] = string(symbol)
		cm.clientsMutex.Unlock()

		log.Printf("Client connected: %s", symbol)
	}
}

// BroadcastToClients broadcasts messages to connected clients
func (cm *ClientManager) BroadcastToClients(msg *models.BroadcastMessage) {
	jsonMsg, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal message: %v", err)
		return
	}

	cm.clientsMutex.RLock()
	defer cm.clientsMutex.RUnlock()

	for conn, symbol := range cm.clients {
		if symbol == msg.Candle.Symbol {
			if err := conn.WriteMessage(websocket.TextMessage, jsonMsg); err != nil {
				log.Printf("Failed to write message to WebSocket: %v", err)
				conn.Close()
				delete(cm.clients, conn)
			}
		}
	}
}

// GetActiveClientsCount returns the number of active clients
func (cm *ClientManager) GetActiveClientsCount() int {
	cm.clientsMutex.RLock()
	defer cm.clientsMutex.RUnlock()
	return len(cm.clients)
}
