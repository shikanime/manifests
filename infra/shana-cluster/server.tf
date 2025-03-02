resource "hcloud_server" "default" {
  name        = var.name
  image       = "opensuse-15"
  server_type = "cax11"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = templatefile("${path.module}/templates/user-data.txt.tftpl", {
    name                    = var.name
    tailscale_client_id     = var.tailscale_client_id
    tailscale_client_secret = var.tailscale_client_secret
    tailscale_authkey       = tailscale_tailnet_key.default.key
  })
  ssh_keys = [hcloud_ssh_key.default.id]
}

resource "hcloud_server_network" "default" {
  server_id  = hcloud_server.default.id
  network_id = hcloud_network.default.id
}
