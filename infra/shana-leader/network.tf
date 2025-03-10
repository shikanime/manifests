resource "hcloud_network" "default" {
  name     = var.name
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "default" {
  network_id   = hcloud_network.default.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
