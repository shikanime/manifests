resource "local_file" "nishir" {
  filename = "${path.module}/.terraform/tmp/scripts/install-k3s-leader.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-leader.sh.tftpl", {
    etcd_access_key = var.etcd_snapshot.access_key_id
    etcd_bucket     = var.etcd_snapshot.bucket
    etcd_endpoint   = var.etcd_snapshot.endpoint
    etcd_region     = var.etcd_snapshot.region
    etcd_secret_key = var.etcd_snapshot.secret_access_key
    token           = var.k3s.token
  })
  file_permission = "0600"
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    nishir_id     = local_file.nishir.id
    sysctl_conf   = filemd5("${path.module}/configs/systctl/99-k3s.conf")
    tmpfiles_conf = filemd5("${path.module}/configs/tmpfiles/var-lib-rancher-k3s.conf")
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    source      = "${path.module}/configs/systctl/99-k3s.conf"
    destination = "/etc/sysctl.d/99-k3s.conf"
  }

  provisioner "file" {
    source      = "${path.module}/configs/tmpfiles/var-lib-rancher-k3s.conf"
    destination = "/etc/tmpfiles.d/var-lib-rancher-k3s.conf"
  }

  provisioner "remote-exec" {
    script = local_file.nishir.filename
  }
}

resource "local_file" "fushi" {
  filename = "${path.module}/.terraform/tmp/scripts/fushi-install-k3s-follower.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-follower.sh.tftpl", {
    server = "https://${var.endpoints.nishir}:6443"
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

  depends_on = [terraform_data.nishir]
}

resource "local_file" "minish" {
  filename = "${path.module}/.terraform/tmp/scripts/minish-install-k3s-follower.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-follower.sh.tftpl", {
    server = "https://${var.endpoints.nishir}:6443"
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

  depends_on = [terraform_data.nishir]
}
