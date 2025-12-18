#!/bin/bash
set -e

# Sekha Docker Deployer (Tier 2)
# One-command deployment for production

SEKHA_VERSION="${SEKHA_VERSION:-latest}"
INSTALL_DIR="${INSTALL_DIR:-./sekha-deployment}"

echo "🚀 Deploying Sekha with Docker Compose..."

# Create project directory
mkdir -p "$INSTALL_DIR" && cd "$INSTALL_DIR"

# Download docker-compose.prod.yml
if [ ! -f docker-compose.prod.yml ]; then
    curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/docker/docker-compose.prod.yml -o docker-compose.prod.yml
fi

# Download config template
if [ ! -f config.prod.toml ]; then
    curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/config.prod.toml -o config.prod.toml
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cat > .env << 'EOF'
# Sekha Configuration
SEKHA_PORT=8080
OLLAMA_HOST=http://host.docker.internal:11434
# For Linux, use: OLLAMA_HOST=http://localhost:11434
CHROMA_HOST=http://chroma:8000
REDIS_HOST=redis://redis:6379/0

# Optional: API Keys for cloud LLMs
# ANTHROPIC_API_KEY=your_key_here
# OPENAI_API_KEY=your_key_here
EOF
    echo "⚠️  Created .env file - please review and add API keys if needed"
fi

# Create data directories
mkdir -p data

# Pull latest images
echo "📦 Pulling container images..."
docker-compose -f docker-compose.prod.yml pull

# Start services
echo "▶️  Starting Sekha services..."
docker-compose -f docker-compose.prod.yml up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check status
echo "✅ Checking service health..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "🎉 Sekha is now running!"
echo ""
echo "📊 Check service logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "🌐 Access Sekha at: http://localhost:8080"
echo "🔧 Configuration: $(pwd)/config.prod.toml"
echo "💾 Data directory: $(pwd)/data"
echo ""
echo "📖 View logs:"
echo "   docker-compose -f docker-compose.prod.yml logs -f"
echo ""
echo "⏹️  Stop services:"
echo "   docker-compose -f docker-compose.prod.yml down"