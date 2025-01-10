terraform {
  required_version = "~> 1.8"
  cloud {
    hostname     = "app.terraform.io"
    organization = "shikanime-studio"
    workspaces {
      name = "nishir-addons"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
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

provider "aws" {
  region = var.regions.longhorn_backups

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  endpoints {
    s3 = var.endpoints.s3
  }
}
