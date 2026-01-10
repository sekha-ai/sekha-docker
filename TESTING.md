# Comprehensive Testing Strategy

**Goal**: Achieve 90% test coverage across all repositories with focus on controller as the most critical component.

## Testing Priority

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  1. Controller (HIGHEST)    ┃  90% coverage target
┃     - Core business logic    ┃
┃     - 4-phase assembly       ┃
┃     - Privacy filtering      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  2. Proxy (HIGH)            ┃  80% coverage target
┃     - Context injection     ┃
┃     - API compatibility     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  3. Integration (MEDIUM)    ┃  Full stack E2E
┃     - Memory continuity     ┃
┃     - Privacy filtering     ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
         │
         ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  4. Performance (MEDIUM)    ┃  Baseline metrics
┃     - Latency < 100ms       ┃
┃     - Throughput > 100 rps  ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## Phase 1: Controller Unit Tests (Days 1-2)

**Repository**: `sekha-controller`

**Target**: 90% coverage

### Current Status
```bash
cd sekha-controller
cargo test --all-features
cargo tarpaulin --out Html --output-dir coverage
```

### Test Categories

#### 1.1 Context Assembly (CRITICAL)

**File**: `src/context/assembly.rs`

- [x] Phase 1: Recall
  - [x] Semantic search returns candidates
  - [x] Pinned messages included
  - [x] Recent messages included
  - [ ] **TODO**: Empty database handling
  - [ ] **TODO**: Large dataset (1M+ messages)

- [x] Phase 2: Rank
  - [x] Composite scoring works
  - [x] Label matching bonus
  - [ ] **TODO**: Recency decay over time
  - [ ] **TODO**: Importance override

- [x] Phase 3: Assemble
  - [x] Token budget respected
  - [x] Message ordering preserved
  - [ ] **TODO**: Budget edge cases (0, negative, huge)
  - [ ] **TODO**: Message truncation

- [ ] Phase 4: Enhance
  - [ ] **TODO**: Citations added correctly
  - [ ] **TODO**: Summaries generated
  - [ ] **TODO**: Metadata enrichment

**Commands**:
```bash
# Run assembly tests
cargo test context::assembly --features test-utils

# With coverage
cargo tarpaulin --features test-utils --lib context::assembly
```

#### 1.2 Privacy Filtering (CRITICAL)

**File**: `src/privacy/filter.rs`

- [x] Exclude exact folder match
- [x] Exclude folder prefix (subfolders)
- [ ] **TODO**: Case sensitivity
- [ ] **TODO**: Empty exclusion list
- [ ] **TODO**: Wildcard patterns
- [ ] **TODO**: Performance with large exclusion lists

**Test Cases**:
```rust
#[test]
fn test_privacy_exact_match() {
    // Exclude /private
    assert!(should_exclude("/private", vec!["/private"]));
}

#[test]
fn test_privacy_prefix_match() {
    // Exclude /private/secrets when /private excluded
    assert!(should_exclude("/private/secrets", vec!["/private"]));
}

#[test]
fn test_privacy_no_match() {
    // /work not excluded
    assert!(!should_exclude("/work", vec!["/private"]));
}
```

**Commands**:
```bash
cargo test privacy --features test-utils
```

#### 1.3 API Endpoints (HIGH)

**Files**: `src/api/*.rs`

- [ ] **TODO**: POST /api/v1/conversations
- [ ] **TODO**: GET /api/v1/conversations
- [ ] **TODO**: POST /api/v1/context/assemble
- [ ] **TODO**: GET /health
- [ ] **TODO**: Error handling (400, 404, 500)
- [ ] **TODO**: Authentication

**Commands**:
```bash
cargo test api --features test-utils
```

#### 1.4 Database Operations (MEDIUM)

**File**: `src/storage/*.rs`

- [ ] **TODO**: Insert conversation
- [ ] **TODO**: Query by folder
- [ ] **TODO**: Query by date range
- [ ] **TODO**: Update metadata
- [ ] **TODO**: Delete conversation
- [ ] **TODO**: Transaction handling

#### 1.5 Vector Store (MEDIUM)

**File**: `src/vector/*.rs`

- [ ] **TODO**: Embed text
- [ ] **TODO**: Similarity search
- [ ] **TODO**: Batch operations
- [ ] **TODO**: ChromaDB connection handling

### Coverage Goals

