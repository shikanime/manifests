variable "username" {
  type    = string
  default = "admin"
}

variable "vmselect_url" {
  type    = string
  default = "http://vmks-vmselect.monitoring-system.svc:8481"
}

variable "vminsert_url" {
  type    = string
  default = "http://vmks-vminsert.monitoring-system.svc:8480"
}

resource "random_password" "vmauth" {
  length  = 32
  special = true
}

locals {
  auth_yaml = yamlencode({
    users = [
      {
        username = var.username
        password = random_password.vmauth.result
        url_map = [
          {
            src_paths  = ["/select/0/prometheus/.*"]
            url_prefix = [var.vmselect_url]
          },
          {
            src_paths  = ["/insert/0/prometheus/.*"]
            url_prefix = [var.vminsert_url]
          }
        ]
      }
    ]
  })
}

resource "kubernetes_secret" "vmauth" {
  metadata {
    name      = "vmauth"
    namespace = "monitoring-system"
  }

  data = {
    "auth.yml" = local.auth_yaml
  }

  type = "Opaque"
}
