locals {
  tailscale_operator_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_operator_oauth_client.data)
  )
  longhorn_backupstore_s3_creds_data = jsondecode(
    base64decode(data.scaleway_secret_version.longhorn_backupstore_s3_creds.data)
  )
  vaultwarden_admin_token = jsondecode(
    base64decode(data.scaleway_secret_version.vaultwarden_admin_token.data)
  )

  vaultwarden_secret_object_ref   = one(kubernetes_secret.vaultwarden.metadata)
  metatube_secret_object_ref      = one(kubernetes_secret.metatube.metadata)
  rclone_webdav_secret_object_ref = one(kubernetes_secret.rclone_webdav.metadata)
  rclone_ftp_secret_object_ref    = one(kubernetes_secret.rclone_ftp.metadata)
}

data "scaleway_secret_version" "tailscale_operator_oauth_client" {
  secret_id = var.secrets.tailscale_operator_oauth_client
  revision  = "latest"
}

data "scaleway_secret_version" "longhorn_backupstore_s3_creds" {
  secret_id = var.secrets.longhorn_backupstore_s3_creds
  revision  = "latest"
}

data "scaleway_secret_version" "vaultwarden_admin_token" {
  secret_id = var.secrets.vaultwarden_admin_token
  revision  = "latest"
}

resource "kubernetes_secret" "tailscale_operator_oauth_client" {
  metadata {
    name      = "tailscale-operator-oauth-client"
    namespace = local.tailscale_namespace_object_ref.name
  }
  data = {
    client_id     = local.tailscale_operator_oauth_client_data.clientId
    client_secret = local.tailscale_operator_oauth_client_data.clientSecret
  }
  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubernetes_secret" "longhorn_hetzner_backups" {
  metadata {
    name      = "longhorn-hetzner-backups"
    namespace = local.longhorn_system_namespace_object_ref.name
    annotations = {
      "longhorn.io/backup-target" = local.longhorn_backup_target
    }
  }
  data = {
    AWS_ACCESS_KEY_ID     = local.longhorn_backupstore_s3_creds_data.access_key_id
    AWS_SECRET_ACCESS_KEY = local.longhorn_backupstore_s3_creds_data.secret_access_key
    AWS_ENDPOINTS         = var.endpoints.s3
  }
  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "kubernetes_secret" "grafana_monitoring_prometheus" {
  metadata {
    name      = "grafana-monitoring-prometheus"
    namespace = local.grafana_namespace_object_ref.name
  }
  data = {
    host     = var.endpoints.prometheus
    username = data.grafana_data_source.prometheus.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_secret" "grafana_monitoring_loki" {
  metadata {
    name      = "grafana-monitoring-loki"
    namespace = local.grafana_namespace_object_ref.name
  }
  data = {
    host     = var.endpoints.loki
    username = data.grafana_data_source.loki.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_secret" "grafana_monitoring_tempo" {
  metadata {
    name      = "grafana-monitoring-tempo"
    namespace = local.grafana_namespace_object_ref.name
  }
  data = {
    host     = var.endpoints.tempo
    username = data.grafana_data_source.tempo.basic_auth_username
    password = grafana_cloud_access_policy_token.kubernetes.token
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.grafana]
}

resource "random_password" "metatube_token" {
  length = 14
}

resource "kubernetes_secret" "metatube" {
  metadata {
    name      = "metatube"
    namespace = local.shikanime_namespace_object_ref.name
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
    namespace = local.shikanime_namespace_object_ref.name
  }
  data = {
    admin-token = random_password.vaultwarden_admin_password.result
  }
  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "rclone_password" {
  length = 14
}

resource "kubernetes_secret" "rclone_webdav" {
  metadata {
    name      = "rclone-webdav"
    namespace = local.shikanime_namespace_object_ref.name
  }
  data = {
    htpasswd = "rclone:${bcrypt(random_password.rclone_password.result)}"
  }
  depends_on = [kubernetes_namespace.shikanime]
}

resource "kubernetes_secret" "rclone_ftp" {
  metadata {
    name      = "rclone-ftp"
    namespace = local.shikanime_namespace_object_ref.name
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
    namespace = local.shikanime_namespace_object_ref.name
  }
  data = {
    username = "transmission"
    password = random_password.transmission_password.result
  }
  type       = "kubernetes.io/basic-auth"
  depends_on = [kubernetes_namespace.shikanime]
}
