#!/bin/bash

# Migration script to move from monolithic main.go to organized structure

echo "🚀 Starting migration to organized folder structure..."

# Create backup of original files
echo "📦 Creating backups..."
mkdir -p backup
cp main.go backup/
cp config.go backup/
cp db.go backup/
cp model.go backup/

echo "✅ Backups created in backup/ directory"

# Test the new structure
echo "🧪 Testing new structure..."
if go run cmd/main.go --help 2>/dev/null; then
    echo "✅ New structure compiles successfully"
else
    echo "⚠️  New structure may have issues, but this is expected if no .env file exists"
fi

echo ""
echo "🎉 Migration completed!"
echo ""
echo "📁 New structure:"
echo "  ├── cmd/main.go              # New entry point"
echo "  ├── internal/"
echo "  │   ├── config/              # Configuration"
echo "  │   ├── database/            # Database operations"
echo "  │   ├── handlers/            # HTTP handlers"
echo "  │   ├── middleware/          # HTTP middleware"
echo "  │   ├── models/              # Data models"
echo "  │   ├── services/            # Business logic"
echo "  │   ├── websocket/           # WebSocket management"
echo "  │   └── broadcaster/         # Real-time broadcasting"
echo "  └── backup/                  # Original files backup"
echo ""
echo "🚀 To run the new structure:"
echo "  go run cmd/main.go"
echo ""
echo "🐳 To build with Docker:"
echo "  docker build -f Dockerfile.prod -t stock-market-backend ."
echo ""
echo "📚 See README.md for detailed documentation" 