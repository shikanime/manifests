variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "kaltashar"
}

variable "display_name" {
  type        = string
  description = "Display name of the cluster"
  default     = "Kaltashar"
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