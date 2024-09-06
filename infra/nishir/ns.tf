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

resource "kubernetes_namespace" "cattle_fleet_system" {
  metadata {
    name = "cattle-fleet-system"
  }
}
