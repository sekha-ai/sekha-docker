# Sekha Docker & Deployment

Production-ready Docker images, Kubernetes manifests, and cloud deployment templates for Sekha Controller.

## �� Repository Structure
sekha-docker/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml     # Base services (Chroma, Redis)
│   ├── docker-compose.full.yml # Full stack (Core + Bridge + Base)
│   ├── docker-compose.dev.yml # Development with hot reload
│   ├── Dockerfile.rust.prod   # Multi-stage distroless Rust build
│   ├── Dockerfile.python.prod # Multi-stage Python build
│   ├── Dockerfile.rust.dev    # Development Rust
│   └── Dockerfile.python.dev  # Development Python
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── helm/                      # Helm charts
│   └── sekha-controller/      # Complete Helm chart
├── cloud/                     # Cloud provider templates
│   └── aws/                   # AWS ECS/Fargate Terraform
├── scripts/                   # Deployment scripts
│   ├── install-local.sh       # Install binary locally
│   ├── deploy-docker.sh       # Deploy with Docker
│   └── deploy-k8s.sh          # Deploy to Kubernetes
└── .github/workflows/         # CI/CD
└── build.yml             # Build & push images


## 🚀 Quick Start

### Tier 1: Local Binary (Development)
```bash
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/install-local.sh | bash
sekha-controller

Tier 2: Docker Compose (Recommended)
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/deploy-docker.sh | bash

Tier 3: Kubernetes (Production)
# Option A: kubectl
./deploy-k8s.sh --version v0.1.0

# Option B: Helm
./deploy-k8s.sh --helm --version v0.1.0

Tier 4: Cloud (Enterprise)
cd cloud/aws
terraform init
terraform apply -var="app_version=v0.1.0"

🏗️ Building Images
Manual Build

cat > ~/sekha/workspace/sekha-docker/README.md << 'EOF'
# Sekha Docker & Deployment

Production-ready Docker images, Kubernetes manifests, and cloud deployment templates for Sekha Controller.

## �� Repository Structure
sekha-docker/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml     # Base services (Chroma, Redis)
│   ├── docker-compose.full.yml # Full stack (Core + Bridge + Base)
│   ├── docker-compose.dev.yml # Development with hot reload
│   ├── Dockerfile.rust.prod   # Multi-stage distroless Rust build
│   ├── Dockerfile.python.prod # Multi-stage Python build
│   ├── Dockerfile.rust.dev    # Development Rust
│   └── Dockerfile.python.dev  # Development Python
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── helm/                      # Helm charts
│   └── sekha-controller/      # Complete Helm chart
├── cloud/                     # Cloud provider templates
│   └── aws/                   # AWS ECS/Fargate Terraform
├── scripts/                   # Deployment scripts
│   ├── install-local.sh       # Install binary locally
│   ├── deploy-docker.sh       # Deploy with Docker
│   └── deploy-k8s.sh          # Deploy to Kubernetes
└── .github/workflows/         # CI/CD
└── build.yml             # Build & push images


## 🚀 Quick Start

### Tier 1: Local Binary (Development)
```bash
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/install-local.sh | bash
sekha-controller

Tier 2: Docker Compose (Recommended)
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/deploy-docker.sh | bash

Tier 3: Kubernetes (Production)
# Option A: kubectl
./deploy-k8s.sh --version v0.1.0

# Option B: Helm
./deploy-k8s.sh --helm --version v0.1.0

Tier 4: Cloud (Enterprise)
cd cloud/aws
terraform init
terraform apply -var="app_version=v0.1.0"

🏗️ Building Images
Manual Build

🏗️ Building Images
Manual Build

# Build Rust controller
docker build -f docker/Dockerfile.rust.prod -t ghcr.io/sekha-ai/sekha-controller:latest https://github.com/sekha-ai/sekha-controller.git#main

# Build Python bridge
docker build -f docker/Dockerfile.python.prod -t ghcr.io/sekha-ai/sekha-mcp:latest https://github.com/sekha-ai/sekha-mcp.git#main

CI/CD Build
Images are automatically built and pushed to GitHub Container Registry on:
Push to main branch
Git tag v*
Pull requests (build only, no push)
📋 Configuration
Environment Variables

| Variable        | Default               | Description          |
| --------------- | --------------------- | -------------------- |
| `SEKHA_PORT`    | 8080                  | Controller HTTP port |
| `BRIDGE_PORT`   | 5001                  | LLM Bridge HTTP port |
| `CHROMA_PORT`   | 8000                  | ChromaDB port        |
| `REDIS_PORT`    | 6379                  | Redis port           |
| `OLLAMA_HOST`   | <http://ollama:11434> | Ollama endpoint      |
| `SEKHA_VERSION` | latest                | Docker image tag     |
| `RUST_LOG`      | info                  | Log level            |



Config File (config.toml)

[server]
port = 8080
host = "0.0.0.0"

[database]
url = "sqlite:///data/sekha.db"

[chroma]
url = "http://chroma:8000"

