locals {
  manifest = jsondecode(file("manifest.json"))
}

resource "local_file" "tailscale" {
  filename = "${path.module}/.terraform/tmp/manifest/tailscale.yaml"
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
  filename = "${path.module}/.terraform/tmp/manifest/longhorn.yaml"
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
  filename = "${path.module}/.terraform/tmp/manifest/grafana-monitoring.yaml"
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
  filename = "${path.module}/.terraform/tmp/manifest/vpa.yaml"
  content = templatefile("${path.module}/templates/vpa.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.vpa.spec.repo
    chart   = local.manifest.kubernetes_manifest.vpa.spec.chart
    version = local.manifest.kubernetes_manifest.vpa.spec.version
  })
  file_permission = "0600"
}

resource "local_file" "cert_manager" {
  filename = "${path.module}/.terraform/tmp/manifest/cert-manager.yaml"
  content = templatefile("${path.module}/templates/cert-manager.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.cert_manager.spec.repo
    chart   = local.manifest.kubernetes_manifest.cert_manager.spec.chart
    version = local.manifest.kubernetes_manifest.cert_manager.spec.version
  })
  file_permission = "0600"
}

resource "local_file" "nfd" {
  filename = "${path.module}/.terraform/tmp/manifest/nfd.yaml"
  content = templatefile("${path.module}/templates/nfd.yaml.tftpl", {
    repo    = local.manifest.kubernetes_manifest.nfd.spec.repo
    chart   = local.manifest.kubernetes_manifest.nfd.spec.chart
    version = local.manifest.kubernetes_manifest.nfd.spec.version
  })
  file_permission = "0600"
}

resource "random_password" "gitea_pkcs12" {
  length = 14
}

resource "random_password" "jellyfin_pkcs12" {
  length = 14
}

resource "random_password" "metatube" {
  length = 14
}

resource "random_password" "rclone" {
  length = 14
}

resource "random_password" "vaultwarden_admin" {
  length = 14
}

resource "local_file" "shikanime" {
  filename = "${path.module}/.terraform/tmp/manifest/shikanime.yaml"
  content = templatefile("${path.module}/templates/shikanime.yaml.tftpl", {
    gitea_pkcs12_password       = random_password.gitea_pkcs12.result
    jellyfin_pkcs12_password    = random_password.jellyfin_pkcs12.result
    metatube_token              = random_password.metatube.result
    rclone_password             = random_password.rclone.result
    rclone_password_bcrypt_hash = random_password.rclone.bcrypt_hash
    vaultwarden_admin_password  = random_password.vaultwarden_admin.result
  })
  file_permission = "0600"
}
