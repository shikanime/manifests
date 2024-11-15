locals {
  backup_target = "s3://${data.scaleway_object_bucket.longhorn_backups.name}@${data.scaleway_object_bucket.longhorn_backups.region}/"
}