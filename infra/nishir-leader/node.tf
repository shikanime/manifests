resource "local_file" "nishir" {
  filename = "${path.module}/.terraform/tmp/scripts/install-k3.sh"
  content = templatefile("${path.module}/templates/scripts/install-k3s.sh", {
    etcd_access_key = var.etcd_snapshot.access_key_id
    etcd_bucket     = var.etcd_snapshot.bucket
    etcd_endpoint   = var.etcd_snapshot.endpoint
    etcd_region     = var.etcd_snapshot.region
    etcd_secret_key = var.etcd_snapshot.secret_access_key
  })
  file_permission = "0600"
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    nishir_id     = local_file.nishir.id
    sysctl_conf   = filemd5("${path.module}/configs/systctl/99-k3s.conf")
    tmpfiles_conf = filemd5("${path.module}/configs/tmpfiles/var-lib-rancher.conf")
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
    source      = "${path.module}/configs/tmpfiles/var-lib-rancher.conf"
    destination = "/etc/tmpfiles.d/var-lib-rancher.conf"
  }

  provisioner "remote-exec" {
    script = local_file.nishir.filename
  }
}
