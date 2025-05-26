#!/bin/bash
# @author madebycm (2025-01-26)

set -e

echo "🚀 Setting up Docker Sandbox Environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Create and activate virtual environment
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install requirements
echo "📚 Installing Python dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt

# Build Docker base image
echo "🐳 Building Docker base image..."
docker-compose build

# Make sandbox executable
chmod +x sandbox

# Launch the CLI
echo "✅ Setup complete! Launching sandbox manager..."
echo ""
./sandbox