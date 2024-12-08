output "vaultwarden_secret_metadata" {
  value = {
    name      = kubernetes_secret.vaultwarden.metadata[0].name
    namespace = kubernetes_secret.vaultwarden.metadata[0].namespace
  }
  description = "Vaultwarden secret metadata"
}

output "metatube_secret_metadata" {
  value = {
    name      = kubernetes_secret.metatube.metadata[0].name
    namespace = kubernetes_secret.metatube.metadata[0].namespace
  }
  description = "Metatube secret metadata"
}

output "rclone_secret_metadata" {
  value = {
    name      = kubernetes_secret.rclone.metadata[0].name
    namespace = kubernetes_secret.rclone.metadata[0].namespace
  }
  description = "Rclone secret metadata"
}

output "etcd_snapshot_oauth_client_secret_id" {
  value       = scaleway_secret.etcd_snapshot_oauth_client.id
  description = "Kubernetes API token secret ID"
}