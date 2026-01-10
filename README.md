[![Build and Publish](https://github.com/sekha-ai/sekha-docker/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/sekha-ai/sekha-docker/actions/workflows/build-and-publish.yml)

# Sekha Docker & Deployment

Production-ready Docker images, Kubernetes manifests, and cloud deployment templates for the complete Sekha stack.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│  Web UI (Port 8081)                         │
│  - Chat interface with memory               │
│  - Privacy controls                         │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│  Sekha Proxy (NEW - Port 8081)              │
│  - Context injection                        │
│  - Privacy filtering                        │
│  - Auto storage                             │
└──────┬──────────────────┬───────────────────┘
       │                  │
       │ Context          │ LLM Requests
       ▼                  ▼
┌──────────────┐   ┌──────────────┐
│ Sekha Core   │   │ Sekha Bridge │
│ (Port 8080)  │   │ (Port 5001)  │
│              │   │              │
│ Controller   │   │ LLM Routing  │
│ 4-Phase Asm  │   │ Multi-model  │
└──────┬───────┘   └──────────────┘
       │
       ▼
┌──────────────┐   ┌──────────────┐
│   ChromaDB   │   │    Redis     │
│  (Port 8000) │   │  (Port 6379) │
│   Vectors    │   │   Caching    │
└──────────────┘   └──────────────┘
```

## 🚀 Quick Start

### Production Deployment (Recommended)

```bash
# Clone repository
git clone https://github.com/sekha-ai/sekha-docker.git
cd sekha-docker/docker

# Set API key
export SEKHA_API_KEY="your-secure-key-here"

# Start all services (includes NEW proxy + UI)
docker-compose -f docker-compose.prod.yml up -d

# Access the Web UI
open http://localhost:8081

# Check health
curl http://localhost:8081/health
```

### Services Exposed

| Service | Port | URL | Purpose |
|---------|------|-----|--------|
| **Proxy + UI** | 8081 | http://localhost:8081 | **NEW: Chat UI with memory** |
| Controller API | 8080 | http://localhost:8080 | Core backend APIs |
| Bridge | 5001 | http://localhost:5001 | LLM routing |
| ChromaDB | 8000 | http://localhost:8000 | Vector database |
| Redis | 6379 | localhost:6379 | Cache layer |

## 🆕 What's New: Sekha Proxy

The **sekha-proxy** service provides:

### Features
- ✅ **Web UI** - Beautiful chat interface
- ✅ **Automatic Context Injection** - AI remembers past conversations
- ✅ **Privacy Controls** - Exclude folders from AI memory
- ✅ **OpenAI Compatible** - Drop-in replacement for `/v1/chat/completions`
- ✅ **Multi-LLM** - Works with any LLM (Ollama, OpenAI, etc.)

### Usage

**Via Web UI:**
```bash
open http://localhost:8081
```

**Via API:**
```python
from openai import OpenAI

# Point to proxy instead of direct LLM
client = OpenAI(base_url="http://localhost:8081")

response = client.chat.completions.create(
    model="llama2",
    messages=[{"role": "user", "content": "Remember my name is Alice"}]
)

# Later...
response = client.chat.completions.create(
    model="llama2",
    messages=[{"role": "user", "content": "What's my name?"}]
)
# AI remembers: "Your name is Alice"
```

### Privacy Filtering

```bash
# Exclude sensitive folders from AI context
export EXCLUDED_FOLDERS="/personal,/private,/confidential"
docker-compose -f docker-compose.prod.yml up -d
```

## 📋 Configuration

### Environment Variables

#### Proxy Settings (NEW)
| Variable | Default | Description |
|----------|---------|-------------|
| `PROXY_PORT` | 8081 | Proxy HTTP port |
| `AUTO_INJECT_CONTEXT` | true | Enable automatic memory |
| `CONTEXT_BUDGET` | 4000 | Max tokens for context |
| `DEFAULT_FOLDER` | /work | Default conversation folder |
| `EXCLUDED_FOLDERS` | - | Comma-separated folders to exclude |
| `SEKHA_API_KEY` | **required** | API key for controller |

#### Controller Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `SEKHA_PORT` | 8080 | Controller HTTP port |
| `RUST_LOG` | info | Log level |

#### Bridge Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `BRIDGE_PORT` | 5001 | LLM Bridge HTTP port |
| `OLLAMA_BASE_URL` | http://host.docker.internal:11434 | Ollama endpoint |
| `REDIS_URL` | redis://redis:6379/0 | Redis connection |

## 📦 Docker Images

Pre-built images on GitHub Container Registry:

```bash
# Controller (Rust)
docker pull ghcr.io/sekha-ai/controller:latest

# Bridge (Python)
docker pull ghcr.io/sekha-ai/llm-bridge:latest

# Proxy (Python) - NEW
docker pull ghcr.io/sekha-ai/proxy:latest
```

### Build from Source

```bash
# Clone proxy repo
git clone https://github.com/sekha-ai/sekha-proxy.git

# Build image
cd sekha-docker
docker build -f docker/Dockerfile.proxy -t ghcr.io/sekha-ai/proxy:latest ../sekha-proxy
```

## 🧪 Testing the Stack

### 1. Health Check

```bash
curl http://localhost:8081/health
```

Expected:
```json
{
  "status": "healthy",
  "controller": "healthy",
  "llm": "healthy"
}
```

### 2. Test Memory (API)

```bash
# Store a fact
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "I use PostgreSQL for my database"}],
    "folder": "/work/myproject"
  }'

