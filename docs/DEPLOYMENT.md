# Sekha v2.0 Deployment Guide

Complete guide for deploying Sekha with multi-provider LLM support.

## Quick Start

### 1. Prerequisites

```bash
# System requirements
- Docker Engine 24.0+
- Docker Compose 2.20+
- 8GB+ RAM (16GB+ recommended)
- 50GB+ disk space

# Optional for GPU support
- NVIDIA GPU
- NVIDIA Container Toolkit
```

### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/sekha-ai/sekha-docker.git
cd sekha-docker

# Checkout v2.0 branch
git checkout feature/v2.0-provider-registry

# Copy environment template
cp .env.v2.example .env

# Edit configuration
nano .env
```

### 3. Start Services

```bash
# Start all services
docker-compose -f docker-compose.v2.yml up -d

# Check status
docker-compose -f docker-compose.v2.yml ps

# View logs
docker-compose -f docker-compose.v2.yml logs -f
```

### 4. Pull Models (First Time)

```bash
# Pull required Ollama models
docker exec sekha-ollama ollama pull nomic-embed-text
docker exec sekha-ollama ollama pull llama3.1:8b

# Verify models
docker exec sekha-ollama ollama list
```

### 5. Verify Installation

```bash
# Check bridge health
curl http://localhost:5001/health

# List available models
curl http://localhost:5001/api/v1/models | jq

# Check controller health
curl http://localhost:8080/health

# Test provider status via MCP
curl -X POST http://localhost:8080/mcp/tools/llm_status \
  -H "X-API-Key: dev_key_123" \
  -H "Content-Type: application/json" \
  -d '{}' | jq
```

## Deployment Scenarios

### Scenario A: Local-Only (Free)

**Use Case:** Development, testing, cost-sensitive deployments

**Configuration:**
```yaml
# In docker-compose.v2.yml, providers section already configured for local-only
# Just ensure cloud API keys are NOT set in .env
```

**Pros:**
- ✅ Zero cost
- ✅ Complete data privacy
- ✅ No external dependencies
- ✅ Predictable performance

**Cons:**
- ❌ Requires local GPU for good performance
- ❌ Limited to available local models
- ❌ No access to latest cloud models

### Scenario B: Hybrid (Recommended)

**Use Case:** Production deployments with cost optimization

**Configuration:**
```bash
# 1. Add OpenAI API key to .env
OPENAI_API_KEY=sk-your-key-here

# 2. Update providers in docker-compose.v2.yml
SEKHA__LLM_PROVIDERS: |
  [
    {
      "id": "ollama_local",
      "type": "ollama",
      "base_url": "http://ollama:11434",
      "priority": 1,
      "models": [
        {"model_id": "nomic-embed-text", "task": "embedding", "context_window": 512, "dimension": 768},
        {"model_id": "llama3.1:8b", "task": "chat_small", "context_window": 8192}
      ]
    },
    {
      "id": "openai_cloud",
      "type": "openai",
      "base_url": "https://api.openai.com/v1",
      "api_key": "${OPENAI_API_KEY}",
      "priority": 2,
      "models": [
        {"model_id": "gpt-4o", "task": "chat_smart", "context_window": 128000, "supports_vision": true},
        {"model_id": "gpt-4o-mini", "task": "chat_small", "context_window": 128000}
      ]
    }
  ]

# 3. Set default models
SEKHA__DEFAULT_MODELS: |
  {
    "embedding": "nomic-embed-text",
    "chat_fast": "llama3.1:8b",
    "chat_smart": "gpt-4o",
    "chat_vision": "gpt-4o"
  }

# 4. Set cost limit
ROUTING_MAX_COST=0.10
```

**Pros:**
- ✅ Cost optimization (use local when possible)
- ✅ Access to advanced cloud models
- ✅ Automatic fallback
- ✅ Flexible based on task

**Cons:**
- ⚠️ Requires cost monitoring
- ⚠️ Cloud provider dependencies

### Scenario C: Cloud-Only

**Use Case:** Cloud deployments without GPU

**Configuration:**
```yaml
# 1. Remove ollama service from docker-compose
# 2. Configure only cloud providers
SEKHA__LLM_PROVIDERS: |
  [
    {
      "id": "openai",
      "type": "openai",
      "base_url": "https://api.openai.com/v1",
      "api_key": "${OPENAI_API_KEY}",
      "priority": 1,
      "models": [
        {"model_id": "text-embedding-3-small", "task": "embedding", "context_window": 8191, "dimension": 1536},
        {"model_id": "gpt-4o-mini", "task": "chat_small", "context_window": 128000},
        {"model_id": "gpt-4o", "task": "chat_smart", "context_window": 128000, "supports_vision": true}
      ]
    }
  ]
```

**Pros:**
- ✅ No GPU required
- ✅ Latest models available
- ✅ Scalable performance

**Cons:**
- ❌ Ongoing costs
- ❌ External dependencies
- ❌ Data sent to third parties

## Production Deployment

### 1. Security Hardening

```bash
# Generate strong API keys
SEKHA_API_KEYS=$(openssl rand -hex 32),$(openssl rand -hex 32)