| Module | Current | Target | Priority |
|--------|---------|--------|----------|
| context/assembly | 75% | 95% | CRITICAL |
| privacy/filter | 85% | 95% | CRITICAL |
| api/* | 60% | 85% | HIGH |
| storage/* | 70% | 80% | MEDIUM |
| vector/* | 65% | 75% | MEDIUM |
| **Overall** | **70%** | **90%** | |

---

## Phase 2: Proxy Unit Tests (Days 3-4)

**Repository**: `sekha-proxy`

**Target**: 80% coverage

### Current Status
```bash
cd sekha-proxy
pytest tests/ -v --cov --cov-report=html
```

**Current**: 19 tests passing in `context_injection.py`

### Test Categories

#### 2.1 Context Injection (HIGH)

**File**: `context_injection.py`

- [x] Extract last user message (19 tests)
- [x] Inject context into system prompt
- [x] Generate labels
- [x] Build metadata
- [ ] **TODO**: Empty context handling
- [ ] **TODO**: Large context (>10K tokens)
- [ ] **TODO**: Unicode/emoji handling

**Commands**:
```bash
pytest tests/test_context_injection.py -v
```

#### 2.2 Health Monitoring (HIGH)

**File**: `health.py`

- [ ] **TODO**: Check controller connectivity
- [ ] **TODO**: Check LLM connectivity
- [ ] **TODO**: Timeout handling
- [ ] **TODO**: Partial failures

**Test Cases**:
```python
@pytest.mark.asyncio
async def test_health_all_services_up():
    monitor = HealthMonitor(...)
    status = await monitor.check_all()
    assert status["status"] == "healthy"

@pytest.mark.asyncio
async def test_health_controller_down():
    # Mock controller as down
    status = await monitor.check_all()
    assert status["status"] == "unhealthy"
    assert "controller" in status["details"]
```

#### 2.3 Configuration (MEDIUM)

**File**: `config.py`

- [ ] **TODO**: Load from environment
- [ ] **TODO**: Validate required fields
- [ ] **TODO**: Default values
- [ ] **TODO**: Invalid values rejected

#### 2.4 Proxy Logic (HIGH)

**File**: `proxy.py`

- [ ] **TODO**: Forward request to controller
- [ ] **TODO**: Forward request to LLM
- [ ] **TODO**: Handle LLM errors
- [ ] **TODO**: Store conversation async
- [ ] **TODO**: Add metadata to response

### Coverage Goals

| Module | Current | Target | Priority |
|--------|---------|--------|----------|
| context_injection.py | 85% | 90% | HIGH |
| health.py | 0% | 80% | HIGH |
| config.py | 50% | 75% | MEDIUM |
| proxy.py | 40% | 80% | HIGH |
| **Overall** | **55%** | **80%** | |

---

## Phase 3: Integration Tests (Days 5-6)

**Repository**: `sekha-docker/tests`

### 3.1 Full Stack Deployment

**File**: `tests/test_integration.py`

```python
import pytest
import requests
import docker
import time

class TestFullStack:
    @classmethod
    def setup_class(cls):
        """Start all services via docker-compose"""
        client = docker.from_env()
        # Start stack
        subprocess.run([
            "docker-compose", "-f", "docker/docker-compose.prod.yml", "up", "-d"
        ])
        # Wait for health
        for _ in range(30):
            try:
                r = requests.get("http://localhost:8081/health")
                if r.json()["status"] == "healthy":
                    break
            except:
                time.sleep(2)
    
    def test_memory_continuity(self):
        """Test AI remembers across sessions"""
        # Session 1: Store fact
        r1 = requests.post("http://localhost:8081/v1/chat/completions", json={
            "messages": [{"role": "user", "content": "I use PostgreSQL"}],
            "folder": "/test"
        })
        assert r1.status_code == 200
        
        # Wait for storage
        time.sleep(2)
        
        # Session 2: Recall fact
        r2 = requests.post("http://localhost:8081/v1/chat/completions", json={
            "messages": [{"role": "user", "content": "What database do I use?"}],
            "folder": "/test"
        })
        assert r2.status_code == 200
        response = r2.json()["choices"][0]["message"]["content"]
        assert "PostgreSQL" in response or "postgres" in response.lower()
    
    def test_privacy_filtering(self):
        """Test excluded folders not recalled"""
        # Store in /private
        r1 = requests.post("http://localhost:8081/v1/chat/completions", json={
            "messages": [{"role": "user", "content": "My secret is ABC123"}],
            "folder": "/private"
        })
        assert r1.status_code == 200
        
        time.sleep(2)
        
        # Query with exclusion
        r2 = requests.post("http://localhost:8081/v1/chat/completions", json={
            "messages": [{"role": "user", "content": "What is my secret?"}],
            "excluded_folders": ["/private"]
        })
        assert r2.status_code == 200
        response = r2.json()["choices"][0]["message"]["content"]
        assert "ABC123" not in response
    
    def test_web_ui_loads(self):
        """Test Web UI is accessible"""
        r = requests.get("http://localhost:8081/")
        assert r.status_code == 200
        assert "Sekha Proxy" in r.text
    
    @classmethod
    def teardown_class(cls):
        """Stop all services"""
        subprocess.run([
            "docker-compose", "-f", "docker/docker-compose.prod.yml", "down"
        ])
```

**Commands**:
```bash
pytest tests/test_integration.py -v -s
```

### 3.2 API Compatibility

**File**: `tests/test_openai_compat.py`

```python
def test_openai_client_compatibility():
    """Test OpenAI SDK works with proxy"""
    from openai import OpenAI
    
    client = OpenAI(base_url="http://localhost:8081")
    response = client.chat.completions.create(
        model="llama2",
        messages=[{"role": "user", "content": "Hello"}]
    )
    assert response.choices[0].message.content
```

---

## Phase 4: Performance Tests (Day 7)

**Repository**: `sekha-docker/tests`

### 4.1 Latency Benchmarks

**File**: `tests/test_performance.py`

```python
import pytest
import requests
import time
import statistics

def test_context_retrieval_latency():
    """Context retrieval should be < 100ms"""
    latencies = []
    for _ in range(100):
        start = time.time()
        requests.post("http://localhost:8080/api/v1/context/assemble", json={
            "query": "test",
            "context_budget": 4000
        })
        latencies.append((time.time() - start) * 1000)
    
    avg = statistics.mean(latencies)
    p95 = statistics.quantiles(latencies, n=20)[18]
    
    assert avg < 100, f"Average latency {avg}ms exceeds 100ms"
    assert p95 < 200, f"P95 latency {p95}ms exceeds 200ms"

def test_proxy_overhead():
    """Proxy overhead should be < 10ms"""
    # Measure direct LLM
    start = time.time()
    requests.post("http://localhost:5001/v1/chat/completions", ...)
    direct_time = time.time() - start
    
    # Measure via proxy
    start = time.time()
    requests.post("http://localhost:8081/v1/chat/completions", ...)
    proxy_time = time.time() - start
    
    overhead = (proxy_time - direct_time) * 1000
    assert overhead < 10, f"Proxy overhead {overhead}ms exceeds 10ms"
```

### 4.2 Load Testing

**Tool**: `locust` or `k6`

```python
# locustfile.py
from locust import HttpUser, task, between

class ProxyUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def chat_with_memory(self):
        self.client.post("/v1/chat/completions", json={
            "messages": [{"role": "user", "content": "Hello"}]
        })
```

**Commands**:
```bash
locust -f tests/locustfile.py --host http://localhost:8081
```

**Target**: > 100 requests/second

---

## Phase 5: Fix CI/CD (Parallel)

### All Repositories

#### 5.1 Linting

```bash
# Python (proxy)
ruff format .
ruff check --fix .

# Rust (controller)
cargo fmt
cargo clippy --fix --allow-dirty
```

#### 5.2 Type Checking

```bash
# Python
mypy . --strict

# Rust
cargo check --all-features
```

#### 5.3 Test Runs

```bash
# Ensure all tests pass
cargo test --all-features
pytest tests/ -v
```

---

## Summary: Test Execution Plan

### Week 1 Schedule

| Day | Focus | Commands | Expected Outcome |
|-----|-------|----------|------------------|
| **Mon** | Controller tests | `cargo test --all` | 85% → 90% coverage |
| **Tue** | Proxy tests | `pytest tests/ --cov` | 55% → 80% coverage |
| **Wed** | Integration tests | `pytest tests/test_integration.py` | All scenarios pass |
| **Thu** | Privacy testing | Manual + automated | 100% privacy scenarios |
| **Fri** | Performance | `pytest tests/test_performance.py` | Baselines established |
| **Sat** | CI/CD fixes | `ruff`, `mypy`, `clippy` | Green builds |
| **Sun** | Documentation | Review all READMEs | Complete & accurate |

### Success Criteria

- ✅ Controller: 90% coverage
- ✅ Proxy: 80% coverage
- ✅ Integration: All scenarios pass
- ✅ Performance: Meets benchmarks
- ✅ CI/CD: All builds green
- ✅ Documentation: Complete

---

## Quick Commands

### Run All Tests

```bash
# Controller
cd sekha-controller && cargo test --all-features

# Proxy
cd sekha-proxy && pytest tests/ -v --cov

# Integration
cd sekha-docker && pytest tests/ -v
```

### Generate Coverage Reports

```bash
# Controller (HTML)
cargo tarpaulin --out Html --output-dir coverage
open coverage/index.html

# Proxy (HTML)
pytest tests/ --cov --cov-report=html
open htmlcov/index.html
```

### Run Specific Test Suites

```bash
# Privacy tests only
cargo test privacy
pytest tests/ -k privacy

# Context assembly only
cargo test context::assembly
pytest tests/test_context_injection.py
```

---

**Let's achieve 90% coverage and ship a bulletproof system!** 🚀
