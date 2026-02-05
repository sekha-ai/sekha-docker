# End-to-End Testing Guide for Sekha v2.0

This guide covers testing the complete Sekha stack with v2.0 multi-provider support.

## Prerequisites

### Required Services
- ✅ Docker & Docker Compose
- ✅ Ollama (running locally or in Docker)
- ✅ PostgreSQL
- ✅ ChromaDB
- ✅ Redis

### Optional for Full Testing
- OpenAI API key (for cloud provider testing)
- Anthropic API key (for Claude testing)

## Test Scenarios

### Scenario 1: Local-Only (Ollama)

**Objective:** Test complete functionality using only free local models.

#### 1. Configure for Local Only
```yaml
# config.yaml
config_version: "2.0"

llm_providers:
  - id: "ollama_local"
    type: "ollama"
    base_url: "http://ollama:11434"
    priority: 1
    models:
      - model_id: "nomic-embed-text"
        task: "embedding"
        context_window: 512
        dimension: 768
      - model_id: "llama3.1:8b"
        task: "chat_small"
        context_window: 8192
      - model_id: "llama3.1:8b"
        task: "chat_smart"
        context_window: 8192

default_models:
  embedding: "nomic-embed-text"
  chat_fast: "llama3.1:8b"
  chat_smart: "llama3.1:8b"
```

#### 2. Start Services
```bash
cd sekha-docker
docker-compose up -d
```

#### 3. Pull Models
```bash
# Pull required Ollama models
docker exec ollama ollama pull nomic-embed-text
docker exec ollama ollama pull llama3.1:8b
```

#### 4. Test Bridge Routing
```bash
# List available models
curl http://localhost:5001/api/v1/models | jq

# Expected: 3 models from ollama_local

# Test routing for embedding
curl -X POST http://localhost:5001/api/v1/route \
  -H "Content-Type: application/json" \
  -d '{"task": "embedding"}' | jq

# Expected:
# {
#   "provider_id": "ollama_local",
#   "model_id": "nomic-embed-text",
#   "estimated_cost": 0.0,
#   "reason": "Selected by priority (1)",
#   "provider_type": "ollama"
# }
```

#### 5. Test Controller Integration
```bash
# Create conversation (triggers embedding)
curl -X POST http://localhost:8080/api/v1/conversations \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "E2E Test - Local Only",
    "folder_path": "/tests"
  }' | jq

# Add message (triggers embedding + storage)
curl -X POST http://localhost:8080/api/v1/conversations/{conv_id}/messages \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test message for local-only routing",
    "speaker": "user"
  }' | jq

# Search (triggers embedding for query)
curl -X POST http://localhost:8080/api/v1/search \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "local routing",
    "limit": 5
  }' | jq
```

#### 6. Verify Logs
```bash
# Check bridge logs for routing decisions
docker logs bridge | grep "Routed to"

# Expected:
# INFO Routed to provider=ollama_local, model=nomic-embed-text, cost=$0.0000

# Check controller logs
docker logs controller | grep "Embedding generated"

# Expected:
# INFO Embedding generated via ollama_local/nomic-embed-text - $0.0000
```

### Scenario 2: Hybrid (Ollama + OpenAI)

**Objective:** Test automatic routing between local and cloud providers based on task and cost.

#### 1. Configure Hybrid Setup
```yaml
# config.yaml
config_version: "2.0"

llm_providers:
  - id: "ollama_local"
    type: "ollama"
    base_url: "http://ollama:11434"
    priority: 1  # Try local first
    models:
      - model_id: "nomic-embed-text"
        task: "embedding"
        context_window: 512
        dimension: 768
      - model_id: "llama3.1:8b"
        task: "chat_small"
        context_window: 8192
  
  - id: "openai_cloud"
    type: "openai"
    base_url: "https://api.openai.com/v1"
    api_key: "${OPENAI_API_KEY}"
    priority: 2  # Fallback to cloud
    models:
      - model_id: "gpt-4o"
        task: "chat_smart"
        context_window: 128000
        supports_vision: true
      - model_id: "gpt-4o-mini"
        task: "chat_small"
        context_window: 128000

default_models:
  embedding: "nomic-embed-text"
  chat_fast: "llama3.1:8b"
  chat_smart: "gpt-4o"
  chat_vision: "gpt-4o"

routing:
  auto_fallback: true
  max_cost_per_request: 0.10
```

#### 2. Set Environment Variables
```bash
export OPENAI_API_KEY="sk-..."
```

#### 3. Restart Services
```bash
docker-compose down
docker-compose up -d
```

#### 4. Test Cost-Based Routing
```bash
# Request with low budget (should use local)
curl -X POST http://localhost:5001/api/v1/route \
  -H "Content-Type: application/json" \
  -d '{
    "task": "chat_small",
    "max_cost": 0.0001
  }' | jq

# Expected: ollama_local/llama3.1:8b

# Request with higher budget (should use cloud if preferred)
curl -X POST http://localhost:5001/api/v1/route \
  -H "Content-Type: application/json" \
  -d '{
    "task": "chat_smart",
    "max_cost": 0.10
  }' | jq

# Expected: openai_cloud/gpt-4o
```

#### 5. Test Provider Fallback
```bash
# Stop Ollama to test fallback
docker stop ollama

# Request embedding (should fallback or fail gracefully)
curl -X POST http://localhost:5001/api/v1/route \
  -H "Content-Type: application/json" \
  -d '{"task": "embedding"}' | jq

# Check provider health
curl http://localhost:5001/api/v1/health/providers | jq

# Expected: ollama_local shows circuit breaker open

# Restart Ollama
docker start ollama
```

### Scenario 3: MCP Tool Testing

