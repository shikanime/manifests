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
      failurePolicy   = "abort"
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
      targetNamespace = one(kubernetes_namespace.longhorn_system.metadata).name
      version         = local.manifest.kubernetes_manifest.longhorn.spec.version
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = jsonencode({
        defaultSettings = {
          backupTarget                 = local.longhorn_backup_target
          backupTargetCredentialSecret = one(kubernetes_secret.longhorn_hetzner_backups.metadata).name
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
      failurePolicy   = "abort"
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

resource "kubernetes_manifest" "multus" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "multus"
      namespace = "kube-system"
    }
    spec = {
      repo            = local.manifest.kubernetes_manifest.multus.spec.repo
      chart           = local.manifest.kubernetes_manifest.multus.spec.chart
      targetNamespace = "kube-system"
      version         = local.manifest.kubernetes_manifest.multus.spec.version
      valuesContent = jsonencode({
        config = {
          fullnameOverride = "multus"
          cni_conf = {
            confDir    = "/mnt/nishir/rancher/k3s/agent/etc/cni/net.d"
            binDir     = "/mnt/nishir/rancher/k3s/data/cni/"
            kubeconfig = "/mnt/nishir/rancher/k3s/agent/etc/cni/net.d/multus.d/multus.kubeconfig"
          }
        }
        manifests = {
          dhcpDaemonSet = true
        }
      })
    }
  }
}
