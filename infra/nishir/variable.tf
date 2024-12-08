variable "account_id" {
  type        = string
  description = "Cloudflare account ID"
  default     = "d4e789904d6943d8cd524e19c5cb36bd"
}

variable "stack_id" {
  type        = string
  description = "Grafana stack ID"
  default     = "370431"
}

variable "secret_ids" {
  type = object({
    tailscale_operator_oauth_client = string
  })
  description = "Scaleway secret IDs"
  default = {
    tailscale_operator_oauth_client = "40a23536-72b3-4026-bf4b-cc1db38bcfa7"
  }
}