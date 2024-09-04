locals {
  prometheus_basic_auth_data = jsondecode(
    base64decode(data.scaleway_secret_version.prometheus_basic_auth.data)
  )
  loki_basic_auth_data = jsondecode(
    base64decode(data.scaleway_secret_version.loki_basic_auth.data)
  )
  tempo_basic_auth_data = jsondecode(
    base64decode(data.scaleway_secret_version.tempo_basic_auth.data)
  )
  tailscale_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_oauth_client.data)
  )
}

data "scaleway_secret_version" "prometheus_basic_auth" {
  secret_id = var.secrets.prometheus_basic_auth
  revision  = "latest"
}

data "scaleway_secret_version" "loki_basic_auth" {
  secret_id = var.secrets.loki_basic_auth
  revision  = "latest"
}

data "scaleway_secret_version" "tempo_basic_auth" {
  secret_id = var.secrets.tempo_basic_auth
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
