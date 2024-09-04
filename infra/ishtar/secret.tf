locals {
  tailscale_oauth_client_data = jsondecode(
    base64decode(data.scaleway_secret_version.tailscale_oauth_client.data)
  )
}

data "scaleway_secret_version" "tailscale_oauth_client" {
  secret_id = var.secrets.tailscale_oauth_client
  revision  = "latest"
}
