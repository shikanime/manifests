resource "local_file" "config" {
  filename = "${path.module}/.terraform/tmp/nodes/primary/config.yaml"
  content = templatefile("${path.module}/templates/nodes/primary/config.yaml.tftpl", {
    etcd_access_key = var.etcd_snapshot.access_key_id
    etcd_bucket     = var.etcd_snapshot.bucket
    etcd_endpoint   = var.etcd_snapshot.endpoint
    etcd_region     = var.etcd_snapshot.region
    etcd_secret_key = var.etcd_snapshot.secret_access_key
    node_ip         = var.ip_addresses.nishir
    tls_san         = var.endpoints.nishir
    token           = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    config_content             = local_file.config.content
    tailscale_content          = local_file.tailscale.content
    longhorn_content           = local_file.longhorn.content
    grafana_monitoring_content = local_file.grafana_monitoring.content
    vpa_content                = local_file.vpa.content
    cert_manager_content       = local_file.cert_manager.content
    nfd_content                = local_file.nfd.content
    shikanime_content          = local_file.shikanime.content
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    content     = local_file.config.content
    destination = "/etc/rancher/k3s/config.yaml"
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
}

resource "local_file" "fushi" {
  filename = "${path.module}/.terraform/tmp/nodes/secondary/config.yaml"
  content = templatefile("${path.module}/templates/nodes/secondary/config.yaml.tftpl", {
    node_ip = var.ip_addresses.fushi
    server  = "https://${var.endpoints.nishir}:6443"
    tls_san = var.endpoints.fushi
    token   = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "fushi" {
  triggers_replace = {
    config_content = local_file.fushi.content
  }

  connection {
    type = "ssh"
    user = "root"
    host = "fushi"
  }

  provisioner "file" {
    content     = local_file.fushi.content
    destination = "/etc/rancher/k3s/config.yaml"
  }
}

resource "local_file" "minish" {
  filename = "${path.module}/.terraform/tmp/nodes/secondary/config.yaml"
  content = templatefile("${path.module}/templates/nodes/secondary/config.yaml.tftpl", {
    node_ip = var.ip_addresses.minish
    server  = "https://${var.endpoints.nishir}:6443"
    tls_san = var.endpoints.minish
    token   = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "minish" {
  triggers_replace = {
    config_content = local_file.minish.content
  }

  connection {
    type = "ssh"
    user = "root"
    host = "minish"
  }

  provisioner "file" {
    content     = local_file.minish.content
    destination = "/etc/rancher/k3s/config.yaml"
  }
}
