resource "local_file" "tailscale" {
  filename = "${path.module}/.terraform/tmp/manifest/tailscale.yaml"
  content = templatefile("${path.module}/templates/manifests/tailscale.yaml.tftpl", {
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  })
  file_permission = "0600"
}

resource "local_file" "longhorn" {
  filename = "${path.module}/.terraform/tmp/manifest/longhorn.yaml"
  content = templatefile("${path.module}/templates/manifests/longhorn.yaml.tftpl", {
    backup_target     = "s3://${var.longhorn_backupstore.bucket}@${var.longhorn_backupstore.region}/"
    access_key_id     = var.longhorn_backupstore.access_key_id
    secret_access_key = var.longhorn_backupstore.secret_access_key
    endpoints         = "https://${var.longhorn_backupstore.endpoint}"
  })
  file_permission = "0600"
}

resource "local_file" "grafana_monitoring" {
  filename = "${path.module}/.terraform/tmp/manifest/grafana-monitoring.yaml"
  content = templatefile("${path.module}/templates/manifests/grafana-monitoring.yaml.tftpl", {
    prometheus = var.prometheus
    loki       = var.loki
    tempo      = var.tempo
  })
  file_permission = "0600"
}

resource "local_file" "vpa" {
  filename        = "${path.module}/.terraform/tmp/manifest/vpa.yaml"
  content         = templatefile("${path.module}/templates/manifests/vpa.yaml.tftpl", {})
  file_permission = "0600"
}

resource "local_file" "cert_manager" {
  filename        = "${path.module}/.terraform/tmp/manifest/cert-manager.yaml"
  content         = templatefile("${path.module}/templates/manifests/cert-manager.yaml.tftpl", {})
  file_permission = "0600"
}

resource "local_file" "nfd" {
  filename        = "${path.module}/.terraform/tmp/manifest/nfd.yaml"
  content         = templatefile("${path.module}/templates/manifests/nfd.yaml.tftpl", {})
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

resource "local_file" "shikanime" {
  filename = "${path.module}/.terraform/tmp/manifest/shikanime.yaml"
  content = templatefile("${path.module}/templates/manifests/shikanime.yaml.tftpl", {
    gitea_pkcs12_password       = random_password.gitea_pkcs12.result
    jellyfin_pkcs12_password    = random_password.jellyfin_pkcs12.result
    metatube_token              = random_password.metatube.result
    rclone_password             = random_password.rclone.result
    rclone_password_bcrypt_hash = random_password.rclone.bcrypt_hash
    vaultwarden_admin_token     = var.vaultwarden.admin_token
  })
  file_permission = "0600"
}
