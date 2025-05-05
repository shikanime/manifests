locals {
  install_commands = [
    "systemd-tmpfiles --create",
    "sysctl --system",
    "apt-get update -y",
    "apt-get install -y open-iscsi nfs-common cryptsetup dmsetup jq",
    "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -s -",
    "systemctl enable rke2-server.service",
    "mkdir -p /etc/rancher/rke2"
  ]

  start_commands = [
    "systemctl start rke2-server.service"
  ]
}

resource "terraform_data" "nishir" {
  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/configs/systctl/99-k8s.conf")
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/configs/tmpfiles/var-lib-rancher.conf")
    destination = "/etc/tmpfiles.d/var-lib-rancher.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
      etcd_s3_access_key_id     = var.etcd_snapshot.access_key_id
      etcd_s3_bucket            = var.etcd_snapshot.bucket
      etcd_s3_endpoint          = var.etcd_snapshot.endpoint
      etcd_s3_region            = var.etcd_snapshot.region
      etcd_s3_secret_access_key = var.etcd_snapshot.secret_access_key
      node_ip                   = var.rke2.node_ip
      node_labels = {
        "beta.kubernetes.io/instance-type" = "rpi5-large"
        "node.kubernetes.io/instance-type" = "rpi5-large"
      }
      tls_san = var.rke2.tls_san
    })
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }

  provisioner "file" {
    content     = file("${path.module}/templates/manifests/rke2-canal-config.yaml")
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-canal-config.yaml"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/manifests/rke2-coredns-config.yaml")
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-coredns-config.yaml"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/manifests/rke2-multus-config.yaml")
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-multus-config.yaml"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/manifests/tailscale-operator.yaml.tftpl", {
      name          = var.name
      client_id     = var.tailscale_operator.client_id
      client_secret = var.tailscale_operator.client_secret
    })
    destination = "/var/lib/rancher/rke2/server/manifests/tailscale-operator.yaml"
  }
}
