#!/bin/bash
set -e

# ============================================
# Sekha Docker Deployer (Tier 2)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEKHA_VERSION="${SEKHA_VERSION:-latest}"

echo "🚀 Deploying Sekha with Docker Compose..."

# Create project directory
DEPLOY_DIR="${SEKHA_DEPLOY_DIR:-./sekha-deployment}"
mkdir -p "$DEPLOY_DIR" && cd "$DEPLOY_DIR"

# Download docker-compose.yml if not exists
if [ ! -f docker-compose.yml ]; then
    echo "📥 Downloading docker-compose.yml..."
    curl -sSL "https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/docker/docker-compose.yml" -o docker-compose.yml
fi

# Create .env file if not exists
if [ ! -f .env ]; then
    echo "🔧 Creating .env file..."
    cat > .env << EOF
# Sekha Configuration
SEKHA_PORT=8080

# Ollama Configuration
OLLAMA_HOST=http://ollama:11434

# Chroma Configuration
CHROMA_HOST=http://chroma:8000

# Redis Configuration
REDIS_HOST=redis://redis:6379/0

# Logging
RUST_LOG=info
EOF
fi

# Create data directory
mkdir -p data

# Create config.toml if not exists
if [ ! -f config.toml ]; then
    echo "📄 Creating config.toml..."
    cat > config.toml << EOF
# Sekha Controller Configuration
[server]
host = "0.0.0.0"
port = 8080

[database]
url = "sqlite:///data/sekha.db"

[chroma]
url = "http://chroma:8000"

[ollama]
url = "http://ollama:11434"
embedding_model = "nomic-embed-text"

[redis]
url = "redis://redis:6379/0"
EOF
fi

# Prompt for API keys if not set
if [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    echo ""
    echo "🔑 Optional: Add API keys for cloud LLM providers"
    echo "   Set OPENAI_API_KEY or ANTHROPIC_API_KEY in .env"
    echo ""
fi

# Pull images
echo "⬇️  Pulling Docker images..."
docker-compose pull

# Start services
echo "▶️  Starting Sekha services..."
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Show status
echo ""
echo "✅ Sekha is now running!"
echo ""
docker-compose ps

# Show URLs
echo ""
echo "📍 Access your services at:"
echo "   - Sekha Controller: http://localhost:8080"
echo "   - LLM Bridge: http://localhost:5001"
echo "   - Chroma UI: http://localhost:8000"
echo "   - Redis: localhost:6379"
echo ""
echo "📖 View logs: docker-compose logs -f"
echo "🛑 Stop: docker-compose down"
echo "🔄 Update: SEKHA_VERSION=new-version ./deploy-docker.sh"