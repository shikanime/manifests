terraform {
  required_version = "~> 1.8"
  backend "s3" {
    bucket                      = "nishir-opentofu-state"
    key                         = "terraform.tfstate"
    region                      = "WEUR"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_s3_checksum            = true
    endpoints = {
      s3 = "https://d4e789904d6943d8cd524e19c5cb36bd.r2.cloudflarestorage.com"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.82"
    }
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

provider "aws" {
  region     = "fsn1"
  access_key = "GPVRTMVK8P700FIA5WAM"
  secret_key = "v5RWH1UmeXNQT0KqCdWlUCPIFZIpLMdAqc0YZij5"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  endpoints {
    s3 = "https://fsn1.your-objectstorage.com"
  }
}
