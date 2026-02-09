# Changelog

All notable changes to Sekha Docker deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-10

### Added
- **LLM Bridge service**: New required service for multi-provider routing
- **OpenRouter configuration**: Easy setup for 400+ model access
- **Provider health monitoring**: Circuit breakers and failover support
- **Deployment validation tests**: Automated testing of docker-compose configuration
- **Minimal test dependencies**: `requirements-test.txt` for CI/CD

### Changed
- **BREAKING**: Proxy now requires Bridge service (new service added to compose)
- **BREAKING**: Environment variable changes:
  - Proxy: `LLM_URL` → `BRIDGE_URL`
  - Proxy: `LLM_PROVIDER` removed
  - Bridge: New service requires configuration
- Updated docker-compose.prod.yml for v0.2.0 architecture
- CI workflow now uses requirements-test.txt
- Removed end-to-end Python tests (focus on deployment validation)

### Fixed
- Docker compose validation in CI
- Service dependency ordering
- Health check configurations

### Deployment

**New Service Architecture:**

```yaml
services:
  sekha-proxy:      # Port 8081 - Main API
  sekha-bridge:     # Port 5001 - NEW: LLM routing
  sekha-core:       # Port 8080 - Controller
  chroma:           # Port 8000 - Vector DB
  redis:            # Port 6379 - Cache
  ollama:           # Port 11434 - Local models (optional)
```

**Required Environment Updates:**

```bash
# Proxy .env updates
BRIDGE_URL=http://sekha-bridge:5001  # Was: LLM_URL
# Remove: LLM_PROVIDER

# Bridge .env (new)
OLLAMA_BASE_URL=http://ollama:11434
OPENROUTER_API_KEY=sk-or-...  # Optional
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
```

### Technical
- All deployment validation tests passing
- Docker images building successfully
- Security scans passing (Trivy, SBOM)
- Full CI/CD pipeline validated

## [0.1.0] - 2026-01-15

### Added
- Initial release
- Docker Compose configuration for full stack
- Production-ready Dockerfiles
- Health monitoring
- Basic deployment scripts
- Documentation

### Services
- Sekha Proxy (Python/FastAPI)
- Sekha Controller (Rust)
- ChromaDB (Vector storage)
- Redis (Caching)

[0.2.0]: https://github.com/sekha-ai/sekha-docker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/sekha-ai/sekha-docker/releases/tag/v0.1.0
