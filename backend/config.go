package main

import (
	"log"

	"github.com/caarlos0/env"
	"github.com/joho/godotenv"
)

type Env struct {
	SERVER_PORT string `env:"PORT" envDefault:"8080"`
	API_KEY     string `env:"API_KEY" envDefault:""`

	// Database
	DB_HOST     string `env:"DB_HOST" envDefault:"localhost"`
	DB_USER     string `env:"DB_USER" envDefault:"postgres"`
	DB_PASSWORD string `env:"DB_PASSWORD" envDefault:""`
	DB_NAME     string `env:"DB_NAME" envDefault:"stock_tracker"`
	DB_SSL_MODE string `env:"DB_SSL_MODE" envDefault:"disable"`
}

func EnvConfig() *Env {
	// Try to load .env file (for local development)
	// Don't fail if it doesn't exist (for production deployments)
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found (this is normal in production): %v", err)
	}

	config := &Env{}
	if err := env.Parse(config); err != nil {
		log.Fatalf("Failed to process environment variables: %v", err)
	}

	// Log configuration (without sensitive data)
	log.Printf("Configuration loaded:")
	log.Printf("  SERVER_PORT: %s", config.SERVER_PORT)
	log.Printf("  DB_HOST: %s", config.DB_HOST)
	log.Printf("  DB_USER: %s", config.DB_USER)
	log.Printf("  DB_NAME: %s", config.DB_NAME)
	log.Printf("  DB_SSL_MODE: %s", config.DB_SSL_MODE)
	log.Printf("  API_KEY: %s", func() string {
		if config.API_KEY == "" {
			return "NOT SET"
		}
		return "SET (hidden)"
	}())

	// Validate required environment variables
	if config.API_KEY == "" {
		log.Fatalf("API_KEY environment variable is required")
	}

	return config
}
