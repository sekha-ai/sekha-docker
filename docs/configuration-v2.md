# SEKHA v2.0 Configuration Guide

**Comprehensive Provider Registry Configuration**

This guide covers all configuration options for Sekha v2.0's multi-provider architecture.

---

## Configuration File Format

Sekha v2.0 uses **YAML** for primary configuration with **environment variable** overrides.

**Load Priority:**
1. `config.yaml` (if exists)
2. Environment variables (`SEKHA__*`)
3. Default values

---

## Minimal Configuration (Ollama Only)

**Use Case:** Local development, privacy-first deployment

```yaml
# config.yaml
llm_providers:
  - id: ollama_local
    provider_type: ollama
    base_url: http://localhost:11434
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
  enable_fallback: false
```

**Environment Variables:**
```bash
# .env
CONTROLLER_URL=http://localhost:8080
LLM_BRIDGE_URL=http://localhost:5001
PROXY_PORT=8081
```

---

## Hybrid Configuration (Ollama + OpenAI)

**Use Case:** Local for embeddings, cloud for advanced reasoning

```yaml
llm_providers:
  # Cloud provider (higher priority for smart tasks)
  - id: openai_cloud
    provider_type: openai
    base_url: https://api.openai.com/v1
    api_key: ${OPENAI_API_KEY}
    priority: 1
    models:
      - model_id: gpt-4o
        task: chat_smart
        context_window: 128000
        supports_vision: true
        cost_per_1k_input: 0.0025
        cost_per_1k_output: 0.01
      
      - model_id: gpt-4o-mini
        task: chat_small
        context_window: 128000
        cost_per_1k_input: 0.00015
        cost_per_1k_output: 0.0006

  # Local provider (fallback + embeddings)
  - id: ollama_local
    provider_type: ollama
    base_url: http://ollama:11434
    priority: 2
    models:
      - model_id: nomic-embed-text:latest
        task: embedding
        dimension: 768
      
      - model_id: llama3.1:70b
        task: chat_large
        context_window: 128000

default_models:
  embedding: nomic-embed-text:latest
  chat_small: gpt-4o-mini
  chat_large: llama3.1:70b
  chat_smart: gpt-4o

routing:
  enable_fallback: true
  cost_limit_per_request: 0.10
  prefer_free_providers: false
```

---

## Full Multi-Provider Configuration

**Use Case:** Production with redundancy, cost optimization

```yaml
llm_providers:
  # Primary: OpenRouter (aggregator)
  - id: openrouter_primary
    provider_type: litellm
    base_url: https://openrouter.ai/api/v1
    api_key: ${OPENROUTER_API_KEY}
    priority: 1
    models:
      - model_id: anthropic/claude-3.5-sonnet
        task: chat_smart
        context_window: 200000
        cost_per_1k_input: 0.003
        cost_per_1k_output: 0.015
      
      - model_id: google/gemini-2.0-flash-thinking-exp:free
        task: chat_small
        context_window: 32000
        cost_per_1k_input: 0.0
        cost_per_1k_output: 0.0

  # Secondary: Direct OpenAI
  - id: openai_direct
    provider_type: openai
    base_url: https://api.openai.com/v1
    api_key: ${OPENAI_API_KEY}
    priority: 2
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

  # Tertiary: Ollama (free fallback)
  - id: ollama_fallback
    provider_type: ollama
    base_url: http://ollama:11434
    priority: 3
    models:
      - model_id: nomic-embed-text:latest
        task: embedding
        dimension: 768
      
      - model_id: llama3.1:70b
        task: chat_large

default_models:
  embedding: text-embedding-3-large
  chat_small: google/gemini-2.0-flash-thinking-exp:free
  chat_large: llama3.1:70b
  chat_smart: anthropic/claude-3.5-sonnet

routing:
  enable_fallback: true
  cost_limit_per_request: 0.05
  prefer_free_providers: true
  circuit_breaker:
    failure_threshold: 3
    timeout_seconds: 60
    half_open_requests: 1
```

