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
    prometheus_credentails = string
    loki_credentails       = string
    tempo_credentails      = string
    metatube_token         = string
    tailscale_oauth_client = string
  })
  description = "The name of the secrets"
}
