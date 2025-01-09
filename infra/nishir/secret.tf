locals {
  tailscale_operator_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_operator_oauth_client.data)
  )
  longhorn_backupstore_s3_creds_data = jsondecode(
    base64decode(data.scaleway_secret_version.longhorn_backupstore_s3_creds.data)
  )
  tailscale_node_singapore_token = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_node_singapore_token.data)
  )
}

data "scaleway_secret_version" "tailscale_operator_oauth_client" {
  secret_id = var.secrets.tailscale_operator_oauth_client
  revision  = "latest"
}

data "scaleway_secret_version" "longhorn_backupstore_s3_creds" {
  secret_id = var.secrets.longhorn_backupstore_s3_creds
  revision  = "latest"
}

data "scaleway_secret_version" "tailscale_node_singapore_token" {
  secret_id = var.secrets.tailscale_node_singapore_token
  revision  = "latest"
}

resource "scaleway_secret" "etcd_snapshot_oauth_client" {
  name        = "oauth-client"
  description = "${var.display_name} ETCD snapshot OAuth client"
  path        = "/${var.name}/etcd-snapshot"
}

resource "scaleway_secret_version" "etcd_snapshot_oauth_client" {
  secret_id = scaleway_secret.etcd_snapshot_oauth_client.id
  data = jsonencode({
    clientId     = cloudflare_api_token.etcd_snapshot.id
    clientSecret = sha256(cloudflare_api_token.etcd_snapshot.value)
  })
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

resource "kubernetes_secret" "longhorn_hetzner_backups" {
  metadata {
    name      = "longhorn-hetzner-backups"
    namespace = one(kubernetes_namespace.longhorn_system.metadata).name
    annotations = {
      "longhorn.io/backup-target" = local.longhorn_backup_target
    }
  }
  data = {
    AWS_ACCESS_KEY_ID     = local.longhorn_backupstore_s3_creds_data.access_key_id
    AWS_SECRET_ACCESS_KEY = local.longhorn_backupstore_s3_creds_data.secret_access_key
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