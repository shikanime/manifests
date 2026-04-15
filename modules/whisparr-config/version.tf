terraform {
  required_version = ">= 1.7.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
