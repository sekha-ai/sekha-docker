# SEKHA v2.0 Migration Guide

**From v1.x (Ollama-Only) → v2.0 (Any Model, Any Provider)**

This guide helps you migrate your existing Sekha deployment from v1.x to v2.0.

## Overview

Sekha v2.0 introduces a **provider-agnostic architecture** that replaces hardcoded Ollama integration with a flexible multi-provider system powered by LiteLLM.

**Key Changes:**
- ✅ Support for multiple LLM providers (Ollama, OpenAI, Anthropic, OpenRouter, etc.)
- ✅ Automatic provider routing and fallback
- ✅ Cost estimation and budget limits
- ✅ Vision model support (GPT-4o, Kimi 2.5, etc.)
- ✅ Multi-dimension embedding collections
- ⚠️ Configuration format changed (YAML-based provider registry)

---

## Breaking Changes

### 1. Configuration Structure

**v1.x (Environment Variables):**
```bash
OLLAMA_URL=http://localhost:11434
EMBEDDING_MODEL=nomic-embed-text:latest
SUMMARIZATION_MODEL=llama3.1:8b
```

**v2.0 (YAML Provider Registry):**
```yaml
llm_providers:
  - id: ollama_local
    provider_type: ollama
    base_url: http://localhost:11434
    priority: 1
    models:
      - model_id: nomic-embed-text:latest
        task: embedding
        dimension: 768
      - model_id: llama3.1:8b
        task: chat_small
```

### 2. Bridge API Changes

**v1.x Endpoints:**
- `POST /embed` - Direct embedding
- `POST /summarize` - Direct summarization

**v2.0 Additional Endpoints:**
- `POST /api/v1/route` - Get optimal provider/model
- `GET /api/v1/models` - List all available models
- `GET /api/v1/health/providers` - Provider health status

*Note: v1.x endpoints still work but use new routing internally*

### 3. Embedding Collections

**v1.x:** Single `conversations` collection (768 dimensions assumed)

**v2.0:** Dimension-aware collections:
- `conversations_768` - nomic-embed-text
- `conversations_1536` - text-embedding-ada-002
- `conversations_3072` - text-embedding-3-large

*Search automatically queries all relevant collections*

### 4. Docker Compose Files

**v1.x:** `docker-compose.yml`

**v2.0:** Use dimension-specific compose files:
- `docker-compose.v2.yml` - Production v2.0 stack
- Legacy files remain for backward compatibility

---

## Migration Steps

### Step 1: Backup Current Configuration

```bash
# Backup environment variables
cp .env .env.v1.backup

# Backup database (if using SQLite)
cp data/sekha.db data/sekha.db.v1.backup

# Backup ChromaDB
cp -r data/chroma data/chroma.v1.backup
```

### Step 2: Run Migration Script

The migration script converts v1.x env vars to v2.0 config format:

```bash
cd sekha-docker
./scripts/migrate-config-v2.sh
```

**What it does:**
- Reads `OLLAMA_URL`, `EMBEDDING_MODEL`, `SUMMARIZATION_MODEL` from `.env`
- Generates `config.yaml` with provider registry
- Creates `.env.v1.backup` backup
- Validates new configuration

**Output:**
```bash
✅ Migration complete!
   - Old config backed up to .env.v1.backup
   - New config written to config.yaml
   - Providers configured: 1 (Ollama)
   - Models configured: 2
```

### Step 3: Review Generated Configuration

Open `config.yaml` and verify:

```yaml
llm_providers:
  - id: ollama_migrated
    provider_type: ollama
    base_url: http://localhost:11434  # From OLLAMA_URL
    priority: 1
    models:
      - model_id: nomic-embed-text:latest
        task: embedding
        context_window: 8192
        dimension: 768
      - model_id: llama3.1:8b
        task: chat_small
        context_window: 128000

default_models:
  embedding: nomic-embed-text:latest
  chat_small: llama3.1:8b

routing:
  enable_fallback: true
  cost_limit_per_request: 0.10
```

### Step 4: Update Docker Compose

Switch to v2.0 compose file:

```bash
# Stop v1.x services
docker-compose down

# Start v2.0 services
docker-compose -f docker-compose.v2.yml up -d
```

**Or update your existing docker-compose.yml:**

```yaml
services:
  controller:
    # ... existing config ...
    volumes:
      - ./config.yaml:/app/config.yaml:ro  # Mount v2.0 config
    environment:
      - SEKHA__CONFIG_FILE=/app/config.yaml  # Use YAML config
```

### Step 5: Verify Migration

Run health checks:

```bash
# Check bridge health
curl http://localhost:5001/health

# List available models
curl http://localhost:5001/api/v1/models

# Test routing
curl -X POST http://localhost:5001/api/v1/route \
  -H "Content-Type: application/json" \
  -d '{"task": "embedding", "preferred_model": null}'
```

**Expected Response:**
```json
{
  "provider_id": "ollama_migrated",
  "model_id": "nomic-embed-text:latest",
  "estimated_cost": 0.0,
  "reason": "Preferred model available",
  "provider_type": "ollama"
}
```

### Step 6: Test End-to-End

```bash
# Store a test conversation
curl -X POST http://localhost:8080/api/v1/conversations \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Test migration"}],
    "metadata": {"test": true}
  }'

# Verify embedding was stored in correct collection
# Check controller logs for: "Successfully stored embedding for message ... in collection conversations_768"
```

