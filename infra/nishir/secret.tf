locals {
  tailscale_oauth_client_data = jsondecode(
    base64decode(data.hcp_vault_secrets_app.nishir.secrets["tailscale_oauth_client"])
  )
}

data "hcp_vault_secrets_app" "nishir" {
  app_name = var.secret_apps.nishir
}

resource "kubernetes_secret" "tailscale_operator_oauth" {
  metadata {
    name      = "operator-oauth"
    namespace = kubernetes_namespace.tailscale.metadata[0].name
  }
  data = {
    client_id     = local.tailscale_oauth_client_data.clientId
    client_secret = local.tailscale_oauth_client_data.clientSecret
  }
}

resource "kubernetes_secret" "longhorn_scw_backups" {
  metadata {
    name      = "longhorn-scw-backups"
    namespace = kubernetes_namespace.longhorn_system.metadata[0].name
    annotations = {
      "longhorn.io/backup-target" = local.backup_target
    }
  }
  data = {
    AWS_ACCESS_KEY_ID     = scaleway_iam_api_key.longhorn.access_key
    AWS_SECRET_ACCESS_KEY = scaleway_iam_api_key.longhorn.secret_key
    AWS_ENDPOINTS         = "https://s3.fr-par.scw.cloud"
  }
}

resource "kubernetes_secret" "grafana_monitoring_prometheus" {
  metadata {
    name      = "grafana-monitoring-prometheus"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  data = {
    host     = "https://prometheus-prod-01-eu-west-0.grafana.net"
    username = data.grafana_data_source.prometheus.basic_auth_username
    password = grafana_cloud_access_policy_token.nishir_kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "grafana_monitoring_loki" {
  metadata {
    name      = "grafana-monitoring-loki"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  data = {
    host     = "http://logs-prod-eu-west-0.grafana.net"
    username = data.grafana_data_source.loki.basic_auth_username
    password = grafana_cloud_access_policy_token.nishir_kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "grafana_monitoring_tempo" {
  metadata {
    name      = "grafana-monitoring-tempo"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  data = {
    host     = "https://empo-eu-west-0.grafana.net"
    username = data.grafana_data_source.tempo.basic_auth_username
    password = grafana_cloud_access_policy_token.nishir_kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
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

resource "random_password" "vaultwarden_admin_password" {
  length = 14
}

resource "kubernetes_secret" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = kubernetes_namespace.shikanime.metadata[0].name
  }
  data = {
    admin-token = random_password.vaultwarden_admin_password.result
  }
  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "rclone_password" {
  length = 14
}

resource "kubernetes_secret" "rclone" {
  metadata {
    name      = "rclone"
    namespace = kubernetes_namespace.shikanime.metadata[0].name
  }
  data = {
    username = "rclone"
    password = random_password.rclone_password.result
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.shikanime]
}
