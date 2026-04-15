resource "random_password" "password" {
  length  = 32
  lower   = true
  numeric = true
  special = false
  upper   = true
}

locals {
  qbt_password = coalesce(var.password, random_password.password.result)
}

resource "kubernetes_secret_v1" "startup_config" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  data = {
    QBT_PASSWORD = local.qbt_password
    QBT_URL      = var.url
    QBT_USER     = var.username
  }

  type = "Opaque"
}
