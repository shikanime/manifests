locals {
  grafana_monitoring_prometheus_secret_object_ref = one(kubernetes_secret.grafana_monitoring_prometheus.metadata)
  grafana_monitoring_loki_secret_object_ref       = one(kubernetes_secret.grafana_monitoring_loki.metadata)
  grafana_monitoring_tempo_secret_object_ref      = one(kubernetes_secret.grafana_monitoring_tempo.metadata)

  tailscale_operator_oauth_client_secret_object_ref = one(kubernetes_secret.tailscale_operator_oauth_client.metadata)

  longhorn_hetzner_backups_secret_object_ref = one(kubernetes_secret.longhorn_hetzner_backups.metadata)

  gitea_pkcs12_secret_object_ref    = one(kubernetes_secret.gitea_pkcs12.metadata)
  jellyfin_pkcs12_secret_object_ref = one(kubernetes_secret.jellyfin_pkcs12.metadata)
  metatube_secret_object_ref        = one(kubernetes_secret.metatube.metadata)
  rclone_ftp_secret_object_ref      = one(kubernetes_secret.rclone_ftp.metadata)
  rclone_webdav_secret_object_ref   = one(kubernetes_secret.rclone_webdav.metadata)
  vaultwarden_secret_object_ref     = one(kubernetes_secret.vaultwarden.metadata)
}

resource "kubernetes_secret" "tailscale_operator_oauth_client" {
  metadata {
    name      = "tailscale-operator-oauth-client"
    namespace = local.tailscale_namespace_object_ref.name
  }
  data = {
    client_id     = var.tailscale.client_id
    client_secret = var.tailscale.client_secret
  }
  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubernetes_secret" "longhorn_hetzner_backups" {
  metadata {
    name      = "longhorn-hetzner-backups"
    namespace = local.longhorn_system_namespace_object_ref.name
    annotations = {
      "longhorn.io/backup-target" = var.longhorn.backup_target
    }
  }
  data = {
    AWS_ACCESS_KEY_ID     = var.longhorn.access_key_id
    AWS_SECRET_ACCESS_KEY = var.longhorn.secret_access_key
    AWS_ENDPOINTS         = var.longhorn.endpoints
  }
  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "kubernetes_secret" "grafana_monitoring_prometheus" {
  metadata {
    name      = "grafana-monitoring-prometheus"
    namespace = local.grafana_namespace_object_ref.name
  }
  data = {
    host     = var.prometheus.endpoint
    username = var.prometheus.username
    password = var.prometheus.password
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
    host     = var.loki.endpoint
    username = var.loki.username
    password = var.loki.password
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
    host     = var.tempo.endpoint
    username = var.tempo.username
    password = var.tempo.password
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
    htpasswd = "rclone:${random_password.rclone_password.bcrypt_hash}"
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

resource "random_password" "jellyfin_pkcs12" {
  length = 14
}

resource "kubernetes_secret" "jellyfin_pkcs12" {
  metadata {
    name      = "jellyfin-pkcs12"
    namespace = local.shikanime_namespace_object_ref.name
  }
  data = {
    password = random_password.jellyfin_pkcs12.result
  }
  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "gitea_pkcs12" {
  length = 14
}

resource "kubernetes_secret" "gitea_pkcs12" {
  metadata {
    name      = "gitea-pkcs12"
    namespace = local.shikanime_namespace_object_ref.name
  }
  data = {
    password = random_password.gitea_pkcs12.result
  }
  depends_on = [kubernetes_namespace.shikanime]
}
