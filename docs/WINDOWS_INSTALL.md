# Sekha - Windows 11 Installation Guide

Complete guide for installing and testing Sekha on Windows 11 (non-WSL).

## Prerequisites

### 1. Docker Desktop for Windows

**Download**: https://www.docker.com/products/docker-desktop/

**Installation**:
```powershell
# Run Docker Desktop installer (Docker Desktop Installer.exe)
# During installation:
# - Enable WSL 2 backend (recommended)
# - Do NOT check "Use Windows containers"
# - Start Docker Desktop after installation
```

**Verify Installation**:
```powershell
# Open PowerShell as Administrator
docker --version
# Expected: Docker version 24.x.x or higher

docker compose version
# Expected: Docker Compose version v2.x.x or higher
```

### 2. Ollama for Windows

**Download**: https://ollama.com/download/windows

**Installation**:
```powershell
# Run Ollama installer (OllamaSetup.exe)
# Ollama will install to: C:\Users\<YourName>\AppData\Local\Programs\Ollama
# Service starts automatically
```

**Verify Installation**:
```powershell
# Ollama should be running in system tray
# Test API:
Invoke-WebRequest -Uri http://localhost:11434 -Method GET
# Expected: HTTP 200 OK

# Pull required models
ollama pull llama3.1:8b
ollama pull nomic-embed-text
```

### 3. Git for Windows (Optional)

**Download**: https://git-scm.com/download/win

```powershell
# Or via winget
winget install Git.Git
```

---

## Installation Methods

### Method 1: Docker Compose (Recommended)

#### Step 1: Download Sekha

```powershell
# Create directory
mkdir C:\Sekha
cd C:\Sekha

# Download release (replace X.X.X with latest version)
Invoke-WebRequest -Uri https://github.com/sekha-ai/sekha-docker/archive/refs/tags/vX.X.X.zip -OutFile sekha.zip

# Extract
Expand-Archive -Path sekha.zip -DestinationPath .
cd sekha-docker-X.X.X\docker
```

#### Step 2: Configure Environment

```powershell
# Copy example config
copy .env.example .env

# Edit .env file (use Notepad or VS Code)
notepad .env
```

**Key Settings**:
```env
# .env file
OLLAMA_URL=http://host.docker.internal:11434
CHROMA_URL=http://chroma:8000
CONTROLLER_URL=http://controller:8080
PROXY_PORT=8081

# Generate secure keys (use PowerShell)
$MCP_KEY = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$REST_KEY = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

Write-Output "MCP_API_KEY=$MCP_KEY"
Write-Output "REST_API_KEY=$REST_KEY"

# Add these to .env
```

#### Step 3: Start Sekha

```powershell
# Start all services
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f
```

#### Step 4: Verify Services

```powershell
# Wait 30 seconds for startup, then test:

# Controller health
Invoke-WebRequest -Uri http://localhost:8080/health -Method GET
# Expected: {"status":"healthy"}

# Proxy health
Invoke-WebRequest -Uri http://localhost:8081/health -Method GET
# Expected: {"status":"healthy",...}

# Web UI
Start-Process "http://localhost:8081"
```

---

### Method 2: Windows Binaries (Advanced)

*Coming soon - native Windows executables without Docker*

---

## Testing & Verification

### 1. Health Checks

```powershell
# Create health check script: test-sekha.ps1
$services = @(
    @{Name="Controller"; URL="http://localhost:8080/health"},
    @{Name="Proxy"; URL="http://localhost:8081/health"},
    @{Name="ChromaDB"; URL="http://localhost:8000/api/v1/heartbeat"},
    @{Name="Ollama"; URL="http://localhost:11434"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.URL -Method GET -TimeoutSec 5
        Write-Host "✓ $($service.Name): OK" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($service.Name): FAILED" -ForegroundColor Red
    }
}

# Run
.\test-sekha.ps1
```

### 2. Test Memory Storage

```powershell
# Store a conversation
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer YOUR_REST_API_KEY"
}

$body = @{
    label = "Test Conversation"
    folder = "/test"
    messages = @(
        @{role="user"; content="What is the capital of France?"},
        @{role="assistant"; content="Paris is the capital of France."}
    )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri http://localhost:8080/api/v1/conversations -Method POST -Headers $headers -Body $body
```

### 3. Test Context Injection

