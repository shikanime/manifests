locals {
  install_commands = [
    "sysctl --system",
    "apt-get update -y",
    "apt-get install -y open-iscsi nfs-common cryptsetup dmsetup jq",
    "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sh -s -",
    "systemctl enable rke2-agent.service",
    "mkdir -p /etc/rancher/rke2"
  ]
  token_commands = [
    "echo '${var.rke2.node_token}' | install -m 600 /dev/stdin /etc/rancher/rke2/token"
  ]
  start_commands = [
    "systemctl restart rke2-agent.service"
  ]

  sysctl_k8s_config = file("${path.module}/templates/configs/systctl/99-k8s.conf")

  rke2_config_fushi = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
    node_ip = var.nodes.fushi.node_ip
    node_labels = {
      "beta.kubernetes.io/instance-type" = "rpi4-large"
      "node.kubernetes.io/instance-type" = "rpi4-large"
    }
    server = "https://${var.rke2.server}:9345"
  })

  rke2_config_minish = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
    node_ip = var.nodes.minish.node_ip
    node_labels = {
      "beta.kubernetes.io/instance-type" = "rpi4-medium"
      "node.kubernetes.io/instance-type" = "rpi4-medium"
    }
    server = "https://${var.rke2.server}:9345"
  })
}

resource "terraform_data" "fushi" {
  triggers_replace = {
    sysctl_k8s_config = sha256(local.sysctl_k8s_config)
    rke2_config       = sha256(local.rke2_config_fushi)
  }

  connection {
    type = "ssh"
    user = "root"
    host = "fushi"
  }

  provisioner "file" {
    content     = local.sysctl_k8s_config
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "remote-exec" {
    inline = local.token_commands
  }

  provisioner "file" {
    content     = local.rke2_config_fushi
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }
}

resource "terraform_data" "minish" {
  triggers_replace = {
    sysctl_k8s_config = sha256(local.sysctl_k8s_config)
    rke2_config       = sha256(local.rke2_config_minish)
  }

  connection {
    type = "ssh"
    user = "root"
    host = "minish"
  }

  provisioner "file" {
    content     = local.sysctl_k8s_config
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    inline = local.install_commands
  }

  provisioner "remote-exec" {
    inline = local.token_commands
  }

  provisioner "file" {
    content     = local.rke2_config_minish
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    inline = local.start_commands
  }
}