[redis]
url = "redis://redis:6379"

[ollama]
url = "http://ollama:11434"

☸️ Kubernetes Deployment
Prerequisites
Kubernetes 1.25+
kubectl configured
(for Helm) Helm 3.x
Using kubectl

# Deploy to default namespace
./deploy-k8s.sh

# Deploy to custom namespace
./deploy-k8s.sh --namespace my-sekha

# Deploy specific version
./deploy-k8s.sh --version v0.1.0


Using Helm
# Add Helm repository
helm repo add sekha https://sekha-ai.github.io/helm-charts
helm repo update

# Install
helm install my-sekha sekha/sekha-controller \
  --namespace sekha \
  --create-namespace \
  --set controller.image.tag=v0.1.0

# Upgrade
helm upgrade my-sekha sekha/sekha-controller \
  --set controller.image.tag=v0.2.0

# Uninstall
helm uninstall my-sekha --namespace sekha


☁️ Cloud Deployment
AWS (ECS Fargate)

cd cloud/aws
terraform init
terraform apply \
  -var="app_version=v0.1.0" \
  -var="aws_region=us-west-2"

GCP (GKE)

cat > ~/sekha/workspace/sekha-docker/README.md << 'EOF'
# Sekha Docker & Deployment

Production-ready Docker images, Kubernetes manifests, and cloud deployment templates for Sekha Controller.

## �� Repository Structure
sekha-docker/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml     # Base services (Chroma, Redis)
│   ├── docker-compose.full.yml # Full stack (Core + Bridge + Base)
│   ├── docker-compose.dev.yml # Development with hot reload
│   ├── Dockerfile.rust.prod   # Multi-stage distroless Rust build
│   ├── Dockerfile.python.prod # Multi-stage Python build
│   ├── Dockerfile.rust.dev    # Development Rust
│   └── Dockerfile.python.dev  # Development Python
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── helm/                      # Helm charts
│   └── sekha-controller/      # Complete Helm chart
├── cloud/                     # Cloud provider templates
│   └── aws/                   # AWS ECS/Fargate Terraform
├── scripts/                   # Deployment scripts
│   ├── install-local.sh       # Install binary locally
│   ├── deploy-docker.sh       # Deploy with Docker
│   └── deploy-k8s.sh          # Deploy to Kubernetes
└── .github/workflows/         # CI/CD
└── build.yml             # Build & push images


## 🚀 Quick Start

### Tier 1: Local Binary (Development)
```bash
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/install-local.sh | bash
sekha-controller

Tier 2: Docker Compose (Recommended)
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/deploy-docker.sh | bash

Tier 3: Kubernetes (Production)
# Option A: kubectl
./deploy-k8s.sh --version v0.1.0

# Option B: Helm
./deploy-k8s.sh --helm --version v0.1.0

Tier 4: Cloud (Enterprise)
cd cloud/aws
terraform init
terraform apply -var="app_version=v0.1.0"

🏗️ Building Images
Manual Build

cat > ~/sekha/workspace/sekha-docker/README.md << 'EOF'
# Sekha Docker & Deployment

Production-ready Docker images, Kubernetes manifests, and cloud deployment templates for Sekha Controller.

## �� Repository Structure
sekha-docker/
├── docker/                    # Docker configurations
│   ├── docker-compose.yml     # Base services (Chroma, Redis)
│   ├── docker-compose.full.yml # Full stack (Core + Bridge + Base)
│   ├── docker-compose.dev.yml # Development with hot reload
│   ├── Dockerfile.rust.prod   # Multi-stage distroless Rust build
│   ├── Dockerfile.python.prod # Multi-stage Python build
│   ├── Dockerfile.rust.dev    # Development Rust
│   └── Dockerfile.python.dev  # Development Python
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── helm/                      # Helm charts
│   └── sekha-controller/      # Complete Helm chart
├── cloud/                     # Cloud provider templates
│   └── aws/                   # AWS ECS/Fargate Terraform
├── scripts/                   # Deployment scripts
│   ├── install-local.sh       # Install binary locally
│   ├── deploy-docker.sh       # Deploy with Docker
│   └── deploy-k8s.sh          # Deploy to Kubernetes
└── .github/workflows/         # CI/CD
└── build.yml             # Build & push images


## 🚀 Quick Start

### Tier 1: Local Binary (Development)
```bash
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/install-local.sh | bash
sekha-controller

Tier 2: Docker Compose (Recommended)
curl -sSL https://raw.githubusercontent.com/sekha-ai/sekha-docker/main/deploy-docker.sh | bash

Tier 3: Kubernetes (Production)
# Option A: kubectl
./deploy-k8s.sh --version v0.1.0

# Option B: Helm
./deploy-k8s.sh --helm --version v0.1.0

Tier 4: Cloud (Enterprise)
cd cloud/aws
terraform init
terraform apply -var="app_version=v0.1.0"

🏗️ Building Images
Manual Build

