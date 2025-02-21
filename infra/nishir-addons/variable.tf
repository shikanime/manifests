variable "etcd_snapshot" {
  type = object({
    access_key_id     = string
    bucket            = string
    endpoint          = string
    region            = string
    secret_access_key = string
  })
  sensitive = true
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
    bucket            = string
    endpoint          = string
    region            = string
    secret_access_key = string
  })
  sensitive = true
}

variable "prometheus" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  sensitive = true
}

variable "loki" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  sensitive = true
}

variable "tempo" {
  type = object({
    endpoint = string
    password = string
    username = string
  })
  sensitive = true
}

variable "vaultwarden" {
  type = object({
    admin_token = string
  })
  sensitive = true
}
