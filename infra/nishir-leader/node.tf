resource "local_file" "config_rke2" {
  filename = "${path.module}/.terraform/tmp/configs/rke2/config.yaml"
  content = templatefile("${path.module}/templates/configs/rke2/config.yaml.tftpl", {
    etcd_s3_access_key_id     = var.etcd_snapshot.access_key_id
    etcd_s3_bucket            = var.etcd_snapshot.bucket
    etcd_s3_endpoint          = var.etcd_snapshot.endpoint
    etcd_s3_region            = var.etcd_snapshot.region
    etcd_s3_secret_access_key = var.etcd_snapshot.secret_access_key
    node_ip                   = var.rke2.node_ip
    tls_san                   = var.rke2.tls_san
  })
  file_permission = "0600"
}

resource "local_file" "config_sysctl_k8s" {
  filename        = "${path.module}/.terraform/tmp/configs/systctl/99-k8s.conf"
  content         = file("${path.module}/templates/configs/systctl/99-k8s.conf")
  file_permission = "0644"
}

resource "local_file" "config_tmpfiles_rancher" {
  filename        = "${path.module}/.terraform/tmp/configs/tmpfiles/var-lib-rancher.conf"
  content         = file("${path.module}/templates/configs/tmpfiles/var-lib-rancher.conf")
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

resource "local_file" "manifest_tailscale" {
  filename = "${path.module}/.terraform/tmp/manifests/tailscale.yaml"
  content = templatefile("${path.module}/templates/manifests/tailscale.yaml.tftpl", {
    name          = var.name
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  })
  file_permission = "0600"
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    config_rke2          = local_file.config_rke2.id
    config_sysctl_conf   = local_file.config_sysctl_k8s.id
    config_tmpfiles_conf = local_file.config_tmpfiles_rancher.id
    manifest_tailscale   = local_file.manifest_tailscale.id
    script_install_rke2  = local_file.script_install_rke2.id
    script_start_rke2    = local_file.script_start_rke2.id
  }

  connection {
    type = "ssh"
    user = "root"
    host = "nishir"
  }

  provisioner "file" {
    source      = local_file.config_sysctl_k8s.filename
    destination = "/etc/sysctl.d/99-k8s.conf"
  }

  provisioner "file" {
    source      = local_file.config_tmpfiles_rancher.filename
    destination = "/etc/tmpfiles.d/var-lib-rancher.conf"
  }

  provisioner "remote-exec" {
    script = local_file.script_install_rke2.filename
  }

  provisioner "file" {
    source      = local_file.config_rke2.filename
    destination = "/etc/rancher/rke2/config.yaml"
  }

  provisioner "remote-exec" {
    script = local_file.script_start_rke2.filename
  }

  provisioner "file" {
    content     = local_file.manifest_tailscale.content
    destination = "/var/lib/rancher/rke2/server/manifests/tailscale.yaml"
  }
}
