terraform {
  required_version = "~> 1.8.1"
  required_providers {
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3.5"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.16.2"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43.0"
    }
  }
}
