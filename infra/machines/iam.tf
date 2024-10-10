resource "scaleway_iam_api_key" "nishir" {
  application_id = var.app
  description    = "Nishir Kubernetes Cluster"
}

resource "scaleway_iam_api_key" "fushi" {
  application_id = var.app
  description    = "Fushi Kubernetes Cluster"
}

resource "tailscale_tailnet_key" "nishir" {
  preauthorized = true
  description   = "Nishir"
}

resource "tailscale_tailnet_key" "fushi" {
  preauthorized = true
  description   = "Fushi"
}
