data "http" "tailscale" {
  url = "https://tailscale.com/install.sh"
}

data "http" "k3s" {
  url = "https://get.k3s.io"
}

resource "terraform_data" "tailscale_nishir" {
  connection {
    type     = local.connection_creds.nishir.type
    user     = local.connection_creds.nishir.user
    host     = local.connection_creds.nishir.host
    password = local.connection_creds.nishir.password
  }
  provisioner "file" {
    content = <<-EOT
    PORT="41641"
    TS_AUTHKEY="${local.tailscale_oauth_client_data.auth_key}"
    TS_EXTRA_ARGS="--advertise-exit-node --accept-routes --ssh"
    EOT
    destination = "/etc/default/tailscaled"
  }
  provisioner "file" {
    content     = data.http.tailscale.body
    destination = "/tmp/nishir/tailscale/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/tailscale/install.sh"
  }
}

resource "terraform_data" "k3s_nishir" {
  connection {
    type     = local.connection_creds.nishir.type
    user     = local.connection_creds.nishir.user
    host     = local.connection_creds.nishir.host
    password = local.connection_creds.nishir.password
  }
  provisioner "file" {
    content = jsonencode({
      tls-san            = var.endpoints.nishir
      cluster-cidr       = var.cirds.cluster
      service-cidr       = var.cirds.service
      data-dir           = "/mnt/nishir/rancher/k3s"
      node-ip            = var.ip_addresses.nishir
      flannel-backend    = "host-gw"
      etcd-s3            = true
      etcd-s3-access-key = local.etcd_snapshot_s3_creds.access_key_id
      etcd-s3-secret-key = local.etcd_snapshot_s3_creds.secret_access_key
      etcd-s3-endpoint   = "fsn1.your-objectstorage.com"
      etcd-s3-region     = regex("s3://.*@(.*)", var.buckets.etcd_snapshot_s3).0
      etcd-s3-bucket     = regex("s3://(.*)@.*", var.buckets.etcd_snapshot_s3).0
      token              = local.k3s_token.token
    })
    destination = "/etc/rancher/k3s/config.yaml"
  }
  provisioner "file" {
    content     = data.http.k3s.body
    destination = "/tmp/nishir/k3s/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/k3s/install.sh"
  }
}

resource "terraform_data" "tailscale_flandre" {
  connection {
    type     = local.connection_creds.flandre.type
    user     = local.connection_creds.flandre.user
    host     = local.connection_creds.flandre.host
    password = local.connection_creds.flandre.password
  }
  provisioner "file" {
    content = <<-EOT
    PORT="41641"
    TS_AUTHKEY="${local.tailscale_oauth_client_data.auth_key}"
    TS_EXTRA_ARGS="--advertise-exit-node --accept-routes --ssh"
    EOT
    destination = "/etc/default/tailscaled"
  }
  provisioner "file" {
    content     = data.http.tailscale.body
    destination = "/tmp/nishir/tailscale/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/tailscale/install.sh"
  }
}


resource "terraform_data" "k3s_flandre" {
  connection {
    type     = local.connection_creds.flandre.type
    user     = local.connection_creds.flandre.user
    host     = local.connection_creds.flandre.host
    password = local.connection_creds.flandre.password
  }
  provisioner "file" {
    content = jsonencode({
      server          = "https://${var.endpoints.nishir}:6443"
      tls-san         = var.endpoints.flandre
      cluster-cidr    = var.cirds.cluster
      service-cidr    = var.cirds.service
      data-dir        = "/mnt/nishir/rancher/k3s"
      node-ip         = var.ip_addresses.flandre
      flannel-backend = "host-gw"
      token           = local.k3s_token.token
    })
    destination = "/etc/rancher/k3s/config.yaml"
  }
  provisioner "file" {
    content     = data.http.k3s.body
    destination = "/tmp/nishir/k3s/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/k3s/install.sh"
  }
}
