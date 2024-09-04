variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "secrets" {
  type        = object({ tailscale_oauth_client = string })
  description = "The name of the secrets"
}