# Generate secure database password
POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Update .env with generated secrets
sed -i "s/SEKHA_API_KEYS=.*/SEKHA_API_KEYS=$SEKHA_API_KEYS/" .env
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" .env
```

### 2. HTTPS/TLS Setup

```yaml
# Add nginx reverse proxy to docker-compose.v2.yml
nginx:
  image: nginx:alpine
  ports:
    - "443:443"
    - "80:80"
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./nginx/ssl:/etc/nginx/ssl:ro
  depends_on:
    - controller
  networks:
    - sekha-network
```

```nginx
# nginx/nginx.conf
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    location / {
        proxy_pass http://controller:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Monitoring

```yaml
# Add Prometheus for metrics
prometheus:
  image: prom/prometheus:latest
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  networks:
    - sekha-network

# Add Grafana for dashboards
grafana:
  image: grafana/grafana:latest
  ports:
    - "3001:3000"
  environment:
    GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
  volumes:
    - grafana_data:/var/lib/grafana
  networks:
    - sekha-network
```

### 4. Backup Strategy

```bash
#!/bin/bash
# backup.sh - Daily backup script

BACKUP_DIR="/backups/sekha"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup PostgreSQL
docker exec sekha-postgres pg_dump -U sekha sekha > \
  "$BACKUP_DIR/postgres_$DATE.sql"

# Backup ChromaDB
docker cp sekha-chroma:/chroma/chroma \
  "$BACKUP_DIR/chroma_$DATE"

# Backup Ollama models
docker cp sekha-ollama:/root/.ollama \
  "$BACKUP_DIR/ollama_$DATE"

# Compress
tar -czf "$BACKUP_DIR/sekha_$DATE.tar.gz" \
  "$BACKUP_DIR/postgres_$DATE.sql" \
  "$BACKUP_DIR/chroma_$DATE" \
  "$BACKUP_DIR/ollama_$DATE"

# Cleanup
rm -rf "$BACKUP_DIR/postgres_$DATE.sql" \
  "$BACKUP_DIR/chroma_$DATE" \
  "$BACKUP_DIR/ollama_$DATE"

# Keep last 30 days
find "$BACKUP_DIR" -name "sekha_*.tar.gz" -mtime +30 -delete
```

### 5. Resource Limits

```yaml
# Add resource limits to docker-compose.v2.yml
services:
  bridge:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
  
  controller:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

## Scaling

### Horizontal Scaling

```bash
# Scale controller instances
docker-compose -f docker-compose.v2.yml up -d --scale controller=3

# Add load balancer
# Update nginx to distribute load across controllers
```

### Vertical Scaling

```yaml
# Increase resources for high-load services
ollama:
  deploy:
    resources:
      limits:
        cpus: '8.0'
        memory: 16G
```

## Monitoring & Maintenance

### Health Checks

```bash
# Check all services
docker-compose -f docker-compose.v2.yml ps

# Provider health
curl http://localhost:5001/api/v1/health/providers | jq

# Circuit breaker states
curl http://localhost:5001/api/v1/health/providers | jq '.providers[].circuit_breaker'
```

### Log Management

```bash
# View recent logs
docker-compose -f docker-compose.v2.yml logs --tail=100 -f

# Filter by service
docker-compose -f docker-compose.v2.yml logs bridge -f

# Search for errors
docker-compose -f docker-compose.v2.yml logs | grep ERROR
```

### Cost Monitoring

```bash
# Track estimated costs in bridge logs
docker logs sekha-bridge | grep "estimated_cost" | \
  awk '{sum+=$NF} END {print "Total estimated: $" sum}'

# Monitor routing decisions
watch -n 5 'curl -s http://localhost:5001/api/v1/health/providers | jq'
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker resources
docker system df

# Check service logs
docker-compose -f docker-compose.v2.yml logs

# Restart specific service
docker-compose -f docker-compose.v2.yml restart bridge

# Full restart
docker-compose -f docker-compose.v2.yml down
docker-compose -f docker-compose.v2.yml up -d
```

### High Memory Usage

```bash
# Check container stats
docker stats

# Reduce Ollama models
docker exec sekha-ollama ollama rm llama3.1:70b

# Clear unused data
docker system prune -a
```

### Slow Performance

```bash
# Check disk I/O
docker stats

# Optimize PostgreSQL
docker exec sekha-postgres psql -U sekha -d sekha -c "VACUUM ANALYZE;"

# Clear Redis cache
docker exec sekha-redis redis-cli FLUSHALL
```

## Upgrade Procedure

### From v1.x to v2.0

```bash
# 1. Backup current data
./backup.sh

# 2. Stop v1.x services
docker-compose down

# 3. Pull v2.0 branch
git fetch origin
git checkout feature/v2.0-provider-registry

# 4. Update configuration
cp .env .env.v1.backup
cp .env.v2.example .env
# Merge your v1.x settings into new .env

# 5. Start v2.0 services
docker-compose -f docker-compose.v2.yml up -d

# 6. Verify migration
curl http://localhost:5001/api/v1/models
curl http://localhost:8080/health
```

## Support

For issues and questions:
- GitHub Issues: https://github.com/sekha-ai/sekha-docker/issues
- Documentation: https://sekha-ai.github.io/docs
- Email: support@sekha.ai