---

## Rollback Procedure

If you encounter issues, rollback to v1.x:

### Quick Rollback

```bash
# Stop v2.0 services
docker-compose -f docker-compose.v2.yml down

# Restore v1.x configuration
cp .env.v1.backup .env

# Restore v1.x database (if needed)
cp data/sekha.db.v1.backup data/sekha.db

# Start v1.x services
docker-compose up -d
```

### Full Rollback (including ChromaDB)

```bash
# Restore ChromaDB
rm -rf data/chroma
cp -r data/chroma.v1.backup data/chroma

# Rebuild containers
docker-compose up -d --build
```

---

## Adding Additional Providers (Post-Migration)

Once migration is complete, add more providers:

### Example: Adding OpenAI

Edit `config.yaml`:

```yaml
llm_providers:
  # Existing Ollama provider
  - id: ollama_migrated
    provider_type: ollama
    base_url: http://localhost:11434
    priority: 2  # Lower priority (try second)
    models:
      - model_id: nomic-embed-text:latest
        task: embedding
        dimension: 768

  # NEW: OpenAI provider
  - id: openai_cloud
    provider_type: openai
    base_url: https://api.openai.com/v1
    api_key: ${OPENAI_API_KEY}  # From environment
    priority: 1  # Higher priority (try first)
    models:
      - model_id: text-embedding-3-large
        task: embedding
        dimension: 3072
        cost_per_1k_tokens: 0.00013
      - model_id: gpt-4o
        task: chat_smart
        supports_vision: true
        cost_per_1k_input: 0.0025
        cost_per_1k_output: 0.01

default_models:
  embedding: text-embedding-3-large  # Now default
  chat_smart: gpt-4o
```

Restart services:

```bash
docker-compose -f docker-compose.v2.yml restart
```

---

## FAQ

### Q: Do I need to re-embed all my existing conversations?

**A:** No. Existing embeddings remain in the original `conversations` collection. v2.0 creates **new** dimension-specific collections for new embeddings. Search queries all collections automatically.

### Q: Can I run v1.x and v2.0 side-by-side?

**A:** Not on the same ports. Use different port bindings:

```yaml
# v1.x on 8080, 5001, 8081
# v2.0 on 8090, 5011, 8091
services:
  controller:
    ports:
      - "8090:8080"
```

### Q: What happens if bridge routing fails?

**A:** v2.0 includes automatic fallback:
1. Try primary provider (priority 1)
2. If fails, try secondary provider (priority 2)
3. If all fail, return error with suggestions

### Q: How do I verify dimension detection?

**A:** Check controller logs:

```bash
docker-compose -f docker-compose.v2.yml logs controller | grep dimension
```

**Expected output:**
```
controller_1 | Detected dimension 768 for model nomic-embed-text:latest (cached)
controller_1 | Embedding routed to collection conversations_768 (dimension=768, model=nomic-embed-text:latest)
```

### Q: Can I disable v2.0 routing and use legacy mode?

**A:** Yes. Remove `llm_providers` from `config.yaml`. The system will fall back to v1.x behavior using env vars.

### Q: Does this affect MCP server?

**A:** Minimal. MCP server config needs version update only:

```python
# sekha-mcp/src/sekha_mcp/config.py
server_version = "2.0.0"  # Updated
controller_url = "http://localhost:8080"  # Same
```

---

## Troubleshooting

### Issue: "No providers configured" error

**Cause:** `config.yaml` not loaded or invalid

**Solution:**
```bash
# Verify file exists and is valid YAML
cat config.yaml | python -m yaml

# Check controller logs
docker-compose -f docker-compose.v2.yml logs controller | grep "provider"
```

### Issue: Embeddings not routed to correct collection

**Cause:** Bridge client not initialized

**Solution:** Check controller initialization:
```bash
docker-compose -f docker-compose.v2.yml logs controller | grep "EmbeddingService"
```

**Expected:**
```
EmbeddingService initialized with v2.0 bridge routing
```

### Issue: "Circuit breaker open" errors

**Cause:** Provider failed 3+ times

**Solution:**
```bash
# Check provider health
curl http://localhost:5001/api/v1/health/providers

# Reset circuit breaker (restart bridge)
docker-compose -f docker-compose.v2.yml restart bridge
```

### Issue: High costs after migration

**Cause:** Accidentally routing to expensive providers

**Solution:** Add cost limits in `config.yaml`:
```yaml
routing:
  cost_limit_per_request: 0.01  # Max $0.01 per request
  prefer_free_providers: true
```

---

## Support

If you encounter migration issues:

1. **Check logs:** `docker-compose -f docker-compose.v2.yml logs`
2. **GitHub Issues:** https://github.com/sekha-ai/sekha-docker/issues
3. **Discord:** https://discord.gg/sekha-ai

---

## Next Steps

After successful migration:

1. **Review** [Configuration Guide](configuration-v2.md) for advanced settings
2. **Explore** [Vision Support](vision-support.md) for image-capable models
3. **Test** provider fallback by temporarily stopping Ollama
4. **Monitor** costs using bridge's cost estimation endpoints

---

**Migration complete! 🎉**

Your Sekha deployment is now ready for multi-provider LLM routing.
