locals {
  etcd_snapshot_s3_creds = jsondecode(
    base64decode(data.scaleway_secret_version.etcd_snapshot_s3_creds.data)
  )
  connection_creds = jsondecode(
    base64decode(data.scaleway_secret_version.connection_creds.data)
  )
  tokens = jsondecode(
    base64decode(data.scaleway_secret_version.tokens.data)
  )
}

data "scaleway_secret_version" "etcd_snapshot_s3_creds" {
  secret_id = var.secrets.etcd_snapshot_s3_creds
  revision  = "latest"
}

data "scaleway_secret_version" "connection_creds" {
  secret_id = var.secrets.connection_creds
  revision  = "latest"
}

data "scaleway_secret_version" "tokens" {
  secret_id = var.secrets.tokens
  revision  = "latest"
}
