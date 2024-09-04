variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "app" {
  type        = string
  description = "The name of the application"
}

variable "buckets" {
  type        = object({ longhorn = string })
  description = "The name of the buckets"
}

variable "secrets" {
  type = object({
    prometheus_basic_auth  = string
    loki_basic_auth        = string
    tempo_basic_auth       = string
    tailscale_oauth_client = string
  })
  description = "The name of the secrets"
}
