#!/bin/bash
# Migrate from v1.x config to v2.0
# This script converts old environment variables and config files to the new multi-provider format

set -e

COLOR_RESET="\033[0m"
COLOR_BLUE="\033[34m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"

echo -e "${COLOR_BLUE}🔄 Migrating Sekha Configuration to v2.0...${COLOR_RESET}"
echo ""

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo -e "${COLOR_RED}❌ Error: Python 3 is required but not installed${COLOR_RESET}"
    exit 1
fi

# Backup old config if it exists
if [ -f "config.toml" ]; then
    cp config.toml config.toml.v1.backup
    echo -e "${COLOR_GREEN}✅ Backed up old config to config.toml.v1.backup${COLOR_RESET}"
fi

if [ -f "config.yaml" ]; then
    cp config.yaml config.yaml.v1.backup
    echo -e "${COLOR_GREEN}✅ Backed up old config to config.yaml.v1.backup${COLOR_RESET}"
fi

# Generate new config from environment or old config
python3 << 'EOF'
import os
import sys
import json
import yaml

# Try to load old config formats
old_config = {}

# Check for .env file
if os.path.exists(".env"):
    print("📄 Reading .env file...")
    with open(".env", "r") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, value = line.split("=", 1)
                old_config[key.lower()] = value.strip('"').strip("'")

# Check environment variables (override .env)
for key in ["OLLAMA_URL", "SEKHA__OLLAMA_URL", "EMBEDDING_MODEL", "SUMMARIZATION_MODEL"]:
    if key in os.environ:
        old_config[key.lower()] = os.environ[key]

# Try to load old TOML config
try:
    import tomli
    if os.path.exists("config.toml"):
        print("📄 Reading config.toml...")
        with open("config.toml", "rb") as f:
            toml_config = tomli.load(f)
            old_config.update(toml_config)
except ImportError:
    pass  # TOML not available, use env vars only

# Extract relevant values with fallbacks
ollama_url = old_config.get("ollama_url") or old_config.get("sekha__ollama_url") or "http://localhost:11434"
embedding_model = old_config.get("embedding_model") or "nomic-embed-text"
summarization_model = old_config.get("summarization_model") or "llama3.1:8b"

# Determine embedding dimension based on model
embedding_dimension = 768  # Default for nomic-embed-text
if "3-large" in embedding_model:
    embedding_dimension = 3072
elif "3-small" in embedding_model:
    embedding_dimension = 1536

# Generate new v2.0 config
new_config = {
    "config_version": "2.0",
    "llm_providers": [
        {
            "id": "ollama_local",
            "type": "ollama",
            "base_url": ollama_url,
            "api_key": None,
            "priority": 1,
            "models": [
                {
                    "model_id": embedding_model,
                    "task": "embedding",
                    "context_window": 512,
                    "dimension": embedding_dimension
                },
                {
                    "model_id": summarization_model,
                    "task": "chat_small",
                    "context_window": 8192
                },
                {
                    "model_id": summarization_model,
                    "task": "chat_smart",
                    "context_window": 8192
                }
            ]
        }
    ],
    "default_models": {
        "embedding": embedding_model,
        "chat_fast": summarization_model,
        "chat_smart": summarization_model
    },
    "routing": {
        "auto_fallback": True,
        "require_vision_for_images": True,
        "max_cost_per_request": None,
        "circuit_breaker": {
            "failure_threshold": 3,
            "timeout_secs": 60,
            "success_threshold": 2
        }
    }
}

# Write new config.yaml
with open("config.yaml", "w") as f:
    yaml.dump(new_config, f, default_flow_style=False, sort_keys=False)

print(f"\n✅ Generated new config.yaml")
print(f"📋 Migrated settings:")
print(f"   - Ollama URL: {ollama_url}")
print(f"   - Embedding Model: {embedding_model} ({embedding_dimension} dimensions)")
print(f"   - Chat Model: {summarization_model}")
print(f"   - Providers: {len(new_config['llm_providers'])}")

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${COLOR_GREEN}✅ Migration complete!${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_YELLOW}⚠️  Next steps:${COLOR_RESET}"
    echo "   1. Review config.yaml and adjust as needed"
    echo "   2. Add additional providers (OpenAI, Anthropic, etc.)"
    echo "   3. Update environment variables for your deployment"
    echo "   4. Restart Sekha services"
    echo ""
    echo -e "${COLOR_BLUE}📖 Documentation:${COLOR_RESET} https://docs.sekha.dev/configuration/v2-migration"
    echo ""
else
    echo -e "${COLOR_RED}❌ Migration failed${COLOR_RESET}"
    exit 1
fi
