resource "random_password" "token" {
  length  = 48
  lower   = true
  numeric = true
  special = false
  upper   = true
}

resource "kubernetes_secret_v1" "metatube" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  data = {
    TOKEN = random_password.token.result
  }

  type = "Opaque"
}
