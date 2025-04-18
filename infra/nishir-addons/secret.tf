resource "random_password" "gitea_tls_password" {
  length = 14
}

resource "kubernetes_secret" "gitea_tls_password" {
  metadata {
    name      = "gitea-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.gitea_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "kubernetes_secret" "grafana_monitoring_loki" {
  metadata {
    name      = "grafana-monitoring-loki"
    namespace = "grafana"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    host     = var.loki.endpoint
    username = var.loki.username
    password = var.loki.password
  }

  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_secret" "grafana_monitoring_prometheus" {
  metadata {
    name      = "grafana-monitoring-prometheus"
    namespace = "grafana"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    host     = var.prometheus.endpoint
    username = var.prometheus.username
    password = var.prometheus.password
  }

  depends_on = [kubernetes_namespace.grafana]
}

resource "kubernetes_secret" "grafana_monitoring_tempo" {
  metadata {
    name      = "grafana-monitoring-tempo"
    namespace = "grafana"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    host     = var.tempo.endpoint
    username = var.tempo.username
    password = var.tempo.password
  }

  depends_on = [kubernetes_namespace.grafana]
}

resource "random_password" "jellyfin_tls_password" {
  length = 14
}

resource "kubernetes_secret" "jellyfin_tls_password" {
  metadata {
    name      = "jellyfin-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.jellyfin_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "kubernetes_secret" "longhorn_hetzner_backups" {
  metadata {
    name      = "longhorn-hetzner-backups"
    namespace = "longhorn-system"
    annotations = {
      "longhorn.io/backup-target" = "s3://${var.longhorn_backupstore.bucket}@${var.longhorn_backupstore.region}/"
    }
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY_ID     = var.longhorn_backupstore.access_key_id
    AWS_SECRET_ACCESS_KEY = var.longhorn_backupstore.secret_access_key
    AWS_ENDPOINTS         = var.longhorn_backupstore.endpoint
  }

  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "random_password" "metatube" {
  length = 14
}

resource "kubernetes_secret" "metatube" {
  metadata {
    name      = "metatube"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    token = random_password.metatube.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "prowlarr_tls_password" {
  length = 14
}

resource "kubernetes_secret" "prowlarr_tls_password" {
  metadata {
    name      = "prowlarr-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.prowlarr_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "qbittorrent_tls_password" {
  length = 14
}

resource "kubernetes_secret" "qbittorrent_tls_password" {
  metadata {
    name      = "qbittorrent-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.qbittorrent_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "radarr_tls_password" {
  length = 14
}

resource "kubernetes_secret" "radarr_tls_password" {
  metadata {
    name      = "radarr-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.radarr_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "rclone" {
  length = 14
}

resource "kubernetes_secret" "rclone_ftp" {
  metadata {
    name      = "rclone-ftp"
    namespace = "shikanime"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = "rclone"
    password = random_password.rclone.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "kubernetes_secret" "rclone_htpasswd" {
  metadata {
    name      = "rclone-htpasswd"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    htpasswd = "rclone:${random_password.rclone.bcrypt_hash}"
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "sonarr_tls_password" {
  length = 14
}

resource "kubernetes_secret" "sonarr_tls_password" {
  metadata {
    name      = "sonarr-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.sonarr_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "kubernetes_secret" "vaultwarden" {
  metadata {
    name      = "vaultwarden"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    admin-token = var.vaultwarden.admin_token
  }

  depends_on = [kubernetes_namespace.shikanime]
}

resource "random_password" "whisparr_tls_password" {
  length = 14
}

resource "kubernetes_secret" "whisparr_tls_password" {
  metadata {
    name      = "whisparr-tls-password"
    namespace = "shikanime"
  }

  type = "Opaque"

  data = {
    password = random_password.whisparr_tls_password.result
  }

  depends_on = [kubernetes_namespace.shikanime]
}