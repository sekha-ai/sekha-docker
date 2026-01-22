# Changelog

All notable changes to Sekha Docker deployment stack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[0.1.0]: https://github.com/sekha-ai/sekha-docker/releases/tag/v0.1.0
