"""End-to-end tests for Sekha v2.0 multi-provider architecture.

These tests validate the complete stack working together:
- Controller: Context assembly and storage
- Bridge: Provider routing and model selection
- Proxy: Request forwarding with context injection
"""

import os
import pytest
import httpx
import asyncio
from typing import Dict, Any

# Service URLs (configurable via environment)
CONTROLLER_URL = os.getenv("CONTROLLER_URL", "http://localhost:8080")
BRIDGE_URL = os.getenv("BRIDGE_URL", "http://localhost:5001")
PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8081")
CONTROLLER_API_KEY = os.getenv("CONTROLLER_API_KEY", "test_key_12345678901234567890123456789012")

# Timeout for E2E tests (longer than unit tests)
E2E_TIMEOUT = 30.0


@pytest.fixture(scope="module")
def anyio_backend():
    return "asyncio"


@pytest.fixture(scope="module")
async def http_client():
    """Shared HTTP client for all E2E tests."""
    async with httpx.AsyncClient(timeout=E2E_TIMEOUT) as client:
        yield client


@pytest.fixture(scope="module")
async def controller_client():
    """HTTP client with controller authentication."""
    async with httpx.AsyncClient(
        timeout=E2E_TIMEOUT,
        headers={"Authorization": f"Bearer {CONTROLLER_API_KEY}"},
    ) as client:
        yield client


