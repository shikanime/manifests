resource "tailscale_tailnet_key" "default" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  description   = var.display_name
  tags          = ["tag:k8s-node", "tag:server"]
}