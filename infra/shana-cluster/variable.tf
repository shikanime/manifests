variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "shana"
}

variable "display_name" {
  type        = string
  description = "Display name of the cluster"
  default     = "Shana"
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
