variable "project" {
  type        = string
  description = "Project name"
  default     = "shikanime-studio"
}

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

variable "stack" {
  type        = string
  description = "Grafana stack ID"
  default     = "370431"
}

variable "secrets" {
  type = object({
    tailscale_operator_oauth_client = string
    tailscale_node_singapore_token  = string
    longhorn_backupstore_s3_creds   = string
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_operator_oauth_client = "371097be-4fd8-4e8f-a3f3-232485c96082"
    tailscale_node_singapore_token  = "603388e8-6c6f-4084-bc1f-abb76aa45bf5"
    longhorn_backupstore_s3_creds   = "b5d61a39-cf9f-44dd-98f9-7d8f73852bde"
  }
}