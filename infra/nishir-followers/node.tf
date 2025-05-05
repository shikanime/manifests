locals {
  install_commands = [
    "systemd-tmpfiles --create",
    "sysctl --system",
    "apt-get update -y",
    "apt-get install -y open-iscsi nfs-common cryptsetup dmsetup jq",
    "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -s -",
    "systemctl enable rke2-agent.service",
    "mkdir -p /etc/rancher/rke2",
    "echo '${var.rke2.node_token}' | install -m 600 /dev/stdin /etc/rancher/rke2/token",
  ]

  start_commands = [
    "systemctl start rke2-agent.service"
  ]
}

resource "terraform_data" "fushi" {
  connection {
    type = "ssh"
    user = "root"
    host = "fushi"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/configs/systctl/99-k8s.conf")
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
      node_ip = var.nodes.fushi.node_ip
      node_labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-large"
        "node.kubernetes.io/instance-type" = "rpi4-large"
      }
      server = "https://${var.rke2.server}:9345"
    })
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }
}

resource "terraform_data" "minish" {
  connection {
    type = "ssh"
    user = "root"
    host = "minish"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/configs/systctl/99-k8s.conf")
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
      node_ip = var.nodes.minish.node_ip
      node_labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-medium"
        "node.kubernetes.io/instance-type" = "rpi4-medium"
      }
      server = "https://${var.rke2.server}:9345"
    })
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }
}
