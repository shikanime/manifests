locals {
  nishir_k3s_node_token = base64decode(
    data.scaleway_secret_version.nishir_k3s_node_token.data
  )
  nishir_credentials_data = jsondecode(
    base64decode(data.scaleway_secret_version.nishir_credentials.data)
  )
  fushi_credentials_data = jsondecode(
    base64decode(data.scaleway_secret_version.fushi_credentials.data)
  )
}

data "scaleway_secret_version" "nishir_k3s_node_token" {
  secret_id = var.secrets.nishir_k3s_node_token
  revision  = "latest"
}

data "scaleway_secret_version" "nishir_credentials" {
  secret_id = var.secrets.nishir_credentials
  revision  = "latest"
}

data "scaleway_secret_version" "fushi_credentials" {
  secret_id = var.secrets.fushi_credentials
  revision  = "latest"
}
