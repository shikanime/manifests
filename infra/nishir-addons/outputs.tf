locals {
  vaultwarden_secret_object_ref   = one(kubernetes_secret.vaultwarden.metadata)
  metatube_secret_object_ref      = one(kubernetes_secret.metatube.metadata)
  rclone_webdav_secret_object_ref = one(kubernetes_secret.rclone_webdav.metadata)
  rclone_ftp_secret_object_ref    = one(kubernetes_secret.rclone_ftp.metadata)
}

output "vaultwarden_secret_object_ref" {
  value = {
    apiVersion = locals.vaultwarden_secret_object_ref.apiVersion
    kind       = locals.vaultwarden_secret_object_ref.kind
    name       = locals.vaultwarden_secret_object_ref.name
    namespace  = locals.vaultwarden_secret_object_ref.namespace
  }
  description = "Vaultwarden secret metadata"
}

output "metatube_secret_object_ref" {
  value = {
    apiVersion = locals.metatube_secret_object_ref.apiVersion
    kind       = locals.metatube_secret_object_ref.kind
    name       = locals.metatube_secret_object_ref.name
    namespace  = locals.metatube_secret_object_ref.namespace
  }
  description = "Metatube secret metadata"
}

output "rclone_webdav_secret_object_ref" {
  value = {
    apiVersion = locals.rclone_webdav_secret_object_ref.apiVersion
    kind       = locals.rclone_webdav_secret_object_ref.kind
    name       = locals.rclone_webdav_secret_object_ref.name
    namespace  = locals.rclone_webdav_secret_object_ref.namespace
  }
  description = "Rclone Webdav secret metadata"
}

output "rclone_ftp_secret_object_ref" {
  value = {
    apiVersion = locals.rclone_ftp_secret_object_ref.apiVersion
    kind       = locals.rclone_ftp_secret_object_ref.kind
    name       = locals.rclone_ftp_secret_object_ref.name
    namespace  = locals.rclone_ftp_secret_object_ref.namespace
  }
  description = "Rclone FTP secret metadata"
}
