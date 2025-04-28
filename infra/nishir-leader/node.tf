resource "local_file" "config_rke2" {
  filename = "${path.module}/.terraform/tmp/configs/rke2/config.yaml.tftpl"
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

resource "local_file" "manifest_tailscale_operator" {
  filename = "${path.module}/.terraform/tmp/manifests/tailscale-operator.yaml"
  content = templatefile("${path.module}/templates/manifests/tailscale-operator.yaml.tftpl", {
    name          = var.name
    client_id     = var.tailscale_operator.client_id
    client_secret = var.tailscale_operator.client_secret
  })
  file_permission = "0600"
}

resource "local_file" "manifest_canal" {
  filename        = "${path.module}/.terraform/tmp/manifests/rke2-canal-config.yaml"
  content         = file("${path.module}/templates/manifests/rke2-canal-config.yaml")
  file_permission = "0600"
}

resource "local_file" "manifest_coredns" {
  filename        = "${path.module}/.terraform/tmp/manifests/rke2-coredns-config.yaml"
  content         = file("${path.module}/templates/manifests/rke2-coredns-config.yaml")
  file_permission = "0600"
}
resource "local_file" "manifest_multus" {
  filename        = "${path.module}/.terraform/tmp/manifests/rke2-multus-config.yaml"
  content         = file("${path.module}/templates/manifests/rke2-multus-config.yaml")
  file_permission = "0600"
}

resource "terraform_data" "nishir" {
  triggers_replace = {
    config_rke2                 = local_file.config_rke2.id
    config_sysctl_conf          = local_file.config_sysctl_k8s.id
    config_tmpfiles_conf        = local_file.config_tmpfiles_rancher.id
    manifest_canal              = local_file.manifest_canal.id
    manifest_coredns            = local_file.manifest_coredns.id
    manifest_multus             = local_file.manifest_multus.id
    manifest_tailscale_operator = local_file.manifest_tailscale_operator.id
    script_install_rke2         = local_file.script_install_rke2.id
    script_start_rke2           = local_file.script_start_rke2.id
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
    content     = local_file.manifest_canal.content
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-canal-config.yaml"
  }

  provisioner "file" {
    content     = local_file.manifest_coredns.content
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-coredns-config.yaml"
  }

  provisioner "file" {
    content     = local_file.manifest_multus.content
    destination = "/var/lib/rancher/rke2/server/manifests/rke2-multus-config.yaml"
  }

  provisioner "file" {
    content     = local_file.manifest_tailscale_operator.content
    destination = "/var/lib/rancher/rke2/server/manifests/tailscale-operator.yaml"
  }
}
