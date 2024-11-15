resource "kubernetes_manifest" "tailscale" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "tailscale"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://pkgs.tailscale.com/helmcharts"
      chart           = "tailscale-operator"
      targetNamespace = kubernetes_namespace.tailscale.metadata[0].name
      version         = "1.76.1"
      helmVersion     = "v3"
      bootstrap       = false
    }
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
      repo            = "https://charts.longhorn.io"
      chart           = "longhorn"
      targetNamespace = kubernetes_namespace.longhorn_system.metadata[0].name
      version         = "1.7.1"
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        defaultSettings = {
          backupTarget                 = local.backup_target
          backupTargetCredentialSecret = kubernetes_secret.longhorn_scw_backups.metadata[0].name
        }
      })
    }
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
      repo            = "https://grafana.github.io/helm-charts"
      chart           = "k8s-monitoring"
      targetNamespace = kubernetes_namespace.grafana.metadata[0].name
      version         = "1.4.6"
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
