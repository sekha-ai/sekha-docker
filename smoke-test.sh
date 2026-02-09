#!/bin/bash
# Sekha v0.2.0 Smoke Test
# Quick validation before launch

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "🔥 Sekha v0.2.0 Smoke Test"
echo "==========================="
echo ""

# Configuration
PROXY_URL="${PROXY_URL:-http://localhost:8081}"
BRIDGE_URL="${BRIDGE_URL:-http://localhost:5001}"
CONTROLLER_URL="${CONTROLLER_URL:-http://localhost:8080}"

echo "Testing endpoints:"
echo "  Proxy:      $PROXY_URL"
echo "  Bridge:     $BRIDGE_URL"
echo "  Controller: $CONTROLLER_URL"
echo ""

# Function to check if services are running
check_services() {
    echo "📦 Checking if services are running..."
    if ! docker compose -f docker/docker-compose.prod.yml ps | grep -q "Up"; then
        echo -e "${RED}❌ Services not running. Start with:${NC}"
        echo "   docker compose -f docker/docker-compose.prod.yml up -d"
        exit 1
    fi
    echo -e "${GREEN}✅ Services are running${NC}"
    echo ""
}

# Wait for services to be healthy
wait_for_health() {
    echo "⏳ Waiting for services to be healthy (max 60s)..."
    
    MAX_WAIT=60
    WAITED=0
    
    while [ $WAITED -lt $MAX_WAIT ]; do
        if curl -sf "$PROXY_URL/health" > /dev/null 2>&1 && \
           curl -sf "$BRIDGE_URL/health" > /dev/null 2>&1 && \
           curl -sf "$CONTROLLER_URL/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ All services healthy${NC}"
            echo ""
            return 0
        fi
        
        echo -n "."
        sleep 2
        WAITED=$((WAITED + 2))
    done
    
    echo -e "${RED}❌ Services failed to become healthy${NC}"
    exit 1
}

# Test health endpoints
test_health() {
    echo "🏥 Testing health endpoints..."
    
    # Proxy health
    echo -n "  Proxy:      "
    if RESPONSE=$(curl -sf "$PROXY_URL/health" 2>&1); then
        if echo "$RESPONSE" | jq -e '.status == "healthy" or .status == "degraded"' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Healthy${NC}"
        else
            echo -e "${YELLOW}⚠️  Degraded${NC}"
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    # Bridge health
    echo -n "  Bridge:     "
    if RESPONSE=$(curl -sf "$BRIDGE_URL/health" 2>&1); then
        if echo "$RESPONSE" | jq -e '.status == "healthy" or .status == "degraded"' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Healthy${NC}"
        else
            echo -e "${YELLOW}⚠️  Degraded${NC}"
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    # Controller health
    echo -n "  Controller: "
    if RESPONSE=$(curl -sf "$CONTROLLER_URL/health" 2>&1); then
        if echo "$RESPONSE" | jq -e '.status == "healthy" or .status == "ok"' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Healthy${NC}"
        else
            echo -e "${YELLOW}⚠️  Degraded${NC}"
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    echo ""
}

# Test bridge routing
test_routing() {
    echo "🎯 Testing bridge routing..."
    
    # Test route endpoint
    echo -n "  Chat routing:  "
    if RESPONSE=$(curl -sf -X POST "$BRIDGE_URL/api/v1/route" \
        -H "Content-Type: application/json" \
        -d '{"task": "chat_small"}' 2>&1); then
        
        if echo "$RESPONSE" | jq -e '.model_id and .provider_id' > /dev/null 2>&1; then
            MODEL=$(echo "$RESPONSE" | jq -r '.model_id')
            PROVIDER=$(echo "$RESPONSE" | jq -r '.provider_id')
            echo -e "${GREEN}✅ $PROVIDER/$MODEL${NC}"
        else
            echo -e "${RED}❌ Invalid response${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    # Test model listing
    echo -n "  Model list:    "
    if RESPONSE=$(curl -sf "$BRIDGE_URL/api/v1/models" 2>&1); then
        MODEL_COUNT=$(echo "$RESPONSE" | jq 'length')
        if [ "$MODEL_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✅ $MODEL_COUNT models available${NC}"
        else
            echo -e "${RED}❌ No models found${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    echo ""
}

# Test chat completion
test_chat() {
    echo "💬 Testing chat completion..."
    
    echo -n "  End-to-end:    "
    if RESPONSE=$(curl -sf -X POST "$PROXY_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d '{
            "messages": [
                {"role": "user", "content": "Reply with exactly: TEST_OK"}
            ],
            "temperature": 0.1
        }' 2>&1); then
        
        # Check for valid response structure
        if echo "$RESPONSE" | jq -e '.choices[0].message.content' > /dev/null 2>&1; then
            # Check for routing metadata (v0.2.0)
            if echo "$RESPONSE" | jq -e '.sekha_metadata.routing' > /dev/null 2>&1; then
                PROVIDER=$(echo "$RESPONSE" | jq -r '.sekha_metadata.routing.provider_id')
                MODEL=$(echo "$RESPONSE" | jq -r '.sekha_metadata.routing.model_id')
                COST=$(echo "$RESPONSE" | jq -r '.sekha_metadata.routing.estimated_cost')
                echo -e "${GREEN}✅ Success ($PROVIDER/$MODEL, \$$COST)${NC}"
            else
                echo -e "${YELLOW}⚠️  Missing routing metadata${NC}"
            fi
        else
            echo -e "${RED}❌ Invalid response structure${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    echo ""
}

# Test web UI
test_web_ui() {
    echo "🌐 Testing web UI..."
    
    echo -n "  Static files:  "
    if curl -sf "$PROXY_URL/static/index.html" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Not accessible${NC}"
    fi
    
    echo -n "  API info:      "
    if RESPONSE=$(curl -sf "$PROXY_URL/api/info" 2>&1); then
        VERSION=$(echo "$RESPONSE" | jq -r '.version')
        if [ "$VERSION" = "0.2.0" ]; then
            echo -e "${GREEN}✅ v$VERSION${NC}"
        else
            echo -e "${YELLOW}⚠️  Version mismatch: $VERSION${NC}"
        fi
    else
        echo -e "${RED}❌ Failed${NC}"
        exit 1
    fi
    
    echo ""
}

# Main execution
main() {
    # Check dependencies
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is required but not installed${NC}"
        echo "   Install: apt-get install jq (or brew install jq on Mac)"
        exit 1
    fi
    
    # Run tests
    check_services
    wait_for_health
    test_health
    test_routing
    test_chat
    test_web_ui
    
    # Summary
    echo "=""========================="
    echo -e "${GREEN}🎉 All smoke tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Open web UI: $PROXY_URL"
    echo "  2. Test chat functionality"
    echo "  3. Check logs: docker compose -f docker/docker-compose.prod.yml logs -f"
    echo "  4. Ready for launch! 🚀"
    echo ""
}

# Run
main
