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
      version         = "1.74.1"
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
          backupTarget                 = "s3://${data.scaleway_object_bucket.longhorn_backups.name}@${data.scaleway_object_bucket.longhorn_backups.region}/"
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
            host = "https://prometheus-prod-01-eu-west-0.grafana.net"
            secret = {
              name = kubernetes_secret.grafana_monitoring_prometheus.metadata[0].name
            }
          }
          loki = {
            host = "http://logs-prod-eu-west-0.grafana.net"
            secret = {
              name = kubernetes_secret.grafana_monitoring_loki.metadata[0].name
            }
          }
          tempo = {
            host = "https://empo-eu-west-0.grafana.net:443"
            secret = {
              name = kubernetes_secret.grafana_monitoring_tempo.metadata[0].name
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
