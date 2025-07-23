package services

import (
	"testing"
	"time"

	"stock-market-websocket/internal/models"
)

func TestCandleService_ProcessTradeData(t *testing.T) {
	// This is a basic test to ensure the service can be instantiated
	// In a real application, you'd want to use a test database
	service := &CandleService{
		db:          nil, // Would be a test database in real tests
		tempCandles: make(map[string]*models.TempCandle),
		broadcastCh: make(chan *models.BroadcastMessage, 100),
	}

	// Test that the broadcast channel is available
	if service.GetBroadcastChannel() == nil {
		t.Fatal("Broadcast channel should be nil")
	}
}

func TestTempCandle_ToCandle(t *testing.T) {
	now := time.Now()
	tempCandle := &models.TempCandle{
		Symbol:     "AAPL",
		OpenTime:   now,
		OpenPrice:  150.0,
		HighPrice:  155.0,
		LowPrice:   148.0,
		CloseTime:  now.Add(time.Minute),
		ClosePrice: 152.0,
		Volume:     1000,
	}

	candle := tempCandle.ToCandle()

	if candle.Symbol != "AAPL" {
		t.Errorf("Expected symbol AAPL, got %s", candle.Symbol)
	}

	if candle.Open != 150.0 {
		t.Errorf("Expected open price 150.0, got %f", candle.Open)
	}

	if candle.High != 155.0 {
		t.Errorf("Expected high price 155.0, got %f", candle.High)
	}

	if candle.Low != 148.0 {
		t.Errorf("Expected low price 148.0, got %f", candle.Low)
	}

	if candle.Close != 152.0 {
		t.Errorf("Expected close price 152.0, got %f", candle.Close)
	}

	if candle.Volume != 1000 {
		t.Errorf("Expected volume 1000, got %d", candle.Volume)
	}
}