---

## Provider Types

### 1. Ollama

**Local LLM server**

```yaml
- id: ollama_local
  provider_type: ollama
  base_url: http://localhost:11434
  # No API key required
  models:
    - model_id: llama3.1:8b  # Must be pulled: `ollama pull llama3.1:8b`
```

### 2. OpenAI

**Official OpenAI API**

```yaml
- id: openai
  provider_type: openai
  base_url: https://api.openai.com/v1
  api_key: ${OPENAI_API_KEY}
  models:
    - model_id: gpt-4o
    - model_id: text-embedding-3-large
```

### 3. Anthropic

**Claude models**

```yaml
- id: anthropic
  provider_type: anthropic
  base_url: https://api.anthropic.com
  api_key: ${ANTHROPIC_API_KEY}
  models:
    - model_id: claude-3.5-sonnet
```

**Note:** Use via OpenRouter for easier integration:
```yaml
  provider_type: litellm
  base_url: https://openrouter.ai/api/v1
  models:
    - model_id: anthropic/claude-3.5-sonnet
```

### 4. LiteLLM (Unified Interface)

**Access 100+ providers through one API**

```yaml
- id: litellm_unified
  provider_type: litellm
  base_url: https://openrouter.ai/api/v1  # or your LiteLLM proxy
  api_key: ${LITELLM_API_KEY}
  models:
    - model_id: google/gemini-pro
    - model_id: mistralai/mixtral-8x7b
    - model_id: deepseek/deepseek-chat
```

### 5. OpenRouter

**LLM aggregator with unified pricing**

```yaml
- id: openrouter
  provider_type: litellm
  base_url: https://openrouter.ai/api/v1
  api_key: ${OPENROUTER_API_KEY}
  models:
    - model_id: anthropic/claude-3.5-sonnet
    - model_id: google/gemini-2.0-flash-thinking-exp:free
    - model_id: meta-llama/llama-3.1-70b-instruct
```

---

## Model Task Types

| Task | Usage | Typical Models | Routing Strategy |
|------|-------|----------------|------------------|
| `embedding` | Vector embeddings for semantic search | nomic-embed-text, text-embedding-3-large | Dimension-aware |
| `chat_small` | Fast responses, simple queries | gpt-4o-mini, llama3.1:8b | Cost-optimized |
| `chat_large` | Complex reasoning, long context | llama3.1:70b, gpt-4o | Balance quality/cost |
| `chat_smart` | Advanced tasks, vision, tool use | gpt-4o, claude-3.5-sonnet | Best available |

**Custom Tasks:**
```yaml
models:
  - model_id: codellama:13b
    task: code_generation
    custom_tags: [coding, python]
```

---

## Cost Management

### Budget Limits

**Per-Request Limit:**
```yaml
routing:
  cost_limit_per_request: 0.01  # Max $0.01 per request
```

**Per-Model Pricing:**
```yaml
models:
  - model_id: gpt-4o
    cost_per_1k_input: 0.0025   # $0.0025 per 1k input tokens
    cost_per_1k_output: 0.01    # $0.01 per 1k output tokens
```

**Prefer Free Providers:**
```yaml
routing:
  prefer_free_providers: true
  # Will route to Ollama or free models first
```

### Cost Estimation API

```bash
curl -X POST http://localhost:5001/api/v1/route \
  -d '{"task": "chat_smart", "max_cost": 0.01}'
```

**Response:**
```json
{
  "provider_id": "openai",
  "model_id": "gpt-4o-mini",
  "estimated_cost": 0.0021,
  "reason": "Within budget, best quality"
}
```

---

## Circuit Breaker Configuration

**Purpose:** Automatically skip failing providers

```yaml
routing:
  circuit_breaker:
    failure_threshold: 3      # Open after 3 failures
    timeout_seconds: 60       # Stay open for 60s
    half_open_requests: 1     # Test with 1 request after timeout
```

