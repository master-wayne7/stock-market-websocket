package main

import (
	"log"

	"github.com/caarlos0/env"
	"github.com/joho/godotenv"
)

type Env struct {
	SERVER_PORT string `env:"SERVER_PORT",default:"8080",required:"true"`
	API_KEY     string `env:"API_KEY",required:"true"`

	// Database
	DB_HOST     string `env:"DB_HOST",required:"true"`
	DB_USER     string `env:"DB_USER",required:"true"`
	DB_PASSWORD string `env:"DB_PASSWORD",required:"true"`
	DB_NAME     string `env:"DB_NAME",required:"true"`
	DB_SSL_MODE string `env:"DB_SSL_MODE",required:"true"`
}

func EnvConfig() *Env {
	if err := godotenv.Load(); err != nil {
		log.Fatalf("Failed to process environment variables: %v", err)
	}
	config := &Env{}
	if err := env.Parse(config); err != nil {
		log.Fatalf("Failed to process environment variables: %v", err)
	}
	return config
}
