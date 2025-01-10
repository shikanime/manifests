locals {
  tailscale_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_oauth_client.data)
  )
  etcd_snapshot_s3_creds = jsondecode(
    base64decode(data.scaleway_secret_version.etcd_snapshot_s3_creds.data)
  )
  connection_creds = jsondecode(
    base64decode(data.scaleway_secret_version.connection_creds.data)
  )
  k3s_token = jsondecode(
    base64decode(data.scaleway_secret_version.k3s_token.data)
  )
}

data "scaleway_secret_version" "tailscale_oauth_client" {
  secret_id = var.secrets.tailscale_oauth_client
  revision  = "latest"
}

data "scaleway_secret_version" "etcd_snapshot_s3_creds" {
  secret_id = var.secrets.etcd_snapshot_s3_creds
  revision  = "latest"
}

data "scaleway_secret_version" "connection_creds" {
  secret_id = var.secrets.connection_creds
  revision  = "latest"
}

data "scaleway_secret_version" "k3s_token" {
  secret_id = var.secrets.k3s_token
  revision  = "latest"
}
