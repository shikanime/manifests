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

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "etcd_snapshot" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}
