terraform {
  required_version = ">=1.3.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=6.38.0"
    }
  }
}