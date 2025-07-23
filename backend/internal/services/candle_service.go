package services

import (
	"log"
	"sync"
	"time"

	"gorm.io/gorm"

	"stock-market-websocket/internal/models"
)

// CandleService manages candle processing and database operations
type CandleService struct {
	db          *gorm.DB
	tempCandles map[string]*models.TempCandle
	mutex       sync.Mutex
	broadcastCh chan *models.BroadcastMessage
}

// NewCandleService creates a new candle service
func NewCandleService(db *gorm.DB) *CandleService {
	return &CandleService{
		db:          db,
		tempCandles: make(map[string]*models.TempCandle),
		broadcastCh: make(chan *models.BroadcastMessage, 100),
	}
}

// GetBroadcastChannel returns the broadcast channel
func (cs *CandleService) GetBroadcastChannel() chan *models.BroadcastMessage {
	return cs.broadcastCh
}

// ProcessTradeData processes trade data and creates/updates candles
func (cs *CandleService) ProcessTradeData(trade *models.TradeData) {
	cs.mutex.Lock()
	defer cs.mutex.Unlock()

	symbol := trade.Symbol
	timestamp := time.UnixMilli(trade.Timestamp)
	price := trade.Price
	volume := trade.Volume

	tempCandle, exists := cs.tempCandles[symbol]
	if !exists || timestamp.After(tempCandle.CloseTime) {
		if exists {
			candle := tempCandle.ToCandle()
			if err := cs.db.Create(candle).Error; err != nil {
				log.Printf("Failed to create candle: %v", err)
			} else {
				cs.broadcastCh <- &models.BroadcastMessage{
					UpdateType: models.Closed,
					Candle:     candle,
				}
			}
		}

		tempCandle = &models.TempCandle{
			Symbol:     symbol,
			OpenTime:   timestamp,
			OpenPrice:  price,
			HighPrice:  price,
			LowPrice:   price,
			CloseTime:  timestamp.Add(1 * time.Minute),
			ClosePrice: price,
			Volume:     volume,
		}
		cs.tempCandles[symbol] = tempCandle

		cs.broadcastCh <- &models.BroadcastMessage{
			UpdateType: models.Live,
			Candle:     tempCandle.ToCandle(),
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

		cs.broadcastCh <- &models.BroadcastMessage{
			UpdateType: models.Live,
			Candle:     tempCandle.ToCandle(),
		}
	}
}

// GetCandles retrieves candles for a specific symbol
func (cs *CandleService) GetCandles(symbol string) ([]models.Candle, error) {
	var candles []models.Candle
	err := cs.db.Where("symbol = ?", symbol).Order("timestamp asc").Find(&candles).Error
	return candles, err
}

// GetAllCandles retrieves all candles grouped by symbol
func (cs *CandleService) GetAllCandles() (map[string][]models.Candle, error) {
	var candles []models.Candle
	err := cs.db.Order("timestamp asc").Find(&candles).Error
	if err != nil {
		return nil, err
	}

	groupedData := make(map[string][]models.Candle)
	for _, candle := range candles {
		groupedData[candle.Symbol] = append(groupedData[candle.Symbol], candle)
	}

	return groupedData, nil
}
