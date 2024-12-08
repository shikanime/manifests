terraform {
  required_version = "~> 1.8.1"
  backend "s3" {
    bucket                      = "shikanime-studio-fr-par-opentofu-state"
    key                         = "nishir/terraform.tfstate"
    region                      = "fr-par"
    skip_region_validation      = true
    skip_credentials_validation = true
    endpoints = {
      s3 = "https://${var.account_id}.r2.cloudflarestorage.com/nishir-opentofu-state"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    grafana = {
      source  = "hashicorp/grafana"
      version = "~> 2.15"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43"
    }
  }
}
