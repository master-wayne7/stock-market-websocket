package main

import "time"

// Candle struct represent simple OHLCV data
type Candle struct {
	Symbol    string    `json:"symbol"`
	Open      float64   `json:"open"`
	High      float64   `json:"high"`
	Low       float64   `json:"low"`
	Close     float64   `json:"close"`
	Timestamp time.Time `json:"timestamp"`
}

// TempCandle struct represent the temporary candle data
type TempCandle struct {
	Symbol     string
	OpenTime   time.Time
	CloseTime  time.Time
	OpenPrice  float64
	HighPrice  float64
	LowPrice   float64
	ClosePrice float64
	Volume     float64
}

// FinnhubMessage struct represent the message from Finnhub Websocket
type FinnhubMessage struct {
	Data []TradeData `json:"data"`
	Type string      `json:"type"`
}

// TradeData struct represent the trade data from Finnhub Websocket
type TradeData struct {
	Conditions []string `json:"c"` // List of trade conditions
	Symbol     string   `json:"s"` // Symbol
	Timestamp  int64    `json:"t"` // UNIX milliseconds timestamp
	Price      float64  `json:"p"` // Last price
	Volume     float64  `json:"v"` // Volume
}

// BroadcastMessage struct represent the message to be broadcasted
type BroadcastMessage struct {
	UpdateType UpdateType `json:"update_type"`
	Candle     *Candle    `json:"candle"`
}

// UpdateType enum for the update type
type UpdateType string

const (
	Live   UpdateType = "live"
	Closed UpdateType = "closed"
)

// GetCandleData function to get the candle data
func (t *TempCandle) toCandle() *Candle {
	return &Candle{
		Symbol:    t.Symbol,
		Open:      t.OpenPrice,
		High:      t.HighPrice,
		Low:       t.LowPrice,
		Close:     t.ClosePrice,
		Timestamp: t.OpenTime,
	}
}
