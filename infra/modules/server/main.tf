data "http" "tailscale" {
  url = "https://tailscale.com/install.sh"
}

resource "terraform_data" "tailscale" {
  connection {
    type     = local.connection_creds.type
    user     = local.connection_creds.user
    host     = local.connection_creds.host
    password = local.connection_creds.password
  }
  provisioner "file" {
    content     = data.http.tailscale.body
    destination = "/tmp/nishir/tailscale/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/tailscale/install.sh"
  }
  provisioner "remote-exec" {
    inline = [
      join(" ", [
        "tailscale",
        "up",
        "--authkey",
        local.tailscale_token.auth_key,
        "--accept-routes",
        "--ssh"
      ])
    ]
  }
}

data "http" "k3s" {
  url = "https://get.k3s.io"
}

resource "terraform_data" "k3s" {
  connection {
    type     = local.connection_creds.type
    user     = local.connection_creds.user
    host     = local.connection_creds.host
    password = local.connection_creds.password
  }
  provisioner "file" {
    content = jsonencode({
      tls-san            = var.endpoints
      cluster-cidr       = var.cirds.cluster
      service-cidr       = var.cirds.service
      data-dir           = "/mnt/nishir/rancher/k3s"
      node-ip            = var.ip_addresses
      flannel-backend    = "wireguard-native"
      flannel-iface      = "eth0"
      etcd-s3            = true
      etcd-s3-access-key = local.etcd_snapshot_s3_creds.access_key_id
      etcd-s3-secret-key = local.etcd_snapshot_s3_creds.secret_access_key
      etcd-s3-endpoint   = "https://fsn1.your-objectstorage.com"
      etcd-s3-region     = regex("s3://.*@(.*)", var.buckets.etcd_snapshot_s3).0
      etcd-s3-bucket     = regex("s3://(.*)@.*", var.buckets.etcd_snapshot_s3).0
      token             = local.k3s_token.token
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
