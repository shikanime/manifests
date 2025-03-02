variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "nishir"
}

variable "endpoints" {
  type = object({
    nishir = string
  })
  description = "Nodes DNS name"
  default = {
    nishir = "nishir.taila659a.ts.net"
  }
}

variable "k3s" {
  type = object({
    token = string
  })
  description = "K3s cluster join token"
  sensitive   = true
}

variable "etcd_snapshot" {
  type = object({
    access_key_id     = string
    bucket            = string
    endpoint          = string
    region            = string
    secret_access_key = string
  })
  description = "ETCD snapshot storage"
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
  description = "Longhorn backup storage configuration"
  sensitive   = true
}

variable "prometheus" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Prometheus monitoring system authentication"
  sensitive   = true
}

variable "loki" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Loki log aggregation system authentication"
  sensitive   = true
}

variable "tempo" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  description = "Tempo distributed tracing system authentication"
  sensitive   = true
}

variable "vaultwarden" {
  type = object({
    admin_token = string
  })
  description = "Vaultwarden password manager administrative configuration"
  sensitive   = true
}
