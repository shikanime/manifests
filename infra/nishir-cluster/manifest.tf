resource "local_file" "tailscale" {
  filename = "${path.module}/.terraform/tmp/manifest/tailscale.yaml"
  content = templatefile("${path.module}/templates/manifests/tailscale.yaml.tftpl", {
    name          = var.name
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
    name       = var.name
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

resource "random_password" "sonarr_pkcs12" {
  length = 14
}

resource "random_password" "radarr_pkcs12" {
  length = 14
}

resource "random_password" "prowlarr_pkcs12" {
  length = 14
}

resource "random_password" "qbittorrent_pkcs12" {
  length = 14
}

resource "random_password" "metatube" {
  length = 14
}

resource "random_password" "rclone" {
  length = 14
}

resource "random_password" "transmission" {
  length = 14
}

resource "local_file" "shikanime" {
  filename = "${path.module}/.terraform/tmp/manifest/shikanime.yaml"
  content = templatefile("${path.module}/templates/manifests/shikanime.yaml.tftpl", {
    gitea_pkcs12_password       = random_password.gitea_pkcs12.result
    jellyfin_pkcs12_password    = random_password.jellyfin_pkcs12.result
    sonarr_pkcs12_password      = random_password.sonarr_pkcs12.result
    radarr_pkcs12_password      = random_password.radarr_pkcs12.result
    prowlarr_pkcs12_password    = random_password.prowlarr_pkcs12.result
    qbittorrent_pkcs12_password = random_password.qbittorrent_pkcs12.result
    metatube_token              = random_password.metatube.result
    rclone_password             = random_password.rclone.result
    rclone_password_bcrypt_hash = random_password.rclone.bcrypt_hash
    transmission_password       = random_password.transmission.result
    vaultwarden_admin_token     = var.vaultwarden.admin_token
  })
  file_permission = "0600"
}

resource "terraform_data" "addons" {
  triggers_replace = {
    tailscale_id          = local_file.tailscale.id
    longhorn_id           = local_file.longhorn.id
    grafana_monitoring_id = local_file.grafana_monitoring.id
    vpa_id                = local_file.vpa.id
    cert_manager_id       = local_file.cert_manager.id
    nfd_id                = local_file.nfd.id
    shikanime_id          = local_file.shikanime.id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    content     = local_file.tailscale.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/tailscale.yaml"
  }

  provisioner "file" {
    content     = local_file.longhorn.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/longhorn.yaml"
  }

  provisioner "file" {
    content     = local_file.grafana_monitoring.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/grafana-monitoring.yaml"
  }

  provisioner "file" {
    content     = local_file.vpa.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/vpa.yaml"
  }

  provisioner "file" {
    content     = local_file.cert_manager.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/cert-manager.yaml"
  }

  provisioner "file" {
    content     = local_file.nfd.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/nfd.yaml"
  }

  provisioner "file" {
    content     = local_file.shikanime.content
    destination = "/mnt/nishir/rancher/k3s/server/manifests/shikanime.yaml"
  }

  depends_on = [terraform_data.nishir]
}
