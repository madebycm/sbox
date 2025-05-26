#!/bin/bash
# @author madebycm (2025-01-26)

set -e

echo "🧪 Running Sandbox Tests..."

# Activate virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q -r requirements.txt

# Build Docker image
echo "Building Docker image..."
docker build -t sandbox-base:latest . > /dev/null 2>&1

# Run tests
echo ""
echo "Running shared installation test..."
python3 test_shared_install.py

echo ""
echo "✅ All tests completed!"