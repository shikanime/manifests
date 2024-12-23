variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "nishir"
}

variable "display_name" {
  type        = string
  description = "Display name of the cluster"
  default     = "Nishir"
}

variable "account" {
  type        = string
  description = "Cloudflare account ID"
  default     = "d4e789904d6943d8cd524e19c5cb36bd"
}

variable "sack" {
  type        = string
  description = "Grafana stack ID"
  default     = "370431"
}

variable "secrets" {
  type = object({
    tailscale_operator_oauth_client = string
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_operator_oauth_client = "371097be-4fd8-4e8f-a3f3-232485c96082"
  }
}