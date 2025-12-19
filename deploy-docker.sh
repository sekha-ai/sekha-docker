#!/bin/bash
set -e

# Sekha Docker Deployer (Tier 2 - Production)
# Usage: ./deploy-docker.sh [--dev] [--version VERSION]

VERSION="latest"
COMPOSE_FILE="docker/docker-compose.full.yml"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            COMPOSE_FILE="docker/docker-compose.dev.yml"
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--dev] [--version VERSION]"
            echo "  --dev      Deploy development version with hot reload"
            echo "  --version  Specify version tag (default: latest)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🚀 Deploying Sekha with Docker Compose..."
echo "📋 Version: $VERSION"
echo "📁 Compose file: $COMPOSE_FILE"

# Create project directory
mkdir -p sekha-deployment && cd sekha-deployment

# Download docker-compose files
echo "📥 Downloading compose files..."
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/docker/docker-compose.yml -o docker-compose.yml
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/docker/docker-compose.full.yml -o docker-compose.full.yml
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/docker/docker-compose.dev.yml -o docker-compose.dev.yml

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "⚙️ Creating .env file..."
    cat > .env << ENVEOF
SEKHA_VERSION=$VERSION
BRIDGE_VERSION=$VERSION

# Ports
SEKHA_PORT=8080
BRIDGE_PORT=5001
CHROMA_PORT=8000
REDIS_PORT=6379

# External Services
OLLAMA_HOST=${OLLAMA_HOST:-http://host.docker.internal:11434}
SEKHA_LOG_LEVEL=info
BRIDGE_LOG_LEVEL=info

# Data persistence
CONFIG_PATH=./config.toml
ENVEOF
fi

# Create config.toml if it doesn't exist
if [ ! -f config.toml ]; then
    echo "⚙️ Creating config.toml..."
    curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-controller/main/config.example.toml -o config.toml
fi

# Pull images
echo "📦 Pulling Docker images..."
export $(cat .env | grep -v '^#' | xargs)
docker-compose -f "$COMPOSE_FILE" pull

# Start services
echo "▶️ Starting services..."
docker-compose -f "$COMPOSE_FILE" up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Show status
echo ""
echo "✅ Sekha deployed successfully!"
echo ""
echo "📊 Service Status:"
docker-compose -f "$COMPOSE_FILE" ps

echo ""
echo "🔗 Access points:"
echo "  - Sekha Controller: http://localhost:${SEKHA_PORT:-8080}"
echo "  - LLM Bridge: http://localhost:${BRIDGE_PORT:-5001}"
echo "  - Chroma DB: http://localhost:${CHROMA_PORT:-8000}"
echo ""
echo "📋 View logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f"
echo ""
echo "🛑 Stop services:"
echo "  docker-compose -f $COMPOSE_FILE down"
