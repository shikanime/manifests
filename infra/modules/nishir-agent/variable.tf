variable "endpoints" {
  type        = list(string)
  description = "The endpoints of the cluster"
  default     = ["flandre.taila659a.ts.net"]
}

variable "ip_addresses" {
  type        = list(string)
  description = "The IP addresses of the node"
  default     = ["100.78.148.86", "fd7a:115c:a1e0::8001:9456"]
}

variable "cirds" {
  type = object({
    cluster = list(string)
    service = list(string)
  })
  description = "The CIDRs of the cluster and service"
  default = {
    cluster = ["10.42.0.0/16", "2001:cafe:42::/56"]
    service = ["10.43.0.0/16", "2001:cafe:43::/112"]
  }
}

variable "secrets" {
  type = object({
    tailscale_oauth_client = string
    connection_creds       = string
    k3s_token              = string
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_oauth_client = ""
    connection_creds       = ""
    k3s_token              = ""
  }
}
