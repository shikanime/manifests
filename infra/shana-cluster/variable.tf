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

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}
