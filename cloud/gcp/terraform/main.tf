terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Cloud SQL - PostgreSQL
resource "google_sql_database_instance" "sekha_db" {
  name             = "sekha-db-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false
}

resource "google_sql_database" "sekha" {
  name     = "sekha"
  instance = google_sql_database_instance.sekha_db.name
}

resource "google_sql_user" "sekha_user" {
  name     = "sekha"
  instance = google_sql_database_instance.sekha_db.name
  password = var.db_password
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

# Cloud Run - Sekha Controller
resource "google_cloud_run_v2_service" "sekha_controller" {
  name     = "sekha-controller"
  location = var.region

  template {
    containers {
      image = "ghcr.io/sekha-ai/sekha-controller:latest"

      ports {
        container_port = 8080
      }

      env {
        name  = "RUST_LOG"
        value = "info"
      }

      env {
        name  = "DATABASE_URL"
        value = "postgresql://sekha:${var.db_password}@${google_sql_database_instance.sekha_db.public_ip_address}:5432/sekha"
      }

      env {
        name  = "VECTOR_DB_URL"
        value = "http://${google_cloud_run_v2_service.sekha_chroma.uri}:8000"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "4Gi"
        }
      }
    }
  }
}

# Cloud Run - ChromaDB
resource "google_cloud_run_v2_service" "sekha_chroma" {
  name     = "sekha-chroma"
  location = var.region

  template {
    containers {
      image = "chromadb/chroma:latest"

      ports {
        container_port = 8000
      }

      env {
        name  = "IS_PERSISTENT"
        value = "TRUE"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "2Gi"
        }
      }
    }
  }
}

# IAM - Allow public access
resource "google_cloud_run_v2_service_iam_member" "controller_public" {
  name     = google_cloud_run_v2_service.sekha_controller.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service_iam_member" "chroma_public" {
  name     = google_cloud_run_v2_service.sekha_chroma.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Outputs
output "controller_url" {
  value = google_cloud_run_v2_service.sekha_controller.uri
}

output "database_ip" {
  value = google_sql_database_instance.sekha_db.public_ip_address
}
