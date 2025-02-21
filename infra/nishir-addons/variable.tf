variable "endpoints" {
  type = object({
    nishir = string
  })
  description = "Nodes DNS name"
}

variable "ip_addresses" {
  type = object({
    nishir = list(string)
  })
  description = "Nodes network addresses"
}

variable "etcd_snapshot" {
  type = object({
    access_key_id     = string
    bucket            = string
    endpoint          = string
    region            = string
    secret_access_key = string
  })
  description = "Configuration for etcd snapshot storage in S3-compatible storage"
  sensitive   = true
}

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  description = "Tailscale operator authentication credentials"
  sensitive   = true
}

variable "longhorn_backupstore" {
  type = object({
    access_key_id     = string
    bucket            = string
    endpoint          = string
    region            = string
    secret_access_key = string
  })
  description = "Longhorn backup storage configuration for S3-compatible storage"
  sensitive   = true
}

variable "prometheus" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Prometheus monitoring system authentication and endpoint configuration"
  sensitive   = true
}

variable "loki" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Loki log aggregation system authentication and endpoint configuration"
  sensitive   = true
}

variable "tempo" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Tempo distributed tracing system authentication and endpoint configuration"
  sensitive   = true
}

variable "vaultwarden" {
  type = object({
    admin_token = string
  })
  description = "Vaultwarden password manager administrative configuration"
  sensitive   = true
}
