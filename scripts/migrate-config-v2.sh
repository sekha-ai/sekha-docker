#!/bin/bash
# ============================================
# Sekha v1.x to v2.0 Configuration Migration
# ============================================
# This script migrates old environment-based configuration
# to the new v2.0 YAML format with provider registry.

set -e  # Exit on error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "  Sekha v1.x → v2.0 Configuration Migration"
echo "================================================"
echo ""

# Backup existing config
BACKUP_DIR=".sekha-backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/config-v1-$(date +%Y%m%d-%H%M%S).backup"

if [ -f "config.yaml" ]; then
    echo -e "${YELLOW}⚠️  Backing up existing config.yaml...${NC}"
    cp config.yaml "$BACKUP_FILE"
    echo -e "${GREEN}✓ Backup saved to: $BACKUP_FILE${NC}"
    echo ""
fi

if [ -f ".env" ]; then
    ENV_BACKUP="$BACKUP_DIR/.env-$(date +%Y%m%d-%H%M%S).backup"
    cp .env "$ENV_BACKUP"
    echo -e "${GREEN}✓ .env backed up to: $ENV_BACKUP${NC}"
    echo ""
fi

# Load environment variables if .env exists
if [ -f ".env" ]; then
    echo "Loading environment variables from .env..."
    set -a
    source .env
    set +a
fi

# Default values from v1.x
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
EMBEDDING_MODEL="${EMBEDDING_MODEL:-nomic-embed-text}"
SUMMARIZATION_MODEL="${SUMMARIZATION_MODEL:-llama3.1:8b}"
SERVER_PORT="${SERVER_PORT:-8080}"
CHROMA_URL="${CHROMA_URL:-http://localhost:8000}"
LLM_BRIDGE_URL="${LLM_BRIDGE_URL:-http://localhost:5001}"
DATABASE_URL="${DATABASE_URL:-sqlite://sekha.db}"
MCP_API_KEY="${MCP_API_KEY:-}"

# Display detected configuration
echo "Detected v1.x configuration:"
echo "  Ollama URL:         $OLLAMA_URL"
echo "  Embedding Model:    $EMBEDDING_MODEL"
echo "  Summarization:      $SUMMARIZATION_MODEL"
echo "  Server Port:        $SERVER_PORT"
echo ""

# Prompt for confirmation
read -p "Proceed with migration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Migration cancelled.${NC}"
    exit 1
fi

# Detect embedding dimension
EMBED_DIMENSION=768
if [[ "$EMBEDDING_MODEL" == *"3-large"* ]]; then
    EMBED_DIMENSION=3072
elif [[ "$EMBEDDING_MODEL" == *"3-small"* ]]; then
    EMBED_DIMENSION=1536
fi

# Generate v2.0 config
echo ""
echo "Generating v2.0 configuration..."

cat > config.yaml << EOF
# ============================================
# Sekha v2.0 Configuration
# Auto-migrated from v1.x on $(date)
# ============================================
# Original v1.x config backed up to: $BACKUP_FILE

version: "2.0"

# ============================================
# LLM Provider Registry
# ============================================
llm_providers:
  - id: "ollama_migrated"
    type: "ollama"
    base_url: "$OLLAMA_URL"
    priority: 1
    timeout: 120
    models:
      - model_id: "$EMBEDDING_MODEL"
        task: "embedding"
        context_window: 8192
        dimension: $EMBED_DIMENSION
      - model_id: "$SUMMARIZATION_MODEL"
        task: "chat_small"
        context_window: 8192
      - model_id: "$SUMMARIZATION_MODEL"
        task: "chat_smart"
        context_window: 8192

# ============================================
# Default Model Selections
# ============================================
default_models:
  embedding: "$EMBEDDING_MODEL"
  chat_fast: "$SUMMARIZATION_MODEL"
  chat_smart: "$SUMMARIZATION_MODEL"
  chat_vision: null

# ============================================
# Routing Configuration
# ============================================
routing:
  auto_fallback: true
  require_vision_for_images: true
  circuit_breaker:
    failure_threshold: 3
    timeout_secs: 60
    success_threshold: 2

# ============================================
# Server Configuration
# ============================================
server_host: "0.0.0.0"
server_port: $SERVER_PORT
max_connections: 10
log_level: "info"

# ============================================
# Database Configuration
# ============================================
database_url: "$DATABASE_URL"
chroma_url: "$CHROMA_URL"
llm_bridge_url: "$LLM_BRIDGE_URL"

# ============================================
# API Security
# ============================================
mcp_api_key: "\${SEKHA_API_KEY}"
rest_api_key: "\${SEKHA_API_KEY}"
rate_limit_per_minute: 1000
cors_enabled: true

# ============================================
# Features
# ============================================
summarization_enabled: true
pruning_enabled: true

EOF

echo -e "${GREEN}✓ Generated config.yaml${NC}"
echo ""

# Generate updated .env template
cat > .env.v2.example << 'EOF'
# ============================================
# Sekha v2.0 Environment Variables
# ============================================
# Copy to .env and customize

# Required: API Key for authentication
SEKHA_API_KEY="your-secure-api-key-minimum-32-characters-long"

# Optional: Cloud provider API keys (if using multi-provider setup)
# OPENAI_API_KEY="sk-..."
# ANTHROPIC_API_KEY="sk-ant-..."
# OPENROUTER_API_KEY="sk-or-..."

# Optional: Override any config.yaml setting
# SEKHA__SERVER_PORT=8081
# SEKHA__LOG_LEVEL=debug
EOF

echo -e "${GREEN}✓ Generated .env.v2.example${NC}"
echo ""

# Create migration summary
MIGRATION_SUMMARY="$BACKUP_DIR/migration-summary-$(date +%Y%m%d-%H%M%S).txt"
cat > "$MIGRATION_SUMMARY" << EOF
Sekha v1.x → v2.0 Migration Summary
====================================
Date: $(date)

Migrated Configuration:
-----------------------
Provider:          Ollama (ollama_migrated)
Base URL:          $OLLAMA_URL
Embedding Model:   $EMBEDDING_MODEL (dimension: $EMBED_DIMENSION)
Chat Model:        $SUMMARIZATION_MODEL

New Files:
----------
✓ config.yaml         - v2.0 configuration with provider registry
✓ .env.v2.example     - Example environment variables

Backups:
--------
✓ $BACKUP_FILE
$([ -f "$ENV_BACKUP" ] && echo "✓ $ENV_BACKUP" || echo "")

Next Steps:
-----------
1. Review config.yaml and adjust as needed
2. Update .env with required API keys (SEKHA_API_KEY)
3. Add additional providers if desired (see config.yaml.example)
4. Restart Sekha services

Rollback:
---------
To rollback to v1.x configuration:
  cp $BACKUP_FILE config.yaml
  $([ -f "$ENV_BACKUP" ] && echo "cp $ENV_BACKUP .env" || echo "")

Documentation:
--------------
See config.yaml.example for multi-provider setup examples
See sekha-config-schema.json for full configuration reference
EOF

echo "================================================"
echo -e "${GREEN}✓ Migration Complete!${NC}"
echo "================================================"
echo ""
echo "Summary saved to: $MIGRATION_SUMMARY"
echo ""
echo "Next steps:"
echo "  1. Review config.yaml"
echo "  2. Set SEKHA_API_KEY in .env (minimum 32 characters)"
echo "  3. Restart Sekha services: docker-compose up -d"
echo ""
echo "To rollback: cp $BACKUP_FILE config.yaml"
echo ""
cat "$MIGRATION_SUMMARY"
