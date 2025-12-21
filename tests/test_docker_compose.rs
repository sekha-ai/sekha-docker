use testcontainers::compose::DockerCompose;
use reqwest;
use std::time::Duration;
use tokio::time::sleep;

#[tokio::test]
async fn test_docker_compose_full_stack() -> Result<(), Box<dyn std::error::Error>> {
    let mut compose = DockerCompose::with_local_client(&["docker-compose.yml"]);
    compose.up().await?;

    // Wait for services to be ready
    sleep(Duration::from_secs(10)).await;

    // Test controller health
    let controller = compose.service("sekha-controller").expect("controller service");
    let port = controller.get_host_port_ipv4(8080).await?;
    let response = reqwest::get(format!("http://localhost:{}/health", port)).await?;
    assert!(response.status().is_success());

    // Test ChromaDB health
    let chroma = compose.service("chroma").expect("chroma service");
    let chroma_port = chroma.get_host_port_ipv4(8000).await?;
    let chroma_response = reqwest::get(format!("http://localhost:{}/api/v1/heartbeat", chroma_port)).await?;
    assert!(chroma_response.status().is_success());

    // Test Postgres connection
    let postgres = compose.service("postgres").expect("postgres service");
    assert!(postgres.get_host_port_ipv4(5432).await.is_ok());

    // Test Redis connection
    let redis = compose.service("redis").expect("redis service");
    assert!(redis.get_host_port_ipv4(6379).await.is_ok());

    Ok(())
}

#[tokio::test]
async fn test_docker_compose_dev_variant() -> Result<(), Box<dyn std::error::Error>> {
    let mut compose = DockerCompose::with_local_client(&["docker/docker-compose.dev.yml"]);
    compose.up().await?;
    sleep(Duration::from_secs(10)).await;

    let controller = compose.service("sekha-controller").expect("controller service");
    let port = controller.get_host_port_ipv4(8080).await?;
    let response = reqwest::get(format!("http://localhost:{}/health", port)).await?;
    assert!(response.status().is_success());

    Ok(())
}