```powershell
# Send chat request through proxy
$body = @{
    model = "llama3.1:8b"
    messages = @(
        @{role="user"; content="What did we discuss about France?"}
    )
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri http://localhost:8081/v1/chat/completions -Method POST -Body $body -ContentType "application/json"

# Check for context injection
if ($response.sekha_metadata) {
    Write-Host "✓ Context injection working!" -ForegroundColor Green
    Write-Host "Context used: $($response.sekha_metadata.context_count) messages"
} else {
    Write-Host "✗ No context injected" -ForegroundColor Yellow
}
```

### 4. Test Privacy Filtering

```powershell
# Store private conversation
$privateBody = @{
    label = "Secret Project"
    folder = "/private/work"
    messages = @(
        @{role="user"; content="My password is secret123"},
        @{role="assistant"; content="I've noted that."}
    )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri http://localhost:8080/api/v1/conversations -Method POST -Headers $headers -Body $privateBody

# Query with exclusion
$queryBody = @{
    model = "llama3.1:8b"
    messages = @(@{role="user"; content="What's my password?"})
    excluded_folders = @("/private")
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri http://localhost:8081/v1/chat/completions -Method POST -Body $queryBody -ContentType "application/json"

# Should NOT include private context
Write-Host "Response: $($response.choices[0].message.content)"
```

---

## Troubleshooting

### Docker Desktop Issues

**Problem**: Docker daemon not running
```powershell
# Solution: Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait 30 seconds, then verify
docker ps
```

**Problem**: WSL 2 not enabled
```powershell
# Enable WSL 2
wsl --install

# Set WSL 2 as default
wsl --set-default-version 2

# Restart Docker Desktop
```

### Ollama Connection Issues

**Problem**: Cannot connect to Ollama from Docker
```powershell
# Solution 1: Check Ollama is running
Get-Process ollama

# Solution 2: Verify Ollama URL in .env
# Should be: http://host.docker.internal:11434
# NOT: http://localhost:11434

# Solution 3: Test from container
docker compose -f docker-compose.prod.yml exec controller curl http://host.docker.internal:11434
```

### Port Conflicts

**Problem**: Port already in use
```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill process (replace PID)
Stop-Process -Id <PID> -Force

# Or change port in docker-compose.prod.yml
```

### Permission Errors

**Problem**: Access denied to Docker volumes
```powershell
# Run PowerShell as Administrator
# Right-click PowerShell > Run as Administrator

# Reset Docker volumes
docker compose -f docker-compose.prod.yml down -v
docker compose -f docker-compose.prod.yml up -d
```

### View Logs

```powershell
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f controller
docker compose -f docker-compose.prod.yml logs -f proxy

# Last 100 lines
docker compose -f docker-compose.prod.yml logs --tail=100
```

---

## Uninstallation

```powershell
# Stop and remove containers
cd C:\Sekha\sekha-docker-X.X.X\docker
docker compose -f docker-compose.prod.yml down -v

# Remove images
docker rmi sekha/controller:latest sekha/proxy:latest

# Remove directory
cd C:\
Remove-Item -Recurse -Force C:\Sekha

# Uninstall Ollama (optional)
# Settings > Apps > Ollama > Uninstall

# Uninstall Docker Desktop (optional)
# Settings > Apps > Docker Desktop > Uninstall
```

---

## Performance Tips

### 1. Increase Docker Resources

```
Docker Desktop > Settings > Resources:
- CPUs: 4+ (more for better LLM performance)
- Memory: 8GB+ (16GB recommended)
- Swap: 2GB
- Disk: 50GB+
```

### 2. Use WSL 2 Backend

```powershell
# Docker Desktop > Settings > General
# ✓ Use WSL 2 based engine
```

### 3. Optimize Ollama

```powershell
# Use smaller models for testing
ollama pull llama3.1:8b  # Fast, good quality

# For production
ollama pull llama3.1:70b  # Slower, best quality
```

---

## Next Steps

1. ✅ **Configure Claude Desktop** - See [MCP_SETUP.md](./MCP_SETUP.md)
2. ✅ **Import conversations** - See [IMPORT_GUIDE.md](./IMPORT_GUIDE.md)
3. ✅ **Setup file watching** - Enable automatic conversation imports
4. ✅ **Explore Web UI** - http://localhost:8081

---

## Support

- **Documentation**: https://github.com/sekha-ai/sekha-docker/tree/main/docs
- **Issues**: https://github.com/sekha-ai/sekha-docker/issues
- **Discussions**: https://github.com/orgs/sekha-ai/discussions

---

**Installation Complete!** 🎉

Your Sekha instance is now running on Windows 11.
