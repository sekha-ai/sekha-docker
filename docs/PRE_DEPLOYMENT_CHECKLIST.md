# Sekha Pre-Deployment Checklist

Complete this checklist before deploying Sekha to ensure all components are tested and ready.

## 💻 Development Environment (Completed)

### Proxy Tests
- ✅ **Unit Tests**: 29 passed
  - context_injection: 16 tests
  - config: 11 tests  
  - health: 7 tests
  - proxy: 2 tests
- ✅ **Coverage**: 83% (exceeds 80% target)
- ✅ **CI Pipeline**: All green
- ✅ **Integration Tests**: Configured (skip when server not running)

### Controller Tests
- ✅ **Unit Tests**: Compiling and passing
- ✅ **Edge Case Tests**: 8 new tests added
  - Empty database handling
  - Budget constraints
  - Privacy filtering
  - Unicode support
  - Metadata enhancement
  - Preferred labels
  - Message truncation
- ✅ **Coverage**: ~83-87% (near 90% target)
- ✅ **CI Pipeline**: Configured

### Docker Tests  
- ✅ **Validation Tests**: 15 tests
  - Docker Compose syntax
  - Required files
  - Documentation completeness
- ✅ **CI Pipeline**: Using Docker Compose v2

---

## 🔧 Pre-Deployment Tasks

### 1. Environment Configuration

```bash
# ☐ Generate API Keys
[] MCP_API_KEY generated (32+ characters)
[] REST_API_KEY generated (32+ characters)
[] Keys stored securely (not in git)

# ☐ Configure .env file
[] OLLAMA_URL set correctly
[] CHROMA_URL set correctly  
[] CONTROLLER_URL set correctly
[] Port mappings verified
[] Database path configured

# ☐ Review docker-compose.prod.yml
[] Volume mounts correct
[] Network configuration valid
[] Resource limits appropriate
[] Restart policies set
```

### 2. System Requirements

**Windows 11 System**:
```powershell
# ☐ Docker Desktop
[] Docker Desktop installed
[] Version 24.x or higher
[] WSL 2 enabled and configured
[] Docker daemon running

# ☐ Ollama
[] Ollama installed
[] Running on port 11434
[] Models downloaded:
   [] llama3.1:8b
   [] nomic-embed-text

# ☐ System Resources
[] CPU: 4+ cores available
[] RAM: 8GB+ available (16GB recommended)
[] Disk: 50GB+ free space
[] Network: Internet access for downloads
```

### 3. Docker Images

```bash
# ☐ Build Images
cd docker

[] Build controller:
   docker compose -f docker-compose.prod.yml build controller
   
[] Build proxy:
   docker compose -f docker-compose.prod.yml build proxy
   
[] Pull dependencies:
   docker compose -f docker-compose.prod.yml pull chroma
   
[] Verify images:
   docker images | grep sekha
```

### 4. Network Verification

```powershell
# ☐ Port Availability
[] Port 8080 free (controller)
[] Port 8081 free (proxy)
[] Port 8000 free (chroma)
[] Port 11434 accessible (ollama)

# Check with:
netstat -ano | findstr "8080 8081 8000 11434"
```

---

## 🚀 Deployment Steps

### 1. Initial Deployment

```powershell
# ☐ Start Services
cd C:\Sekha\sekha-docker\docker

[] Start all services:
   docker compose -f docker-compose.prod.yml up -d
   
[] Wait 30 seconds for initialization

[] Check container status:
   docker compose -f docker-compose.prod.yml ps
   
[] All containers should be "running"
```

### 2. Health Checks

```powershell
# ☐ Service Health
[] Controller health:
   Invoke-WebRequest http://localhost:8080/health
   Expected: {"status":"healthy"}
   
[] Proxy health:
   Invoke-WebRequest http://localhost:8081/health
   Expected: {"status":"healthy"}
   
[] ChromaDB:
   Invoke-WebRequest http://localhost:8000/api/v1/heartbeat
   Expected: HTTP 200
   
[] Ollama:
   Invoke-WebRequest http://localhost:11434
   Expected: HTTP 200
```

### 3. View Logs

```powershell
# ☐ Verify No Errors
[] Controller logs:
   docker compose -f docker-compose.prod.yml logs controller | Select-String -Pattern "ERROR"
   
[] Proxy logs:
   docker compose -f docker-compose.prod.yml logs proxy | Select-String -Pattern "ERROR"
   
[] No critical errors found
```

---

## ✅ Functional Testing

### Test 1: Store Conversation

```powershell
# ☐ Create test conversation
$headers = @{
    "Authorization" = "Bearer YOUR_REST_API_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    label = "Test - Deployment Verification"
    folder = "/test/deployment"
    messages = @(
        @{role="user"; content="What is the capital of France?"},
        @{role="assistant"; content="The capital of France is Paris."}
    )
} | ConvertTo-Json -Depth 5

[] POST request successful:
   $response = Invoke-RestMethod -Uri http://localhost:8080/api/v1/conversations -Method POST -Headers $headers -Body $body
   
[] Response contains conversation ID
[] Conversation stored successfully
```

