resource "hcloud_ssh_key" "default" {
  name       = var.display_name
  public_key = tls_private_key.default.public_key_openssh
}

resource "tls_private_key" "default" {
  algorithm = "ED25519"
}
