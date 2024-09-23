output "rclone_password" {
  value       = random_password.rclone_password.result
  sensitive   = true
  description = "Password for rclone"
}

output "metatube_token" {
  value       = random_password.metatube_token.result
  sensitive   = true
  description = "Token for metatube"
}
