data "hcp_vault_secrets_app" "default" {
  app_name = var.name
}

resource "kubernetes_secret" "tailscale_operator_oauth_client" {
  metadata {
    name      = "tailscale-operator-oauth-client"
    namespace = one(kubernetes_namespace.tailscale.metadata).name
  }
  data = {
    client_id     = data.hcp_vault_secrets_app.default.secrets.etcd_snapshot_client_id
    client_secret = data.hcp_vault_secrets_app.default.secrets.etcd_snapshot_client_secret
  }
}

resource "kubernetes_secret" "longhorn_hetzner_backups" {
  metadata {
    name      = "longhorn-hetzner-backups"
    namespace = one(kubernetes_namespace.longhorn_system.metadata).name
    annotations = {
      "longhorn.io/backup-target" = local.longhorn_backup_target
    }
  }
  data = {
    AWS_ACCESS_KEY_ID     = data.hcp_vault_secrets_app.default.secrets.longhorn_backupstore_access_key_id
    AWS_SECRET_ACCESS_KEY = data.hcp_vault_secrets_app.default.secrets.longhorn_backupstore_secret_access_key
    AWS_ENDPOINTS         = local.longhorn_endpoints
  }
}

resource "kubernetes_secret" "grafana_monitoring_prometheus" {
  metadata {
    name      = "grafana-monitoring-prometheus"
    namespace = one(kubernetes_namespace.grafana.metadata).name
  }
  data = {
    host     = "https://prometheus-prod-01-eu-west-0.grafana.net"
    username = data.grafana_data_source.prometheus.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "grafana_monitoring_loki" {
  metadata {
    name      = "grafana-monitoring-loki"
    namespace = one(kubernetes_namespace.grafana.metadata).name
  }
  data = {
    host     = "http://logs-prod-eu-west-0.grafana.net"
    username = data.grafana_data_source.loki.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "grafana_monitoring_tempo" {
  metadata {
    name      = "grafana-monitoring-tempo"
    namespace = one(kubernetes_namespace.grafana.metadata).name
  }
  data = {
    host     = "https://empo-eu-west-0.grafana.net"
    username = data.grafana_data_source.tempo.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type = "kubernetes.io/basic-auth"
}

resource "random_password" "metatube_token" {
  length = 14
}

resource "kubernetes_secret" "metatube" {
  metadata {
    name      = "metatube"
    namespace = one(kubernetes_namespace.shikanime.metadata).name
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
    namespace = one(kubernetes_namespace.shikanime.metadata).name
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
    namespace = one(kubernetes_namespace.shikanime.metadata).name
  }
  data = {
    username = "rclone"
    password = random_password.rclone_password.result
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.shikanime]
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