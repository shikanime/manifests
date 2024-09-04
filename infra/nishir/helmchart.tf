resource "kubernetes_manifest" "tailscale_operator" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "tailscale-operator"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://pkgs.tailscale.com/helmcharts"
      chart           = "tailscale-operator"
      targetNamespace = kubernetes_namespace.tailscale.metadata[0].name
      version         = "1.68.1"
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = yamlencode({
        apiServerProxyConfig = {
          mode = "true"
        }
        oauth = {
          clientId     = local.tailscale_oauth_client_data.clientId
          clientSecret = local.tailscale_oauth_client_data.clientSecret
        }
        operatorConfig = {
          hostname = "${var.name}-k8s-operator"
        }
      })
    }
  }
  depends_on = [kubernetes_namespace.tailscale]
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
      version         = "1.6.2"
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = yamlencode({
        preUpgradeChecker = {
          jobEnabled = false
        }
        persistence = {
          defaultFsType            = "xfs"
          defaultClassReplicaCount = 2
        }
        defaultSettings = {
          backupTarget                        = "s3://${data.scaleway_object_bucket.longhorn.name}@${data.scaleway_object_bucket.longhorn.region}/"
          backupTargetCredentialSecret        = kubernetes_secret.longhorn_scw_backups.metadata[0].name
          defaultDataLocality                 = "best-effort"
          engineReplicaTimeout                = 30
          replicaAutoBalance                  = "best-effort"
          defaultReplicaCount                 = 2
          allowCollectingLonghornUsageMetrics = false
          deletingConfirmationFlag            = true
          snapshotDataIntegrityCronjob        = "0 4 */7 * *"
        }
      })
    }
  }
  depends_on = [
    kubernetes_namespace.longhorn_system,
    kubernetes_secret.longhorn_scw_backups
  ]
}

resource "kubernetes_manifest" "grafana_k8s_monitoring" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "grafana-k8s-monitoring"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://grafana.github.io/helm-charts"
      chart           = "k8s-monitoring"
      targetNamespace = kubernetes_namespace.grafana.metadata[0].name
      version         = "1.4.6"
      helmVersion     = "v3"
      bootstrap       = false
      valuesContent = yamlencode({
        externalServices = {
          prometheus = {
            host = "https://prometheus-prod-01-eu-west-0.grafana.net"
            basicAuth = {
              username = local.prometheus_basic_auth_data.username
              password = local.prometheus_basic_auth_data.password
            }
          }
          loki = {
            host = "http://logs-prod-eu-west-0.grafana.net"
            basicAuth = {
              username = local.loki_basic_auth_data.username
              password = local.loki_basic_auth_data.password
            }
          }
          tempo = {
            host = "https://empo-eu-west-0.grafana.net:443"
            basicAuth = {
              username = local.tempo_basic_auth_data.username
              password = local.tempo_basic_auth_data.password
            }
          }
        }
        cluster = {
          name = var.name
        }
        metrics = {
          enabled = true
          alloy = {
            metricsTuning = {
              useIntegrationAllowList = true
            }
          }
          cost = {
            enabled = true
          }
          kepler = {
            enabled = false
          }
          node-exporter = {
            enabled = true
          }
        }
        logs = {
          enabled = true
          pod_logs = {
            enabled = true
          }
          cluster_events = {
            enabled = true
          }
        }
        traces = {
          enabled = true
        }
        receivers = {
          grpc = {
            enabled = true
          }
          http = {
            enabled = true
          }
          zipkin = {
            enabled = true
          }
          grafanaCloudMetrics = {
            enabled = false
          }
        }
        opencost = {
          enabled = true
          opencost = {
            exporter = {
              defaultClusterId = var.name
            }
            prometheus = {
              external = {
                url = "https://prometheus-prod-01-eu-west-0.grafana.net/api/prom"
              }
            }
          }
        }
        kube-state-metrics = {
          enabled = true
        }
        prometheus-node-exporter = {
          enabled = true
        }
        prometheus-operator-crds = {
          enabled = true
        }
        kepler = {
          enabled = false
        }
      })
    }
  }
  depends_on = [kubernetes_namespace.grafana]
}