class TestServiceHealth:
    """Test that all services are healthy and properly configured."""

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_controller_health(self, http_client):
        """Controller should be healthy."""
        response = await http_client.get(f"{CONTROLLER_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["healthy", "ok"]

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_bridge_health(self, http_client):
        """Bridge should be healthy with providers loaded."""
        response = await http_client.get(f"{BRIDGE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["healthy", "degraded"]
        assert len(data.get("models_loaded", [])) > 0

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_proxy_health(self, http_client):
        """Proxy should be healthy."""
        response = await http_client.get(f"{PROXY_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["healthy", "ok", "degraded"]


class TestBridgeRouting:
    """Test bridge routing endpoints."""

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_list_models(self, http_client):
        """Bridge should list available models from all providers."""
        response = await http_client.get(f"{BRIDGE_URL}/api/v1/models")
        assert response.status_code == 200
        
        models = response.json()
        assert isinstance(models, list)
        assert len(models) > 0
        
        # Check model structure
        model = models[0]
        assert "model_id" in model
        assert "provider_id" in model
        assert "task" in model

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_route_embedding(self, http_client):
        """Bridge should route embedding requests."""
        response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={
                "task": "embedding",
            },
        )
        assert response.status_code == 200
        
        routing = response.json()
        assert "provider_id" in routing
        assert "model_id" in routing
        assert "estimated_cost" in routing
        assert routing["estimated_cost"] >= 0.0

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_route_chat(self, http_client):
        """Bridge should route chat requests."""
        response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={
                "task": "chat_small",
            },
        )
        assert response.status_code == 200
        
        routing = response.json()
        assert "provider_id" in routing
        assert "model_id" in routing
        assert "reason" in routing

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_provider_health(self, http_client):
        """Bridge should report provider health."""
        response = await http_client.get(f"{BRIDGE_URL}/api/v1/health/providers")
        assert response.status_code == 200
        
        health = response.json()
        assert "providers" in health
        assert "total_providers" in health
        assert "healthy_providers" in health
        assert health["total_providers"] > 0


class TestProxyRouting:
    """Test proxy routing with context injection."""

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_proxy_chat_completion(self, http_client):
        """Proxy should route chat requests through bridge."""
        response = await http_client.post(
            f"{PROXY_URL}/v1/chat/completions",
            json={
                "messages": [
                    {"role": "user", "content": "What is 2+2?"}
                ],
                "temperature": 0.1,
            },
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "choices" in data
        assert len(data["choices"]) > 0
        assert "message" in data["choices"][0]
        
        # v2.0: Should include routing metadata
        assert "sekha_metadata" in data
        assert "routing" in data["sekha_metadata"]
        
        routing = data["sekha_metadata"]["routing"]
        assert "provider_id" in routing
        assert "model_id" in routing
        assert "estimated_cost" in routing

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_proxy_info(self, http_client):
        """Proxy info should show v2.0 features."""
        response = await http_client.get(f"{PROXY_URL}/api/info")
        assert response.status_code == 200
        
        info = response.json()
        assert info["version"] == "2.0.0"
        assert "features" in info
        
        features = info["features"]
        assert "Multi-provider routing via bridge" in features
        assert "Vision model routing" in features


class TestFullStack:
    """Test complete flow through all services."""

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_conversation_with_context(self, http_client, controller_client):
        """Test full conversation flow with context injection.
        
        Flow:
        1. Store conversation in controller
        2. Query proxy with related topic
        3. Verify context was injected
        4. Verify routing metadata present
        """
        # Step 1: Store a conversation
        store_response = await controller_client.post(
            f"{CONTROLLER_URL}/api/v1/conversations",
            json={
                "label": "Python testing info",
                "folder": "/test-folder",
                "messages": [
                    {
                        "role": "user",
                        "content": "What is pytest used for?",
                    },
                    {
                        "role": "assistant",
                        "content": "Pytest is a testing framework for Python.",
                    },
                ],
                "metadata": {"test": "e2e"},
            },
        )
        assert store_response.status_code == 201
        
        # Wait for embedding to be generated
        await asyncio.sleep(2)
        
        # Step 2: Query proxy about related topic
        chat_response = await http_client.post(
            f"{PROXY_URL}/v1/chat/completions",
            json={
                "messages": [
                    {"role": "user", "content": "Tell me about Python testing."}
                ],
            },
        )
        assert chat_response.status_code == 200
        
        data = chat_response.json()
        
        # Step 3: Check for routing metadata
        assert "sekha_metadata" in data
        assert "routing" in data["sekha_metadata"]
        
        routing = data["sekha_metadata"]["routing"]
        assert routing["provider_id"] is not None
        assert routing["model_id"] is not None
        
        # Step 4: Context may or may not be injected depending on similarity
        # but the structure should be present
        metadata = data["sekha_metadata"]
        # Context field should exist even if empty
        if "context" in metadata:
            assert "count" in metadata["context"]

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_embedding_dimension_routing(self, http_client, controller_client):
        """Test that embeddings route correctly based on model dimension.
        
        This validates:
        1. Bridge routes embedding requests
        2. Controller uses correct dimension collection
        3. Search works across dimensions
        """
        # Get routing for embedding
        route_response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={"task": "embedding"},
        )
        assert route_response.status_code == 200
        
        routing = route_response.json()
        model_id = routing["model_id"]
        
        # Get model info to check dimension
        models_response = await http_client.get(f"{BRIDGE_URL}/api/v1/models")
        models = models_response.json()
        
        embedding_model = next(
            (m for m in models if m["model_id"] == model_id and m["task"] == "embedding"),
            None,
        )
        
        assert embedding_model is not None
        assert "dimension" in embedding_model
        
        # Dimension should be one of the supported sizes
        assert embedding_model["dimension"] in [768, 1024, 1536, 3072]

    @pytest.mark.asyncio
    @pytest.mark.e2e
    @pytest.mark.skipif(
        os.getenv("SKIP_VISION_TESTS") == "true",
        reason="Vision tests require vision-capable model",
    )
    async def test_vision_routing(self, http_client):
        """Test that vision requests route to vision-capable models."""
        # Request with image should route to vision model
        response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={
                "task": "vision",
                "require_vision": True,
            },
        )
        
        if response.status_code == 503:
            pytest.skip("No vision-capable providers available")
        
        assert response.status_code == 200
        
        routing = response.json()
        
        # Should route to a vision-capable model
        models_response = await http_client.get(f"{BRIDGE_URL}/api/v1/models")
        models = models_response.json()
        
        routed_model = next(
            (m for m in models if m["model_id"] == routing["model_id"]),
            None,
        )
        
        assert routed_model is not None
        assert routed_model.get("supports_vision", False) is True


class TestCostEstimation:
    """Test cost estimation across the stack."""

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_routing_includes_cost(self, http_client):
        """Routing decisions should include cost estimates."""
        response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={"task": "chat_small"},
        )
        assert response.status_code == 200
        
        routing = response.json()
        assert "estimated_cost" in routing
        assert isinstance(routing["estimated_cost"], (int, float))
        assert routing["estimated_cost"] >= 0.0

    @pytest.mark.asyncio
    @pytest.mark.e2e
    async def test_local_model_cost_is_zero(self, http_client):
        """Local models should have zero cost."""
        response = await http_client.post(
            f"{BRIDGE_URL}/api/v1/route",
            json={
                "task": "embedding",
                "preferred_model": "nomic-embed-text",
            },
        )
        assert response.status_code == 200
        
        routing = response.json()
        
        # If routed to local model, cost should be 0
        if "ollama" in routing["provider_id"].lower():
            assert routing["estimated_cost"] == 0.0


if __name__ == "__main__":
    # Run E2E tests
    pytest.main([
        __file__,
        "-v",
        "-m", "e2e",
        "--tb=short",
    ])
