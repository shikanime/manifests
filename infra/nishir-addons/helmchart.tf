resource "kubernetes_manifest" "helmchart_cluster_api_operator" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "cluster-api-operator"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://kubernetes-sigs.github.io/cluster-api-operator"
      chart           = "cluster-api-operator"
      targetNamespace = "capi-operator-system"
      version         = "0.20.0"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/cluster-api-operator/values.yaml",
        {}
      )
    }
  }

  depends_on = [kubernetes_namespace.capi_operator_system]
}

resource "kubernetes_manifest" "helmchart_descheduler" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "descheduler"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://kubernetes-sigs.github.io/descheduler"
      chart           = "descheduler"
      targetNamespace = "kube-system"
      version         = "0.33.0"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/descheduler/values.yaml",
        {}
      )
    }
  }
}

resource "kubernetes_manifest" "helmchart_cert_manager" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "cert-manager"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://charts.jetstack.io"
      chart           = "cert-manager"
      targetNamespace = "cert-manager"
      version         = "v1.18.0"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/cert-manager/values.yaml",
        {}
      )
    }
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

resource "kubernetes_manifest" "helmchart_k8s_monitoring" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "k8s-monitoring"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://grafana.github.io/helm-charts"
      chart           = "k8s-monitoring"
      targetNamespace = "grafana-system"
      version         = "3.0.1"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/k8s-monitoring/values.yaml",
        {
          name = var.name
          logs_secret_ref = {
            name = kubernetes_secret.grafana_cloud_logs_k8s_monitoring.metadata.0.name
          }
          metrics_secret_ref = {
            name = kubernetes_secret.grafana_cloud_metrics_k8s_monitoring.metadata.0.name
          }
          traces_secret_ref = {
            name = kubernetes_secret.grafana_cloud_traces_k8s_monitoring.metadata.0.name
          }
        }
      )
    }
  }

  depends_on = [kubernetes_namespace.grafana_system]
}

resource "kubernetes_manifest" "helmchart_longhorn" {
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
      targetNamespace = "longhorn-system"
      version         = "1.9.0"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/longhorn/values.yaml",
        {
          backupstore_target = var.longhorn_backupstore
          backupstore_secret_ref = {
            name = kubernetes_secret.longhorn_hetzner_backups.metadata.0.name
          }
        }
      )
    }
  }

  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "kubernetes_manifest" "helmchart_node_feature_discovery" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "node-feature-discovery"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://kubernetes-sigs.github.io/node-feature-discovery/charts"
      chart           = "node-feature-discovery"
      targetNamespace = "kube-system"
      version         = "0.17.3"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
    }
  }
}

resource "kubernetes_manifest" "helmchart_vpa" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "vpa"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://charts.fairwinds.com/stable"
      chart           = "vpa"
      targetNamespace = "kube-system"
      version         = "4.7.2"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
    }
  }
}
