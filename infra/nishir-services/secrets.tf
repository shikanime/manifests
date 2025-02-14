locals {
  tailscale_operator_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_operator_oauth_client.data)
  )
  longhorn_backupstore_s3_creds_data = jsondecode(
    base64decode(data.scaleway_secret_version.longhorn_backupstore_s3_creds.data)
  )
  vaultwarden_admin_token = jsondecode(
    base64decode(data.scaleway_secret_version.vaultwarden_admin_token.data)
  )
}

data "scaleway_secret_version" "tailscale_operator_oauth_client" {
  secret_id = var.secrets.tailscale_operator_oauth_client
  revision  = "latest"
}

data "scaleway_secret_version" "longhorn_backupstore_s3_creds" {
  secret_id = var.secrets.longhorn_backupstore_s3_creds
  revision  = "latest"
}

data "scaleway_secret_version" "vaultwarden_admin_token" {
  secret_id = var.secrets.vaultwarden_admin_token
  revision  = "latest"
}
