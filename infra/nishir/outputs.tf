output "vaultwarden_secret_metadata" {
  value = {
    name      = one(kubernetes_secret.vaultwarden.metadata).name
    namespace = one(kubernetes_secret.vaultwarden.metadata).namespace
  }
  description = "Vaultwarden secret metadata"
}

output "metatube_secret_metadata" {
  value = {
    name      = one(kubernetes_secret.metatube.metadata).name
    namespace = one(kubernetes_secret.metatube.metadata).namespace
  }
  description = "Metatube secret metadata"
}

output "rclone_secret_metadata" {
  value = {
    name      = one(kubernetes_secret.rclone.metadata).name
    namespace = one(kubernetes_secret.rclone.metadata).namespace
  }
  description = "Rclone secret metadata"
}

output "etcd_snapshot_oauth_client_secret_id" {
  value       = scaleway_secret.etcd_snapshot_oauth_client.id
  description = "Kubernetes API token secret ID"
}