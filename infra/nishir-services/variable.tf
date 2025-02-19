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

variable "stack" {
  type        = string
  description = "Grafana stack ID"
  default     = "370431"
}

variable "regions" {
  type = object({
    grafana_cloud_access_policy = string
    aws_s3_bucket               = string
  })
  description = "Resource regions"
  default = {
    grafana_cloud_access_policy = "eu"
    aws_s3_bucket               = "fsn1"
  }
}

variable "endpoints" {
  type = object({
    prometheus = string
    loki       = string
    tempo      = string
    s3         = string
  })
  description = "Resource API endpoints"
  default = {
    prometheus = "https://prometheus-prod-01-eu-west-0.grafana.net"
    loki       = "https://logs-prod-eu-west-0.grafana.net"
    tempo      = "https://tempo-eu-west-0.grafana.net"
    s3         = "https://fsn1.your-objectstorage.com"
  }
}

variable "secrets" {
  type = object({
    tailscale_operator_oauth_client = string
    longhorn_backupstore_s3_creds   = string
    vaultwarden_admin_token         = string
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_operator_oauth_client = "29c61112-a8b6-4098-b1e5-b9aa650fc3e4"
    longhorn_backupstore_s3_creds   = "b5d61a39-cf9f-44dd-98f9-7d8f73852bde"
    vaultwarden_admin_token         = "4e4b6a04-8885-4579-ad8a-a25d72f63758"
  }
}