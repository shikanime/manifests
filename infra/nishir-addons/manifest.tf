locals {
  manifest = jsondecode(file("manifest.json"))
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
      targetNamespace = local.tailscale_namespace_object_ref.name
      version         = local.manifest.kubernetes_manifest.tailscale.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        oauthSecretVolume = {
          secret = {
            secretName = local.tailscale_operator_oauth_client_secret_object_ref.name
          }
        }
      })
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
      repo            = local.manifest.kubernetes_manifest.longhorn.spec.repo
      chart           = local.manifest.kubernetes_manifest.longhorn.spec.chart
      targetNamespace = local.longhorn_system_namespace_object_ref.name
      version         = local.manifest.kubernetes_manifest.longhorn.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        defaultSettings = {
          backupTarget                 = local.longhorn_backup_target
          backupTargetCredentialSecret = local.longhorn_hetzner_backups_secret_object_ref.name
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
      repo            = local.manifest.kubernetes_manifest.grafana_monitoring.spec.repo
      chart           = local.manifest.kubernetes_manifest.grafana_monitoring.spec.chart
      targetNamespace = local.grafana_namespace_object_ref.name
      version         = local.manifest.kubernetes_manifest.grafana_monitoring.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        destinations = [
          {
            name = "metricsService"
            type = "prometheus"
            url  = var.endpoints.prometheus
            secret = {
              create = false
              name   = local.grafana_monitoring_prometheus_secret_object_ref.name
            }
          },
          {
            name = "logsService"
            type = "loki"
            url  = var.endpoints.loki
            secret = {
              create = false
              name   = local.grafana_monitoring_loki_secret_object_ref.name
            }
          },
          {
            name = "tracesService"
            type = "otlp"
            metrics = {
              enabled = false
            }
            logs = {
              enabled = false
            }
            traces = {
              enabled = true
            }
            url = var.endpoints.tempo
            secret = {
              create = false
              name   = local.grafana_monitoring_tempo_secret_object_ref.name
            }
          }
        ]
        clusterMetrics = {
          opencost = {
            enabled = true
            opencost = {
              prometheus = {
                external = {
                  url = "${var.endpoints.prometheus}/api/prom"
                }
                existingSecretName = local.grafana_monitoring_prometheus_secret_object_ref.name
              }
            }
          }
        }
      })
    }
  }
}

resource "kubernetes_manifest" "vpa" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "vpa"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.vpa.spec.repo
      chart           = local.manifest.kubernetes_manifest.vpa.spec.chart
      targetNamespace = "kube-system"
      version         = local.manifest.kubernetes_manifest.vpa.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
    }
  }
}

resource "kubernetes_manifest" "cert_manager" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "cert-manager"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.cert_manager.spec.repo
      chart           = local.manifest.kubernetes_manifest.cert_manager.spec.chart
      targetNamespace = "kube-system"
      version         = local.manifest.kubernetes_manifest.cert_manager.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        crds = {
          enabled = true
        }
      })
    }
  }
}