variable "name" {
  type        = string
  description = "The name of the cluster"
}

variable "app" {
  type        = string
  description = "The name of the application"
}

variable "devices" {
  type = object({
    nishir = string
    fushi  = string
  })
  description = "The Tailscale devices"
}

variable "buckets" {
  type = object({
    etcd_backups = string
  })
  description = "The name of the buckets"
}

variable "secrets" {
  type = object({
    nishir_credentials    = string
    fushi_credentials     = string
  })
  description = "The name of the secrets"
}