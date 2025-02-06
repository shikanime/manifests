resource "hcloud_server" "default" {
  name        = var.name
  image       = "opensuse-15"
  server_type = "cax11"
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
  user_data = <<-EOF
  #cloud-config
  package_update: true
  package_upgrade: true
  packages:
    - curl
  runcmd:
    - curl -sfL https://get.k3s.io | sh -s - server \
        --cluster-init
  EOF
  ssh_keys  = [hcloud_ssh_key.default.id]
}

resource "hcloud_server_network" "default" {
  server_id  = hcloud_server.default.id
  network_id = hcloud_network.default.id
}
