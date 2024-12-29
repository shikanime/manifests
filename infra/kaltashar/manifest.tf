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
      targetNamespace = one(kubernetes_namespace.tailscale.metadata).name
      version         = local.manifest.kubernetes_manifest.tailscale.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        oauthSecretVolume = {
          secret = {
            secretName = one(kubernetes_secret.tailscale_operator_oauth_client.metadata).name
          }
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
      targetNamespace = one(kubernetes_namespace.grafana.metadata).name
      version         = local.manifest.kubernetes_manifest.grafana_monitoring.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = jsonencode({
        externalServices = {
          prometheus = {
            secret = {
              create = false
              name   = one(kubernetes_secret.grafana_monitoring_prometheus.metadata).name
            }
          }
          loki = {
            secret = {
              create = false
              name   = one(kubernetes_secret.grafana_monitoring_loki.metadata).name
            }
          }
          tempo = {
            secret = {
              create = false
              name   = one(kubernetes_secret.grafana_monitoring_tempo.metadata).name
            }
          }
        }
        opencost = {
          opencost = {
            prometheus = {
              existingSecretName = one(kubernetes_secret.grafana_monitoring_prometheus.metadata).name
            }
          }
        }
      })
    }
  }
}