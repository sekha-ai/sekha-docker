"""Deployment tests for sekha-docker.

These tests validate:
1. Docker Compose configuration syntax
2. Required files exist
3. Documentation is present
"""

import os
import subprocess
import yaml
import pytest
from pathlib import Path


REPO_ROOT = Path(__file__).parent.parent
DOCKER_DIR = REPO_ROOT / "docker"


class TestDockerComposeFiles:
    """Test Docker Compose configuration files."""
    
    def test_prod_compose_exists(self) -> None:
        """Test that production docker-compose file exists."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        assert prod_file.exists(), "docker-compose.prod.yml not found"
    
    def test_prod_compose_valid_yaml(self) -> None:
        """Test that production compose file is valid YAML."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        with open(prod_file) as f:
            data = yaml.safe_load(f)
        assert data is not None
        assert "services" in data
    
    def test_prod_compose_has_required_services(self) -> None:
        """Test that all required services are defined."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        with open(prod_file) as f:
            data = yaml.safe_load(f)
        
        services = data.get("services", {})
        required_services = [
            "sekha-proxy",
            "sekha-core",
            "sekha-bridge",
            "chroma",
            "redis"
        ]
        
        for service in required_services:
            assert service in services, f"Required service '{service}' not found"
    
    def test_prod_compose_proxy_port_exposed(self) -> None:
        """Test that proxy exposes port 8081."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        with open(prod_file) as f:
            data = yaml.safe_load(f)
        
        proxy = data["services"]["sekha-proxy"]
        ports = proxy.get("ports", [])
        
        # Should have port 8081 exposed
        assert any("8081" in str(port) for port in ports), "Port 8081 not exposed"
    
    def test_docker_compose_config_valid(self) -> None:
        """Test that docker compose config validates successfully."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        result = subprocess.run(
            ["docker", "compose", "-f", str(prod_file), "config", "--quiet"],
            capture_output=True,
            text=True
        )
        
        assert result.returncode == 0, f"docker compose config failed: {result.stderr}"


class TestDockerfiles:
    """Test Dockerfile configurations."""
    
    def test_proxy_dockerfile_exists(self) -> None:
        """Test that proxy Dockerfile exists."""
        dockerfile = DOCKER_DIR / "Dockerfile.proxy"
        assert dockerfile.exists(), "Dockerfile.proxy not found"
    
    def test_rust_prod_dockerfile_exists(self) -> None:
        """Test that Rust production Dockerfile exists."""
        dockerfile = DOCKER_DIR / "Dockerfile.rust.prod"
        assert dockerfile.exists(), "Dockerfile.rust.prod not found"
    
    def test_python_prod_dockerfile_exists(self) -> None:
        """Test that Python production Dockerfile exists."""
        dockerfile = DOCKER_DIR / "Dockerfile.python.prod"
        assert dockerfile.exists(), "Dockerfile.python.prod not found"


class TestDocumentation:
    """Test that documentation is present and complete."""
    
    def test_readme_exists(self) -> None:
        """Test that README exists."""
        readme = REPO_ROOT / "README.md"
        assert readme.exists(), "README.md not found"
    
    def test_readme_mentions_proxy(self) -> None:
        """Test that README mentions the new proxy service."""
        readme = REPO_ROOT / "README.md"
        content = readme.read_text()
        
        assert "sekha-proxy" in content.lower(), "README doesn't mention sekha-proxy"
        assert "8081" in content, "README doesn't mention proxy port 8081"
    
    def test_readme_has_quick_start(self) -> None:
        """Test that README has quick start section."""
        readme = REPO_ROOT / "README.md"
        content = readme.read_text()
        
        assert "Quick Start" in content or "quick start" in content.lower()
    
    def test_testing_doc_exists(self) -> None:
        """Test that TESTING.md exists."""
        testing_doc = REPO_ROOT / "TESTING.md"
        assert testing_doc.exists(), "TESTING.md not found"
    
    def test_testing_doc_has_coverage_goals(self) -> None:
        """Test that TESTING.md mentions coverage goals."""
        testing_doc = REPO_ROOT / "TESTING.md"
        content = testing_doc.read_text()
        
        assert "90%" in content, "TESTING.md doesn't mention 90% coverage goal"
        assert "coverage" in content.lower()


class TestEnvironmentVariables:
    """Test environment variable documentation."""
    
    def test_env_example_exists(self) -> None:
        """Test that .env.example exists if env vars are required."""
        # Optional - only if we create .env.example
        env_example = REPO_ROOT / ".env.example"
        if env_example.exists():
            content = env_example.read_text()
            assert "SEKHA_API_KEY" in content
    
    def test_readme_documents_env_vars(self) -> None:
        """Test that README documents required environment variables."""
        readme = REPO_ROOT / "README.md"
        content = readme.read_text()
        
        assert "SEKHA_API_KEY" in content, "README doesn't document SEKHA_API_KEY"
        assert "environment" in content.lower() or "variable" in content.lower()


class TestScripts:
    """Test deployment scripts if they exist."""
    
    def test_scripts_directory_structure(self) -> None:
        """Test scripts directory exists (optional)."""
        scripts_dir = REPO_ROOT / "scripts"
        # Optional - only fail if scripts exist but are broken
        if scripts_dir.exists():
            assert scripts_dir.is_dir()


@pytest.mark.integration
class TestDeploymentIntegration:
    """Integration tests that require Docker.
    
    These are skipped by default. Run with:
    pytest tests/ -v -m integration
    """
    
    @pytest.mark.skip(reason="Requires full stack deployment - run manually")
    def test_docker_compose_up(self) -> None:
        """Test that docker compose up works."""
        prod_file = DOCKER_DIR / "docker-compose.prod.yml"
        
        # Start services
        result = subprocess.run(
            ["docker", "compose", "-f", str(prod_file), "up", "-d"],
            capture_output=True,
            text=True
        )
        
        assert result.returncode == 0, f"docker compose up failed: {result.stderr}"
        
        # TODO: Wait for health and test endpoints
        # TODO: docker compose down
