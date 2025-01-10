variable "host" {
  type        = string
  description = "The hostname of the node"
  default     = "nishir.local"
}

variable "endpoints" {
  type        = list(string)
  description = "The endpoints of the cluster"
  default     = ["nishir.taila659a.ts.net"]
}

variable "ip_addresses" {
  type        = list(string)
  description = "The IP addresses of the node"
  default     = ["192.168.1.100", "2001:cafe:42::100"]
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

variable "buckets" {
  type = object({
    etcd_snapshot_s3 = string
  })
  description = "The S3 bucket names"
  default = {
    etcd_snapshot_s3 = "s3://etcd-snapshot-nishir@fsn1"
  }
}

variable "secrets" {
  type = object({
    tailscale_oauth_client = string
    etcd_snapshot_s3_creds = string
    connection_creds       = string
    k3s_token              = string
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_oauth_client = ""
    etcd_snapshot_s3_creds = ""
    connection_creds       = ""
    k3s_token              = ""
  }
}
