terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


# Configure the google cloud provider
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

