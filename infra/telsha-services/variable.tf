variable "project" {
  type        = string
  description = "Project name"
  default     = "shikanime-studio"
}

variable "name" {
  type        = string
  description = "Name of the cluster"
  default     = "telsha"
}

variable "display_name" {
  type        = string
  description = "Display name of the cluster"
  default     = "Telsha"
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

variable "tailscale_operator" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "longhorn_backupstore" {
  type = object({
    access_key_id     = string
    secret_access_key = string
  })
  sensitive = true
}