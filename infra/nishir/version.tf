terraform {
  required_version = "~> 1.8.1"
  backend "s3" {
    bucket                      = "shikanime-studio-fr-par-opentofu-state"
    key                         = "nishir/terraform.tfstate"
    region                      = "fr-par"
    endpoint                    = "s3.fr-par.scw.cloud"
    skip_region_validation      = true
    skip_credentials_validation = true
  }
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
  }
}