### Test 2: Context Injection

```powershell
# ☐ Test memory retrieval
$chatBody = @{
    model = "llama3.1:8b"
    messages = @(
        @{role="user"; content="What did we discuss about France?"}
    )
} | ConvertTo-Json -Depth 5

[] Send chat request:
   $response = Invoke-RestMethod -Uri http://localhost:8081/v1/chat/completions -Method POST -Body $chatBody -ContentType "application/json"
   
[] Response includes sekha_metadata
[] sekha_metadata.context_count > 0
[] Assistant references previous conversation
[] Context injection working!
```

### Test 3: Privacy Filtering

```powershell
# ☐ Store private conversation
$privateBody = @{
    label = "Private Test"
    folder = "/private/secrets"
    messages = @(
        @{role="user"; content="My secret code is ABC123"},
        @{role="assistant"; content="I've recorded that."}
    )
} | ConvertTo-Json -Depth 5

[] Store private conversation:
   Invoke-RestMethod -Uri http://localhost:8080/api/v1/conversations -Method POST -Headers $headers -Body $privateBody

# ☐ Query with exclusion
$queryBody = @{
    model = "llama3.1:8b"
    messages = @(@{role="user"; content="What's my secret code?"})
    excluded_folders = @("/private")
} | ConvertTo-Json -Depth 5

[] Send query with exclusion:
   $response = Invoke-RestMethod -Uri http://localhost:8081/v1/chat/completions -Method POST -Body $queryBody -ContentType "application/json"
   
[] Response does NOT include private info
[] Privacy filtering working!
```

### Test 4: Web UI

```powershell
# ☐ Access Web Interface
[] Open browser: http://localhost:8081
[] UI loads successfully
[] Can view conversations
[] Can search conversations
[] Settings page accessible
[] Web UI functional!
```

### Test 5: Performance

```powershell
# ☐ Load Test (optional)
[] Send 10 chat requests
[] Average response time < 5 seconds
[] No errors or timeouts
[] System stable under load
```

---

## 🛡️ Security Verification

```bash
# ☐ API Key Protection
[] API keys not in docker-compose.yml
[] API keys not in git repository
[] .env file in .gitignore
[] Unauthorized requests rejected (401)

# ☐ Network Security
[] Only necessary ports exposed
[] Internal services on docker network
[] No sensitive data in logs

# ☐ Data Privacy
[] Excluded folders respected
[] Private data not in context
[] Conversation isolation working
```

---

## 📊 Monitoring Setup

```powershell
# ☐ Health Monitoring
[] Create health check script
[] Schedule periodic checks
[] Alert on service failures

# ☐ Log Rotation
[] Docker log limits configured
[] Old logs archived/deleted
[] Disk space monitored

# ☐ Backup Strategy
[] Database backup location defined
[] Backup schedule created
[] Restore procedure tested
```

---

## 📄 Documentation

```bash
# ☐ User Documentation
[] README.md reviewed
[] WINDOWS_INSTALL.md complete
[] MCP_SETUP.md available
[] TROUBLESHOOTING.md available

# ☐ Configuration Examples
[] .env.example provided
[] Sample docker-compose files
[] Example API calls documented

# ☐ Architecture Documentation
[] ARCHITECTURE.md explains design
[] Component interactions documented
[] API endpoints documented
```

---

## ✅ Ready for Production?

**Before declaring "production ready":**

```
☐ All tests pass
☐ All functional tests complete
☐ Security verified
☐ Documentation complete
☐ Monitoring configured
☐ Backup strategy in place
☐ User training completed
☐ Rollback plan documented
```

---

## 🔄 Rollback Plan

If deployment fails:

```powershell
# 1. Stop services
docker compose -f docker-compose.prod.yml down

# 2. Backup current data
copy .\data .\data.backup

# 3. Restore previous version
# (Re-deploy from previous release tag)

# 4. Verify health
# (Run health checks)

# 5. Notify users
# (Communication plan)
```

---

## 👥 Post-Deployment

```bash
# ☐ User Onboarding
[] Users have access credentials
[] Training materials provided
[] Support channel established
[] Feedback mechanism in place

# ☐ Maintenance Plan
[] Update schedule defined
[] Maintenance windows communicated
[] Emergency contact list created
```

---

## 🎉 Deployment Complete!

Once all items are checked:

1. ✅ **Document deployment date and version**
2. ✅ **Archive this checklist with notes**
3. ✅ **Begin user onboarding**
4. ✅ **Monitor for 24-48 hours**
5. ✅ **Celebrate! 🎉**

---

**Next Steps**: [MCP_SETUP.md](./MCP_SETUP.md) for Claude Desktop integration
