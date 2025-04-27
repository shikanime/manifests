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

resource "kubernetes_secret" "grafana_cloud_logs_k8s_monitoring" {
  metadata {
    name      = "grafana-cloud-logs-k8s-monitoring"
    namespace = "grafana-system"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.loki.username
    password = var.loki.password
  }

  depends_on = [kubernetes_namespace.grafana_system]
}

resource "kubernetes_secret" "grafana_cloud_metrics_k8s_monitoring" {
  metadata {
    name      = "grafana-cloud-metrics-k8s-monitoring"
    namespace = "grafana-system"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.prometheus.username
    password = var.prometheus.password
  }

  depends_on = [kubernetes_namespace.grafana_system]
}

resource "kubernetes_secret" "grafana_cloud_traces_k8s_monitoring" {
  metadata {
    name      = "grafana-cloud-traces-k8s-monitoring"
    namespace = "grafana-system"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.tempo.username
    password = var.tempo.password
  }

  depends_on = [kubernetes_namespace.grafana_system]
}

resource "kubernetes_secret" "grafana_cloud_profiles_k8s_monitoring" {
  metadata {
    name      = "grafana-cloud-profiles-k8s-monitoring"
    namespace = "grafana-system"
  }

  type = "kubernetes.io/basic-auth"

  data = {
    username = var.pyroscope.username
    password = var.pyroscope.password
  }

  depends_on = [kubernetes_namespace.grafana_system]
}

resource "kubernetes_secret" "hetzner" {
  metadata {
    name      = "hetzner"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    hcloud-token = var.hetzner.hcloud_token
  }
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

resource "kubernetes_secret" "rke2_hetzner_manifests" {
  metadata {
    name      = "rke2-hetzner-manifests"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    "hcloud-cloud-controller-manager.yaml" = file("${path.module}/templates/manifests/hcloud-cloud-controller-manager.yaml")
    "hcloud-csi.yaml"                      = file("${path.module}/templates/manifests/hcloud-csi.yaml")
    "hetzner.yaml" = templatefile("${path.module}/templates/manifests/hetzner.yaml.tftpl", {
      hcloud_token = var.hetzner.hcloud_token
    })
  }
}

resource "kubernetes_secret" "rke2_tailscale_operator_manifests" {
  metadata {
    name      = "rke2-tailscale-operator-manifests"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    "tailscale-operator.yaml" = templatefile("${path.module}/templates/manifests/tailscale-operator.yaml.tftpl", {
      name          = var.name
      client_id     = var.tailscale_operator.client_id
      client_secret = var.tailscale_operator.client_secret
    })
  }
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