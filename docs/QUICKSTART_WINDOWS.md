# Sekha - Quick Start (Windows 11)

**Get Sekha running in 10 minutes!**

---

## Prerequisites

### 1. Install Docker Desktop

**Download**: https://www.docker.com/products/docker-desktop/

1. Run the installer
2. Enable WSL 2 when prompted
3. Start Docker Desktop
4. Wait for "Docker Desktop is running" in system tray

### 2. Install Ollama

**Download**: https://ollama.com/download/windows

1. Run the installer  
2. Ollama will start automatically (check system tray)
3. Pull required models:

```powershell
# Open PowerShell
ollama pull llama3.1:8b
ollama pull nomic-embed-text
```

---

## Installation

### Step 1: Download Sekha

```powershell
# Create directory
mkdir C:\Sekha
cd C:\Sekha

# Download latest release
Invoke-WebRequest -Uri https://github.com/sekha-ai/sekha-docker/archive/refs/heads/main.zip -OutFile sekha.zip

# Extract
Expand-Archive -Path sekha.zip -DestinationPath .
cd sekha-docker-main\docker
```

### Step 2: Configure API Keys

```powershell
# Copy example config
copy .env.example .env

# Generate secure API keys
$MCP_KEY = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$REST_KEY = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})

Write-Output "Copy these to your .env file:"
Write-Output "MCP_API_KEY=$MCP_KEY"
Write-Output "REST_API_KEY=$REST_KEY"

# Edit .env file
notepad .env
```

**In .env file**:
1. Replace `MCP_API_KEY=CHANGE_ME...` with your generated key
2. Replace `REST_API_KEY=CHANGE_ME...` with your generated key
3. Verify `OLLAMA_URL=http://host.docker.internal:11434`
4. Save and close

### Step 3: Clone Source Repositories (For Local Build)

```powershell
# Go back to C:\Sekha
cd C:\Sekha

# Clone controller
git clone https://github.com/sekha-ai/sekha-controller.git

# Clone proxy
git clone https://github.com/sekha-ai/sekha-proxy.git

# Your structure should be:
# C:\Sekha\
#   sekha-docker-main\
#   sekha-controller\
#   sekha-proxy\
```

### Step 4: Start Sekha

```powershell
# Go to docker directory
cd C:\Sekha\sekha-docker-main\docker

# Start all services (builds images first time)
docker compose -f docker-compose.local.yml up -d

# Watch logs (Ctrl+C to exit)
docker compose -f docker-compose.local.yml logs -f
```

**Wait ~2-3 minutes for first-time build and startup**

### Step 5: Verify It's Working

```powershell
# Check services
docker compose -f docker-compose.local.yml ps

# All should show "Up" and "healthy"

# Test controller
Invoke-WebRequest -Uri http://localhost:8080/health
# Expected: {"status":"ok"...}

# Test proxy
Invoke-WebRequest -Uri http://localhost:8081/health
# Expected: {"status":"healthy"...}

# Open Web UI
Start-Process "http://localhost:8081"
```

---

## Quick Test

### Store a Conversation

```powershell
# Create test-sekha.ps1
@'
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer YOUR_REST_API_KEY_HERE"
}

$body = @{
    label = "First Test"
    folder = "/test"
    messages = @(
        @{role="user"; content="What is the capital of France?"},
        @{role="assistant"; content="Paris is the capital of France."}
    )
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri http://localhost:8080/api/v1/conversations -Method POST -Headers $headers -Body $body
Write-Host "Stored conversation ID: $($response.id)" -ForegroundColor Green
'@ | Out-File test-sekha.ps1

# Edit the script to add your REST_API_KEY
notepad test-sekha.ps1

# Run test
.\test-sekha.ps1
```

### Test Context Injection

```powershell
# Send chat request
$chatBody = @{
    model = "llama3.1:8b"
    messages = @(
        @{role="user"; content="What did we discuss about France?"}
    )
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri http://localhost:8081/v1/chat/completions -Method POST -Body $chatBody -ContentType "application/json"

if ($response.sekha_metadata) {
    Write-Host "✓ Context injection working!" -ForegroundColor Green
    Write-Host "Context used: $($response.sekha_metadata.context_count) messages"
    Write-Host "Response: $($response.choices[0].message.content)"
} else {
    Write-Host "✗ No context injected" -ForegroundColor Yellow
}
```

---

## Common Issues

### "Cannot find path .env.example"
**Fix**: Make sure you're in `C:\Sekha\sekha-docker-main\docker` directory

### "denied: error from registry"
**Fix**: Use `docker-compose.local.yml` instead of `docker-compose.prod.yml`

### "Cannot connect to Ollama"
**Fix**: 
1. Check Ollama is running (system tray)
2. Test: `Invoke-WebRequest http://localhost:11434`
3. Verify `.env` has `OLLAMA_URL=http://host.docker.internal:11434`

### "Port already in use"
```powershell
# Find what's using the port
netstat -ano | findstr :8080

# Kill the process (replace PID)
Stop-Process -Id <PID> -Force

# Or change port in .env
```

### "Build failed" or "Context does not exist"
**Fix**: Make sure you cloned sekha-controller and sekha-proxy to `C:\Sekha\`

---

## Stopping/Restarting

```powershell
# Stop all services
cd C:\Sekha\sekha-docker-main\docker
docker compose -f docker-compose.local.yml down

# Start again
docker compose -f docker-compose.local.yml up -d

# Restart just one service
docker compose -f docker-compose.local.yml restart proxy

# View logs
docker compose -f docker-compose.local.yml logs -f controller
docker compose -f docker-compose.local.yml logs -f proxy
```

---

## Next Steps

- **✅ Configure Claude Desktop**: See [MCP_SETUP.md](./MCP_SETUP.md)
- **✅ Explore Web UI**: http://localhost:8081
- **✅ Import conversations**: See [IMPORT_GUIDE.md](./IMPORT_GUIDE.md)
- **✅ Setup file watching**: Auto-import conversations

---

## Getting Help

- **Full Manual Install**: [WINDOWS_INSTALL.md](./WINDOWS_INSTALL.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- **Issues**: https://github.com/sekha-ai/sekha-docker/issues

---

**🎉 You're all set!** Sekha is now running on your Windows 11 machine.
