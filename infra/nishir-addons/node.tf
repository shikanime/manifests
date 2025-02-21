resource "local_file" "nishir" {
  filename = "${path.module}/.terraform/tmp/scripts/install-k3s-leader.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-leader.sh.tftpl", {
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
    install_script = local_file.nishir.content
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "remote-exec" {
    script = local_file.nishir.filename
  }
}

resource "local_file" "fushi" {
  filename = "${path.module}/.terraform/tmp/scripts/install-k3s-follower.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-follower.sh.tftpl", {
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

  provisioner "remote-exec" {
    script = local_file.fushi.filename
  }

  depends_on = [terraform_data.nishir_manifests]
}

resource "local_file" "minish" {
  filename = "${path.module}/.terraform/tmp/scripts/install-k3s-follower.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s-follower.sh.tftpl", {
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

  provisioner "remote-exec" {
    script = local_file.minish.filename
  }

  depends_on = [terraform_data.nishir_manifests]
}
