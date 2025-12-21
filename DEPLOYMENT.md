You're absolutely right, and I apologize! Let me provide the **COMPLETE DEPLOYMENT.md in ONE single code block** that you can copy and paste directly:

***

**Create `sekha-docker/DEPLOYMENT.md`** (copy this entire block once):

```markdown
# Sekha Deployment Guide

Complete deployment documentation for Sekha AI Memory Controller across all platforms.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Tier 1: Local Binary](#tier-1-local-binary-easiest)
3. [Tier 2: Docker Compose](#tier-2-docker-compose-recommended)
4. [Tier 3: Kubernetes](#tier-3-kubernetes-production)
5. [Cloud Deployments](#cloud-deployments)
6. [Configuration](#configuration)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

**Choose your deployment method:**

| Method | Complexity | Use Case |
|--------|------------|----------|
| [Local Binary](#tier-1-local-binary-easiest) | ⭐ Easy | Individual developers, testing |
| [Docker Compose](#tier-2-docker-compose-recommended) | ⭐⭐ Medium | Teams, local development |
| [Kubernetes](#tier-3-kubernetes-production) | ⭐⭐⭐ Advanced | Production, scale |
| [AWS](#aws-deployment) | ⭐⭐⭐ Advanced | Cloud production |
| [Azure](#azure-deployment) | ⭐⭐⭐ Advanced | Cloud production |
| [GCP](#gcp-deployment) | ⭐⭐⭐ Advanced | Cloud production |

---

## Tier 1: Local Binary (Easiest)

**Best for:** Individual developers, quick testing, minimal setup

### Installation

#### Option A: Quick Install Script

```
curl -sSL https://install.sekha.ai | bash
```

#### Option B: Cargo Install

```
# Install from crates.io
cargo install sekha-controller

# Or from GitHub
cargo install --git https://github.com/sekha-ai/sekha-controller
```

#### Option C: Pre-built Binary

```
# Download latest release
wget https://github.com/sekha-ai/sekha-controller/releases/latest/download/sekha-controller-linux-x86_64

# Make executable
chmod +x sekha-controller-linux-x86_64

# Move to PATH
sudo mv sekha-controller-linux-x86_64 /usr/local/bin/sekha-controller
```

### Setup

```
# Initialize configuration
sekha-controller setup

# This creates:
# ~/.sekha/config.toml
# ~/.sekha/data/
# ~/.sekha/logs/
```

### Configuration

Edit `~/.sekha/config.toml`:

```
[server]
host = "127.0.0.1"
port = 8080
api_key = "sk-dev-12345678901234567890123456789012"  # Change this!

[database]
url = "sqlite://$HOME/.sekha/data/sekha.db"

[vector_db]
url = "http://localhost:8000"
collection_name = "sekha_conversations"

[bridge]
url = "http://localhost:5001"
provider = "ollama"
model = "nomic-embed-text"

[storage]
data_dir = "$HOME/.sekha/data"
log_dir = "$HOME/.sekha/logs"
```

### Running

```
# Start server (foreground)
sekha-controller start

# Start as daemon
sekha-controller start --daemon

# Check status
sekha-controller status

# Check health
sekha-controller health

# Stop daemon
sekha-controller stop
```

### Prerequisites

You'll need **Ollama** or another embedding provider:

```
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull embedding model
ollama pull nomic-embed-text

# Start Ollama (runs on localhost:11434)
ollama serve
```

---

## Tier 2: Docker Compose (Recommended)

**Best for:** Teams, local development with all services, easy management

### Quick Start

```
# Clone deployment repo
git clone https://github.com/sekha-ai/sekha-docker.git
cd sekha-docker

# Copy example config
cp config.example.toml config.toml

# Edit configuration
nano config.toml

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f sekha-controller
```

### What Gets Deployed

The default `docker-compose.yml` includes:

- **sekha-controller** - Main API server (port 8080)
- **sekha-bridge** - LLM bridge for embeddings (port 5001)
- **PostgreSQL 16** - Primary database (port 5432)
- **ChromaDB** - Vector database (port 8000)
- **Redis** - Caching and task queue (port 6379)

### Configuration Files

#### `config.toml`

```
[server]
host = "0.0.0.0"
port = 8080
api_key = "your-secure-api-key-min-32-chars"

[database]
url = "postgresql://sekha:sekha_password@postgres:5432/sekha"

[vector_db]
url = "http://chroma:8000"
collection_name = "sekha_conversations"

