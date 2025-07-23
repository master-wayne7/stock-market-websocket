package broadcaster

import (
	"time"

	"stock-market-websocket/internal/models"
	"stock-market-websocket/internal/websocket"
)

// Broadcaster manages real-time updates to clients
type Broadcaster struct {
	broadcastChan chan *models.BroadcastMessage
	clientManager *websocket.ClientManager
	ticker        *time.Ticker
}

// NewBroadcaster creates a new broadcaster
func NewBroadcaster(clientManager *websocket.ClientManager) *Broadcaster {
	return &Broadcaster{
		broadcastChan: make(chan *models.BroadcastMessage, 100),
		clientManager: clientManager,
		ticker:        time.NewTicker(1 * time.Second),
	}
}

// GetBroadcastChannel returns the broadcast channel
func (b *Broadcaster) GetBroadcastChannel() chan *models.BroadcastMessage {
	return b.broadcastChan
}

// Start begins broadcasting updates
func (b *Broadcaster) Start() {
	go b.broadcastUpdates()
}

// Stop stops the broadcaster
func (b *Broadcaster) Stop() {
	b.ticker.Stop()
}

// broadcastUpdates handles the broadcasting logic
func (b *Broadcaster) broadcastUpdates() {
	defer b.ticker.Stop()

	var latestUpdate *models.BroadcastMessage

	for {
		select {
		case msg := <-b.broadcastChan:
			// If closed candle then broadcast immediately
			if msg.UpdateType == models.Closed {
				b.clientManager.BroadcastToClients(msg)
			} else {
				// Replace temporary candle with the new live candle
				latestUpdate = msg
			}
		case <-b.ticker.C:
			// For every 1 second, broadcast the live candle
			if latestUpdate != nil {
				b.clientManager.BroadcastToClients(latestUpdate)
			}
			latestUpdate = nil
		}
	}
}
