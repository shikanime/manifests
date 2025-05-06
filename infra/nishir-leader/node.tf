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

  sysctl_k8s_config       = file("${path.module}/templates/configs/systctl/99-k8s.conf")
  tmpfiles_rancher_config = file("${path.module}/templates/configs/tmpfiles/var-lib-rancher.conf")
  rke2_config = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
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

  canal_manifest   = file("${path.module}/templates/manifests/rke2-canal-config.yaml")
  coredns_manifest = file("${path.module}/templates/manifests/rke2-coredns-config.yaml")
  multus_manifest  = file("${path.module}/templates/manifests/rke2-multus-config.yaml")
  tailscale_manifest = templatefile("${path.module}/templates/manifests/tailscale-operator.yaml.tftpl", {
    name          = var.name
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  })
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    sysctl_k8s_config       = sha256(local.sysctl_k8s_config)
    tmpfiles_rancher_config = sha256(local.tmpfiles_rancher_config)
    rke2_config             = sha256(local.rke2_config)
    canal_manifest          = sha256(local.canal_manifest)
    coredns_manifest        = sha256(local.coredns_manifest)
    multus_manifest         = sha256(local.multus_manifest)
    tailscale_manifest      = sha256(local.tailscale_manifest)
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    content     = local.sysctl_k8s_config
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "file" {
    content     = local.tmpfiles_rancher_config
    destination = "/etc/tmpfiles.d/var-lib-rancher.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "file" {
    content     = local.rke2_config
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }

  provisioner "file" {
    content     = local.canal_manifest
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-canal-config.yaml"
  }

  provisioner "file" {
    content     = local.coredns_manifest
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-coredns-config.yaml"
  }

  provisioner "file" {
    content     = local.multus_manifest
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-multus-config.yaml"
  }

  provisioner "file" {
    content     = local.tailscale_manifest
    destination = "/var/lib/rancher/rke2/server/manifests/tailscale-operator.yaml"
  }
}