[bridge]
url = "http://sekha-bridge:5001"
provider = "ollama"
model = "nomic-embed-text"
```

### Environment Variables

Create `.env` file:

```
# Database
POSTGRES_DB=sekha
POSTGRES_USER=sekha
POSTGRES_PASSWORD=your_secure_password_here

# Sekha
RUST_LOG=info
SEKHA_API_KEY=your-secure-api-key-min-32-chars

# Bridge
OLLAMA_HOST=http://host.docker.internal:11434
```

### Docker Compose Variants

```
# Development (hot reload, debug)
docker-compose -f docker-compose.dev.yml up

# Production (optimized builds)
docker-compose -f docker-compose.prod.yml up -d

# Full stack (includes monitoring)
docker-compose -f docker-compose.full.yml up -d

# Testing (ephemeral containers)
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

### Management Commands

```
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes (DESTRUCTIVE)
docker-compose down -v

# Restart specific service
docker-compose restart sekha-controller

# View logs
docker-compose logs -f

# Execute command in container
docker-compose exec sekha-controller sh

# Update images
docker-compose pull
docker-compose up -d

# Check resource usage
docker stats
```

### Health Checks

```
# Controller health
curl http://localhost:8080/health

# ChromaDB health
curl http://localhost:8000/api/v1/heartbeat

# Redis health
docker-compose exec redis redis-cli ping
```

---

## Tier 3: Kubernetes (Production)

**Best for:** Production deployments, high availability, auto-scaling

### Prerequisites

- Kubernetes cluster (1.25+)
- kubectl configured
- Helm 3.x (optional)

### Option A: Helm Chart (Recommended)

```
# Add Sekha Helm repository
helm repo add sekha https://charts.sekha.ai
helm repo update

# Install with default values
helm install my-sekha sekha/sekha-controller

# Install with custom values
helm install my-sekha sekha/sekha-controller \
  --set replicaCount=3 \
  --set storage.size=100Gi \
  --set bridge.provider=anthropic \
  --set bridge.apiKey=sk-ant-your-key \
  --namespace sekha \
  --create-namespace
```

#### Custom Values (`values.yaml`)

```
replicaCount: 3

image:
  repository: ghcr.io/sekha-ai/sekha-controller
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 8080

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: sekha.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: sekha-tls
      hosts:
        - sekha.yourdomain.com

storage:
  size: 50Gi
  storageClassName: standard

database:
  enabled: true
  type: postgres
  host: postgres-service
  port: 5432
  name: sekha
  user: sekha
  passwordSecret: sekha-db-secret

vectorDb:
  enabled: true
  url: http://chroma-service:8000

bridge:
  enabled: true
  provider: ollama
  model: nomic-embed-text
  url: http://ollama-service:11434

redis:
  enabled: true
  url: redis://redis-service:6379

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

### Option B: Raw Kubernetes Manifests

```
# Clone repo
git clone https://github.com/sekha-ai/sekha-docker.git
cd sekha-docker/k8s

# Create namespace
kubectl create namespace sekha

# Apply manifests
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check deployment
kubectl get pods -n sekha
kubectl get svc -n sekha

# View logs
kubectl logs -f -n sekha deployment/sekha-controller
```

### Scaling

```
# Manual scaling
kubectl scale deployment sekha-controller --replicas=5 -n sekha

# Enable autoscaling
kubectl autoscale deployment sekha-controller \
  --min=2 \
  --max=10 \
  --cpu-percent=70 \
  -n sekha

# Check autoscaler
kubectl get hpa -n sekha
```

### Updates

```
# Update image
kubectl set image deployment/sekha-controller \
  sekha-controller=ghcr.io/sekha-ai/sekha-controller:v1.2.0 \
  -n sekha

# Rollout status
kubectl rollout status deployment/sekha-controller -n sekha

# Rollback if needed
kubectl rollout undo deployment/sekha-controller -n sekha
```

---

## Cloud Deployments

### AWS Deployment

**Using ECS + Fargate:**

```
cd cloud/aws

# Configure AWS CLI
aws configure

# Deploy with Terraform
terraform init
terraform plan
terraform apply

# Get ALB URL
terraform output alb_url
```

**Architecture:**
- ECS Fargate for container orchestration
- RDS PostgreSQL for database
- ElastiCache Redis
- Application Load Balancer
- CloudWatch for logging

**Estimated Cost:** ~$150-300/month

### Azure Deployment

**Using Azure Container Instances:**

```
cd cloud/azure

# Login to Azure
az login

# Set subscription
az account set --subscription "Your Subscription"

# Deploy
./deploy.sh

# Get endpoint
az deployment group show \
  --resource-group sekha-rg \
  --name deploy-azure \
  --query properties.outputs.controllerUrl.value
