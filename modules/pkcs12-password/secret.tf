resource "random_password" "pkcs12_password" {
  length           = 64
  lower            = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  override_special = "!@#$%^*()-_=+[]{}:?,."
  special          = true
  upper            = true
}

resource "kubernetes_secret_v1" "pkcs12_password" {
  metadata {
    name        = var.name
    namespace   = var.namespace
    labels      = var.labels
    annotations = var.annotations
  }

  data = {
    password = random_password.pkcs12_password.result
  }

  type = "Opaque"
}
