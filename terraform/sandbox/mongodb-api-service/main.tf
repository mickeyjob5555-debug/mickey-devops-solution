terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = "synthetic-sandbox"
  region  = "us-central1"
}

module "mongodb" {
  source = "../../modules/mongodb-instance"

  name          = "mongodb-api-service"
  replica_count = 3
  zone          = "us-central1-a"
  disk_size_gb  = 100

  labels = {
    environment = "sandbox"
    replica_set = "mongodb-api-service"
  }
}
