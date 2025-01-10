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
    content = join("\n", [
      "PORT=41641",
      "TS_AUTHKEY=${local.tokens.tailscale_auth_key}",
      "TS_EXTRA_ARGS=--advertise-exit-node --accept-routes --ssh"
    ])
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
    content = join("\n", [
      "K3S_TLS_SAN=${var.endpoints.nishir}",
      "K3S_CLUSTER_CIDR=${var.cirds.cluster}",
      "K3S_SERVICE_CIDR=${var.cirds.service}",
      "K3S_DATA_DIR=/mnt/nishir/rancher/k3s",
      "K3S_NODE_IP=${var.ip_addresses.nishir}",
      "K3S_FLANNEL_BACKEND=host-gw",
      "K3S_ETCD_S3=true",
      "K3S_ETCD_S3_ACCESS_KEY=${local.etcd_snapshot_s3_creds.access_key_id}",
      "K3S_ETCD_S3_SECRET_KEY=${local.etcd_snapshot_s3_creds.secret_access_key}",
      "K3S_ETCD_S3_ENDPOINT=fsn1.your-objectstorage.com",
      "K3S_ETCD_S3_REGION=${regex("s3://.*@(.*)", var.buckets.etcd_snapshot_s3).0}",
      "K3S_ETCD_S3_BUCKET=${regex("s3://(.*)@.*", var.buckets.etcd_snapshot_s3).0}",
      "K3S_TOKEN=${local.tokens.k3s_server_token}"
    ])
    destination = "/etc/default/k3s"
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
    content = join("\n", [
      "PORT=41641",
      "TS_AUTHKEY=${local.tokens.tailscale_auth_key}",
      "TS_EXTRA_ARGS=--advertise-exit-node --accept-routes --ssh"
    ])
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
    content = join("\n", [
      "SERVER=https://${var.endpoints.nishir}:6443",
      "TLS_SAN=${var.endpoints.flandre}",
      "CLUSTER_CIDR=${var.cirds.cluster}",
      "SERVICE_CIDR=${var.cirds.service}",
      "DATA_DIR=/mnt/nishir/rancher/k3s",
      "NODE_IP=${var.ip_addresses.flandre}",
      "FLANNEL_BACKEND=host-gw",
      "TOKEN=${local.tokens.k3s_server_token}"
    ])
    destination = "/etc/default/k3s"
  }
  provisioner "file" {
    content     = data.http.k3s.body
    destination = "/tmp/nishir/k3s/install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir/k3s/install.sh"
  }
}
