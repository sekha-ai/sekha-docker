# Sekha Docker Deployment

> **Production-Ready Docker Compose Setup for Sekha**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Docker](https://img.shields.io/badge/docker-ready-green.svg)](https://www.docker.com)

---

## What's Included

Complete Sekha stack in one command:

- ✅ **Sekha Controller** (Rust core engine)
- ✅ **Sekha LLM Bridge** (Python)
- ✅ **Sekha Proxy** (Python)
- ✅ **ChromaDB** (vector storage)
- ✅ **Ollama** (local LLM)
- ✅ Pre-configured networking
- ✅ Volume persistence
- ✅ Health checks

**This is the recommended way to deploy Sekha.**

---

## 📚 Documentation

**Complete deployment guide: [docs.sekha.dev/deployment](https://docs.sekha.dev/deployment/docker-compose/)**

- [Docker Compose Guide](https://docs.sekha.dev/deployment/docker-compose/)
- [Production Deployment](https://docs.sekha.dev/deployment/production/)
- [Security Hardening](https://docs.sekha.dev/deployment/security/)
- [Configuration](https://docs.sekha.dev/getting-started/configuration/)

---

## 🚀 Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/sekha-ai/sekha-docker.git
cd sekha-docker

# 2. Start everything
docker compose up -d

# 3. Verify it's running
curl http://localhost:8080/health

# Expected: {"status":"healthy",...}
```

**That's it! Sekha is now running at http://localhost:8080**

---

## 📚 API Documentation

Once running, visit:

- **Swagger UI:** http://localhost:8080/swagger-ui/
- **OpenAPI Spec:** http://localhost:8080/api-doc/openapi.json

---

## 🔧 Configuration Files

```
sekha-docker/
├── docker-compose.yml       # Development stack
├── docker-compose.prod.yml  # Production stack
├── .env.example             # Environment variables template
├── config/
│   ├── controller.toml      # Controller config
│   └── llm-bridge.yaml      # LLM Bridge config
└── scripts/
    ├── start.sh             # Helper scripts
    └── stop.sh
```

---

## ⚙️ Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
# Required
SEKHA_API_KEY=your-secure-api-key-min-32-chars

# Optional
SEKHA_PORT=8080
CHROMA_PORT=8000
OLLAMA_PORT=11434
```

**See [Configuration Guide](https://docs.sekha.dev/getting-started/configuration/) for all options.**

---

## 🛠️ Commands

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Restart services
docker compose restart

# Update to latest images
docker compose pull
docker compose up -d

# Production deployment
docker compose -f docker-compose.prod.yml up -d
```

---

## 📊 Services

| Service | Port | Purpose |
|---------|------|----------|
| sekha-controller | 8080 | Main API server |
| sekha-llm-bridge | 5001 | LLM operations (internal) |
| sekha-proxy      |      | Transparent capture proxy |
| chroma | 8000 | Vector database |
| ollama | 11434 | Local LLM runtime |

---

## 🔒 Production Deployment

For production, use:

```bash
docker compose -f docker-compose.prod.yml up -d
```

**Differences from dev:**

- Proper API key management
- Resource limits
- Restart policies
- Volume persistence
- Health checks
- Logging configuration

**See [Production Guide](https://docs.sekha.dev/deployment/production/) for full setup.**

---

## 🔗 Links

- **Main Repo:** [sekha-controller](https://github.com/sekha-ai/sekha-controller)
- **Docs:** [docs.sekha.dev](https://docs.sekha.dev)
- **Website:** [sekha.dev](https://sekha.dev)
- **Discord:** [discord.gg/sekha](https://discord.gg/gZb7U9deKH))

---

## 📄 License

AGPL-3.0 - **[License Details](https://docs.sekha.dev/about/license/)**
