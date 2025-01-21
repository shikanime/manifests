output "vaultwarden_secret_object_ref" {
  value = {
    name      = local.vaultwarden_secret_object_ref.name
    namespace = local.vaultwarden_secret_object_ref.namespace
  }
  description = "Vaultwarden secret metadata"
}

output "metatube_secret_object_ref" {
  value = {
    name      = local.metatube_secret_object_ref.name
    namespace = local.metatube_secret_object_ref.namespace
  }
  description = "Metatube secret metadata"
}

output "rclone_webdav_secret_object_ref" {
  value = {
    name      = local.rclone_webdav_secret_object_ref.name
    namespace = local.rclone_webdav_secret_object_ref.namespace
  }
  description = "Rclone Webdav secret metadata"
}

output "rclone_ftp_secret_object_ref" {
  value = {
    name      = local.rclone_ftp_secret_object_ref.name
    namespace = local.rclone_ftp_secret_object_ref.namespace
  }
  description = "Rclone FTP secret metadata"
}
