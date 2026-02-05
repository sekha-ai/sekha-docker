# Changelog

All notable changes to Sekha Docker deployment stack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-02-05

### 🚀 Major Features

#### Multi-Provider Architecture
- **Provider Registry System**: Centralized provider management with automatic routing
- **Cost-Aware Routing**: Automatic selection of cheapest suitable provider
- **Circuit Breakers**: Automatic provider failover on errors
- **Fallback Support**: Graceful degradation when providers fail
- **Vision Model Support**: Automatic detection and routing of image-based requests

#### New Components
- **Model Registry** (`sekha-llm-bridge`): Central coordination of all LLM providers
- **Provider Abstraction**: Unified interface for Ollama, OpenAI, Anthropic, OpenRouter, Moonshot, DeepSeek
- **Dynamic Dimension Switching**: Automatic ChromaDB collection selection based on embedding model
- **Cost Estimation**: Per-request cost tracking and budget enforcement

#### API Enhancements
- `/api/v1/models` - List all available models across providers
- `/api/v1/route` - Get optimal provider/model for a task
- `/api/v1/health/providers` - Monitor provider health and circuit breaker states
- Bridge routing integration in proxy (replaces direct LLM calls)

### ⚙️ Configuration Changes

#### New Configuration Format
- **YAML-based config** (`config.yaml`) replaces scattered environment variables
- **Multi-provider definitions** with priorities and capabilities
- **Task-based routing** (embedding, chat_small, chat_smart, vision)
- **Circuit breaker settings** per deployment

Example minimal config:
```yaml
config_version: "2.0"
llm_providers:
  - id: "ollama_local"
    type: "ollama"
    base_url: "http://localhost:11434"
    priority: 1
    models:
      - model_id: "llama3.1:8b"
        task: "chat_small"
        context_window: 8192
```

See `docs/configuration-v2.md` for full details.

### 📦 Updated Services

#### Sekha LLM Bridge (2.0.0)
- Added provider registry with LiteLLM integration
- Implemented cost estimation system
- Added circuit breakers for resilience
- Multi-dimension embedding support (768, 1024, 1536, 3072)
- Vision pass-through to capable providers

#### Sekha Proxy (2.0.0)
- **BREAKING**: Now routes through bridge instead of direct LLM
- Automatic vision model detection from message content
- Routing metadata included in responses
- Updated to use `LLM_BRIDGE_URL` instead of `LLM_URL`

#### Sekha Controller (no version change)
- Enhanced bridge client with routed methods
- Multi-dimension ChromaDB collections
- Search across all dimensions with automatic merging
- Graceful LLM fallback in summarization

#### Sekha MCP (2.0.0)
- Updated to v2.0 compatibility
- No code changes needed (controller handles routing transparently)

### 🔧 Breaking Changes

1. **Configuration**:
   - Environment variables alone no longer sufficient
   - Must provide `config.yaml` or equivalent JSON in `SEKHA__LLM_PROVIDERS`
   - See `docs/migration-guide-v2.md`

2. **Proxy**:
   - `LLM_URL` → `LLM_BRIDGE_URL`
   - `LLM_PROVIDER` deprecated (bridge handles provider selection)
   - Responses now include `sekha_metadata.routing` field

3. **Bridge**:
   - Old single-provider env vars deprecated
   - Must configure providers via config system
   - Default models must be specified

### 📚 Documentation

#### Added
- `docs/migration-guide-v2.md` - Step-by-step v1.x → v2.0 migration
- `docs/configuration-v2.md` - Complete v2.0 configuration reference
- `docs/vision-support.md` - Vision model integration guide
- `config.yaml.example` - Three example configurations (minimal, hybrid, full)

#### Updated
- README.md - v2.0 architecture diagrams
- DEPLOYMENT.md - v2.0 deployment steps
- E2E_TESTING.md - v2.0 testing procedures

### 🧪 Testing