**States:**
1. **Closed** (normal): All requests go through
2. **Open** (failing): Skip provider, use fallback
3. **Half-Open** (testing): Try 1 request to see if recovered

**Health Check:**
```bash
curl http://localhost:5001/api/v1/health/providers
```

**Response:**
```json
{
  "providers": [
    {"id": "openai", "status": "healthy", "circuit_breaker": "closed"},
    {"id": "ollama", "status": "unhealthy", "circuit_breaker": "open", "failures": 5}
  ]
}
```

---

## Environment Variable Overrides

**Override specific values without editing YAML:**

```bash
# Override provider API key
SEKHA__LLM_PROVIDERS__0__API_KEY=sk-new-key

# Override cost limit
SEKHA__ROUTING__COST_LIMIT_PER_REQUEST=0.05

# JSON override (entire provider array)
SEKHA__LLM_PROVIDERS='[{"id":"ollama","provider_type":"ollama","base_url":"http://ollama:11434","priority":1}]'
```

---

## Vision Model Configuration

**Enable image input support:**

```yaml
models:
  - model_id: gpt-4o
    task: chat_smart
    supports_vision: true
    max_image_size: 20000000  # 20MB
  
  - model_id: moonshot-v1-128k  # Kimi 2.5
    task: chat_smart
    supports_vision: true
    provider_specific:
      base_url: https://api.moonshot.cn/v1
```

**Usage via Proxy:**
```bash
curl -X POST http://localhost:8081/v1/chat/completions \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "What is in this image?"},
          {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
        ]
      }
    ]
  }'
```

See [Vision Support Guide](vision-support.md) for details.

---

## Advanced Routing Strategies

### 1. Latency-Based Routing

```yaml
routing:
  strategy: latency_optimized
  latency_threshold_ms: 500  # Prefer providers under 500ms
```

### 2. Region-Based Routing

```yaml
llm_providers:
  - id: openai_us
    provider_type: openai
    base_url: https://api.openai.com/v1
    region: us-east
    priority: 1
  
  - id: openai_eu
    provider_type: openai
    base_url: https://api.openai.com/v1
    region: eu-west
    priority: 2

routing:
  prefer_region: ${USER_REGION}  # From request metadata
```

### 3. Load Balancing

```yaml
routing:
  strategy: round_robin  # or least_connections
  providers:
    - ollama_instance_1
    - ollama_instance_2
    - ollama_instance_3
```

---

## Validation & Testing

### Validate Configuration

```bash
# Built-in validator
curl -X POST http://localhost:8080/api/v1/config/validate \
  --data-binary @config.yaml
```

### Test Provider

```bash
# Test specific provider
curl -X POST http://localhost:5001/api/v1/test-provider \
  -d '{"provider_id": "openai", "test_task": "embedding"}'
```

### Dry-Run Routing

```bash
# See what would be routed without executing
curl -X POST http://localhost:5001/api/v1/route \
  -d '{"task": "chat_smart", "dry_run": true}'
```

---

## Troubleshooting

### Issue: Provider not available

**Check:**
```bash
curl http://localhost:5001/api/v1/models | jq '.[] | select(.provider_id=="openai")'
```

**Fix:** Verify API key and base URL

### Issue: Wrong model selected

**Check routing logic:**
```bash
curl -X POST http://localhost:5001/api/v1/route \
  -d '{"task": "embedding", "preferred_model": "nomic-embed-text:latest"}'
```

**Adjust priorities** in `config.yaml`

### Issue: Circuit breaker stuck open

**Reset:**
```bash
docker-compose restart bridge
```

---

## Examples Repository

More configurations at:
https://github.com/sekha-ai/sekha-docker/tree/main/examples/configs

- `minimal-ollama.yaml`
- `hybrid-ollama-openai.yaml`
- `production-multi-provider.yaml`
- `cost-optimized.yaml`
- `vision-enabled.yaml`

---

**Next:** [Vision Support Guide](vision-support.md) | [Migration Guide](migration-guide-v2.md)
