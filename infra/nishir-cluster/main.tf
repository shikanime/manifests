data "http" "tailscale" {
  url = "https://tailscale.com/install.sh"
}

data "http" "k3s" {
  url = "https://get.k3s.io"
}

resource "terraform_data" "tailscale_nishir" {
  connection {
    type     = local.connection_creds.nishir_type
    user     = local.connection_creds.nishir_user
    host     = local.connection_creds.nishir_host
    password = local.connection_creds.nishir_password
  }
  provisioner "file" {
    content = join("\n", [
      "PORT=41641",
      "TS_EXTRA_ARGS=--advertise-exit-node --accept-routes --ssh"
    ])
    destination = "/etc/default/tailscaled"
  }
  provisioner "file" {
    content     = data.http.tailscale.response_body
    destination = "/tmp/nishir-tailscale-install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir-tailscale-install.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "tailscale up --authkey ${local.tokens.tailscale_auth_key}"
    ]
  }
}

resource "terraform_data" "k3s_nishir" {
  connection {
    type     = local.connection_creds.nishir_type
    user     = local.connection_creds.nishir_user
    host     = local.connection_creds.nishir_host
    password = local.connection_creds.nishir_password
  }
  provisioner "file" {
    content = join("\n", [
      "K3S_TLS_SAN=${var.endpoints.nishir}",
      "K3S_CLUSTER_CIDR=${join(",", var.cirds.cluster)}",
      "K3S_SERVICE_CIDR=${join(",", var.cirds.service)}",
      "K3S_DATA_DIR=/mnt/nishir/rancher/k3s",
      "K3S_NODE_IP=${join(",", var.ip_addresses.nishir)}",
      "K3S_FLANNEL_BACKEND=host-gw",
      "K3S_ETCD_S3=true",
      "K3S_ETCD_S3_ACCESS_KEY=${local.etcd_snapshot_s3_creds.access_key_id}",
      "K3S_ETCD_S3_SECRET_KEY=${local.etcd_snapshot_s3_creds.secret_access_key}",
      "K3S_ETCD_S3_ENDPOINT=fsn1.your-objectstorage.com",
      "K3S_ETCD_S3_REGION=${var.regions.aws_s3_bucket}",
      "K3S_ETCD_S3_BUCKET=${var.buckets.etcd_backups}",
      "K3S_TOKEN=${local.tokens.k3s_server_token}"
    ])
    destination = "/etc/default/k3s"
  }
  provisioner "file" {
    content     = data.http.k3s.response_body
    destination = "/tmp/nishir-k3s-install.sh"
  }
}

resource "terraform_data" "tailscale_flandre" {
  connection {
    type     = local.connection_creds.flandre_type
    user     = local.connection_creds.flandre_user
    host     = local.connection_creds.flandre_host
    password = local.connection_creds.flandre_password
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
    content     = data.http.tailscale.response_body
    destination = "/tmp/nishir-tailscale-install.sh"
  }
  provisioner "remote-exec" {
    script = "/tmp/nishir-tailscale-install.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "tailscale up --authkey ${local.tokens.tailscale_auth_key}"
    ]
  }
}

resource "terraform_data" "k3s_flandre" {
  connection {
    type     = local.connection_creds.flandre_type
    user     = local.connection_creds.flandre_user
    host     = local.connection_creds.flandre_host
    password = local.connection_creds.flandre_password
  }
  provisioner "file" {
    content = join("\n", [
      "SERVER=https://${var.endpoints.nishir}:6443",
      "TLS_SAN=${var.endpoints.flandre}",
      "CLUSTER_CIDR=${join(",", var.cirds.cluster)}",
      "SERVICE_CIDR=${join(",", var.cirds.service)}",
      "DATA_DIR=/mnt/nishir/rancher/k3s",
      "NODE_IP=${join(",", var.ip_addresses.flandre)}",
      "FLANNEL_BACKEND=host-gw",
      "TOKEN=${local.tokens.k3s_server_token}"
    ])
    destination = "/etc/default/k3s"
  }
  provisioner "file" {
    content     = data.http.k3s.response_body
    destination = "/tmp/nishir-k3s-install.sh"
  }
}
