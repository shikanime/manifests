locals {
  tailscale_operator_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_operator_oauth_client.data)
  )
}

data "scaleway_secret_version" "tailscale_operator_oauth_client" {
  secret_id = var.secrets.tailscale_operator_oauth_client
  revision  = "latest"
}

resource "kubernetes_secret" "tailscale_operator_oauth_client" {
  metadata {
    name      = "tailscale-operator-oauth-client"
    namespace = one(kubernetes_namespace.tailscale.metadata).name
  }
  data = {
    client_id     = local.tailscale_operator_oauth_client_data.clientId
    client_secret = local.tailscale_operator_oauth_client_data.clientSecret
  }
}

resource "random_password" "transmission_password" {
  length = 14
}

resource "kubernetes_secret" "transmission" {
  metadata {
    name      = "transmission"
    namespace = one(kubernetes_namespace.shikanime.metadata).name
  }
  data = {
    username = "transmission"
    password = random_password.transmission_password.result
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.shikanime]
}