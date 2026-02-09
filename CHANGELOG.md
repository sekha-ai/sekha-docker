# Changelog

All notable changes to Sekha Docker deployments will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-10

### Added
- **sekha-llm-bridge service**: New required component for multi-provider LLM routing
- **OpenRouter support**: Access to 400+ models through single configuration
- **Health monitoring**: Comprehensive health checks across all services
- **Test infrastructure**: Deployment validation tests for CI/CD
- **requirements-test.txt**: Minimal test dependencies for CI

### Changed
- **Proxy configuration**: Updated environment variables (`LLM_URL` → `BRIDGE_URL`)
- **Service dependencies**: Proxy now depends on bridge service
- **Docker Compose structure**: Added bridge service with proper networking
- **CI workflow**: Updated to use requirements-test.txt for consistent testing

### Removed
- **E2E Python tests**: Removed from docker repo (component repos have comprehensive tests)

### Fixed
- Test suite now focuses on deployment validation only
- Removed unnecessary Python dependencies
- Improved CI efficiency

### Configuration Updates

**docker-compose.prod.yml changes:**
```yaml
services:
  sekha-proxy:
    environment:
      - BRIDGE_URL=http://sekha-bridge:5001  # Changed from LLM_URL
      - PREFERRED_CHAT_MODEL=llama3.1:8b      # New
      - PREFERRED_VISION_MODEL=gpt-4o         # New

  sekha-bridge:  # New service
    image: ghcr.io/sekha-ai/sekha-llm-bridge:latest
    ports:
      - "5001:5001"
    environment:
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

### Deployment

**Full stack now includes:**
1. `sekha-controller` - Memory orchestration (Rust)
2. `sekha-llm-bridge` - Multi-provider routing (Python + LiteLLM)
3. `sekha-proxy` - Context injection (Python)
4. `chroma` - Vector database
5. `redis` - Cache layer

### Testing

**Run deployment validation:**
```bash
pip install -r requirements-test.txt
pytest tests/ -v
```

**Validate Docker Compose:**
```bash
docker compose -f docker/docker-compose.prod.yml config
```

## [0.1.0] - 2026-01-15

### Added
- Initial deployment configuration
- Docker Compose for full stack
- Dockerfiles for all services
- Basic CI/CD workflows
- Documentation and README
- Environment configuration examples

### Services
- sekha-controller (Rust)
- sekha-proxy (Python)
- chroma (Vector DB)
- redis (Cache)

[0.2.0]: https://github.com/sekha-ai/sekha-docker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/sekha-ai/sekha-docker/releases/tag/v0.1.0
