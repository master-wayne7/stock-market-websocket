package models

import (
	"time"
)

// Candle represents a candlestick data point
type Candle struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Symbol    string    `json:"symbol"`
	Open      float64   `json:"open"`
	High      float64   `json:"high"`
	Low       float64   `json:"low"`
	Close     float64   `json:"close"`
	Volume    int64     `json:"volume"`
	Timestamp time.Time `json:"timestamp"`
}

// TempCandle represents a temporary candle being built
type TempCandle struct {
	Symbol     string    `json:"symbol"`
	OpenTime   time.Time `json:"open_time"`
	OpenPrice  float64   `json:"open_price"`
	HighPrice  float64   `json:"high_price"`
	LowPrice   float64   `json:"low_price"`
	CloseTime  time.Time `json:"close_time"`
	ClosePrice float64   `json:"close_price"`
	Volume     int64     `json:"volume"`
}

// FinnhubMessage represents a message from Finnhub WebSocket
type FinnhubMessage struct {
	Type string      `json:"type"`
	Data []TradeData `json:"data"`
}

// TradeData represents individual trade data from Finnhub
type TradeData struct {
	Symbol    string  `json:"s"`
	Price     float64 `json:"p"`
	Volume    int64   `json:"v"`
	Timestamp int64   `json:"t"`
}

// BroadcastMessage represents a message to be broadcast to clients
type BroadcastMessage struct {
	UpdateType UpdateType `json:"update_type"`
	Candle     *Candle    `json:"candle"`
}

// UpdateType represents the type of update
type UpdateType string

const (
	Live   UpdateType = "live"
	Closed UpdateType = "closed"
)

// TableName specifies the table name for Candle model
func (Candle) TableName() string {
	return "candles"
}

// ToCandle converts TempCandle to Candle
func (tc *TempCandle) ToCandle() *Candle {
	return &Candle{
		Symbol:    tc.Symbol,
		Open:      tc.OpenPrice,
		High:      tc.HighPrice,
		Low:       tc.LowPrice,
		Close:     tc.ClosePrice,
		Volume:    tc.Volume,
		Timestamp: tc.OpenTime,
	}
}
