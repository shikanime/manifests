terraform {
  required_version = "~> 1.8"
  cloud {
    hostname     = "app.terraform.io"
    organization = "shikanime-studio"
    workspaces {
      name = "nishir"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
    hcp = {
      source = "hashicorp/hcp"
      version = "~> 0.101"
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

provider "aws" {
  region = "fsn1"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  endpoints {
    s3 = "https://fsn1.your-objectstorage.com"
  }
}
