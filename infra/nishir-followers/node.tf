resource "local_file" "fushi" {
  filename = "${path.module}/.terraform/tmp/scripts/fushi-install-k3s.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s.sh.tftpl", {
    server = "https://${var.k3s.server}:6443"
    token  = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "fushi" {
  triggers_replace = {
    fushi_id    = local_file.fushi.id
    sysctl_conf = filemd5("${path.module}/configs/systctl/99-k3s.conf")
  }

  connection {
    type = "ssh"
    user = "root"
    host = "fushi"
  }

  provisioner "file" {
    source      = "${path.module}/configs/systctl/99-k3s.conf"
    destination = "/etc/sysctl.d/99-k3s.conf"
  }

  provisioner "remote-exec" {
    script = local_file.fushi.filename
  }
}

resource "local_file" "minish" {
  filename = "${path.module}/.terraform/tmp/scripts/minish-install-k3s.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s.sh.tftpl", {
    server = "https://${var.k3s.server}:6443"
    token  = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "minish" {
  triggers_replace = {
    minish_id   = local_file.minish.id
    sysctl_conf = filemd5("${path.module}/configs/systctl/99-k3s.conf")
  }

  connection {
    type = "ssh"
    user = "root"
    host = "minish"
  }

  provisioner "file" {
    source      = "${path.module}/configs/systctl/99-k3s.conf"
    destination = "/etc/sysctl.d/99-k3s.conf"
  }

  provisioner "remote-exec" {
    script = local_file.minish.filename
  }
}
