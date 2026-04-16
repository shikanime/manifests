resource "random_password" "admin_token" {
  length  = 64
  lower   = true
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret_v1" "vaultwarden" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  data = {
    ADMIN_TOKEN = random_password.admin_token.result
  }

  type = "Opaque"
}
