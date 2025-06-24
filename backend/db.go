package main

import (
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm/logger"

	"gorm.io/gorm"
)

func DBConneciton(env *Env) *gorm.DB {
	url := fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=%s port=5432", env.DB_HOST, env.DB_USER, env.DB_PASSWORD, env.DB_NAME, env.DB_SSL_MODE)
	db, err := gorm.Open(postgres.Open(url), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	fmt.Println("Connected to database")
	if err := db.AutoMigrate(&Candle{}); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
	return db
}
