locals {
  prometheus_credentials_data = jsondecode(
    base64decode(data.scaleway_secret_version.prometheus_credentials.data)
  )
  loki_credentials_data = jsondecode(
    base64decode(data.scaleway_secret_version.loki_credentials.data)
  )
  tempo_credentials_data = jsondecode(
    base64decode(data.scaleway_secret_version.tempo_credentials.data)
  )
  tailscale_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_oauth_client.data)
  )
}

data "scaleway_secret_version" "prometheus_credentials" {
  secret_id = var.secrets.prometheus_credentials
  revision  = "latest"
}

data "scaleway_secret_version" "loki_credentials" {
  secret_id = var.secrets.loki_credentials
  revision  = "latest"
}

data "scaleway_secret_version" "tempo_credentials" {
  secret_id = var.secrets.tempo_credentials
  revision  = "latest"
}

data "scaleway_secret_version" "tailscale_oauth_client" {
  secret_id = var.secrets.tailscale_oauth_client
  revision  = "latest"
}

resource "kubernetes_secret" "longhorn_scw_backups" {
  metadata {
    name      = "longhorn-scw-backups"
    namespace = kubernetes_namespace.longhorn_system.metadata[0].name
  }
  data = {
    AWS_ACCESS_KEY_ID     = scaleway_iam_api_key.longhorn.access_key
    AWS_SECRET_ACCESS_KEY = scaleway_iam_api_key.longhorn.secret_key
    AWS_ENDPOINT          = "https://s3.fr-par.scw.cloud"
  }
}

resource "random_password" "metatube_token" {
  length = 14
}

resource "kubernetes_secret" "metatube" {
  metadata {
    name      = "metatube"
    namespace = kubernetes_namespace.shikanime.metadata[0].name
  }
  data = {
    token = random_password.metatube_token.result
  }
  depends_on = [kubernetes_namespace.shikanime]
}
