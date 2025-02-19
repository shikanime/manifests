locals {
  manifest = jsondecode(file("manifest.json"))
}

resource "local_file" "shikanime_namespace" {
  filename        = "${path.module}/manifests/shikanime-namespace.yaml"
  content         = templatefile("${path.module}/templates/shikanime-namespace.yaml.tftpl", {})
  file_permission = "0600"
}

resource "local_file" "tailscale" {
  filename = "${path.module}/manifests/tailscale.yaml"
  content = templatefile("${path.module}/templates/tailscale.yaml.tftpl", {
    repo                    = local.manifest.kubernetes_manifest.tailscale.spec.repo
    chart                   = local.manifest.kubernetes_manifest.tailscale.spec.chart
    version                 = local.manifest.kubernetes_manifest.tailscale.spec.version
    tailscale_client_id     = var.tailscale.client_id
    tailscale_client_secret = var.tailscale.client_secret
  })
  file_permission = "0600"
}

resource "local_file" "longhorn" {
  filename = "${path.module}/manifests/longhorn.yaml"
  content = templatefile("${path.module}/templates/longhorn.yaml.tftpl", {
    repo              = local.manifest.kubernetes_manifest.longhorn.spec.repo
    chart             = local.manifest.kubernetes_manifest.longhorn.spec.chart
    version           = local.manifest.kubernetes_manifest.longhorn.spec.version
    backup_target     = var.longhorn.backup_target
    access_key_id     = var.longhorn.access_key_id
    secret_access_key = var.longhorn.secret_access_key
    endpoints         = var.longhorn.endpoints
  })
  file_permission = "0600"
}

resource "local_file" "grafana_monitoring" {
  filename = "${path.module}/manifests/grafana-monitoring.yaml"
  content = templatefile("${path.module}/templates/grafana-monitoring.yaml.tftpl", {
    repo       = local.manifest.kubernetes_manifest.grafana_monitoring.spec.repo
    chart      = local.manifest.kubernetes_manifest.grafana_monitoring.spec.chart
    version    = local.manifest.kubernetes_manifest.grafana_monitoring.spec.version
    prometheus = var.prometheus
    loki       = var.loki
    tempo      = var.tempo
  })
  file_permission = "0600"
}

resource "local_file" "vpa" {
  filename = "${path.module}/manifests/vpa.yaml"
  content = templatefile("${path.module}/templates/vpa.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.vpa.spec.repo
    chart   = local.manifest.kubernetes_manifest.vpa.spec.chart
    version = local.manifest.kubernetes_manifest.vpa.spec.version
  })
  file_permission = "0600"
}

resource "local_file" "cert_manager" {
  filename = "${path.module}/manifests/cert-manager.yaml"
  content = templatefile("${path.module}/templates/cert-manager.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.cert_manager.spec.repo
    chart   = local.manifest.kubernetes_manifest.cert_manager.spec.chart
    version = local.manifest.kubernetes_manifest.cert_manager.spec.version
  })
  file_permission = "0600"
}

resource "local_file" "node_feature_discovery" {
  filename = "${path.module}/manifests/node-feature-discovery.yaml"
  content = templatefile("${path.module}/templates/node-feature-discovery.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.node_feature_discovery.spec.repo
    chart   = local.manifest.kubernetes_manifest.node_feature_discovery.spec.chart
    version = local.manifest.kubernetes_manifest.node_feature_discovery.spec.version
  })
  file_permission = "0600"
}
