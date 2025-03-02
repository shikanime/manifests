resource "hcloud_server" "default" {
  name        = var.name
  image       = "opensuse-15"
  server_type = "cax11"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = templatefile("${path.module}/templates/user-data.txt.tftpl", {
    tailscale_authkey = tailscale_tailnet_key.default.key
  })
}

resource "hcloud_server_network" "default" {
  server_id  = hcloud_server.default.id
  network_id = hcloud_network.default.id
}
