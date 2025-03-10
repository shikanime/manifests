output "ssh_private_key" {
  value     = tls_private_key.default.private_key_openssh
  sensitive = true
}

output "ssh_public_key" {
  value = tls_private_key.default.public_key_openssh
}
