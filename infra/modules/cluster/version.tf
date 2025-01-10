terraform {
  required_version = "~> 1.8"
  cloud {
    hostname     = "app.terraform.io"
    organization = "shikanime-studio"
    workspaces {
      name = "nishir-cluster"
    }
  }
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43"
    }
  }
}