```

**Architecture:**
- Azure Container Instances
- Azure Database for PostgreSQL
- Azure Cache for Redis
- Azure Container Registry

**Estimated Cost:** ~$100-250/month

### GCP Deployment

**Using Cloud Run:**

```
cd cloud/gcp

# Authenticate
gcloud auth login

# Set project
export GCP_PROJECT_ID=your-project-id
export SEKHA_DB_PASSWORD=$(openssl rand -base64 32)

# Deploy
./deploy.sh

# Get URL
terraform output controller_url
```

**Architecture:**
- Cloud Run (serverless containers)
- Cloud SQL PostgreSQL
- Memorystore Redis
- Cloud Load Balancing

**Estimated Cost:** ~$80-200/month (pay per use)

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUST_LOG` | Log level (trace, debug, info, warn, error) | `info` |
| `DATABASE_URL` | PostgreSQL connection string | - |
| `VECTOR_DB_URL` | ChromaDB endpoint | `http://localhost:8000` |
| `BRIDGE_URL` | LLM Bridge endpoint | `http://localhost:5001` |
| `SEKHA_API_KEY` | API authentication key (min 32 chars) | - |
| `OLLAMA_HOST` | Ollama server URL | `http://localhost:11434` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379` |

### Security Best Practices

1. **Always use strong API keys** (minimum 32 characters)
   ```
   # Generate secure key
   openssl rand -base64 32
   ```

2. **Use environment variables for secrets** (never commit to git)
   ```
   export SEKHA_API_KEY=$(openssl rand -base64 32)
   ```

3. **Enable TLS in production**
   ```
   [server]
   tls_cert = "/path/to/cert.pem"
   tls_key = "/path/to/key.pem"
   ```

4. **Restrict network access** (use firewalls/security groups)

5. **Regular backups**
   ```
   # Backup PostgreSQL
   docker-compose exec postgres pg_dump -U sekha sekha > backup.sql
   
   # Backup ChromaDB
   docker-compose exec chroma tar -czf /tmp/chroma-backup.tar.gz /chroma/chroma
   docker cp sekha-chroma:/tmp/chroma-backup.tar.gz ./chroma-backup.tar.gz
   ```

---

## Troubleshooting

### Common Issues

#### Controller won't start

```
# Check logs
docker-compose logs sekha-controller

# Common causes:
# 1. Invalid API key (must be 32+ chars)
# 2. Database connection failed
# 3. Port already in use

# Fix port conflict
lsof -i :8080
kill -9 <PID>
```

#### ChromaDB connection errors

```
# Verify ChromaDB is running
curl http://localhost:8000/api/v1/heartbeat

# Restart ChromaDB
docker-compose restart chroma

# Check network connectivity
docker-compose exec sekha-controller ping chroma
```

#### Embedding timeouts

```
# Check bridge is running
curl http://localhost:5001/health

# Check Ollama
curl http://localhost:11434/api/tags

# Increase timeout in config.toml
[bridge]
timeout_seconds = 120
```

#### Database migration failures

```
# Manual migration
docker-compose exec sekha-controller sh
cd /app
./sekha-controller migrate

# Reset database (DESTRUCTIVE)
docker-compose down -v
docker-compose up -d
```

### Performance Tuning

#### For high-volume workloads:

```
# docker-compose.prod.yml adjustments
services:
  sekha-controller:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

```
# config.toml adjustments
[server]
max_connections = 100
request_timeout_seconds = 60

[database]
pool_size = 20
connection_timeout_seconds = 5

[vector_db]
batch_size = 100
```

### Monitoring

#### Health Check Endpoints

```
# Controller
curl http://localhost:8080/health
curl http://localhost:8080/metrics  # Prometheus metrics

# Bridge
curl http://localhost:5001/health

# ChromaDB
curl http://localhost:8000/api/v1/heartbeat

# PostgreSQL
docker-compose exec postgres pg_isready

# Redis
docker-compose exec redis redis-cli ping
```

#### Log Aggregation

```
# Follow all logs
docker-compose logs -f

# Filter by service
docker-compose logs -f sekha-controller

# Export logs
docker-compose logs --no-color > sekha-logs.txt
```

---

## Support

- **Documentation:** https://docs.sekha.ai
- **GitHub Issues:** https://github.com/sekha-ai/sekha-controller/issues
- **Discord Community:** https://discord.gg/sekha-ai

---

## License

AGPL-3.0 - See [LICENSE](LICENSE) for details.
```

***

**That's it!** One copy-paste for the entire deployment documentation. All the Azure/GCP deployment code files I provided earlier are complete and ready to use as-is.