# Build Rust controller
docker build -f docker/Dockerfile.rust.prod -t ghcr.io/sekha-ai/sekha-controller:latest https://github.com/sekha-ai/sekha-controller.git#main

# Build Python bridge
docker build -f docker/Dockerfile.python.prod -t ghcr.io/sekha-ai/sekha-mcp:latest https://github.com/sekha-ai/sekha-mcp.git#main

CI/CD Build
Images are automatically built and pushed to GitHub Container Registry on:
Push to main branch
Git tag v*
Pull requests (build only, no push)
📋 Configuration
Environment Variables

| Variable        | Default               | Description          |
| --------------- | --------------------- | -------------------- |
| `SEKHA_PORT`    | 8080                  | Controller HTTP port |
| `BRIDGE_PORT`   | 5001                  | LLM Bridge HTTP port |
| `CHROMA_PORT`   | 8000                  | ChromaDB port        |
| `REDIS_PORT`    | 6379                  | Redis port           |
| `OLLAMA_HOST`   | <http://ollama:11434> | Ollama endpoint      |
| `SEKHA_VERSION` | latest                | Docker image tag     |
| `RUST_LOG`      | info                  | Log level            |



Config File (config.toml)

[server]
port = 8080
host = "0.0.0.0"

[database]
url = "sqlite:///data/sekha.db"

[chroma]
url = "http://chroma:8000"

[redis]
url = "redis://redis:6379"

[ollama]
url = "http://ollama:11434"

☸️ Kubernetes Deployment
Prerequisites
Kubernetes 1.25+
kubectl configured
(for Helm) Helm 3.x
Using kubectl

# Deploy to default namespace
./deploy-k8s.sh

# Deploy to custom namespace
./deploy-k8s.sh --namespace my-sekha

# Deploy specific version
./deploy-k8s.sh --version v0.1.0


Using Helm
# Add Helm repository
helm repo add sekha https://sekha-ai.github.io/helm-charts
helm repo update

# Install
helm install my-sekha sekha/sekha-controller \
  --namespace sekha \
  --create-namespace \
  --set controller.image.tag=v0.1.0

# Upgrade
helm upgrade my-sekha sekha/sekha-controller \
  --set controller.image.tag=v0.2.0

# Uninstall
helm uninstall my-sekha --namespace sekha


☁️ Cloud Deployment
AWS (ECS Fargate)

cd cloud/aws
terraform init
terraform apply \
  -var="app_version=v0.1.0" \
  -var="aws_region=us-west-2"

GCP (GKE)
# See cloud/gcp/ directory

Azure (AKS)
# See cloud/azure/ directory


🔧 Development
Local Development with Hot Reload

# Clone all repositories
git clone https://github.com/sekha-ai/sekha-controller
git clone https://github.com/sekha-ai/sekha-mcp
git clone https://github.com/sekha-ai/sekha-docker

# Start development environment
cd sekha-docker
docker-compose -f docker/docker-compose.dev.yml --profile dev up

# OR use the convenience script
./scripts/dev-run.sh


Building from Source
# Build all images locally
make build

# Push to registry
make push VERSION=v0.1.0

# Run tests
make test



📊 Monitoring & Observability

Health Checks
Controller: http://localhost:8080/health
Bridge: http://localhost:5001/health
Chroma: http://localhost:8000/api/v1/heartbeat

Metrics
Prometheus metrics available at:
Controller: http://localhost:8080/metrics

Logging
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f sekha-core

# View with specific log level
docker-compose exec sekha-core env RUST_LOG=debug sekha-controller


🔒 Security
Distroless images: Minimal attack surface
Non-root containers: All services run as unprivileged users
Read-only root filesystem: Where possible
Secrets management: Use Kubernetes secrets or Docker secrets


🔄 CI/CD
GitHub Actions workflow (.github/workflows/build.yml):
Builds on PR/push to main
Builds on version tags
Multi-arch builds (amd64, arm64)
Publishes to GitHub Container Registry
Generates SBOM (Software Bill of Materials)
Runs vulnerability scanning


📈 Performance Benchmarks
Resource Requirements

| Service      | CPU      | Memory    | Storage |
| ------------ | -------- | --------- | ------- |
| sekha-core   | 100-500m | 128-512Mi | 10Gi    |
| sekha-bridge | 50-200m  | 64-256Mi  | -       |
| chroma       | 100-500m | 256Mi-1Gi | 5Gi     |
| redis        | 50-200m  | 32-128Mi  | 1Gi     |

Expected Performance
Database: ~10K messages/sec insert (SQLite)
Search: ~100 queries/sec (Chroma local)
Embedding: ~50 messages/sec (Ollama GPU)

🤝 Contributing
See CONTRIBUTING.md in the main repository.

📄 License
AGPL v3 - See LICENSE

🆘 Support
📖 Documentation: https://sekha-ai.dev/docs
💬 Discussions: https://github.com/sekha-ai/sekha-controller/discussions
🐛 Issues: https://github.com/sekha-ai/sekha-controller/issues
