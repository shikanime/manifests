resource "kubernetes_namespace" "capi_operator_system" {
  metadata {
    name = "capi-operator-system"
  }
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "grafana_system" {
  metadata {
    name = "grafana-system"
  }
}

resource "kubernetes_namespace" "longhorn_system" {
  metadata {
    name = "longhorn-system"
  }
}

resource "kubernetes_namespace" "shikanime" {
  metadata {
    name = "shikanime"
  }
}
