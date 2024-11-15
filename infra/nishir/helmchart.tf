locals {
  helmchart = jsondecode(file("helmchart.json"))
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
      repo            = local.helmchart.tailscale.spec.repo
      chart           = local.helmchart.tailscale.spec.chart
      targetNamespace = kubernetes_namespace.tailscale.metadata[0].name
      version         = local.helmchart.tailscale.spec.version
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
      repo            = local.helmchart.longhorn.spec.repo
      chart           = local.helmchart.longhorn.spec.chart
      targetNamespace = kubernetes_namespace.longhorn_system.metadata[0].name
      version         = local.helmchart.longhorn.spec.version
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
      repo            = local.helmchart.grafana_monitoring.spec.repo
      chart           = local.helmchart.grafana_monitoring.spec.chart
      targetNamespace = kubernetes_namespace.grafana.metadata[0].name
      version         = local.helmchart.grafana_monitoring.spec.version
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