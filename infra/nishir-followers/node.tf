resource "local_file" "config_rke2_fushi" {
  filename = "${path.module}/.terraform/tmp/configs/rke2/config-fushi.yaml"
  content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
    node_ip = var.nodes.fushi.node_ip
    node_labels = {
      "beta.kubernetes.io/instance-type" = "rpi4-large"
      "node.kubernetes.io/instance-type" = "rpi4-large"
    }
    server = "https://${var.rke2.server}:9345"
    token  = var.rke2.node_token
  })
  file_permission = "0600"
}

resource "local_file" "config_rke2_minish" {
  filename = "${path.module}/.terraform/tmp/configs/rke2/config-minish.yaml"
  content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
    node_ip = var.nodes.minish.node_ip
    node_labels = {
      "beta.kubernetes.io/instance-type" = "rpi4-medium"
      "node.kubernetes.io/instance-type" = "rpi4-medium"
    }
    server = "https://${var.rke2.server}:9345"
    token  = var.rke2.node_token
  })
  file_permission = "0600"
}

resource "local_file" "config_sysctl_k8s" {
  filename        = "${path.module}/.terraform/tmp/configs/systctl/99-k8s.conf"
  content         = file("${path.module}/templates/configs/systctl/99-k8s.conf")
  file_permission = "0644"
}

resource "local_file" "script_install_rke2" {
  filename        = "${path.module}/.terraform/tmp/scripts/install-rke2.sh"
  content         = file("${path.module}/templates/scripts/install-rke2.sh")
  file_permission = "0600"
}

resource "local_file" "script_start_rke2" {
  filename        = "${path.module}/.terraform/tmp/scripts/start-rke2.sh"
  content         = file("${path.module}/templates/scripts/start-rke2.sh")
  file_permission = "0600"
}

resource "terraform_data" "fushi" {
  triggers_replace = {
    config_rke2         = local_file.config_rke2_fushi.id
    config_sysctl_k8s   = local_file.config_sysctl_k8s.id
    script_install_rke2 = local_file.script_install_rke2.id
    script_start_rke2   = local_file.script_start_rke2.id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "fushi"
  }

  provisioner "file" {
    source      = local_file.config_sysctl_k8s.filename
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    script = local_file.script_install_rke2.filename
  }

  provisioner "file" {
    source      = local_file.config_rke2_fushi.filename
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    script = local_file.script_start_rke2.filename
  }
}

resource "local_file" "minish" {
  filename = "${path.module}/.terraform/tmp/scripts/minish-install-rke2.sh"
  content = templatefile("${path.module}/templates/scripts/install-rke2.sh", {
    server = "https://${var.rke2.server}:6443"
    token  = var.rke2.node_token
  })
  file_permission = "0600"
}

resource "terraform_data" "minish" {
  triggers_replace = {
    config_rke2         = local_file.config_rke2_minish.id
    config_sysctl_k8s   = local_file.config_sysctl_k8s.id
    script_install_rke2 = local_file.script_install_rke2.id
    script_start_rke2   = local_file.script_start_rke2.id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "minish"
  }

  provisioner "file" {
    source      = local_file.config_sysctl_k8s.filename
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "remote-exec" {
    script = local_file.script_install_rke2.filename
  }

  provisioner "file" {
    source      = local_file.config_rke2_minish.filename
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    script = local_file.script_start_rke2.filename
  }
}