**Objective:** Test MCP tools for LLM provider status and routing.

#### 1. Test LLM Status Tool
```bash
curl -X POST http://localhost:8080/mcp/tools/llm_status \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' | jq

# Expected:
# {
#   "content": [
#     {
#       "type": "text",
#       "text": "LLM Providers: 2 total, 2 healthy"
#     }
#   ],
#   "result": {
#     "providers": [...],
#     "total_providers": 2,
#     "healthy_providers": 2
#   }
# }
```

#### 2. Test Routing Tool
```bash
curl -X POST http://localhost:8080/mcp/tools/llm_routing \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "task": "chat_smart",
    "max_cost": 0.05
  }' | jq

# Expected:
# {
#   "content": [
#     {
#       "type": "text",
#       "text": "Routing: openai_cloud/gpt-4o ($0.0125)"
#     }
#   ],
#   "result": {
#     "provider_id": "openai_cloud",
#     "model_id": "gpt-4o",
#     "estimated_cost": 0.0125
#   }
# }
```

### Scenario 4: Load Testing

**Objective:** Test system behavior under load with multiple providers.

#### 1. Install Load Testing Tool
```bash
pip install locust
```

#### 2. Create Load Test Script
```python
# locustfile.py
from locust import HttpUser, task, between
import random

class SekhaUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        self.api_key = "your_key_here"
    
    @task(3)
    def create_and_search(self):
        # Create conversation
        conv = self.client.post(
            "/api/v1/conversations",
            headers={"X-API-Key": self.api_key},
            json={
                "title": f"Load Test {random.randint(1, 10000)}",
                "folder_path": "/load-tests"
            }
        ).json()
        
        conv_id = conv["id"]
        
        # Add message
        self.client.post(
            f"/api/v1/conversations/{conv_id}/messages",
            headers={"X-API-Key": self.api_key},
            json={
                "content": f"Load test message {random.randint(1, 10000)}",
                "speaker": "user"
            }
        )
        
        # Search
        self.client.post(
            "/api/v1/search",
            headers={"X-API-Key": self.api_key},
            json={
                "query": "load test",
                "limit": 5
            }
        )
    
    @task(1)
    def check_provider_status(self):
        self.client.post(
            "/mcp/tools/llm_status",
            headers={"X-API-Key": self.api_key},
            json={}
        )
```

#### 3. Run Load Test
```bash
locust -f locustfile.py --host=http://localhost:8080 \
  --users 10 --spawn-rate 2 --run-time 5m
```

#### 4. Monitor
```bash
# Watch provider health during load test
watch -n 1 'curl -s http://localhost:5001/api/v1/health/providers | jq .healthy_providers'

# Watch circuit breaker states
docker logs bridge -f | grep "circuit breaker"
```

## Test Results Checklist

### ✅ Configuration
- [ ] Config validates successfully
- [ ] Migration from v1.x works
- [ ] Environment variables override config
- [ ] Multiple providers configured

### ✅ Routing
- [ ] Models listed correctly
- [ ] Routing selects optimal provider
- [ ] Cost limits respected
- [ ] Preferred models honored
- [ ] Task-based routing works

### ✅ Providers
- [ ] Ollama provider healthy
- [ ] OpenAI provider healthy (if configured)
- [ ] Provider health endpoint accurate
- [ ] Circuit breakers open on failures
- [ ] Circuit breakers reset after recovery

### ✅ Controller Integration
- [ ] Embeddings use routing
- [ ] Summaries use routing
- [ ] Searches work end-to-end
- [ ] Cost tracking visible in logs
- [ ] Provider info in responses

### ✅ MCP Tools
- [ ] llm_status returns accurate info
- [ ] llm_routing returns recommendations
- [ ] Tools work with API key auth

### ✅ Performance
- [ ] Response times acceptable under load
- [ ] No memory leaks during extended use
- [ ] Circuit breakers prevent cascading failures
- [ ] Provider fallback works automatically

## Troubleshooting

### Bridge Can't Connect to Providers
```bash
# Check provider health
curl http://localhost:5001/api/v1/health/providers

# Check bridge logs
docker logs bridge -f

# Test Ollama directly
curl http://localhost:11434/api/tags

# Test OpenAI API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Circuit Breakers Stuck Open
```bash
# Check circuit breaker config
curl http://localhost:5001/api/v1/health/providers | jq '.providers[].circuit_breaker'

# Restart bridge to reset
docker restart bridge
```

### High Costs
```bash
# Check routing decisions in logs
docker logs bridge | grep "estimated_cost"

# Verify max_cost_per_request set in config
grep max_cost config.yaml

# Test with explicit cost limit
curl -X POST http://localhost:5001/api/v1/route \
  -d '{"task": "chat_smart", "max_cost": 0.01}'
```

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove test data
docker volume rm sekha-docker_postgres_data
docker volume rm sekha-docker_chroma_data

# Remove test conversations
curl -X DELETE http://localhost:8080/api/v1/conversations \
  -H "X-API-Key: $SEKHA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"folder_path": "/tests"}'
```

## Success Criteria

All tests pass if:
1. ✅ Local-only scenario works with zero cost
2. ✅ Hybrid scenario correctly routes based on cost and task
3. ✅ Provider fallback works when a provider fails
4. ✅ MCP tools return accurate information
5. ✅ System handles load without errors
6. ✅ Circuit breakers prevent cascading failures
7. ✅ Cost estimates are reasonable
8. ✅ All provider types (Ollama, OpenAI, Anthropic) work

## Next Steps

After successful E2E testing:
1. Deploy to staging environment
2. Run extended soak tests (24+ hours)
3. Monitor costs in production
4. Set up alerting for circuit breaker opens
5. Document production configuration examples
