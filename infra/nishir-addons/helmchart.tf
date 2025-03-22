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
      version         = "0.17.1"
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
      version         = "v1.17.1"
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

resource "kubernetes_manifest" "helmchart_grafana_monitoring" {
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
      targetNamespace = "grafana"
      version         = "2.0.18"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/grafana-monitoring/values.yaml",
        {
          name       = var.name
          prometheus = var.prometheus
          loki       = var.loki
          tempo      = var.tempo
        }
      )
    }
  }

  depends_on = [kubernetes_namespace.grafana]
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
      version         = "1.8.1"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/longhorn/values.yaml",
        { longhorn_backupstore = var.longhorn_backupstore }
      )
    }
  }

  depends_on = [kubernetes_namespace.longhorn_system]
}

resource "kubernetes_manifest" "helmchart_multus" {
  manifest = {
    apiVersion = "helm.cattle.io/v1"
    kind       = "HelmChart"
    metadata = {
      name      = "multus"
      namespace = "kube-system"
    }
    spec = {
      repo            = "https://rke2-charts.rancher.io"
      chart           = "rke2-multus"
      targetNamespace = "kube-system"
      version         = "v4.1.404"
      helmVersion     = "v3"
      bootstrap       = false
      failurePolicy   = "abort"
      valuesContent = templatefile(
        "${path.module}/templates/charts/multus/values.yaml",
        {}
      )
    }
  }
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
      version         = "0.17.2"
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
