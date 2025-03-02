variable "project" {
  type        = string
  description = "Project name"
  default     = "shikanime-studio"
}

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

variable "tailscale_client_id" {
  type        = string
  description = "Tailscale OAuth client ID"
  sensitive   = true
}

variable "tailscale_client_secret" {
  type        = string
  description = "Tailscale OAuth client secret key"
  sensitive   = true
}
