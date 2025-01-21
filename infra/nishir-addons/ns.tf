locals {
  shikanime_namespace_object_ref       = one(kubernetes_namespace.shikanime.metadata)
  tailscale_namespace_object_ref       = one(kubernetes_namespace.tailscale.metadata)
  longhorn_system_namespace_object_ref = one(kubernetes_namespace.longhorn_system.metadata)
  grafana_namespace_object_ref         = one(kubernetes_namespace.grafana.metadata)
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

resource "kubernetes_namespace" "longhorn_system" {
  metadata {
    name = "longhorn-system"
  }
}

resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}