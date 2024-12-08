variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "display_name" {
  type        = string
  description = "The display name of the cluster"
}

variable "account" {
  type        = string
  description = "The Cloudflare account"
}

variable "stack" {
  type        = string
  description = "The Grafana Cloud stack"
}

variable "data_sources" {
  type = object({
    prometheus = string
    loki       = string
    tempo      = string
  })
  description = "The Grafana data sources"
}

variable "buckets" {
  type = object({
    longhorn_backups = string
    etcd_backups     = string
  })
  description = "The name of the buckets"
}

variable "secrets" {
  type = object({
    tailscale_oauth_client = string
  })
  description = "The name of the secrets"
}
