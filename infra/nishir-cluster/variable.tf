variable "endpoints" {
  type = object({
    nishir  = string
    flandre = string
    s3      = string
  })
  description = "The endpoints of the cluster"
  default = {
    nishir  = "nishir.taila659a.ts.net"
    flandre = "flandre.taila659a.ts.net"
    s3      = "fsn1.your-objectstorage.com"
  }
}

variable "ip_addresses" {
  type = object({
    nishir  = list(string)
    flandre = list(string)
  })
  description = "The IP addresses of the node"
  default = {
    nishir  = ["192.168.1.100", "2001:cafe:42::100"]
    flandre = ["100.78.148.86", "fd7a:115c:a1e0::8001:9456"]
  }
}

variable "cirds" {
  type = object({
    cluster = list(string)
    service = list(string)
  })
  description = "The CIDRs of the cluster and service"
  default = {
    cluster = ["10.42.0.0/16", "2001:cafe:42::/56"]
    service = ["10.43.0.0/16", "2001:cafe:43::/112"]
  }
}

variable "regions" {
  type = object({
    aws_s3_bucket = string
  })
  description = "Resource regions"
  default = {
    aws_s3_bucket = "fsn1"
  }
}

variable "buckets" {
  type = object({
    etcd_backups = string
  })
  description = "The buckets of the cluster"
  default = {
    etcd_backups = "shikanime-studio-nishir-etcd-backups-7a256561"
  }
}

variable "secrets" {
  type = object({
    etcd_snapshot_s3_creds = string
    connection_creds       = string
    tokens                 = string
  })
  description = "Scaleway secrets ID"
  default = {
    etcd_snapshot_s3_creds = "f852d0e5-e603-4a38-8287-f8bd3ec42ebe"
    connection_creds       = "54b6d00b-359e-429a-8178-f13cb7511fff"
    tokens                 = "3a598e4c-c3cd-46c1-ad85-222bc1224c4d"
  }
}
