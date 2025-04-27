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
    s3 = string
  })
  description = "Resource API endpoints"
  default = {
    s3 = "https://fsn1.your-objectstorage.com"
  }
}

variable "hetzner" {
  type = object({
    hcloud_token = string
  })
  description = "Hetzner Cloud API credentials"
  sensitive   = true
}

variable "etcd_snapshot" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  description = "S3 credentials for etcd snapshot storage"
  sensitive   = true
}

variable "longhorn_backupstore" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  description = "S3 credentials for Longhorn backup storage"
  sensitive   = true
}

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  description = "Tailscale OAuth credentials for the operator"
  sensitive   = true
}

variable "vaultwarden" {
  type = object({
    admin_token = string
  })
  description = "Vaultwarden admin interface access token"
  sensitive   = true
}
