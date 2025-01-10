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
  })
  description = "Scaleway secrets ID"
  default = {
    tailscale_operator_oauth_client = "371097be-4fd8-4e8f-a3f3-232485c96082"
    longhorn_backupstore_s3_creds   = "b5d61a39-cf9f-44dd-98f9-7d8f73852bde"
  }
}