#!/bin/bash

# Create necessary directories
mkdir -p docs

# Check if backend directory exists
if [ ! -d "backend" ]; then
    echo "Error: backend directory not found"
    exit 1
fi

# Set environment variables for the virtual environment and link mode
export UV_PROJECT_ENVIRONMENT="$HOME/.venv"
export UV_LINK_MODE=copy

echo "Starting Course Materials RAG System..."
echo "Make sure you have set your ANTHROPIC_API_KEY in .env"

# Change to backend directory and start the server
cd backend && uv run uvicorn app:app --reload --port 8000 --host ::
