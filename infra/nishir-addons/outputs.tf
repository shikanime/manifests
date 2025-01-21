output "vaultwarden_secret_object_ref" {
  value = {
    name      = one(kubernetes_secret.vaultwarden.metadata).name
    namespace = one(kubernetes_secret.vaultwarden.metadata).namespace
  }
  description = "Vaultwarden secret metadata"
}

output "metatube_secret_object_ref" {
  value = {
    name      = one(kubernetes_secret.metatube.metadata).name
    namespace = one(kubernetes_secret.metatube.metadata).namespace
  }
  description = "Metatube secret metadata"
}

output "rclone_webdav_secret_object_ref" {
  value = {
    name      = one(kubernetes_secret.rclone_webdav.metadata).name
    namespace = one(kubernetes_secret.rclone_webdav.metadata).namespace
  }
  description = "Rclone Webdav secret metadata"
}

output "rclone_ftp_secret_object_ref" {
  value = {
    name      = one(kubernetes_secret.rclone_ftp.metadata).name
    namespace = one(kubernetes_secret.rclone_ftp.metadata).namespace
  }
  description = "Rclone FTP secret metadata"
}