#### Added Tests
- `test_integration_v2.py` - Multi-provider routing tests
- `test_resilience.py` - Circuit breaker and fallback tests
- `test_config.py` - Configuration validation tests
- Provider health check integration tests

### 🐛 Bug Fixes

- Fixed proxy bypassing bridge routing (now uses `/api/v1/route`)
- Fixed dimension mismatch in multi-model scenarios
- Fixed missing vision model detection in proxy
- Fixed circuit breaker not resetting after recovery
- Fixed cost estimation for local models (now correctly returns $0.00)

### ⚡ Performance

- Reduced provider failover time (circuit breakers)
- Optimized routing decision making (<10ms overhead)
- Parallel health checks for providers
- Connection pooling for bridge/controller clients

### 🔒 Security

- API keys now support `${ENV_VAR}` syntax in config
- Secrets not logged in routing responses
- Updated security scanning for new dependencies

### 📊 Metrics

- Cost tracking per request
- Provider selection reasoning
- Circuit breaker state changes
- Model usage statistics

### 🚀 Migration from v1.x

**Quick migration:**
```bash
# 1. Pull v2.0 branch
git checkout feature/v2.0-provider-registry

# 2. Copy example config
cp config.yaml.example config.yaml

# 3. Edit config with your providers
vim config.yaml

# 4. Update docker-compose env vars
export LLM_BRIDGE_URL="http://sekha-llm-bridge:5001"
# (remove old LLM_URL, LLM_PROVIDER)

# 5. Restart stack
docker-compose down
docker-compose up -d
```

See `docs/migration-guide-v2.md` for complete instructions.

### 🎯 Roadmap

#### Future Enhancements (v2.1+)
- [ ] Automatic provider cost monitoring and budget alerts
- [ ] Model performance benchmarking
- [ ] A/B testing between providers
- [ ] Streaming support in proxy routing
- [ ] Fine-tuned model support
- [ ] Custom provider plugins

---

## [0.1.0] - 2026-01-21

### Added
- Initial production deployment setup
- Docker Compose configurations (prod, dev, local, test)
- Multi-arch Docker image builds (amd64/arm64)
- Complete stack deployment:
  - Sekha Controller (Rust) - Core memory engine
  - Sekha LLM Bridge (Python) - LLM operations service
  - Sekha Proxy (Python) - Intelligent routing with context injection
  - ChromaDB - Vector database
  - Redis - Cache layer
- Kubernetes manifests and Helm charts
- Cloud deployment templates (AWS, GCP, Azure)
- Comprehensive documentation (README, DEPLOYMENT, TESTING)
- CI/CD pipeline for automated builds and releases
- Security scanning and SBOM generation
- Integration tests for full stack validation

### Features
- One-command deployment: `docker-compose -f docker/docker-compose.prod.yml up -d`
- Web UI for chat with persistent memory
- Privacy controls with folder exclusion
- OpenAI-compatible proxy endpoint
- Health monitoring for all services
- Multi-architecture support (x86_64, ARM64)

### Documentation
- Deployment guide with multiple scenarios
- Testing procedures and validation scripts
- Cloud-specific deployment guides
- Kubernetes/Helm deployment instructions

### Changed
- Fixed Docker image builds to use correct repository (sekha-llm-bridge instead of sekha-mcp)
- Consolidated CI workflows from 7 to 5 (removed duplicates)
- Enhanced CI pipeline with comprehensive deployment script validation
- Fixed Helm chart dependencies and test procedures
- Updated security scanning to only report CRITICAL/HIGH vulnerabilities

### Fixed
- Docker build cache configuration compatibility issues
- Helm template service account naming
- Missing security-events permissions for Trivy scans
- Workflow badge references in README

### Removed
- Redundant docker-build.yml workflow (superseded by build.yml)
- Duplicate deployment-tests.yml workflow (merged into ci.yml)

[2.0.0]: https://github.com/sekha-ai/sekha-docker/releases/tag/v2.0.0
[0.1.0]: https://github.com/sekha-ai/sekha-docker/releases/tag/v0.1.0