# Test recall
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "What database do I use?"}],
    "folder": "/work/myproject"
  }'
```

AI should remember "PostgreSQL"!

### 3. Test Privacy

```bash
# Store sensitive data
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "My SSN is 123-45-6789"}],
    "folder": "/private/secrets"
  }'

# Query with exclusion
curl -X POST http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "What is my SSN?"}],
    "excluded_folders": ["/private"]
  }'
```

AI should NOT recall the SSN!

## ☸️ Kubernetes Deployment

```bash
# Deploy with kubectl
./deploy-k8s.sh --version v1.0.0

# Or with Helm
helm install sekha sekha/sekha-controller \
  --set proxy.enabled=true \
  --set proxy.image.tag=latest
```

## 🔧 Development

### Local Development

```bash
# Start with hot reload
docker-compose -f docker/docker-compose.dev.yml up

# Or use convenience script
./scripts/dev-run.sh
```

### Building All Images

```bash
make build      # Build all images
make push       # Push to registry
make test       # Run tests
```

## 📊 Monitoring

### View Logs

```bash
# All services
docker-compose -f docker/docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker/docker-compose.prod.yml logs -f sekha-proxy
```

### Metrics

- Controller metrics: http://localhost:8080/metrics
- Proxy health: http://localhost:8081/health
- Bridge health: http://localhost:5001/health

## 🔒 Security

- **Distroless images**: Minimal attack surface
- **Non-root containers**: All services run unprivileged
- **Secrets management**: Use Docker secrets or K8s secrets
- **Privacy controls**: Folder-level data exclusion

## 📈 Performance

### Resource Requirements

| Service | CPU | Memory | Storage |
|---------|-----|--------|--------|
| sekha-core | 0.25-1.0 | 256M-1G | 10Gi |
| sekha-proxy | 0.1-0.5 | 128M-512M | - |
| sekha-bridge | 0.5-2.0 | 512M-2G | - |
| chroma | 0.1-0.5 | 256M-1G | 5Gi |
| redis | 0.05-0.2 | 32M-128M | 1Gi |

### Benchmarks

- **Context retrieval**: <100ms for 1M+ messages
- **Proxy overhead**: <10ms vs direct LLM
- **Throughput**: 100+ req/s on modest hardware

## 🆘 Support

- 📖 **Documentation**: [docs.sekha.dev](https://docs.sekha.dev)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/sekha-ai/sekha-controller/discussions)
- 🐛 **Issues**: [GitHub Issues](https://github.com/sekha-ai/sekha-docker/issues)

## 📄 License

AGPL-3.0-or-later

## 🔗 Related Repositories

- [sekha-controller](https://github.com/sekha-ai/sekha-controller) - Core Rust backend
- [sekha-proxy](https://github.com/sekha-ai/sekha-proxy) - Python proxy with UI
- [sekha-mcp](https://github.com/sekha-ai/sekha-mcp) - MCP server integration

---

**Built with 💙 by the Sekha team**
