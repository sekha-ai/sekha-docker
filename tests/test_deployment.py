# sekha-docker/tests/test_deployment.py

def test_docker_compose_up():
    """Test docker-compose brings up all services"""
    subprocess.run(["docker-compose", "-f", "docker/docker-compose.prod.yml", "up", "-d"])
    time.sleep(30)
    
    # Check all services healthy
    assert is_service_healthy("http://localhost:8081/health")
    assert is_service_healthy("http://localhost:8080/health")
    
def test_full_stack_memory():
    """Test memory works end-to-end"""
    # Store conversation
    # Recall conversation
    # Verify context injection
    
def test_privacy_filtering_e2e():
    """Test privacy filtering works"""
    # Store in /private
    # Query with exclusion
    # Verify not recalled
