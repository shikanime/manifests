variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "app" {
  type        = string
  description = "The name of the application"
}

variable "stacks" {
  type = object({
    shikanime = string
  })
  description = "The Grafana Cloud stacks"
}

variable "data_sources" {
  type = object({
    prometheus = string
    loki       = string
    tempo      = string
  })
  description = "The Grafana data sources"
}

variable "buckets" {
  type = object({
    longhorn_backups = string
  })
  description = "The name of the buckets"
}

variable "secret_apps" {
  type = object({
    nishir = string
  })
  description = "The name of the secret apps"
}
