terraform {
  required_version = "~> 1.8.1"
  backend "s3" {
    bucket                      = "shikanime-studio-fr-par-opentofu-state"
    key                         = "nishir/terraform.tfstate"
    region                      = "fr-par"
    skip_region_validation      = true
    skip_credentials_validation = true
    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
  }
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    grafana = {
      source  = "hashicorp/grafana"
      version = "~> 2.15"
    }
  }
}
