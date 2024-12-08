locals {
  manifest = jsondecode(file("manifest.json"))
}

resource "kubernetes_namespace" "shikanime" {
  metadata {
    name = "shikanime"
  }
}

resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_manifest" "tailscale" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "tailscale"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.tailscale.spec.repo
      chart           = local.manifest.kubernetes_manifest.tailscale.spec.chart
      targetNamespace = kubernetes_namespace.tailscale.metadata[0].name
      version         = local.manifest.kubernetes_manifest.tailscale.spec.version
      helmVersion     = "v3"
      bootstrap       = false
    }
  }
}

resource "kubernetes_namespace" "longhorn_system" {
  metadata {
    name = "longhorn-system"
  }
}

resource "kubernetes_manifest" "longhorn" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "longhorn"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.longhorn.spec.repo
      chart           = local.manifest.kubernetes_manifest.longhorn.spec.chart
      targetNamespace = kubernetes_namespace.longhorn_system.metadata[0].name
      version         = local.manifest.kubernetes_manifest.longhorn.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        defaultSettings = {
          backupTarget                 = local.backup_target
          backupTargetCredentialSecret = kubernetes_secret.longhorn_cf_backups.metadata[0].name
        }
      })
    }
  }
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_manifest" "grafana_monitoring" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "grafana-monitoring"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.grafana_monitoring.spec.repo
      chart           = local.manifest.kubernetes_manifest.grafana_monitoring.spec.chart
      targetNamespace = kubernetes_namespace.grafana.metadata[0].name
      version         = local.manifest.kubernetes_manifest.grafana_monitoring.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        externalServices = {
          prometheus = {
            secret = {
              create = false
              name   = kubernetes_secret.grafana_monitoring_prometheus.metadata[0].name
            }
          }
          loki = {
            secret = {
              create = false
              name   = kubernetes_secret.grafana_monitoring_loki.metadata[0].name
            }
          }
          tempo = {
            secret = {
              create = false
              name   = kubernetes_secret.grafana_monitoring_tempo.metadata[0].name
            }
          }
        }
        opencost = {
          opencost = {
            prometheus = {
              existingSecretName = kubernetes_secret.grafana_monitoring_prometheus.metadata[0].name
            }
          }
        }
      })
    }
  }
}